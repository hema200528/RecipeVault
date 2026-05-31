# RecipeVault — Milestone 3: Performance Evidence

**Track:** A — RAG Pipeline  
**Database:** PostgreSQL 18.3 (Homebrew)  
**Machine:** Apple MacBook Pro, Apple Silicon (aarch64), macOS 25.2  
**Dataset:** 1,755 recipes, 17,015 recipe-ingredient links, 34,070 NER tags, 27,532 steps  

---

## 1. Project Summary

RecipeVault is a dessert recipe assistant built on a relational PostgreSQL 
database. It stores 1,755 dessert and baking recipes filtered from the 
RecipeNLP Kaggle dataset, enriched with two custom columns: occasion and 
flavour_profile. The system is designed to support a RAG pipeline that 
answers natural language queries like "give me a chocolate cake under 5 steps" 
by searching the database and returning grounded, cited answers.

---

## 2. Objective

This report identifies slow queries in the RecipeVault database, creates 
appropriate B-Tree indexes to improve performance, and provides before and 
after execution plan evidence using EXPLAIN ANALYZE.

---

## 3. Test Environment

| Item | Detail |
|---|---|
| Database engine | PostgreSQL 18.3 (Homebrew) |
| Machine | MacBook Pro, Apple M-series, aarch64 |
| Operating system | macOS Darwin 25.2 |
| Dataset size | 1,755 recipes |
| Total rows across all tables | ~81,000 |

---

## 4. Slow Queries Identified

Two queries were identified as candidates for optimisation.

**Query 1 — Filter recipes by flavour profile**  
This query is central to the RAG pipeline. When a user asks for a chocolate 
dessert, the system filters the recipe table by flavour_profile. Without an 
index, PostgreSQL performs a full sequential scan reading all 1,755 rows to 
find the 455 matching chocolate recipes.

**Query 2 — Join recipe with NER tags filtered by occasion**  
This query retrieves recipes and their NER tags for a specific occasion such 
as Christmas. Without indexes, PostgreSQL performs a Hash Join scanning all 
34,070 NER tag rows and all 1,755 recipe rows (expensive for a result set 
of only 262 rows.)

---

## 5. Methodology

Each query was run twice once without indexes (sequential scan baseline) 
and once after creating B-Tree indexes on the relevant columns. The same 
dataset and conditions were used for both runs. Timing was captured using 
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT).

---

## 6. Results

### Query 1 — flavour_profile filter

| | Before Index | After Index |
|---|---|---|
| Scan type | Sequential Scan | Bitmap Index Scan |
| Execution time | 1.140 ms | 0.354 ms |
| Rows scanned | 1,755 | 455 (index filtered) |
| Improvement | — | 3.2x faster |

**Before:** PostgreSQL read all 1,755 rows and filtered 1,300 out.  
**After:** PostgreSQL used idx_recipe_flavour to jump directly to the 
455 matching rows without reading the rest.

### Query 2 — occasion + NER tag join

| | Before Index | After Index |
|---|---|---|
| Scan type | Hash Join + Seq Scan | Nested Loop + Index Scans |
| Execution time | 9.421 ms | 0.191 ms |
| Rows scanned | 34,070 (ner_tag) + 1,755 (recipe) | 13 (recipe) + 262 (ner_tag) |
| Improvement | — | 49x faster |

**Before:** PostgreSQL scanned all 34,070 NER tag rows using a Hash Join.  
**After:** PostgreSQL used idx_recipe_occasion to find 13 Christmas recipes 
first, then used idx_ner_tag_recipe_id to fetch only the relevant NER tags 
for those 13 recipes via a Nested Loop drastically reducing rows read.

---

## 7. Index DDL and Justification

```sql
CREATE INDEX idx_recipe_flavour ON recipe(flavour_profile);
CREATE INDEX idx_recipe_occasion ON recipe(occasion);
CREATE INDEX idx_ner_tag_recipe_id ON ner_tag(recipe_id);
CREATE INDEX idx_step_recipe_id ON step(recipe_id);
CREATE INDEX idx_recipe_ingredient_recipe_id ON recipe_ingredient(recipe_id);
```

All indexes are B-Tree type the PostgreSQL default and the correct choice 
for equality filters (WHERE flavour_profile = 'Chocolate') and join conditions 
(ON recipe_id = recipe_id). B-Tree indexes support both equality and range 
queries and work well on low-to-medium cardinality columns like occasion and 
flavour_profile.

---

## 8. Stored Procedure

A stored procedure get_recipes_by_flavour() was created. It accepts a 
flavour profile as input and returns all matching recipes with their occasion 
and step count ordered by complexity. This is used by the RAG pipeline to 
retrieve candidate recipes before passing them to the language model.

```sql
SELECT * FROM get_recipes_by_flavour('Chocolate') LIMIT 5;
```

Sample output:

| recipe_id | title | occasion | step_count |
|---|---|---|---|
| 1154 | Cannoli | Everyday | 84 |
| 52 | Chocolate Chip Cookies | Everyday | 84 |
| 1993 | White Chocolate Stick Cake | Everyday | 84 |
| 980 | Chocolate Cupcakes with Mascarpone | Everyday | 76 |
| 1496 | Chocolate Caramel Tart with Sea Salt | Everyday | 74 |

---

## 9. Interpretation of Query Plans

The key difference between the before and after plans is the scan type. 
A Sequential Scan reads every row in the table regardless of how many 
rows match. An Index Scan reads only the rows that satisfy the condition 
by following pointers in the index structure. A Bitmap Index Scan is a 
middle ground it reads the index first to build a bitmap of matching 
pages, then fetches only those pages from the heap.

For Query 2, the shift from Hash Join to Nested Loop is significant. 
A Hash Join builds a hash table of one input and probes it with the other 
— efficient for large result sets but wasteful when only 13 rows match. 
A Nested Loop iterates over the outer rows (13 Christmas recipes) and 
looks up the inner table (NER tags) using the index for each far more 
efficient when the outer set is small.

---

## 10. Conclusions

Both queries showed clear improvement after indexing. Query 2 improved 
by 49x from 9.421ms to 0.191ms because the index eliminated a full 
scan of 34,070 NER tag rows. The results confirm that B-Tree indexes on 
foreign key columns and frequently filtered columns significantly reduce 
query cost even on a modest dataset of 1,755 recipes. On a larger 
production dataset the improvement would be even more pronounced.

---

## AI Usage Disclosure

Claude (Anthropic) was used for syntax suggestions, debugging, and report 
structure. All queries were run, verified, and interpreted independently.