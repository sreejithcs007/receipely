-- Migration to fix empty recipe images by falling back to recipes.thumbnail_image_url if recipe_images has no primary image.

-- 1. Update get_recipe_by_slug
CREATE OR REPLACE FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") RETURNS TABLE("id" "uuid", "title" "text", "description" "text", "rating" numeric, "reviews_count" integer, "prep_time" "text", "cook_time" "text", "total_time" "text", "calories" "text", "servings" "text", "difficulty" "text", "cuisine" "text", "spice_level" integer, "estimated_cost" numeric, "is_featured" boolean, "is_trending" boolean, "chef_id" "uuid", "chef_name" "text", "chef_avatar" "text", "chef_verified" boolean, "primary_image_url" "text", "slug" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT r.id, r.title, r.description, r.rating, r.reviews_count,
           r.prep_time, r.cook_time, r.total_time, r.calories, r.servings,
           r.difficulty, r.cuisine, r.spice_level, r.estimated_cost,
           r.is_featured, r.is_trending,
           c.id, c.name, c.avatar_url, c.is_verified,
           COALESCE(img.image_url, r.thumbnail_image_url), r.slug
    FROM public.recipes r
    LEFT JOIN public.chefs c ON r.chef_id = c.id AND c.deleted_at IS NULL
    LEFT JOIN public.recipe_images img ON img.recipe_id = r.id AND img.is_primary = true AND img.deleted_at IS NULL
    WHERE r.slug = p_slug AND r.deleted_at IS NULL AND r.status = 'published'
    LIMIT 1;
$$;

