"""
app.py — RecipeVault terminal app
A RAG pipeline dessert finder with a fallback plan.

Normal mode: embeds your question -> searches Pinecone -> fetches from PostgreSQL.
Fallback mode: if Pinecone/network is unavailable, falls back to a
PostgreSQL keyword search so the app always works.
"""

import os
import psycopg2
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
from pinecone import Pinecone

# ── setup ─────────────────────────────────────────────
load_dotenv()

print("Loading RecipeVault...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# connect to PostgreSQL (always needed)
conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER")
)
cur = conn.cursor()

# try to connect to Pinecone — if it fails, we use fallback mode
USE_RAG = True
try:
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index("recipevault")
    index.describe_index_stats()  # test the connection
    print("Connected to Pinecone — RAG mode active.")
except Exception as e:
    USE_RAG = False
    print("Pinecone unavailable — using database fallback search.")


def fetch_details(recipe_id):
    """Get full recipe details from PostgreSQL."""
    cur.execute("""
        SELECT r.title, r.flavour_profile, r.occasion,
               COUNT(s.step_id) AS step_count
        FROM recipe r
        LEFT JOIN step s ON r.recipe_id = s.recipe_id
        WHERE r.recipe_id = %s
        GROUP BY r.recipe_id, r.title, r.flavour_profile, r.occasion
    """, (recipe_id,))
    return cur.fetchone()


def search_rag(question, top_k=5):
    """RAG search: embed question -> Pinecone -> PostgreSQL."""
    query_vector = model.encode(question).tolist()
    results = index.query(vector=query_vector, top_k=top_k, include_metadata=True)

    recipes = []
    for match in results["matches"]:
        recipe_id = int(match["id"])
        row = fetch_details(recipe_id)
        if row:
            recipes.append({
                "id": recipe_id, "title": row[0], "flavour": row[1],
                "occasion": row[2], "steps": row[3], "score": match["score"]
            })
    return recipes


def search_fallback(question, top_k=5):
    """Fallback: simple PostgreSQL keyword search on title and flavour."""
    cur.execute("""
        SELECT r.recipe_id, r.title, r.flavour_profile, r.occasion,
               COUNT(s.step_id) AS step_count
        FROM recipe r
        LEFT JOIN step s ON r.recipe_id = s.recipe_id
        WHERE LOWER(r.title) LIKE %s
           OR LOWER(r.flavour_profile) LIKE %s
        GROUP BY r.recipe_id, r.title, r.flavour_profile, r.occasion
        LIMIT %s
    """, (f"%{question.lower()}%", f"%{question.lower()}%", top_k))

    recipes = []
    for row in cur.fetchall():
        recipes.append({
            "id": row[0], "title": row[1], "flavour": row[2],
            "occasion": row[3], "steps": row[4], "score": None
        })
    return recipes


def search_recipes(question, top_k=5):
    """Use RAG if available, otherwise fall back to keyword search."""
    if USE_RAG:
        try:
            return search_rag(question, top_k)
        except Exception:
            print("(RAG search failed, switching to fallback...)")
            return search_fallback(question, top_k)
    else:
        return search_fallback(question, top_k)


# ── main loop ─────────────────────────────────────────
mode = "RAG semantic search" if USE_RAG else "database keyword search"
print("\n" + "=" * 52)
print("  Welcome to RecipeVault!")
print(f"  Mode: {mode}")
print("  Ask me for a dessert. Type 'quit' to exit.")
print("=" * 52)

while True:
    question = input("\nWhat are you craving? > ").strip()

    if question.lower() in ("quit", "exit", "q"):
        print("Bye! Happy baking.")
        break

    if not question:
        continue

    matches = search_recipes(question)

    if not matches:
        print("Hmm, I couldn't find anything. Try another craving!")
        continue

    print(f"\nHere are {len(matches)} treats for you:\n")
    for i, r in enumerate(matches, 1):
        print(f"  {i}. {r['title']}")
        print(f"     {r['flavour']} | {r['occasion']} | {r['steps']} steps")
        score_text = f"match score: {r['score']:.2f} | " if r['score'] is not None else ""
        print(f"     {score_text}source: recipe #{r['id']}")
        print()

cur.close()
conn.close()