# RecipeVault

**Student:** Hemamalini Kamaladhasan  
**Roll Number:** ZDA24B025  
**Track:** A — RAG Pipeline  
**Database:** PostgreSQL 18  

---

## Project Overview

## Project Overview

RecipeVault is a smart dessert recipe assistant built on a relational 
database and a RAG pipeline. The original dataset contained 100,000 
recipes from Kaggle, this was narrowed down specifically to dessert 
and baking recipes based on title keywords, resulting in a focused 
dataset of 1,755 recipes. The system answers natural language questions 
like "give me a chocolate cake recipe under 5 steps" with grounded, 
cited answers pulled directly from the database. Two custom columns :
occasion and flavour_profile were added to enrich the dataset beyond 
what the original source provided.

---

## Repository Structure

| File | Milestone | Purpose |
|---|---|---|
| `schema.sql` | M1 | Creates all 5 tables in PostgreSQL |
| `er_diagram.png` | M1 | ER diagram in Chen notation |
| `desserts.csv` | M2 | Filtered dessert dataset (1,755 recipes) |
| `import_data.py` | M2 | Loads CSV data into PostgreSQL |
| `queries.sql` | M2 | 10 SQL queries |
| `README.md` | All | This file |

---

## Milestone 1 — Schema Design

### How to Run

**Step 1 — Start PostgreSQL**
```bash
brew services start postgresql@18
```

**Step 2 — Connect and create tables**
```bash
psql postgres
```
Then paste contents of `schema.sql` and run.

**Step 3 — Verify**
```sql
\dt
```
Should show 5 tables: recipe, ingredient, recipe_ingredient, step, ner_tag

---

### Schema Overview

| Table | Type | Purpose |
|---|---|---|
| `recipe` | Entity | Core recipe data — title, directions, occasion, flavour_profile |
| `ingredient` | Entity | Normalised ingredient master list |
| `recipe_ingredient` | Junction | Resolves M:N between recipes and ingredients |
| `step` | Weak Entity | Ordered cooking steps per recipe |
| `ner_tag` | Weak Entity | NLP extracted food tags per recipe |

---

### 3NF Argument

**recipe**
- FD: recipe_id → title, directions, link, source, occasion, flavour_profile
- No partial dependencies (single attribute PK)
- No transitive dependencies
- ✓ 3NF

**ingredient**
- FD: ingredient_id → name, category
- No partial or transitive dependencies
- ✓ 3NF

**recipe_ingredient**
- FD: (recipe_id, ingredient_id) → quantity, unit
- quantity and unit depend on the full composite key — not just one part
- ✓ 3NF

**step**
- FD: step_id → recipe_id, step_number, description
- All attributes depend directly on step_id
- ✓ 3NF

**ner_tag**
- FD: ner_id → recipe_id, tag
- All attributes depend directly on ner_id
- ✓ 3NF

---

## Milestone 2 — Dataset and Queries

### Dataset

- **Source:** RecipeNLP dataset from Kaggle
- **Link:** https://www.kaggle.com/datasets/paultimothymooney/recipenlg
- **Filtered to:** Dessert and baking recipes only
- **Rows imported:** 1,755 recipes
- **Extra columns added:** occasion, flavour_profile

### Data Dictionary

| Column | Table | Description |
|---|---|---|
| title | recipe | Recipe name |
| directions | recipe | Full cooking instructions |
| occasion | recipe | Everyday, Christmas, Birthday, Halloween, Valentine, Easter |
| flavour_profile | recipe | Chocolate, Vanilla/Cream, Citrus, Caramel, Fruity/Berry, Spiced, Nutty, Tropical |
| name | ingredient | Ingredient name |
| quantity | recipe_ingredient | Amount of ingredient used |
| unit | recipe_ingredient | Unit of measurement |
| step_number | step | Order of the instruction |
| description | step | Instruction text |
| tag | ner_tag | NLP extracted food entity |

### Row Counts After Import

| Table | Rows |
|---|---|
| recipe | 1,755 |
| ingredient | 9,277 |
| recipe_ingredient | 17,015 |
| step | 27,532 |
| ner_tag | 34,070 |

### Data Cleaning Steps

1. Filtered 100,000 row dataset down to dessert and baking recipes using title keywords
2. Removed savoury dishes that matched keywords (e.g. chicken pie, fish pie)
3. Added occasion column — classified from title and NER text
4. Added flavour_profile column — classified from title and NER text
5. Duplicate titles removed on import using ON CONFLICT DO NOTHING

---

### How to Run

**Step 1 — Install Python libraries**
```bash
pip3 install pandas psycopg2-binary
```

**Step 2 — Import data**
```bash
python3 import_data.py
```

**Step 3 — Run queries**
```bash
psql postgres -f queries.sql
```

---

### Query Summary

| # | Type | Description |
|---|---|---|
| 1 | Aggregation | Recipe count per flavour profile |
| 2 | Aggregation | Recipe count per occasion |
| 3 | Join | Recipes with ingredient list and count |
| 4 | Join | Recipes with occasion, flavour and step count |
| 5 | Subquery | Recipes above average ingredient count |
| 6 | Subquery | Recipes with no NER tags |
| 7 | CTE | Difficulty classification by step count |
| 8 | CTE | Top 3 ingredients per flavour profile |
| 9 | Window Function | Rank recipes within each occasion by ingredient count |
| 10 | Window Function | Running total of recipes by flavour profile |

---

## AI Usage Disclosure

Claude (Anthropic) was used for syntax suggestions, debugging, dataset filtering, and README structure. 
All design decisions and execution were done independently.