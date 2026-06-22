"""
build_index.py
Loads all recipes from PostgreSQL, turns them into embeddings,
and uploads them to Pinecone. Run this ONCE to set up the search.
"""

import os
import psycopg2
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
from pinecone import Pinecone, ServerlessSpec

# ── load settings from .env ───────────────────────────
load_dotenv()
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")

print("Starting...")

# ── connect to PostgreSQL ─────────────────────────────
conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER")
)
cur = conn.cursor()
print("Connected to PostgreSQL")

# ── load the embedding model ──────────────────────────
print("Loading embedding model (first time downloads ~90MB)...")
model = SentenceTransformer("all-MiniLM-L6-v2")
print("Model loaded")

# ── set up Pinecone ───────────────────────────────────
pc = Pinecone(api_key=PINECONE_API_KEY)
INDEX_NAME = "recipevault"

# create the index if it doesn't exist
existing = [i.name for i in pc.list_indexes()]
if INDEX_NAME not in existing:
    print(f"Creating Pinecone index '{INDEX_NAME}'...")
    pc.create_index(
        name=INDEX_NAME,
        dimension=384,  # all-MiniLM-L6-v2 produces 384-number vectors
        metric="cosine",
        spec=ServerlessSpec(cloud="aws", region="us-east-1")
    )
    print("Index created")
else:
    print("Index already exists")

index = pc.Index(INDEX_NAME)

# ── fetch all recipes from PostgreSQL ─────────────────
print("Fetching recipes from database...")
cur.execute("""
    SELECT recipe_id, title, occasion, flavour_profile, directions
    FROM recipe
""")
recipes = cur.fetchall()
print(f"Got {len(recipes)} recipes")

# ── embed and upload in batches ───────────────────────
print("Embedding and uploading to Pinecone (this takes a minute)...")
batch = []
for recipe_id, title, occasion, flavour, directions in recipes:
    # the text we search against: title + flavour + occasion
    text = f"{title}. Flavour: {flavour}. Occasion: {occasion}."
    vector = model.encode(text).tolist()

    batch.append({
        "id": str(recipe_id),
        "values": vector,
        "metadata": {
            "title": title,
            "occasion": occasion or "",
            "flavour": flavour or ""
        }
    })

    # upload every 100
    if len(batch) >= 100:
        index.upsert(vectors=batch)
        batch = []
        print(".", end="", flush=True)

# upload any leftovers
if batch:
    index.upsert(vectors=batch)

print("\nDone! All recipes are now searchable in Pinecone.")

# show the index stats
stats = index.describe_index_stats()
print(f"Total vectors in index: {stats['total_vector_count']}")

cur.close()
conn.close()