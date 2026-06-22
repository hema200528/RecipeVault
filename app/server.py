"""
server.py — connects the cute RecipeVault web page to the real RAG pipeline.
Run this, then open the cute page in your browser.
"""

import os
import psycopg2
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
from pinecone import Pinecone
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

load_dotenv()

print("Loading RecipeVault server...")
model = SentenceTransformer("all-MiniLM-L6-v2")

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    options="-c search_path=public"
)
conn.autocommit = True

# try Pinecone, fall back to DB search if unavailable
USE_RAG = True
try:
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index("recipevault")
    index.describe_index_stats()
    print("Connected to Pinecone — RAG mode active.")
except Exception:
    USE_RAG = False
    print("Pinecone unavailable — using database fallback.")

app = Flask(__name__)
CORS(app)


def fetch_details(cur, recipe_id):
    cur.execute("""
        SELECT r.title, r.flavour_profile, r.occasion,
               COUNT(s.step_id) AS step_count
        FROM recipe r
        LEFT JOIN step s ON r.recipe_id = s.recipe_id
        WHERE r.recipe_id = %s
        GROUP BY r.recipe_id, r.title, r.flavour_profile, r.occasion
    """, (recipe_id,))
    return cur.fetchone()


@app.route("/search")
def search():
    question = request.args.get("q", "").strip()
    if not question:
        return jsonify([])

    cur = conn.cursor()
    recipes = []

    if USE_RAG:
        try:
            vector = model.encode(question).tolist()
            results = index.query(vector=vector, top_k=6, include_metadata=True)
            for match in results["matches"]:
                rid = int(match["id"])
                row = fetch_details(cur, rid)
                if row:
                    recipes.append({
                        "id": rid, "title": row[0], "flavour": row[1],
                        "occasion": row[2], "steps": row[3],
                        "score": round(match["score"], 2)
                    })
        except Exception:
            recipes = []

    # fallback if RAG off or returned nothing
    if not recipes:
        cur.execute("""
            SELECT r.recipe_id, r.title, r.flavour_profile, r.occasion,
                   COUNT(s.step_id)
            FROM recipe r
            LEFT JOIN step s ON r.recipe_id = s.recipe_id
            WHERE LOWER(r.title) LIKE %s OR LOWER(r.flavour_profile) LIKE %s
            GROUP BY r.recipe_id, r.title, r.flavour_profile, r.occasion
            LIMIT 6
        """, (f"%{question.lower()}%", f"%{question.lower()}%"))
        for row in cur.fetchall():
            recipes.append({
                "id": row[0], "title": row[1], "flavour": row[2],
                "occasion": row[3], "steps": row[4], "score": None
            })

    cur.close()
    return jsonify(recipes)

@app.route("/recipe/<int:recipe_id>")
def recipe_detail(recipe_id):
    """Get the full recipe: title, ingredients, and ordered steps."""
    cur = conn.cursor()

    # basic info
    cur.execute("""
        SELECT title, flavour_profile, occasion
        FROM recipe WHERE recipe_id = %s
    """, (recipe_id,))
    info = cur.fetchone()
    if not info:
        cur.close()
        return jsonify({"error": "not found"}), 404

    # ingredients
    cur.execute("""
        SELECT i.name
        FROM recipe_ingredient ri
        JOIN ingredient i ON ri.ingredient_id = i.ingredient_id
        WHERE ri.recipe_id = %s
    """, (recipe_id,))
    ingredients = [row[0] for row in cur.fetchall()]

    # steps in order
    cur.execute("""
        SELECT step_number, description
        FROM step
        WHERE recipe_id = %s
        ORDER BY step_number
    """, (recipe_id,))
    steps = [{"number": row[0], "text": row[1]} for row in cur.fetchall()]

    cur.close()
    return jsonify({
        "id": recipe_id,
        "title": info[0],
        "flavour": info[1],
        "occasion": info[2],
        "ingredients": ingredients,
        "steps": steps
    })
# serve the cute page
@app.route("/")
def home():
    return send_from_directory(".", "recipevault_cute.html")


if __name__ == "__main__":
    print("\nServer running! Open this in your browser:")
    print("   http://localhost:5050\n")
    app.run(port=5050, debug=False)