-- 2. Update search_ingredients
CREATE OR REPLACE FUNCTION "public"."search_ingredients"("p_ingredients" "text", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "title" "text", "description" "text", "rating" numeric, "reviews_count" integer, "prep_time" "text", "cook_time" "text", "total_time" "text", "calories" "text", "servings" "text", "difficulty" "text", "chef_name" "text", "primary_image_url" "text", "matched_ingredients" "text"[], "match_score" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    AS $$
DECLARE v_terms TEXT[];
BEGIN
    SELECT ARRAY(SELECT trim(lower(t)) FROM unnest(string_to_array(regexp_replace(p_ingredients,',',' ','g'),' ')) t WHERE trim(t)<>'') INTO v_terms;
    RETURN QUERY
    WITH im AS (
        SELECT ri.recipe_id,
               array_agg(DISTINCT ri.name ORDER BY ri.name) AS matched_names,
               COUNT(DISTINCT (SELECT t2 FROM unnest(v_terms) t2 WHERE lower(ri.name) LIKE '%'||t2||'%' LIMIT 1)) AS match_count
        FROM public.recipe_ingredients ri
        WHERE EXISTS(SELECT 1 FROM unnest(v_terms) t WHERE lower(ri.name) LIKE '%'||t||'%')
        GROUP BY ri.recipe_id
        HAVING COUNT(DISTINCT (SELECT t2 FROM unnest(v_terms) t2 WHERE lower(ri.name) LIKE '%'||t2||'%' LIMIT 1))
               >= GREATEST(1, array_length(v_terms,1)/2)
    )
    SELECT r.id,r.title,r.description,r.rating,r.reviews_count,
           r.prep_time,r.cook_time,r.total_time,r.calories,r.servings,r.difficulty,
           c.name,COALESCE(img.image_url, r.thumbnail_image_url),im.matched_names,im.match_count::INTEGER
    FROM im JOIN public.recipes r ON r.id=im.recipe_id AND r.deleted_at IS NULL AND r.status='published'
    LEFT JOIN public.chefs c ON r.chef_id=c.id AND c.deleted_at IS NULL
    LEFT JOIN public.recipe_images img ON img.recipe_id=r.id AND img.is_primary=true AND img.deleted_at IS NULL
    ORDER BY im.match_count DESC, r.rating DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

-- 3. Update search_recipes
CREATE OR REPLACE FUNCTION "public"."search_recipes"("p_query" "text" DEFAULT NULL::"text", "p_category_id" "uuid" DEFAULT NULL::"uuid", "p_cuisine" "text" DEFAULT NULL::"text", "p_difficulty" "text" DEFAULT NULL::"text", "p_max_time_min" integer DEFAULT NULL::integer, "p_max_calories" integer DEFAULT NULL::integer, "p_min_rating" numeric DEFAULT NULL::numeric, "p_meal_type" "text" DEFAULT NULL::"text", "p_dietary" "text"[] DEFAULT NULL::"text"[], "p_sort_by" "text" DEFAULT 'relevance'::"text", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0, "p_user_id" "uuid" DEFAULT NULL::"uuid") RETURNS TABLE("id" "uuid", "title" "text", "description" "text", "rating" numeric, "reviews_count" integer, "prep_time" "text", "cook_time" "text", "total_time" "text", "calories" "text", "servings" "text", "difficulty" "text", "cuisine" "text", "spice_level" integer, "estimated_cost" numeric, "is_featured" boolean, "is_trending" boolean, "is_recommended" boolean, "nutrition_info" "jsonb", "chef_id" "uuid", "chef_name" "text", "chef_avatar" "text", "chef_verified" boolean, "primary_image_url" "text", "search_rank" double precision, "total_count" bigint)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    AS $$
DECLARE
    v_tsquery   tsquery;
    v_expanded  TEXT := '';
    v_term      TEXT;
    v_has_query BOOLEAN := p_query IS NOT NULL AND trim(p_query) <> '';
BEGIN
    IF v_has_query THEN
        FOREACH v_term IN ARRAY string_to_array(trim(p_query),' ') LOOP
            v_expanded := v_expanded || ' ' || public.expand_synonyms(v_term);
        END LOOP;
        BEGIN
            v_tsquery := to_tsquery('english',
                array_to_string(ARRAY(
                    SELECT t||':*' FROM unnest(string_to_array(
                        regexp_replace(unaccent(lower(trim(v_expanded))),'[^a-z0-9 ]','','g'),' '
                    )) t WHERE trim(t)<>''
                ),' | '));
        EXCEPTION WHEN OTHERS THEN
            v_tsquery := plainto_tsquery('english', unaccent(p_query));
        END;
    END IF;

    RETURN QUERY
    WITH base AS (
        SELECT
            r.id, r.title, r.description, r.rating, r.reviews_count,
            r.prep_time, r.cook_time, r.total_time, r.calories, r.servings,
            r.difficulty, r.cuisine, r.spice_level, r.estimated_cost,
            r.is_featured, r.is_trending, r.is_recommended, r.nutrition_info,
            r.total_time_minutes, r.calories_int,
            c.id          AS chef_id,
            c.name        AS chef_name,
            c.avatar_url  AS chef_avatar,
            c.is_verified AS chef_verified,
            COALESCE(img.image_url, r.thumbnail_image_url) AS primary_image_url,
            (CASE WHEN v_has_query AND v_tsquery IS NOT NULL THEN
                GREATEST(ts_rank_cd(r.search_vector, v_tsquery, 32),0.0)*10.0
                + CASE WHEN lower(r.title)=lower(trim(p_query))                   THEN 5.0 ELSE 0.0 END
                + CASE WHEN lower(r.title) LIKE lower(trim(p_query))||'%'         THEN 2.0 ELSE 0.0 END
                + similarity(lower(r.title), lower(trim(p_query)))*3.0
            ELSE 0.0 END
            + CASE WHEN r.is_featured THEN 2.0 ELSE 0.0 END
            + CASE WHEN r.is_trending THEN 1.5 ELSE 0.0 END
            + (r.rating/5.0)*3.0
            + LOG(GREATEST(r.reviews_count,1)::NUMERIC)*0.4) AS search_rank
        FROM public.recipes r
        LEFT JOIN public.chefs c ON r.chef_id=c.id AND c.deleted_at IS NULL
        LEFT JOIN public.recipe_images img ON img.recipe_id=r.id AND img.is_primary=true AND img.deleted_at IS NULL
        LEFT JOIN public.recipe_categories rc ON rc.recipe_id=r.id AND p_category_id IS NOT NULL AND rc.category_id=p_category_id
        WHERE r.deleted_at IS NULL AND r.status='published'
          AND (NOT v_has_query OR v_tsquery IS NULL
               OR r.search_vector @@ v_tsquery
               OR similarity(lower(r.title), lower(trim(COALESCE(p_query,''))))>0.2)
          AND (p_category_id  IS NULL OR rc.recipe_id IS NOT NULL)
          AND (p_cuisine      IS NULL OR lower(r.cuisine) LIKE '%'||lower(trim(p_cuisine))||'%')
          AND (p_difficulty   IS NULL OR r.difficulty=p_difficulty)
          AND (p_max_time_min IS NULL OR r.total_time_minutes<=p_max_time_min)
          AND (p_max_calories IS NULL OR r.calories_int<=p_max_calories)
          AND (p_min_rating   IS NULL OR r.rating>=p_min_rating)
          AND (p_meal_type IS NULL OR EXISTS(
                SELECT 1 FROM public.recipe_tags rt2 JOIN public.tags t2 ON rt2.tag_id=t2.id
                WHERE rt2.recipe_id=r.id AND lower(t2.name)=lower(trim(p_meal_type))))
          AND (p_dietary IS NULL OR (
                SELECT COUNT(DISTINCT lower(t3.name)) FROM public.recipe_tags rt3 JOIN public.tags t3 ON rt3.tag_id=t3.id
                WHERE rt3.recipe_id=r.id AND lower(t3.name)=ANY(SELECT lower(x) FROM unnest(p_dietary) x)
               )=array_length(p_dietary,1))
    ),
    counted AS (SELECT *, COUNT(*) OVER() AS total_count FROM base)
    SELECT c2.id,c2.title,c2.description,c2.rating,c2.reviews_count,
           c2.prep_time,c2.cook_time,c2.total_time,c2.calories,c2.servings,
           c2.difficulty,c2.cuisine,c2.spice_level,c2.estimated_cost,
           c2.is_featured,c2.is_trending,c2.is_recommended,c2.nutrition_info,
           c2.chef_id,c2.chef_name,c2.chef_avatar,c2.chef_verified,
           c2.primary_image_url,c2.search_rank,c2.total_count
    FROM counted c2
    ORDER BY
        CASE p_sort_by WHEN 'rating'     THEN c2.rating             END DESC NULLS LAST,
        CASE p_sort_by WHEN 'popularity' THEN c2.reviews_count       END DESC NULLS LAST,
        CASE p_sort_by WHEN 'cook_time'  THEN c2.total_time_minutes  END ASC  NULLS LAST,
        CASE p_sort_by WHEN 'calories'   THEN c2.calories_int        END ASC  NULLS LAST,
        c2.search_rank DESC, c2.rating DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;

-- 4. Update search_recipes_phonetic
CREATE OR REPLACE FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer DEFAULT 20) RETURNS TABLE("id" "uuid", "title" "text", "rating" numeric, "primary_image_url" "text", "phonetic_rank" double precision)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT r.id, r.title, r.rating, COALESCE(img.image_url, r.thumbnail_image_url) AS primary_image_url,
           (1.0 / (1.0 + levenshtein(soundex(lower(r.title)), soundex(lower(trim(p_query)))) ::FLOAT)) AS phonetic_rank
    FROM public.recipes r
    LEFT JOIN public.recipe_images img ON img.recipe_id = r.id AND img.is_primary = true AND img.deleted_at IS NULL
    WHERE r.deleted_at IS NULL AND r.status = 'published'
      AND soundex(lower(r.title)) = soundex(lower(trim(p_query)))
    ORDER BY phonetic_rank DESC, r.rating DESC
    LIMIT p_limit;
$$;
