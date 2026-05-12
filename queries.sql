-- ── QUERY 1: AGGREGATION ─────────────────────────────────────────
-- Count how many dessert recipes belong to each flavour profile
-- Shows which flavour dominates our dessert collection

SELECT
    flavour_profile,
    COUNT(*) AS total_recipes
FROM recipe
GROUP BY flavour_profile
ORDER BY total_recipes DESC;


-- ── QUERY 2: AGGREGATION ─────────────────────────────────────────
-- Count recipes per occasion
-- Shows the spread across Everyday, Christmas, Birthday etc.

SELECT
    occasion,
    COUNT(*) AS total_recipes
FROM recipe
GROUP BY occasion
ORDER BY total_recipes DESC;
-- ── QUERY 3: JOIN ────────────────────────────────────────────────
-- List each recipe with all its ingredients in one line
-- Joins Recipe, Recipe_Ingredient and Ingredient together

SELECT
    r.title,
    r.flavour_profile,
    STRING_AGG(i.name, ', ' ORDER BY i.name) AS ingredients_list,
    COUNT(i.ingredient_id) AS ingredient_count
FROM recipe r
JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
JOIN ingredient i ON ri.ingredient_id = i.ingredient_id
GROUP BY r.recipe_id, r.title, r.flavour_profile
ORDER BY ingredient_count DESC
LIMIT 10;


-- ── QUERY 4: JOIN ────────────────────────────────────────────────
-- Show each recipe with its occasion, flavour and total steps
-- Joins Recipe and Step together

SELECT
    r.title,
    r.occasion,
    r.flavour_profile,
    COUNT(s.step_id) AS total_steps
FROM recipe r
JOIN step s ON r.recipe_id = s.recipe_id
GROUP BY r.recipe_id, r.title, r.occasion, r.flavour_profile
ORDER BY total_steps DESC
LIMIT 10;
-- ── QUERY 5: SUBQUERY ────────────────────────────────────────────
-- Find recipes that use more ingredients than the average recipe
-- Subquery calculates the average first

SELECT
    r.title,
    r.flavour_profile,
    COUNT(ri.ingredient_id) AS ingredient_count
FROM recipe r
JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
GROUP BY r.recipe_id, r.title, r.flavour_profile
HAVING COUNT(ri.ingredient_id) > (
    SELECT AVG(ing_count)
    FROM (
        SELECT COUNT(ingredient_id) AS ing_count
        FROM recipe_ingredient
        GROUP BY recipe_id
    ) AS counts
)
ORDER BY ingredient_count DESC
LIMIT 10;


-- ── QUERY 6: SUBQUERY ────────────────────────────────────────────
-- Find the most used NER tag per flavour profile
-- Subquery finds the top tag inside each group

SELECT
    r.flavour_profile,
    n.tag,
    COUNT(*) AS tag_count
FROM ner_tag n
JOIN recipe r ON n.recipe_id = r.recipe_id
GROUP BY r.flavour_profile, n.tag
HAVING COUNT(*) = (
    SELECT MAX(inner_count)
    FROM (
        SELECT COUNT(*) AS inner_count
        FROM ner_tag n2
        JOIN recipe r2 ON n2.recipe_id = r2.recipe_id
        WHERE r2.flavour_profile = r.flavour_profile
        GROUP BY n2.tag
    ) AS sub
)
ORDER BY r.flavour_profile;


-- ── QUERY 7: CTE ─────────────────────────────────────────────────
-- Classify recipes as Easy, Medium or Hard based on step count
-- CTE calculates step count first, then we classify

WITH StepCounts AS (
    SELECT
        recipe_id,
        COUNT(*) AS step_count
    FROM step
    GROUP BY recipe_id
),
Classified AS (
    SELECT
        r.recipe_id,
        r.title,
        r.flavour_profile,
        sc.step_count,
        CASE
            WHEN sc.step_count <= 3 THEN 'Easy'
            WHEN sc.step_count <= 6 THEN 'Medium'
            ELSE 'Hard'
        END AS difficulty
    FROM recipe r
    JOIN StepCounts sc ON r.recipe_id = sc.recipe_id
)
SELECT
    difficulty,
    COUNT(*)              AS recipe_count,
    ROUND(AVG(step_count)::NUMERIC, 2) AS avg_steps
FROM Classified
GROUP BY difficulty
ORDER BY avg_steps;


-- ── QUERY 8: CTE ─────────────────────────────────────────────────
-- Find top 5 most used ingredients per flavour profile
-- CTE ranks ingredients within each flavour group

WITH IngredientRanks AS (
    SELECT
        r.flavour_profile,
        i.name            AS ingredient,
        COUNT(*)          AS used_count,
        RANK() OVER (
            PARTITION BY r.flavour_profile
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM recipe r
    JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
    JOIN ingredient i          ON ri.ingredient_id = i.ingredient_id
    GROUP BY r.flavour_profile, i.name
)
SELECT flavour_profile, ingredient, used_count
FROM IngredientRanks
WHERE rnk <= 3
ORDER BY flavour_profile, rnk;


-- ── QUERY 9: WINDOW FUNCTION ─────────────────────────────────────
-- Rank recipes within each occasion by ingredient count
-- ROW_NUMBER assigns a unique rank inside each occasion group

SELECT
    title,
    occasion,
    ingredient_count,
    ROW_NUMBER() OVER (
        PARTITION BY occasion
        ORDER BY ingredient_count DESC
    ) AS rank_in_occasion
FROM (
    SELECT
        r.recipe_id,
        r.title,
        r.occasion,
        COUNT(ri.ingredient_id) AS ingredient_count
    FROM recipe r
    JOIN recipe_ingredient ri ON r.recipe_id = ri.recipe_id
    GROUP BY r.recipe_id, r.title, r.occasion
) AS counts
ORDER BY occasion, rank_in_occasion
LIMIT 20;


-- ── QUERY 10: WINDOW FUNCTION ────────────────────────────────────
-- Running total of recipes by flavour profile
-- SUM OVER shows cumulative count as we go through each flavour

SELECT
    flavour_profile,
    total_recipes,
    SUM(total_recipes) OVER (
        ORDER BY total_recipes DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT
        flavour_profile,
        COUNT(*) AS total_recipes
    FROM recipe
    GROUP BY flavour_profile
) AS flavour_counts
ORDER BY total_recipes DESC;