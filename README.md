# RecipeVault 🧁

**A Cozy Dessert Recipe Assistant Powered by a RAG Pipeline**

**Student:** Hemamalini Kamaladhasan
**Roll Number:** ZDA24B025
**Track:** A — RAG Pipeline
**Course:** Z2004 Database Management Systems · IIT Madras Zanzibar
**Database:** PostgreSQL 18 · **Vector store:** Pinecone
**Developed on:** macOS (Apple Silicon), using VS Code + SQLTools

---

## Project Overview

RecipeVault is a dessert recipe assistant built on a relational PostgreSQL database with a Retrieval-Augmented Generation (RAG) pipeline. A user asks for a dessert in plain English  for example, *"a chocolate cake under 5 steps"* and the app returns matching recipes pulled directly from the database, each grounded and cited.

Searching for recipes online is often overwhelming and cluttered. RecipeVault solves this with intelligent semantic search and a calm, soothing interface that keeps the focus on finding a recipe quickly.

The original dataset of 100,000 Kaggle recipes was narrowed to **1,755 dessert recipes** by title keywords. Two custom columns `occasion` and `flavour_profile`  were added to enrich it.

---

## Repository Structure

```
RecipeVault/
├── schema/        ER diagram + final DDL script (schema.sql)
├── data/          Full dataset (desserts.csv) + import script
├── queries/       All 10 SQL queries, labelled by purpose
├── performance/   Indexing, EXPLAIN ANALYZE results, stored procedure
├── app/           Python RAG application (terminal + web interface)
├── report/        Final report (PDF)
├── demo/          5-minute demo video
└── README.md      This file
```

---

## How It Works (RAG Pipeline)

1. The user's question is turned into an **embedding** (384 numbers) using `all-MiniLM-L6-v2` in Python.
2. The embedding is sent to **Pinecone**, which finds the closest matching recipes by meaning.
3. The matching recipe IDs are used to fetch full details from **PostgreSQL**.
4. Results are shown with a match score and a link to the source recipe.

If Pinecone or the network is unavailable, the app **falls back** to a PostgreSQL keyword search, so it always returns results.

---

## Setup and Run Instructions (Start to Finish)

This project was developed on macOS using **VS Code with the SQLTools extension** to run SQL, and the terminal for starting PostgreSQL and running the Python app.

### Prerequisites
- PostgreSQL 18 (via Homebrew)
- Python 3
- VS Code with the **SQLTools** + **SQLTools PostgreSQL** extensions
- A free Pinecone account + API key

### Step 1 — Start PostgreSQL (terminal)
```bash
brew services start postgresql@18
```

### Step 2 — Connect VS Code to the database
In VS Code, open the **SQLTools** sidebar and connect with:
- Driver: **PostgreSQL**
- Server: `localhost`  ·  Port: `5432`
- Database: `postgres`  ·  Username: your Mac username
- (no password)

### Step 3 — Create the tables (VS Code)
Open `schema/schema.sql` in VS Code, connect via SQLTools, and run the whole file (right-click → Run Query / **Cmd+E Cmd+E**). Then verify by running:
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```
You should see 5 tables: recipe, ingredient, recipe_ingredient, step, ner_tag.

### Step 4 — Load the data (terminal)
```bash
pip3 install pandas psycopg2-binary
python3 data/import_data.py
```
Then in VS Code, verify:
```sql
SELECT COUNT(*) FROM recipe;   - should return 1755
```

### Step 5 — Install app dependencies (terminal)
```bash
pip3 install sentence-transformers pinecone python-dotenv flask flask-cors
```

### Step 6 — Configure secrets
Copy `app/.env.example` to `app/.env` and fill in your Pinecone API key:
```
PINECONE_API_KEY=your_key_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=postgres
DB_USER=your_username
```

### Step 7 — Build the vector index (terminal, run once)
```bash
cd app
python3 build_index.py
```
This embeds all 1,755 recipes into Pinecone. Expect: "Total vectors in index: 1755".

### Step 8 — Run the app (terminal)

**Web interface (recommended):**
```bash
python3 server.py
```
Then open **http://localhost:5050** in your browser.

**Terminal interface:**
```bash
python3 app.py
```
Type a craving (e.g. "chocolate cake"); type `quit` to exit.

---

## Three Test Cases (Expected Outputs)

| Input | Expected Output |
|-------|-----------------|
| `chocolate cake` | Chocolate-flavour cakes (e.g. "Chocolate Cake And Its Icing") with match scores |
| `lemon dessert` | Citrus-flavour desserts (lemon/lime tarts, pies) |
| `christmas treat` | Recipes with occasion = Christmas |

### Fallback Plan (network/API down)
If Pinecone is unavailable, the app automatically switches to a PostgreSQL keyword search on recipe titles and flavours. For example, searching `chocolate` still returns chocolate recipes via SQL `LIKE` matching — no crash, results still appear.

---

## Database Design

5 tables, normalised to 3NF:

| Table | Primary Key | Purpose |
|-------|-------------|---------|
| `recipe` | recipe_id | Core data: title, directions, occasion, flavour_profile |
| `ingredient` | ingredient_id | Master list of unique ingredients |
| `recipe_ingredient` | recipe_id + ingredient_id | Junction (M:N) + quantity, unit |
| `step` | step_id | Ordered cooking steps (weak entity) |
| `ner_tag` | ner_id | Keyword tags per recipe (weak entity) |

All foreign keys use `ON DELETE CASCADE`.

### Row Counts
| Table | Rows |
|-------|------|
| recipe | 1,755 |
| ingredient | 9,277 |
| recipe_ingredient | 17,015 |
| step | 13,762 |
| ner_tag | 15,333 |

---

## Queries (10, labelled in queries/queries.sql)

| # | Type | Description |
|---|------|-------------|
| 1–2 | Aggregation | Recipe count per flavour / per occasion |
| 3–4 | Join | Recipes with ingredients / with step counts |
| 5–6 | Subquery | Above-average ingredient count / no NER tags |
| 7–8 | CTE | Difficulty classification / top ingredients per flavour |
| 9–10 | Window function | Rank within occasion / running total by flavour |

Plus a stored procedure `get_recipes_by_flavour()` in performance/.

---

## Performance

5 B-Tree indexes on the columns the app filters and joins on. Measured with `EXPLAIN ANALYZE` in VS Code, before and after:

| Metric | Before | After |
|--------|--------|-------|
| Scan type | Hash Join + Seq Scan | Nested Loop + Index Scan |
| Execution time | 9.421 ms | 0.191 ms |
| **Improvement** | baseline | **~49× faster** |

---

## AI Usage Disclosure

Claude (Anthropic) was used for syntax suggestions, debugging, dataset filtering, and structuring the code and documentation. All design decisions, query logic, and execution were carried out and verified independently, and the system was built and tested on my own machine.
