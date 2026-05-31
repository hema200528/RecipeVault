import pandas as pd
import psycopg2
import ast

# ── connect ───────────────────────────────────────────
conn = psycopg2.connect(
    host="localhost",
    dbname="postgres",
    user="HemaMalini"
)
cur = conn.cursor()
print("Connected!")

# ── read CSV ──────────────────────────────────────────
df = pd.read_csv("/Users/HemaMalini/DBMS_PRO/desserts.csv")
print(f"Loaded {len(df)} rows from CSV")

# ── build recipe_map from existing DB ─────────────────
# instead of inserting, just fetch what's already there
print("Building recipe map from existing data...")
cur.execute("SELECT title, recipe_id FROM recipe")
title_to_id = {row[0]: row[1] for row in cur.fetchall()}

recipe_map = {}
for _, row in df.iterrows():
    title = str(row['title'])[:254]
    if title in title_to_id:
        recipe_map[row['id']] = title_to_id[title]

print(f"Mapped {len(recipe_map)} recipes")

# ── insert ingredients ────────────────────────────────
print("Inserting ingredients...")

ingredient_cache = {}

for _, row in df.iterrows():
    recipe_id = recipe_map.get(row['id'])
    if not recipe_id:
        continue

    try:
        ingredients = ast.literal_eval(row['ingredients'])
    except:
        continue

    for raw in ingredients:
        name = str(raw).strip()[:98]
        if not name:
            continue

        if name not in ingredient_cache:
            cur.execute("""
                INSERT INTO Ingredient (name)
                VALUES (%s)
                ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
                RETURNING ingredient_id
            """, (name,))
            ingredient_cache[name] = cur.fetchone()[0]

        cur.execute("""
            INSERT INTO Recipe_Ingredient (recipe_id, ingredient_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
        """, (recipe_id, ingredient_cache[name]))

conn.commit()
print(f"Inserted {len(ingredient_cache)} unique ingredients")
# ── insert steps ──────────────────────────────────────
print("Inserting steps...")

step_count = 0
for _, row in df.iterrows():
    recipe_id = recipe_map.get(row['id'])
    if not recipe_id:
        continue

    try:
        steps = ast.literal_eval(row['directions'])
    except:
        steps = [str(row['directions'])]

    for step_num, step_text in enumerate(steps, start=1):
        step_text = str(step_text).strip()
        if step_text:
            cur.execute("""
                INSERT INTO Step (recipe_id, step_number, description)
                VALUES (%s, %s, %s)
            """, (recipe_id, step_num, step_text[:5000]))
            step_count += 1

conn.commit()
print(f"Inserted {step_count} steps")

# ── insert NER tags ───────────────────────────────────
print("Inserting NER tags...")

ner_count = 0
for _, row in df.iterrows():
    recipe_id = recipe_map.get(row['id'])
    if not recipe_id:
        continue

    try:
        tags = ast.literal_eval(row['NER'])
    except:
        continue

    for tag in tags:
        tag = str(tag).strip()[:49]
        if tag:
            cur.execute("""
                INSERT INTO NER_Tag (recipe_id, tag)
                VALUES (%s, %s)
            """, (recipe_id, tag))
            ner_count += 1

conn.commit()
print(f"Inserted {ner_count} NER tags")

# ── final check ───────────────────────────────────────
print("\nFinal row counts:")
for table in ['recipe', 'ingredient', 'recipe_ingredient', 'step', 'ner_tag']:
    cur.execute(f"SELECT COUNT(*) FROM {table}")
    print(f"  {table}: {cur.fetchone()[0]:,} rows")

cur.close()
conn.close()
print("\nDone!")