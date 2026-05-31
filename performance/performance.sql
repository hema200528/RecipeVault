-- ============================================================
-- RecipeVault
-- Milestone 3: Performance Evidence
-- Track A: RAG Pipeline
-- Database: PostgreSQL 18.3
-- ============================================================


-- ============================================================
-- SECTION 1: BEFORE INDEXES
-- Baseline queries showing sequential scans
-- ============================================================

-- Query 1: Filter recipes by flavour profile
-- Without index: Seq Scan on recipe
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT r.title, r.flavour_profile
FROM recipe r
WHERE r.flavour_profile = 'Chocolate';


-- Query 2: Join recipe with ner_tag filtered by occasion
-- Without index: Hash Join + Seq Scan on ner_tag
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT r.title, n.tag
FROM recipe r
JOIN ner_tag n ON r.recipe_id = n.recipe_id
WHERE r.occasion = 'Christmas';


-- ============================================================
-- SECTION 2: INDEX CREATION
-- B-Tree indexes on frequently queried columns
-- ============================================================

-- Index 1: flavour_profile
-- Most user queries filter desserts by flavour
CREATE INDEX IF NOT EXISTS idx_recipe_flavour
    ON recipe(flavour_profile);

-- Index 2: occasion
-- Seasonal queries filter by occasion (Christmas, Birthday etc.)
CREATE INDEX IF NOT EXISTS idx_recipe_occasion
    ON recipe(occasion);

-- Index 3: ner_tag.recipe_id
-- Every NER tag query joins back to recipe via recipe_id
CREATE INDEX IF NOT EXISTS idx_ner_tag_recipe_id
    ON ner_tag(recipe_id);

-- Index 4: step.recipe_id
-- Step count queries join on recipe_id frequently
CREATE INDEX IF NOT EXISTS idx_step_recipe_id
    ON step(recipe_id);

-- Index 5: recipe_ingredient.recipe_id
-- Ingredient count queries join recipe_ingredient on recipe_id
CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_recipe_id
    ON recipe_ingredient(recipe_id);


-- ============================================================
-- SECTION 3: AFTER INDEXES
-- Same queries showing index usage and improved timing
-- ============================================================

-- Query 1 After: Now uses Bitmap Index Scan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT r.title, r.flavour_profile
FROM recipe r
WHERE r.flavour_profile = 'Chocolate';


-- Query 2 After: Now uses Index Scan on both tables
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT r.title, n.tag
FROM recipe r
JOIN ner_tag n ON r.recipe_id = n.recipe_id
WHERE r.occasion = 'Christmas';


-- ============================================================
-- SECTION 4: STORED PROCEDURE
-- get_recipes_by_flavour(p_flavour)
-- Returns all recipes for a given flavour profile
-- with their occasion and step count ordered by complexity
-- ============================================================

CREATE OR REPLACE FUNCTION get_recipes_by_flavour(p_flavour VARCHAR)
RETURNS TABLE (
    recipe_id  INT,
    title      VARCHAR,
    occasion   VARCHAR,
    step_count BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.recipe_id,
        r.title,
        r.occasion,
        COUNT(s.step_id) AS step_count
    FROM recipe r
    LEFT JOIN step s ON r.recipe_id = s.recipe_id
    WHERE r.flavour_profile = p_flavour
    GROUP BY r.recipe_id, r.title, r.occasion
    ORDER BY step_count DESC;
END;
$$;


-- ============================================================
-- SECTION 5: TEST THE STORED PROCEDURE
-- ============================================================

SELECT * FROM get_recipes_by_flavour('Chocolate') LIMIT 5;
SELECT * FROM get_recipes_by_flavour('Citrus') LIMIT 5;
SELECT * FROM get_recipes_by_flavour('Spiced') LIMIT 5;

