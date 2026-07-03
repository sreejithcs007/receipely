


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "auth";


ALTER SCHEMA "auth" OWNER TO "supabase_admin";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "storage";


ALTER SCHEMA "storage" OWNER TO "supabase_admin";


CREATE TYPE "auth"."aal_level" AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE "auth"."aal_level" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."code_challenge_method" AS ENUM (
    's256',
    'plain'
);


ALTER TYPE "auth"."code_challenge_method" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_status" AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE "auth"."factor_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_type" AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE "auth"."factor_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_authorization_status" AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE "auth"."oauth_authorization_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_client_type" AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE "auth"."oauth_client_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_registration_type" AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE "auth"."oauth_registration_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_response_type" AS ENUM (
    'code'
);


ALTER TYPE "auth"."oauth_response_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."one_time_token_type" AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE "auth"."one_time_token_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "storage"."buckettype" AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


ALTER TYPE "storage"."buckettype" OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "auth"."email"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION "auth"."email"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."email"() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';



CREATE OR REPLACE FUNCTION "auth"."jwt"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION "auth"."jwt"() OWNER TO "supabase_auth_admin";


CREATE OR REPLACE FUNCTION "auth"."role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION "auth"."role"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."role"() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';



CREATE OR REPLACE FUNCTION "auth"."uid"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION "auth"."uid"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."uid"() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';



CREATE OR REPLACE FUNCTION "public"."auto_assign_slug"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE base_slug TEXT; final_slug TEXT; suffix INT := 0;
BEGIN
    IF NEW.slug IS NULL THEN
        base_slug := public.slugify(NEW.title);
        final_slug := base_slug;
        LOOP
            EXIT WHEN NOT EXISTS(SELECT 1 FROM public.recipes WHERE slug = final_slug AND id <> NEW.id);
            suffix := suffix + 1;
            final_slug := base_slug || '-' || suffix::TEXT;
        END LOOP;
        NEW.slug := final_slug;
    END IF;
    RETURN NEW;
END; $$;


ALTER FUNCTION "public"."auto_assign_slug"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."autocomplete_ingredients"("p_query" "text", "p_limit" integer DEFAULT 10) RETURNS TABLE("name" "text", "frequency" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT lower(ri.name), COUNT(*) AS freq
    FROM public.recipe_ingredients ri
    WHERE lower(ri.name) LIKE lower(trim(p_query)) || '%'
    GROUP BY lower(ri.name)
    ORDER BY freq DESC
    LIMIT p_limit;
$$;


ALTER FUNCTION "public"."autocomplete_ingredients"("p_query" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."capture_zero_result_searches"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.search_synonym_candidates (term, frequency)
    SELECT lower(trim(query)), COUNT(*)
    FROM public.search_analytics
    WHERE had_results = false AND trim(query) <> ''
      AND created_at > now() - INTERVAL '7 days'
    GROUP BY lower(trim(query))
    ON CONFLICT (term) DO UPDATE
        SET frequency = public.search_synonym_candidates.frequency + EXCLUDED.frequency;
END; $$;


ALTER FUNCTION "public"."capture_zero_result_searches"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."capture_zero_result_searches"() IS 'Run weekly to populate synonym_candidates from zero-result searches.';



CREATE OR REPLACE FUNCTION "public"."cascade_search_on_category_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN PERFORM public.refresh_recipe_search_vector(COALESCE(NEW.recipe_id,OLD.recipe_id)); RETURN NULL; END; $$;


ALTER FUNCTION "public"."cascade_search_on_category_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cascade_search_on_ingredient_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN PERFORM public.refresh_recipe_search_vector(COALESCE(NEW.recipe_id,OLD.recipe_id)); RETURN NULL; END; $$;


ALTER FUNCTION "public"."cascade_search_on_ingredient_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cascade_search_on_tag_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN PERFORM public.refresh_recipe_search_vector(COALESCE(NEW.recipe_id,OLD.recipe_id)); RETURN NULL; END; $$;


ALTER FUNCTION "public"."cascade_search_on_tag_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."clear_search_history"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$ DELETE FROM public.search_history WHERE user_id=p_user_id; $$;


ALTER FUNCTION "public"."clear_search_history"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_search_history_item"("p_user_id" "uuid", "p_history_id" "uuid") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$ DELETE FROM public.search_history WHERE id=p_history_id AND user_id=p_user_id; $$;


ALTER FUNCTION "public"."delete_search_history_item"("p_user_id" "uuid", "p_history_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."expand_synonyms"("p_term" "text") RETURNS "text"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT string_agg(DISTINCT u,'  ')
    FROM (
        SELECT p_term AS u
        UNION ALL
        SELECT unnest(synonyms) FROM public.search_synonyms WHERE term=lower(trim(p_term))
    ) t;
$$;


ALTER FUNCTION "public"."expand_synonyms"("p_term" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_recent_searches"("p_user_id" "uuid", "p_limit" integer DEFAULT 15) RETURNS TABLE("id" "uuid", "query" "text", "frequency" integer, "last_searched" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT sh.id,sh.query,sh.frequency,sh.created_at FROM public.search_history sh
    WHERE sh.user_id=p_user_id ORDER BY sh.created_at DESC LIMIT p_limit;
$$;


ALTER FUNCTION "public"."get_recent_searches"("p_user_id" "uuid", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") RETURNS TABLE("id" "uuid", "title" "text", "description" "text", "rating" numeric, "reviews_count" integer, "prep_time" "text", "cook_time" "text", "total_time" "text", "calories" "text", "servings" "text", "difficulty" "text", "cuisine" "text", "spice_level" integer, "estimated_cost" numeric, "is_featured" boolean, "is_trending" boolean, "chef_id" "uuid", "chef_name" "text", "chef_avatar" "text", "chef_verified" boolean, "primary_image_url" "text", "slug" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT r.id, r.title, r.description, r.rating, r.reviews_count,
           r.prep_time, r.cook_time, r.total_time, r.calories, r.servings,
           r.difficulty, r.cuisine, r.spice_level, r.estimated_cost,
           r.is_featured, r.is_trending,
           c.id, c.name, c.avatar_url, c.is_verified,
           img.image_url, r.slug
    FROM public.recipes r
    LEFT JOIN public.chefs c ON r.chef_id = c.id AND c.deleted_at IS NULL
    LEFT JOIN public.recipe_images img ON img.recipe_id = r.id AND img.is_primary = true AND img.deleted_at IS NULL
    WHERE r.slug = p_slug AND r.deleted_at IS NULL AND r.status = 'published'
    LIMIT 1;
$$;


ALTER FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") IS 'Fetch a published recipe by its URL slug.';



CREATE OR REPLACE FUNCTION "public"."get_trending_searches"("p_window" "text" DEFAULT 'weekly'::"text", "p_limit" integer DEFAULT 10) RETURNS TABLE("query" "text", "search_count" integer, "last_searched" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT ts.query,
           CASE p_window WHEN 'daily' THEN ts.daily_count WHEN 'monthly' THEN ts.monthly_count
                         WHEN 'all_time' THEN ts.search_count ELSE ts.weekly_count END,
           ts.last_searched_at
    FROM public.trending_searches ts
    WHERE CASE p_window WHEN 'daily' THEN ts.daily_count>0 WHEN 'monthly' THEN ts.monthly_count>0
                        WHEN 'all_time' THEN ts.search_count>0 ELSE ts.weekly_count>0 END
    ORDER BY CASE p_window WHEN 'daily' THEN ts.daily_count WHEN 'monthly' THEN ts.monthly_count
                           WHEN 'all_time' THEN ts.search_count ELSE ts.weekly_count END DESC,
             ts.last_searched_at DESC
    LIMIT p_limit;
$$;


ALTER FUNCTION "public"."get_trending_searches"("p_window" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_zero_result_searches"("p_limit" integer DEFAULT 50) RETURNS TABLE("query" "text", "search_count" bigint, "last_searched" timestamp with time zone)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT lower(trim(sa.query)),COUNT(*),MAX(sa.created_at) FROM public.search_analytics sa
    WHERE sa.had_results=false AND trim(sa.query)<>''
    GROUP BY lower(trim(sa.query)) ORDER BY COUNT(*) DESC LIMIT p_limit;
$$;


ALTER FUNCTION "public"."get_zero_result_searches"("p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.users (id, email, name, avatar_url)
    VALUES (
        NEW.id, NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email,'@',1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', 'user-avatars/default.png')
    ) ON CONFLICT (id) DO NOTHING;
    INSERT INTO public.user_preferences (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    RETURN NEW;
END; $$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_role"("p_role" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT EXISTS(SELECT 1 FROM public.user_roles WHERE user_id=auth.uid() AND role=p_role);
$$;


ALTER FUNCTION "public"."has_role"("p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."init_recipe_analytics"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.recipe_analytics (recipe_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."init_recipe_analytics"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_profile_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    IF NEW.name<>OLD.name           THEN INSERT INTO public.profile_changes(user_id,field_name,old_value,new_value) VALUES(NEW.id,'name',OLD.name,NEW.name); END IF;
    IF NEW.avatar_url<>OLD.avatar_url THEN INSERT INTO public.profile_changes(user_id,field_name,old_value,new_value) VALUES(NEW.id,'avatar_url',OLD.avatar_url,NEW.avatar_url); END IF;
    IF NEW.chef_level<>OLD.chef_level THEN INSERT INTO public.profile_changes(user_id,field_name,old_value,new_value) VALUES(NEW.id,'chef_level',OLD.chef_level,NEW.chef_level); END IF;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."log_profile_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_recipe_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE v_action TEXT;
BEGIN
    IF    TG_OP='INSERT' THEN v_action:='INSERT';
    ELSIF TG_OP='DELETE' THEN v_action:='DELETE';
    ELSIF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN v_action:='SOFT_DELETE';
    ELSE  v_action:='UPDATE';
    END IF;
    INSERT INTO public.recipe_history (recipe_id,action,changed_by,old_data,new_data)
    VALUES (COALESCE(NEW.id,OLD.id),v_action,auth.uid(),
            CASE WHEN TG_OP<>'INSERT' THEN to_jsonb(OLD) END,
            CASE WHEN TG_OP<>'DELETE' THEN to_jsonb(NEW) END);
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."log_recipe_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_search_event"("p_user_id" "uuid" DEFAULT NULL::"uuid", "p_query" "text" DEFAULT ''::"text", "p_results_count" integer DEFAULT 0, "p_had_results" boolean DEFAULT true, "p_search_duration_ms" integer DEFAULT NULL::integer, "p_clicked_recipe_id" "uuid" DEFAULT NULL::"uuid", "p_sort_by" "text" DEFAULT NULL::"text", "p_filters_applied" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
    INSERT INTO public.search_analytics (user_id,query,results_count,had_results,search_duration_ms,clicked_recipe_id,sort_by,filters_applied)
    VALUES (p_user_id,p_query,p_results_count,p_had_results,p_search_duration_ms,p_clicked_recipe_id,p_sort_by,p_filters_applied);
$$;


ALTER FUNCTION "public"."log_search_event"("p_user_id" "uuid", "p_query" "text", "p_results_count" integer, "p_had_results" boolean, "p_search_duration_ms" integer, "p_clicked_recipe_id" "uuid", "p_sort_by" "text", "p_filters_applied" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE v_views INT; v_saves INT; v_reviews INT; v_rating NUMERIC;
BEGIN
    SELECT COALESCE(views_count,0), COALESCE(saves_count,0), COALESCE(reviews_count,0), COALESCE(rating,0)
    INTO v_views, v_saves, v_reviews, v_rating
    FROM public.recipes WHERE id = p_recipe_id;

    UPDATE public.recipes SET
        engagement_score = (v_views * 0.1 + v_saves * 1.0 + v_reviews * 2.0 + v_rating * 5.0),
        popularity_score = (v_views * 0.05 + v_saves * 2.0 + v_reviews * 3.0),
        trending_score   = (
            (v_views  * 0.1  + v_saves * 1.5 + v_reviews * 2.5)
            * EXP(-0.01 * EXTRACT(EPOCH FROM (now() - COALESCE(published_at, created_at))) / 86400)
        )
    WHERE id = p_recipe_id;
END; $$;


ALTER FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") IS 'Recomputes engagement, popularity, and time-decayed trending scores for a recipe.';



CREATE OR REPLACE FUNCTION "public"."refresh_all_materialized_views"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.featured_recipes_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.trending_recipes_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.recommended_recipes_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.latest_recipes_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.home_dashboard_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.category_recipe_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.chef_profile_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.top_chefs_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.recipe_leaderboard_view;
END; $$;


ALTER FUNCTION "public"."refresh_all_materialized_views"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."refresh_all_materialized_views"() IS 'Refresh all materialized views concurrently. Schedule via pg_cron or Edge Function.';



CREATE OR REPLACE FUNCTION "public"."refresh_recipe_search_vector"("p_recipe_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE ing_text TEXT; tag_text TEXT; cat_text TEXT; chef_nm TEXT;
BEGIN
    SELECT COALESCE(string_agg(name,' '),'')         INTO ing_text  FROM public.recipe_ingredients WHERE recipe_id = p_recipe_id;
    SELECT COALESCE(string_agg(t.name,' '),'')       INTO tag_text  FROM public.recipe_tags rt JOIN public.tags t ON rt.tag_id=t.id WHERE rt.recipe_id=p_recipe_id;
    SELECT COALESCE(string_agg(c.name,' '),'')       INTO cat_text  FROM public.recipe_categories rc JOIN public.categories c ON rc.category_id=c.id WHERE rc.recipe_id=p_recipe_id;
    SELECT COALESCE(ch.name,'')                      INTO chef_nm   FROM public.recipes r LEFT JOIN public.chefs ch ON r.chef_id=ch.id WHERE r.id=p_recipe_id;
    UPDATE public.recipes SET
        search_vector =
            setweight(to_tsvector('english', unaccent(COALESCE(title,''))),                           'A') ||
            setweight(to_tsvector('english', unaccent(COALESCE(description,''))),                     'B') ||
            setweight(to_tsvector('english', unaccent(ing_text||' '||tag_text)),                      'C') ||
            setweight(to_tsvector('english', unaccent(COALESCE(cuisine,'')||' '||chef_nm||' '||cat_text)), 'D'),
        updated_at = now()
    WHERE id = p_recipe_id;
END; $$;


ALTER FUNCTION "public"."refresh_recipe_search_vector"("p_recipe_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_daily_trending_counts"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$ UPDATE public.trending_searches SET daily_count=0;   $$;


ALTER FUNCTION "public"."reset_daily_trending_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_monthly_trending_counts"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$ UPDATE public.trending_searches SET monthly_count=0; $$;


ALTER FUNCTION "public"."reset_monthly_trending_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."reset_weekly_trending_counts"() RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$ UPDATE public.trending_searches SET weekly_count=0;  $$;


ALTER FUNCTION "public"."reset_weekly_trending_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_categories"("p_query" "text", "p_limit" integer DEFAULT 10) RETURNS TABLE("id" "uuid", "name" "text", "image_url" "text", "recipe_count" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT cat.id,cat.name,cat.image_url,COUNT(rc.recipe_id)
    FROM public.categories cat
    LEFT JOIN public.recipe_categories rc ON rc.category_id=cat.id
    LEFT JOIN public.recipes r ON r.id=rc.recipe_id AND r.deleted_at IS NULL AND r.status='published'
    WHERE cat.deleted_at IS NULL
      AND (lower(cat.name) LIKE '%'||lower(trim(p_query))||'%' OR similarity(lower(cat.name),lower(trim(p_query)))>0.2)
    GROUP BY cat.id,cat.name,cat.image_url
    ORDER BY similarity(lower(cat.name),lower(trim(p_query))) DESC, COUNT(rc.recipe_id) DESC
    LIMIT p_limit;
$$;


ALTER FUNCTION "public"."search_categories"("p_query" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_chefs"("p_query" "text", "p_limit" integer DEFAULT 10, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "name" "text", "bio" "text", "avatar_url" "text", "followers_count" integer, "recipes_count" integer, "average_rating" numeric, "is_verified" boolean, "rank" double precision)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT c.id,c.name,c.bio,c.avatar_url,c.followers_count,c.recipes_count,c.average_rating,c.is_verified,
           (similarity(lower(c.name),lower(trim(p_query)))*5.0
            + CASE WHEN c.is_verified THEN 2.0 ELSE 0.0 END
            + LOG(GREATEST(c.followers_count,1)::NUMERIC)*0.3) AS rank
    FROM public.chefs c
    WHERE c.deleted_at IS NULL
      AND (lower(c.name) LIKE '%'||lower(trim(p_query))||'%'
           OR similarity(lower(c.name),lower(trim(p_query)))>0.2
           OR to_tsvector('english',COALESCE(c.name,'')||' '||COALESCE(c.bio,''))@@plainto_tsquery('english',p_query))
    ORDER BY rank DESC, c.followers_count DESC
    LIMIT p_limit OFFSET p_offset;
$$;


ALTER FUNCTION "public"."search_chefs"("p_query" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


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
           c.name,img.image_url,im.matched_names,im.match_count::INTEGER
    FROM im JOIN public.recipes r ON r.id=im.recipe_id AND r.deleted_at IS NULL AND r.status='published'
    LEFT JOIN public.chefs c ON r.chef_id=c.id AND c.deleted_at IS NULL
    LEFT JOIN public.recipe_images img ON img.recipe_id=r.id AND img.is_primary=true AND img.deleted_at IS NULL
    ORDER BY im.match_count DESC, r.rating DESC
    LIMIT p_limit OFFSET p_offset;
END; $$;


ALTER FUNCTION "public"."search_ingredients"("p_ingredients" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


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
            img.image_url AS primary_image_url,
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


ALTER FUNCTION "public"."search_recipes"("p_query" "text", "p_category_id" "uuid", "p_cuisine" "text", "p_difficulty" "text", "p_max_time_min" integer, "p_max_calories" integer, "p_min_rating" numeric, "p_meal_type" "text", "p_dietary" "text"[], "p_sort_by" "text", "p_limit" integer, "p_offset" integer, "p_user_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."search_recipes"("p_query" "text", "p_category_id" "uuid", "p_cuisine" "text", "p_difficulty" "text", "p_max_time_min" integer, "p_max_calories" integer, "p_min_rating" numeric, "p_meal_type" "text", "p_dietary" "text"[], "p_sort_by" "text", "p_limit" integer, "p_offset" integer, "p_user_id" "uuid") IS 'Production search: FTS + synonyms + partial + typo + smart ranking + filters + sorting + pagination.';



CREATE OR REPLACE FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer DEFAULT 20) RETURNS TABLE("id" "uuid", "title" "text", "rating" numeric, "primary_image_url" "text", "phonetic_rank" double precision)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    SELECT r.id, r.title, r.rating, img.image_url AS primary_image_url,
           (1.0 / (1.0 + levenshtein(soundex(lower(r.title)), soundex(lower(trim(p_query)))) ::FLOAT)) AS phonetic_rank
    FROM public.recipes r
    LEFT JOIN public.recipe_images img ON img.recipe_id = r.id AND img.is_primary = true AND img.deleted_at IS NULL
    WHERE r.deleted_at IS NULL AND r.status = 'published'
      AND soundex(lower(r.title)) = soundex(lower(trim(p_query)))
    ORDER BY phonetic_rank DESC, r.rating DESC
    LIMIT p_limit;
$$;


ALTER FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer) IS 'Returns recipes matching phonetically (soundex + levenshtein).';



CREATE OR REPLACE FUNCTION "public"."search_suggestions"("p_query" "text", "p_limit" integer DEFAULT 8) RETURNS TABLE("suggestion" "text", "recipe_id" "uuid", "image_url" "text", "source" "text")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
    (
        SELECT DISTINCT ON (lower(r.title)) r.title AS suggestion, r.id AS recipe_id, img.image_url, 'title' AS source
        FROM public.recipes r
        LEFT JOIN public.recipe_images img ON img.recipe_id=r.id AND img.is_primary=true AND img.deleted_at IS NULL
        WHERE r.deleted_at IS NULL AND r.status='published'
          AND (lower(r.title) LIKE lower(trim(p_query))||'%' OR similarity(lower(r.title),lower(trim(p_query)))>0.25)
        ORDER BY lower(r.title), r.rating DESC
    )
    UNION ALL
    (
        SELECT DISTINCT ON (lower(c.name)) c.name, NULL::UUID, c.avatar_url, 'chef'
        FROM public.chefs c WHERE c.deleted_at IS NULL AND lower(c.name) LIKE lower(trim(p_query))||'%'
        ORDER BY lower(c.name)
    )
    UNION ALL
    (
        SELECT DISTINCT ON (lower(cat.name)) cat.name, NULL::UUID, cat.image_url, 'category'
        FROM public.categories cat WHERE cat.deleted_at IS NULL AND lower(cat.name) LIKE lower(trim(p_query))||'%'
        ORDER BY lower(cat.name)
    )
    LIMIT p_limit;
$$;


ALTER FUNCTION "public"."search_suggestions"("p_query" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_published_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.status = 'published' AND OLD.status <> 'published' AND NEW.published_at IS NULL THEN
        NEW.published_at := now();
    END IF;
    RETURN NEW;
END; $$;


ALTER FUNCTION "public"."set_published_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."slugify"("p_title" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE v TEXT;
BEGIN
    v := lower(unaccent(trim(p_title)));
    v := regexp_replace(v, '[^a-z0-9\s-]', '', 'g');
    v := regexp_replace(v, '\s+', '-', 'g');
    v := regexp_replace(v, '-{2,}', '-', 'g');
    RETURN trim(v, '-');
END; $$;


ALTER FUNCTION "public"."slugify"("p_title" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."slugify"("p_title" "text") IS 'Converts a recipe title to a URL-safe slug.';



CREATE OR REPLACE FUNCTION "public"."sync_chef_followers"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE chef_uuid UUID; fc INTEGER;
BEGIN
    chef_uuid := COALESCE(NEW.chef_id, OLD.chef_id);
    SELECT COUNT(*) INTO fc FROM public.chef_followers WHERE chef_id = chef_uuid;
    UPDATE public.chefs SET followers_count = fc WHERE id = chef_uuid;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_chef_followers"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_chef_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE chef_uuid UUID; rc INTEGER;
BEGIN
    chef_uuid := COALESCE(NEW.chef_id, OLD.chef_id);
    IF chef_uuid IS NOT NULL THEN
        SELECT COUNT(*) INTO rc FROM public.recipes WHERE chef_id = chef_uuid;
        UPDATE public.chefs SET recipes_count = rc WHERE id = chef_uuid;
    END IF;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_chef_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_collection_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE col_id UUID; rc INTEGER;
BEGIN
    col_id := COALESCE(NEW.collection_id, OLD.collection_id);
    SELECT COUNT(*) INTO rc FROM public.collection_recipes WHERE collection_id = col_id;
    UPDATE public.collections SET recipe_count = rc WHERE id = col_id;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_collection_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_collection_likes"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE col_id UUID;
BEGIN
    col_id := COALESCE(NEW.collection_id, OLD.collection_id);
    UPDATE public.collections SET likes_count = (SELECT COUNT(*) FROM public.collection_likes WHERE collection_id = col_id) WHERE id = col_id;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_collection_likes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_recipe_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE r_id UUID; chef_uuid UUID; avg_r NUMERIC(3,2); rc INTEGER; chef_avg NUMERIC(3,2);
BEGIN
    r_id := COALESCE(NEW.recipe_id, OLD.recipe_id);
    SELECT COALESCE(AVG(rating),0), COUNT(*) INTO avg_r, rc FROM public.reviews WHERE recipe_id = r_id;
    UPDATE public.recipes SET rating = avg_r, reviews_count = rc WHERE id = r_id;
    SELECT chef_id INTO chef_uuid FROM public.recipes WHERE id = r_id;
    IF chef_uuid IS NOT NULL THEN
        SELECT COALESCE(AVG(rating),0) INTO chef_avg FROM public.recipes WHERE chef_id = chef_uuid;
        UPDATE public.chefs SET average_rating = chef_avg WHERE id = chef_uuid;
    END IF;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_recipe_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_recipe_view_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.recipe_analytics (recipe_id, total_views) VALUES (NEW.recipe_id, 1)
    ON CONFLICT (recipe_id) DO UPDATE
        SET total_views = public.recipe_analytics.total_views + 1, updated_at = now();
    -- also bump the denormalized counter on recipes
    UPDATE public.recipes SET views_count = views_count + 1 WHERE id = NEW.recipe_id;
    PERFORM public.recompute_recipe_scores(NEW.recipe_id);
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_recipe_view_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_review_helpful_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE r_id UUID;
BEGIN
    r_id := COALESCE(NEW.review_id, OLD.review_id);
    UPDATE public.reviews SET helpful_count = (SELECT COUNT(*) FROM public.review_helpful_votes WHERE review_id = r_id) WHERE id = r_id;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_review_helpful_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_follow_counts"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE fid UUID; gid UUID;
BEGIN
    fid := COALESCE(NEW.follower_id,  OLD.follower_id);
    gid := COALESCE(NEW.following_id, OLD.following_id);
    UPDATE public.users SET following_count = (SELECT COUNT(*) FROM public.user_follows WHERE follower_id  = fid) WHERE id = fid;
    UPDATE public.users SET follower_count  = (SELECT COUNT(*) FROM public.user_follows WHERE following_id = gid) WHERE id = gid;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_user_follow_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_saved_count"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE u_id UUID; fc INTEGER;
BEGIN
    u_id := COALESCE(NEW.user_id, OLD.user_id);
    SELECT COUNT(*) INTO fc FROM public.favorites WHERE user_id = u_id;
    UPDATE public.users SET saved_count = fc WHERE id = u_id;
    RETURN NULL;
END; $$;


ALTER FUNCTION "public"."sync_user_saved_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_recipe_search_vector"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE ing_text TEXT; tag_text TEXT; cat_text TEXT; chef_nm TEXT;
BEGIN
    SELECT COALESCE(string_agg(name,' '),'')   INTO ing_text FROM public.recipe_ingredients WHERE recipe_id=NEW.id;
    SELECT COALESCE(string_agg(t.name,' '),'') INTO tag_text FROM public.recipe_tags rt JOIN public.tags t ON rt.tag_id=t.id WHERE rt.recipe_id=NEW.id;
    SELECT COALESCE(string_agg(c.name,' '),'') INTO cat_text FROM public.recipe_categories rc JOIN public.categories c ON rc.category_id=c.id WHERE rc.recipe_id=NEW.id;
    SELECT COALESCE(ch.name,'')                INTO chef_nm  FROM public.chefs ch WHERE ch.id=NEW.chef_id;
    NEW.search_vector :=
        setweight(to_tsvector('english', unaccent(COALESCE(NEW.title,''))),                               'A') ||
        setweight(to_tsvector('english', unaccent(COALESCE(NEW.description,''))),                         'B') ||
        setweight(to_tsvector('english', unaccent(ing_text||' '||tag_text)),                              'C') ||
        setweight(to_tsvector('english', unaccent(COALESCE(NEW.cuisine,'')||' '||chef_nm||' '||cat_text)),'D');
    RETURN NEW;
END; $$;


ALTER FUNCTION "public"."update_recipe_search_vector"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_search_history"("p_user_id" "uuid", "p_query" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.search_history (user_id,query,frequency) VALUES (p_user_id,p_query,1)
    ON CONFLICT (user_id,normalised_query) DO UPDATE SET frequency=public.search_history.frequency+1, created_at=now(), query=EXCLUDED.query;
    INSERT INTO public.trending_searches (query,search_count,daily_count,weekly_count,monthly_count,last_searched_at)
    VALUES (lower(trim(p_query)),1,1,1,1,now())
    ON CONFLICT (query) DO UPDATE SET search_count=public.trending_searches.search_count+1,
        daily_count=public.trending_searches.daily_count+1, weekly_count=public.trending_searches.weekly_count+1,
        monthly_count=public.trending_searches.monthly_count+1, last_searched_at=now();
END; $$;


ALTER FUNCTION "public"."upsert_search_history"("p_user_id" "uuid", "p_query" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


ALTER FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."allow_only_operation"("expected_operation" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


ALTER FUNCTION "storage"."allow_only_operation"("expected_operation" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."enforce_bucket_name_length"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION "storage"."enforce_bucket_name_length"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."extension"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION "storage"."extension"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."filename"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION "storage"."filename"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."foldername"("name" "text") RETURNS "text"[]
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION "storage"."foldername"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


ALTER FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_size_by_bucket"() RETURNS TABLE("size" bigint, "bucket_id" "text")
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION "storage"."get_size_by_bucket"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "next_key_token" "text" DEFAULT ''::"text", "next_upload_token" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "id" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "next_key_token" "text", "next_upload_token" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "start_after" "text" DEFAULT ''::"text", "next_token" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "metadata" "jsonb", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "start_after" "text", "next_token" "text", "sort_order" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."operation"() RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION "storage"."operation"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."protect_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "storage"."protect_delete"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "offsets" integer DEFAULT 0, "search" "text" DEFAULT ''::"text", "sortcolumn" "text" DEFAULT 'name'::"text", "sortorder" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer, "levels" integer, "offsets" integer, "search" "text", "sortcolumn" "text", "sortorder" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


ALTER FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "start_after" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text", "sort_column" "text" DEFAULT 'name'::"text", "sort_column_after" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


ALTER FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer, "levels" integer, "start_after" "text", "sort_order" "text", "sort_column" "text", "sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION "storage"."update_updated_at_column"() OWNER TO "supabase_storage_admin";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "auth"."audit_log_entries" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "payload" json,
    "created_at" timestamp with time zone,
    "ip_address" character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE "auth"."audit_log_entries" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."audit_log_entries" IS 'Auth: Audit trail for user actions.';



CREATE TABLE IF NOT EXISTS "auth"."custom_oauth_providers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "provider_type" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "name" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "client_secret" "text" NOT NULL,
    "acceptable_client_ids" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "pkce_enabled" boolean DEFAULT true NOT NULL,
    "attribute_mapping" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "authorization_params" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "email_optional" boolean DEFAULT false NOT NULL,
    "issuer" "text",
    "discovery_url" "text",
    "skip_nonce_check" boolean DEFAULT false NOT NULL,
    "cached_discovery" "jsonb",
    "discovery_cached_at" timestamp with time zone,
    "authorization_url" "text",
    "token_url" "text",
    "userinfo_url" "text",
    "jwks_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "custom_claims_allowlist" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    CONSTRAINT "custom_oauth_providers_authorization_url_https" CHECK ((("authorization_url" IS NULL) OR ("authorization_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_authorization_url_length" CHECK ((("authorization_url" IS NULL) OR ("char_length"("authorization_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_client_id_length" CHECK ((("char_length"("client_id") >= 1) AND ("char_length"("client_id") <= 512))),
    CONSTRAINT "custom_oauth_providers_discovery_url_length" CHECK ((("discovery_url" IS NULL) OR ("char_length"("discovery_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_identifier_format" CHECK (("identifier" ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::"text")),
    CONSTRAINT "custom_oauth_providers_issuer_length" CHECK ((("issuer" IS NULL) OR (("char_length"("issuer") >= 1) AND ("char_length"("issuer") <= 2048)))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_https" CHECK ((("jwks_uri" IS NULL) OR ("jwks_uri" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_length" CHECK ((("jwks_uri" IS NULL) OR ("char_length"("jwks_uri") <= 2048))),
    CONSTRAINT "custom_oauth_providers_name_length" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 100))),
    CONSTRAINT "custom_oauth_providers_oauth2_requires_endpoints" CHECK ((("provider_type" <> 'oauth2'::"text") OR (("authorization_url" IS NOT NULL) AND ("token_url" IS NOT NULL) AND ("userinfo_url" IS NOT NULL)))),
    CONSTRAINT "custom_oauth_providers_oidc_discovery_url_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("discovery_url" IS NULL) OR ("discovery_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_issuer_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NULL) OR ("issuer" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_requires_issuer" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NOT NULL))),
    CONSTRAINT "custom_oauth_providers_provider_type_check" CHECK (("provider_type" = ANY (ARRAY['oauth2'::"text", 'oidc'::"text"]))),
    CONSTRAINT "custom_oauth_providers_token_url_https" CHECK ((("token_url" IS NULL) OR ("token_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_token_url_length" CHECK ((("token_url" IS NULL) OR ("char_length"("token_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_https" CHECK ((("userinfo_url" IS NULL) OR ("userinfo_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_length" CHECK ((("userinfo_url" IS NULL) OR ("char_length"("userinfo_url") <= 2048)))
);


ALTER TABLE "auth"."custom_oauth_providers" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."flow_state" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid",
    "auth_code" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "code_challenge" "text",
    "provider_type" "text" NOT NULL,
    "provider_access_token" "text",
    "provider_refresh_token" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "authentication_method" "text" NOT NULL,
    "auth_code_issued_at" timestamp with time zone,
    "invite_token" "text",
    "referrer" "text",
    "oauth_client_state_id" "uuid",
    "linking_target_id" "uuid",
    "email_optional" boolean DEFAULT false NOT NULL
);


ALTER TABLE "auth"."flow_state" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."flow_state" IS 'Stores metadata for all OAuth/SSO login flows';



CREATE TABLE IF NOT EXISTS "auth"."identities" (
    "provider_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "identity_data" "jsonb" NOT NULL,
    "provider" "text" NOT NULL,
    "last_sign_in_at" timestamp with time zone,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "email" "text" GENERATED ALWAYS AS ("lower"(("identity_data" ->> 'email'::"text"))) STORED,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "auth"."identities" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."identities" IS 'Auth: Stores identities associated to a user.';



COMMENT ON COLUMN "auth"."identities"."email" IS 'Auth: Email is a generated column that references the optional email property in the identity_data';



CREATE TABLE IF NOT EXISTS "auth"."instances" (
    "id" "uuid" NOT NULL,
    "uuid" "uuid",
    "raw_base_config" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "auth"."instances" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."instances" IS 'Auth: Manages users across multiple sites.';



CREATE TABLE IF NOT EXISTS "auth"."mfa_amr_claims" (
    "session_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "authentication_method" "text" NOT NULL,
    "id" "uuid" NOT NULL
);


ALTER TABLE "auth"."mfa_amr_claims" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_amr_claims" IS 'auth: stores authenticator method reference claims for multi factor authentication';



CREATE TABLE IF NOT EXISTS "auth"."mfa_challenges" (
    "id" "uuid" NOT NULL,
    "factor_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "verified_at" timestamp with time zone,
    "ip_address" "inet" NOT NULL,
    "otp_code" "text",
    "web_authn_session_data" "jsonb"
);


ALTER TABLE "auth"."mfa_challenges" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_challenges" IS 'auth: stores metadata about challenge requests made';



CREATE TABLE IF NOT EXISTS "auth"."mfa_factors" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "friendly_name" "text",
    "factor_type" "auth"."factor_type" NOT NULL,
    "status" "auth"."factor_status" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "secret" "text",
    "phone" "text",
    "last_challenged_at" timestamp with time zone,
    "web_authn_credential" "jsonb",
    "web_authn_aaguid" "uuid",
    "last_webauthn_challenge_data" "jsonb"
);


ALTER TABLE "auth"."mfa_factors" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_factors" IS 'auth: stores metadata about factors';



COMMENT ON COLUMN "auth"."mfa_factors"."last_webauthn_challenge_data" IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';



CREATE TABLE IF NOT EXISTS "auth"."oauth_authorizations" (
    "id" "uuid" NOT NULL,
    "authorization_id" "text" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "redirect_uri" "text" NOT NULL,
    "scope" "text" NOT NULL,
    "state" "text",
    "resource" "text",
    "code_challenge" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "response_type" "auth"."oauth_response_type" DEFAULT 'code'::"auth"."oauth_response_type" NOT NULL,
    "status" "auth"."oauth_authorization_status" DEFAULT 'pending'::"auth"."oauth_authorization_status" NOT NULL,
    "authorization_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:03:00'::interval) NOT NULL,
    "approved_at" timestamp with time zone,
    "nonce" "text",
    CONSTRAINT "oauth_authorizations_authorization_code_length" CHECK (("char_length"("authorization_code") <= 255)),
    CONSTRAINT "oauth_authorizations_code_challenge_length" CHECK (("char_length"("code_challenge") <= 128)),
    CONSTRAINT "oauth_authorizations_expires_at_future" CHECK (("expires_at" > "created_at")),
    CONSTRAINT "oauth_authorizations_nonce_length" CHECK (("char_length"("nonce") <= 255)),
    CONSTRAINT "oauth_authorizations_redirect_uri_length" CHECK (("char_length"("redirect_uri") <= 2048)),
    CONSTRAINT "oauth_authorizations_resource_length" CHECK (("char_length"("resource") <= 2048)),
    CONSTRAINT "oauth_authorizations_scope_length" CHECK (("char_length"("scope") <= 4096)),
    CONSTRAINT "oauth_authorizations_state_length" CHECK (("char_length"("state") <= 4096))
);


ALTER TABLE "auth"."oauth_authorizations" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_client_states" (
    "id" "uuid" NOT NULL,
    "provider_type" "text" NOT NULL,
    "code_verifier" "text",
    "created_at" timestamp with time zone NOT NULL
);


ALTER TABLE "auth"."oauth_client_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."oauth_client_states" IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';



CREATE TABLE IF NOT EXISTS "auth"."oauth_clients" (
    "id" "uuid" NOT NULL,
    "client_secret_hash" "text",
    "registration_type" "auth"."oauth_registration_type" NOT NULL,
    "redirect_uris" "text" NOT NULL,
    "grant_types" "text" NOT NULL,
    "client_name" "text",
    "client_uri" "text",
    "logo_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "client_type" "auth"."oauth_client_type" DEFAULT 'confidential'::"auth"."oauth_client_type" NOT NULL,
    "token_endpoint_auth_method" "text" NOT NULL,
    CONSTRAINT "oauth_clients_client_name_length" CHECK (("char_length"("client_name") <= 1024)),
    CONSTRAINT "oauth_clients_client_uri_length" CHECK (("char_length"("client_uri") <= 2048)),
    CONSTRAINT "oauth_clients_logo_uri_length" CHECK (("char_length"("logo_uri") <= 2048)),
    CONSTRAINT "oauth_clients_token_endpoint_auth_method_check" CHECK (("token_endpoint_auth_method" = ANY (ARRAY['client_secret_basic'::"text", 'client_secret_post'::"text", 'none'::"text"])))
);


ALTER TABLE "auth"."oauth_clients" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_consents" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "scopes" "text" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone,
    CONSTRAINT "oauth_consents_revoked_after_granted" CHECK ((("revoked_at" IS NULL) OR ("revoked_at" >= "granted_at"))),
    CONSTRAINT "oauth_consents_scopes_length" CHECK (("char_length"("scopes") <= 2048)),
    CONSTRAINT "oauth_consents_scopes_not_empty" CHECK (("char_length"(TRIM(BOTH FROM "scopes")) > 0))
);


ALTER TABLE "auth"."oauth_consents" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."one_time_tokens" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token_type" "auth"."one_time_token_type" NOT NULL,
    "token_hash" "text" NOT NULL,
    "relates_to" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "one_time_tokens_token_hash_check" CHECK (("char_length"("token_hash") > 0))
);


ALTER TABLE "auth"."one_time_tokens" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."refresh_tokens" (
    "instance_id" "uuid",
    "id" bigint NOT NULL,
    "token" character varying(255),
    "user_id" character varying(255),
    "revoked" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "parent" character varying(255),
    "session_id" "uuid"
);


ALTER TABLE "auth"."refresh_tokens" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."refresh_tokens" IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';



CREATE SEQUENCE IF NOT EXISTS "auth"."refresh_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNER TO "supabase_auth_admin";


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNED BY "auth"."refresh_tokens"."id";



CREATE TABLE IF NOT EXISTS "auth"."saml_providers" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "entity_id" "text" NOT NULL,
    "metadata_xml" "text" NOT NULL,
    "metadata_url" "text",
    "attribute_mapping" "jsonb",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "name_id_format" "text",
    CONSTRAINT "entity_id not empty" CHECK (("char_length"("entity_id") > 0)),
    CONSTRAINT "metadata_url not empty" CHECK ((("metadata_url" = NULL::"text") OR ("char_length"("metadata_url") > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK (("char_length"("metadata_xml") > 0))
);


ALTER TABLE "auth"."saml_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_providers" IS 'Auth: Manages SAML Identity Provider connections.';



CREATE TABLE IF NOT EXISTS "auth"."saml_relay_states" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "request_id" "text" NOT NULL,
    "for_email" "text",
    "redirect_to" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "flow_state_id" "uuid",
    CONSTRAINT "request_id not empty" CHECK (("char_length"("request_id") > 0))
);


ALTER TABLE "auth"."saml_relay_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_relay_states" IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';



CREATE TABLE IF NOT EXISTS "auth"."schema_migrations" (
    "version" character varying(255) NOT NULL
);


ALTER TABLE "auth"."schema_migrations" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."schema_migrations" IS 'Auth: Manages updates to the auth system.';



CREATE TABLE IF NOT EXISTS "auth"."sessions" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "factor_id" "uuid",
    "aal" "auth"."aal_level",
    "not_after" timestamp with time zone,
    "refreshed_at" timestamp without time zone,
    "user_agent" "text",
    "ip" "inet",
    "tag" "text",
    "oauth_client_id" "uuid",
    "refresh_token_hmac_key" "text",
    "refresh_token_counter" bigint,
    "scopes" "text",
    CONSTRAINT "sessions_scopes_length" CHECK (("char_length"("scopes") <= 4096))
);


ALTER TABLE "auth"."sessions" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sessions" IS 'Auth: Stores session data associated to a user.';



COMMENT ON COLUMN "auth"."sessions"."not_after" IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_hmac_key" IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_counter" IS 'Holds the ID (counter) of the last issued refresh token.';



CREATE TABLE IF NOT EXISTS "auth"."sso_domains" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "domain" "text" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK (("char_length"("domain") > 0))
);


ALTER TABLE "auth"."sso_domains" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_domains" IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';



CREATE TABLE IF NOT EXISTS "auth"."sso_providers" (
    "id" "uuid" NOT NULL,
    "resource_id" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "disabled" boolean,
    CONSTRAINT "resource_id not empty" CHECK ((("resource_id" = NULL::"text") OR ("char_length"("resource_id") > 0)))
);


ALTER TABLE "auth"."sso_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_providers" IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';



COMMENT ON COLUMN "auth"."sso_providers"."resource_id" IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';



CREATE TABLE IF NOT EXISTS "auth"."users" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "aud" character varying(255),
    "role" character varying(255),
    "email" character varying(255),
    "encrypted_password" character varying(255),
    "email_confirmed_at" timestamp with time zone,
    "invited_at" timestamp with time zone,
    "confirmation_token" character varying(255),
    "confirmation_sent_at" timestamp with time zone,
    "recovery_token" character varying(255),
    "recovery_sent_at" timestamp with time zone,
    "email_change_token_new" character varying(255),
    "email_change" character varying(255),
    "email_change_sent_at" timestamp with time zone,
    "last_sign_in_at" timestamp with time zone,
    "raw_app_meta_data" "jsonb",
    "raw_user_meta_data" "jsonb",
    "is_super_admin" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "phone" "text" DEFAULT NULL::character varying,
    "phone_confirmed_at" timestamp with time zone,
    "phone_change" "text" DEFAULT ''::character varying,
    "phone_change_token" character varying(255) DEFAULT ''::character varying,
    "phone_change_sent_at" timestamp with time zone,
    "confirmed_at" timestamp with time zone GENERATED ALWAYS AS (LEAST("email_confirmed_at", "phone_confirmed_at")) STORED,
    "email_change_token_current" character varying(255) DEFAULT ''::character varying,
    "email_change_confirm_status" smallint DEFAULT 0,
    "banned_until" timestamp with time zone,
    "reauthentication_token" character varying(255) DEFAULT ''::character varying,
    "reauthentication_sent_at" timestamp with time zone,
    "is_sso_user" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "is_anonymous" boolean DEFAULT false NOT NULL,
    CONSTRAINT "users_email_change_confirm_status_check" CHECK ((("email_change_confirm_status" >= 0) AND ("email_change_confirm_status" <= 2)))
);


ALTER TABLE "auth"."users" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."users" IS 'Auth: Stores user login data within a secure schema.';



COMMENT ON COLUMN "auth"."users"."is_sso_user" IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';



CREATE TABLE IF NOT EXISTS "auth"."webauthn_challenges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "challenge_type" "text" NOT NULL,
    "session_data" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    CONSTRAINT "webauthn_challenges_challenge_type_check" CHECK (("challenge_type" = ANY (ARRAY['signup'::"text", 'registration'::"text", 'authentication'::"text"])))
);


ALTER TABLE "auth"."webauthn_challenges" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."webauthn_credentials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "credential_id" "bytea" NOT NULL,
    "public_key" "bytea" NOT NULL,
    "attestation_type" "text" DEFAULT ''::"text" NOT NULL,
    "aaguid" "uuid",
    "sign_count" bigint DEFAULT 0 NOT NULL,
    "transports" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "backup_eligible" boolean DEFAULT false NOT NULL,
    "backed_up" boolean DEFAULT false NOT NULL,
    "friendly_name" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_used_at" timestamp with time zone
);


ALTER TABLE "auth"."webauthn_credentials" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "public"."achievements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "icon_url" "text",
    "target" integer NOT NULL,
    "metric" "text" NOT NULL,
    "xp_reward" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "achievements_metric_check" CHECK (("metric" = ANY (ARRAY['recipes_published'::"text", 'reviews_given'::"text", 'recipes_cooked'::"text", 'recipes_saved'::"text", 'followers'::"text"]))),
    CONSTRAINT "achievements_target_check" CHECK (("target" > 0)),
    CONSTRAINT "achievements_xp_reward_check" CHECK (("xp_reward" >= 0))
);


ALTER TABLE "public"."achievements" OWNER TO "postgres";


COMMENT ON TABLE "public"."achievements" IS 'Achievement definitions with target thresholds.';



CREATE TABLE IF NOT EXISTS "public"."admin_actions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "admin_id" "uuid",
    "action_type" "text" NOT NULL,
    "target_type" "text",
    "target_id" "uuid",
    "details" "jsonb",
    "acted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_actions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "admin_id" "uuid",
    "action" "text" NOT NULL,
    "target_type" "text",
    "target_id" "uuid",
    "ip_address" "text",
    "user_agent" "text",
    "details" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."admin_logs" IS 'Detailed admin action log including IP and user-agent.';



CREATE TABLE IF NOT EXISTS "public"."admin_settings" (
    "key" "text" NOT NULL,
    "value" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "updated_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_settings" OWNER TO "postgres";


COMMENT ON TABLE "public"."admin_settings" IS 'Admin-only JSONB configuration store.';



CREATE TABLE IF NOT EXISTS "public"."app_settings" (
    "key" "text" NOT NULL,
    "value" "text" NOT NULL,
    "description" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."app_settings" OWNER TO "postgres";


COMMENT ON TABLE "public"."app_settings" IS 'Key-value store for global app configuration (maintenance, versioning, URLs).';



CREATE TABLE IF NOT EXISTS "public"."badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" NOT NULL,
    "icon_url" "text",
    "tier" "text" DEFAULT 'bronze'::"text" NOT NULL,
    "criteria" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "badges_tier_check" CHECK (("tier" = ANY (ARRAY['bronze'::"text", 'silver'::"text", 'gold'::"text", 'platinum'::"text"])))
);


ALTER TABLE "public"."badges" OWNER TO "postgres";


COMMENT ON TABLE "public"."badges" IS 'Badge definitions (Verified Chef, Top Contributor, etc.).';



CREATE TABLE IF NOT EXISTS "public"."banners" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "image_url" "text" NOT NULL,
    "target_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."banners" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "image_url" "text" NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "categories_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) >= 2))
);


ALTER TABLE "public"."categories" OWNER TO "postgres";


COMMENT ON TABLE "public"."categories" IS 'Recipe categories for browsing and filtering.';



CREATE TABLE IF NOT EXISTS "public"."chefs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "bio" "text",
    "website" "text",
    "instagram" "text",
    "avatar_url" "text" DEFAULT 'chef-avatars/default.png'::"text" NOT NULL,
    "followers_count" integer DEFAULT 0 NOT NULL,
    "recipes_count" integer DEFAULT 0 NOT NULL,
    "average_rating" numeric(3,2) DEFAULT 0.00 NOT NULL,
    "is_verified" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "chefs_average_rating_check" CHECK ((("average_rating" >= 0.00) AND ("average_rating" <= 5.00))),
    CONSTRAINT "chefs_followers_count_check" CHECK (("followers_count" >= 0)),
    CONSTRAINT "chefs_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) >= 2)),
    CONSTRAINT "chefs_recipes_count_check" CHECK (("recipes_count" >= 0)),
    CONSTRAINT "chefs_website_check" CHECK ((("website" IS NULL) OR ("website" ~ '^https?://'::"text")))
);


ALTER TABLE "public"."chefs" OWNER TO "postgres";


COMMENT ON TABLE "public"."chefs" IS 'Chef/creator profiles with social links, stats, verification.';



COMMENT ON COLUMN "public"."chefs"."is_verified" IS 'TRUE = verified badge shown in the UI.';



CREATE TABLE IF NOT EXISTS "public"."recipe_categories" (
    "recipe_id" "uuid" NOT NULL,
    "category_id" "uuid" NOT NULL
);


ALTER TABLE "public"."recipe_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_images" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "image_url" "text" NOT NULL,
    "is_primary" boolean DEFAULT false NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "width" integer,
    "height" integer,
    "mime_type" "text" DEFAULT 'image/jpeg'::"text",
    "file_size" bigint,
    "alt_text" "text",
    "blur_hash" "text",
    "uploaded_by" "uuid",
    "uploaded_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "thumbnail_url" "text",
    "medium_url" "text",
    "large_url" "text",
    "webp_url" "text",
    "avif_url" "text",
    "aspect_ratio" numeric(6,4),
    "dominant_color" "text",
    "compression_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    CONSTRAINT "recipe_images_compression_status_check" CHECK (("compression_status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'done'::"text", 'failed'::"text"]))),
    CONSTRAINT "recipe_images_display_order_check" CHECK (("display_order" >= 0)),
    CONSTRAINT "recipe_images_file_size_check" CHECK ((("file_size" IS NULL) OR ("file_size" >= 0))),
    CONSTRAINT "recipe_images_height_check" CHECK ((("height" IS NULL) OR ("height" > 0))),
    CONSTRAINT "recipe_images_width_check" CHECK ((("width" IS NULL) OR ("width" > 0)))
);


ALTER TABLE "public"."recipe_images" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_images" IS 'Ordered images per recipe with full metadata.';



COMMENT ON COLUMN "public"."recipe_images"."thumbnail_url" IS '150×150 thumbnail CDN URL.';



COMMENT ON COLUMN "public"."recipe_images"."medium_url" IS '600px wide medium image CDN URL.';



COMMENT ON COLUMN "public"."recipe_images"."large_url" IS '1200px wide large image CDN URL.';



COMMENT ON COLUMN "public"."recipe_images"."webp_url" IS 'WebP optimized format CDN URL.';



COMMENT ON COLUMN "public"."recipe_images"."avif_url" IS 'AVIF next-gen format CDN URL.';



COMMENT ON COLUMN "public"."recipe_images"."aspect_ratio" IS 'width / height stored for responsive layout hints.';



COMMENT ON COLUMN "public"."recipe_images"."dominant_color" IS 'Hex color extracted from image for palette/placeholders.';



COMMENT ON COLUMN "public"."recipe_images"."compression_status" IS 'CDN processing pipeline status.';



CREATE TABLE IF NOT EXISTS "public"."recipes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "chef_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "rating" numeric(3,2) DEFAULT 0.00 NOT NULL,
    "reviews_count" integer DEFAULT 0 NOT NULL,
    "prep_time" "text" DEFAULT '10 min'::"text" NOT NULL,
    "cook_time" "text" DEFAULT '20 min'::"text" NOT NULL,
    "total_time" "text" DEFAULT '30 min'::"text" NOT NULL,
    "calories" "text" DEFAULT '0 kcal'::"text" NOT NULL,
    "servings" "text" DEFAULT '4 servings'::"text" NOT NULL,
    "prep_time_minutes" integer DEFAULT 10 NOT NULL,
    "cook_time_minutes" integer DEFAULT 20 NOT NULL,
    "total_time_minutes" integer DEFAULT 30 NOT NULL,
    "calories_int" integer DEFAULT 0 NOT NULL,
    "servings_int" integer DEFAULT 4 NOT NULL,
    "cuisine" "text",
    "difficulty" "text" NOT NULL,
    "spice_level" integer DEFAULT 0 NOT NULL,
    "estimated_cost" numeric(10,2) DEFAULT 0.00,
    "status" "text" DEFAULT 'published'::"text" NOT NULL,
    "is_featured" boolean DEFAULT false NOT NULL,
    "is_trending" boolean DEFAULT false NOT NULL,
    "is_recommended" boolean DEFAULT false NOT NULL,
    "nutrition_info" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "search_vector" "tsvector",
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "slug" "text",
    "seo_title" "text",
    "seo_description" "text",
    "seo_keywords" "text"[],
    "canonical_url" "text",
    "language" "text" DEFAULT 'en'::"text" NOT NULL,
    "published_at" timestamp with time zone,
    "scheduled_publish_at" timestamp with time zone,
    "featured_until" timestamp with time zone,
    "recipe_version" integer DEFAULT 1 NOT NULL,
    "moderation_status" "text" DEFAULT 'approved'::"text" NOT NULL,
    "visibility" "text" DEFAULT 'public'::"text" NOT NULL,
    "allow_reviews" boolean DEFAULT true NOT NULL,
    "allow_comments" boolean DEFAULT true NOT NULL,
    "allow_download" boolean DEFAULT true NOT NULL,
    "estimated_cost_currency" "text" DEFAULT 'USD'::"text" NOT NULL,
    "difficulty_order" integer GENERATED ALWAYS AS (
CASE "difficulty"
    WHEN 'Easy'::"text" THEN 1
    WHEN 'Medium'::"text" THEN 2
    WHEN 'Hard'::"text" THEN 3
    ELSE 4
END) STORED,
    "views_count" integer DEFAULT 0 NOT NULL,
    "shares_count" integer DEFAULT 0 NOT NULL,
    "saves_count" integer DEFAULT 0 NOT NULL,
    "engagement_score" numeric(8,4) DEFAULT 0.0 NOT NULL,
    "popularity_score" numeric(8,4) DEFAULT 0.0 NOT NULL,
    "trending_score" numeric(8,4) DEFAULT 0.0 NOT NULL,
    CONSTRAINT "recipes_calories_int_check" CHECK (("calories_int" >= 0)),
    CONSTRAINT "recipes_cook_time_minutes_check" CHECK (("cook_time_minutes" >= 0)),
    CONSTRAINT "recipes_description_check" CHECK (("length"(TRIM(BOTH FROM "description")) >= 10)),
    CONSTRAINT "recipes_difficulty_check" CHECK (("difficulty" = ANY (ARRAY['Easy'::"text", 'Medium'::"text", 'Hard'::"text"]))),
    CONSTRAINT "recipes_estimated_cost_check" CHECK (("estimated_cost" >= (0)::numeric)),
    CONSTRAINT "recipes_moderation_status_check" CHECK (("moderation_status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text", 'flagged'::"text"]))),
    CONSTRAINT "recipes_prep_time_minutes_check" CHECK (("prep_time_minutes" >= 0)),
    CONSTRAINT "recipes_rating_check" CHECK ((("rating" >= 0.00) AND ("rating" <= 5.00))),
    CONSTRAINT "recipes_recipe_version_check" CHECK (("recipe_version" >= 1)),
    CONSTRAINT "recipes_reviews_count_check" CHECK (("reviews_count" >= 0)),
    CONSTRAINT "recipes_saves_count_check" CHECK (("saves_count" >= 0)),
    CONSTRAINT "recipes_servings_int_check" CHECK (("servings_int" >= 1)),
    CONSTRAINT "recipes_shares_count_check" CHECK (("shares_count" >= 0)),
    CONSTRAINT "recipes_spice_level_check" CHECK ((("spice_level" >= 0) AND ("spice_level" <= 3))),
    CONSTRAINT "recipes_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'published'::"text"]))),
    CONSTRAINT "recipes_title_check" CHECK (("length"(TRIM(BOTH FROM "title")) >= 3)),
    CONSTRAINT "recipes_total_time_minutes_check" CHECK (("total_time_minutes" >= 0)),
    CONSTRAINT "recipes_views_count_check" CHECK (("views_count" >= 0)),
    CONSTRAINT "recipes_visibility_check" CHECK (("visibility" = ANY (ARRAY['public'::"text", 'private'::"text", 'unlisted'::"text"])))
);


ALTER TABLE "public"."recipes" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipes" IS 'Core recipe records.';



COMMENT ON COLUMN "public"."recipes"."cuisine" IS 'Primary cuisine (Italian, Indian, Mexican …).';



COMMENT ON COLUMN "public"."recipes"."spice_level" IS '0=mild 1=low 2=medium 3=hot.';



COMMENT ON COLUMN "public"."recipes"."search_vector" IS 'Weighted tsvector A=title B=description C=ingredients+tags D=cuisine+chef+category.';



COMMENT ON COLUMN "public"."recipes"."slug" IS 'URL-friendly unique identifier e.g. truffle-mushroom-pasta.';



COMMENT ON COLUMN "public"."recipes"."moderation_status" IS 'Content moderation state. Only approved recipes show publicly.';



COMMENT ON COLUMN "public"."recipes"."visibility" IS 'public | private | unlisted.';



COMMENT ON COLUMN "public"."recipes"."difficulty_order" IS 'Generated sort key: Easy=1, Medium=2, Hard=3.';



COMMENT ON COLUMN "public"."recipes"."engagement_score" IS 'Computed engagement signal (views × 0.1 + saves × 1 + reviews × 2).';



COMMENT ON COLUMN "public"."recipes"."trending_score" IS 'Decaying popularity signal updated by trigger.';



CREATE MATERIALIZED VIEW "public"."category_recipe_view" AS
 SELECT "rc"."category_id",
    "cat"."name" AS "category_name",
    "r"."id" AS "recipe_id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."is_featured",
    "r"."is_trending",
    "r"."created_at",
    "c"."name" AS "chef_name",
    "img"."image_url" AS "primary_image_url"
   FROM (((("public"."recipe_categories" "rc"
     JOIN "public"."categories" "cat" ON ((("rc"."category_id" = "cat"."id") AND ("cat"."deleted_at" IS NULL))))
     JOIN "public"."recipes" "r" ON ((("rc"."recipe_id" = "r"."id") AND ("r"."deleted_at" IS NULL) AND ("r"."status" = 'published'::"text"))))
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."category_recipe_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."category_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."category_views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."chef_followers" (
    "user_id" "uuid" NOT NULL,
    "chef_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."chef_followers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collection_followers" (
    "user_id" "uuid" NOT NULL,
    "collection_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."collection_followers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collection_likes" (
    "user_id" "uuid" NOT NULL,
    "collection_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."collection_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collection_recipes" (
    "collection_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."collection_recipes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."collections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "recipe_count" integer DEFAULT 0 NOT NULL,
    "badge_hex_color" bigint DEFAULT '4294963929'::bigint NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "description" "text",
    "cover_image" "text",
    "is_public" boolean DEFAULT true NOT NULL,
    "likes_count" integer DEFAULT 0 NOT NULL,
    "follower_count" integer DEFAULT 0 NOT NULL,
    "is_collaborative" boolean DEFAULT false NOT NULL,
    CONSTRAINT "collections_follower_count_check" CHECK (("follower_count" >= 0)),
    CONSTRAINT "collections_likes_count_check" CHECK (("likes_count" >= 0)),
    CONSTRAINT "collections_name_check" CHECK (("length"(TRIM(BOTH FROM "name")) >= 1)),
    CONSTRAINT "collections_recipe_count_check" CHECK (("recipe_count" >= 0))
);


ALTER TABLE "public"."collections" OWNER TO "postgres";


COMMENT ON COLUMN "public"."collections"."badge_hex_color" IS 'Flutter Color int (e.g. 0xFFFFF2D9) for folder colour.';



COMMENT ON COLUMN "public"."collections"."is_public" IS 'TRUE = visible to all users.';



COMMENT ON COLUMN "public"."collections"."is_collaborative" IS 'TRUE = other invited users can add recipes.';



CREATE TABLE IF NOT EXISTS "public"."favorites" (
    "user_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."favorites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_flags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "flag_name" "text" NOT NULL,
    "is_enabled" boolean DEFAULT false NOT NULL,
    "description" "text",
    "rollout_pct" integer DEFAULT 100 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "feature_flags_rollout_pct_check" CHECK ((("rollout_pct" >= 0) AND ("rollout_pct" <= 100)))
);


ALTER TABLE "public"."feature_flags" OWNER TO "postgres";


COMMENT ON TABLE "public"."feature_flags" IS 'Feature flag registry for gradual rollouts.';



CREATE MATERIALIZED VIEW "public"."featured_recipes_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."cuisine",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."nutrition_info",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."created_at",
    "c"."id" AS "chef_id",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "c"."is_verified" AS "chef_verified",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."is_featured" = true) AND ("r"."status" = 'published'::"text") AND ("r"."deleted_at" IS NULL))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."featured_recipes_view" OWNER TO "postgres";


CREATE MATERIALIZED VIEW "public"."home_dashboard_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."cuisine",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."nutrition_info",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."created_at",
    "c"."id" AS "chef_id",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "c"."is_verified" AS "chef_verified",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."status" = 'published'::"text") AND ("r"."deleted_at" IS NULL) AND (("r"."is_featured" = true) OR ("r"."is_trending" = true) OR ("r"."is_recommended" = true)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."home_dashboard_view" OWNER TO "postgres";


CREATE MATERIALIZED VIEW "public"."latest_recipes_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."cuisine",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."nutrition_info",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."created_at",
    "c"."id" AS "chef_id",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "c"."is_verified" AS "chef_verified",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."status" = 'published'::"text") AND ("r"."deleted_at" IS NULL))
  ORDER BY "r"."created_at" DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."latest_recipes_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."meal_plan_recipes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "plan_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "plan_date" "date" NOT NULL,
    "meal_type" "text" NOT NULL,
    "servings" integer DEFAULT 1 NOT NULL,
    "notes" "text",
    "is_cooked" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "meal_plan_recipes_meal_type_check" CHECK (("meal_type" = ANY (ARRAY['breakfast'::"text", 'lunch'::"text", 'dinner'::"text", 'snack'::"text", 'dessert'::"text"]))),
    CONSTRAINT "meal_plan_recipes_servings_check" CHECK (("servings" >= 1))
);


ALTER TABLE "public"."meal_plan_recipes" OWNER TO "postgres";


COMMENT ON TABLE "public"."meal_plan_recipes" IS 'Recipes assigned to specific dates and meal slots in a plan.';



CREATE TABLE IF NOT EXISTS "public"."meal_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" DEFAULT 'My Meal Plan'::"text" NOT NULL,
    "week_start" "date" NOT NULL,
    "is_recurring" boolean DEFAULT false NOT NULL,
    "recur_days" integer,
    "notes" "text",
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "meal_plans_recur_days_check" CHECK ((("recur_days" IS NULL) OR ("recur_days" > 0)))
);


ALTER TABLE "public"."meal_plans" OWNER TO "postgres";


COMMENT ON TABLE "public"."meal_plans" IS 'Weekly meal plans created by users.';



CREATE TABLE IF NOT EXISTS "public"."moderation_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "content_type" "text" NOT NULL,
    "content_id" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "priority" "text" DEFAULT 'normal'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "assigned_to" "uuid",
    "resolved_by" "uuid",
    "resolution" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "resolved_at" timestamp with time zone,
    CONSTRAINT "moderation_queue_content_type_check" CHECK (("content_type" = ANY (ARRAY['recipe'::"text", 'review'::"text", 'user'::"text", 'comment'::"text"]))),
    CONSTRAINT "moderation_queue_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "moderation_queue_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'in_review'::"text", 'resolved'::"text", 'escalated'::"text"])))
);


ALTER TABLE "public"."moderation_queue" OWNER TO "postgres";


COMMENT ON TABLE "public"."moderation_queue" IS 'Content moderation queue for admins and moderators.';



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notification_type" "text" DEFAULT 'info'::"text" NOT NULL,
    "priority" "text" DEFAULT 'normal'::"text" NOT NULL,
    "deep_link" "text",
    "image_url" "text",
    "action_label" "text",
    "action_url" "text",
    "expires_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "notifications_notification_type_check" CHECK (("notification_type" = ANY (ARRAY['info'::"text", 'alert'::"text", 'promo'::"text", 'recipe'::"text", 'review'::"text", 'follow'::"text", 'achievement'::"text", 'system'::"text"]))),
    CONSTRAINT "notifications_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "notifications_title_check" CHECK (("length"(TRIM(BOTH FROM "title")) >= 1))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


COMMENT ON COLUMN "public"."notifications"."notification_type" IS 'Category of notification for filtering in the UI.';



COMMENT ON COLUMN "public"."notifications"."priority" IS 'Delivery priority (affects push notification urgency).';



COMMENT ON COLUMN "public"."notifications"."deep_link" IS 'In-app deep link to navigate on tap.';



COMMENT ON COLUMN "public"."notifications"."expires_at" IS 'Notification hides after this timestamp.';



CREATE TABLE IF NOT EXISTS "public"."profile_changes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "field_name" "text" NOT NULL,
    "old_value" "text",
    "new_value" "text",
    "changed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_changes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recently_viewed" (
    "user_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."recently_viewed" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_ai_tags" (
    "recipe_id" "uuid" NOT NULL,
    "health_score" numeric(4,2),
    "ai_keywords" "text"[],
    "season" "text"[],
    "occasion" "text"[],
    "cuisine_confidence" numeric(4,3),
    "difficulty_prediction" "text",
    "dietary_labels" "text"[],
    "quality_score" numeric(4,2),
    "generated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_ai_tags_cuisine_confidence_check" CHECK ((("cuisine_confidence" >= (0)::numeric) AND ("cuisine_confidence" <= (1)::numeric))),
    CONSTRAINT "recipe_ai_tags_difficulty_prediction_check" CHECK (("difficulty_prediction" = ANY (ARRAY['Easy'::"text", 'Medium'::"text", 'Hard'::"text"]))),
    CONSTRAINT "recipe_ai_tags_health_score_check" CHECK ((("health_score" >= (0)::numeric) AND ("health_score" <= (10)::numeric))),
    CONSTRAINT "recipe_ai_tags_quality_score_check" CHECK ((("quality_score" >= (0)::numeric) AND ("quality_score" <= (10)::numeric))),
    CONSTRAINT "recipe_ai_tags_season_check" CHECK (("season" <@ ARRAY['spring'::"text", 'summer'::"text", 'autumn'::"text", 'winter'::"text", 'year_round'::"text"]))
);


ALTER TABLE "public"."recipe_ai_tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_ai_tags" IS 'AI-generated metadata tags and predictions for recipes.';



CREATE TABLE IF NOT EXISTS "public"."recipe_analytics" (
    "recipe_id" "uuid" NOT NULL,
    "total_views" bigint DEFAULT 0 NOT NULL,
    "unique_views" bigint DEFAULT 0 NOT NULL,
    "total_shares" integer DEFAULT 0 NOT NULL,
    "total_downloads" integer DEFAULT 0 NOT NULL,
    "total_prints" integer DEFAULT 0 NOT NULL,
    "total_saves" integer DEFAULT 0 NOT NULL,
    "avg_completion_rate" numeric(5,4) DEFAULT 0.0 NOT NULL,
    "avg_cook_duration_s" integer DEFAULT 0 NOT NULL,
    "avg_session_duration_s" integer DEFAULT 0 NOT NULL,
    "click_through_rate" numeric(5,4) DEFAULT 0.0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_analytics_avg_completion_rate_check" CHECK ((("avg_completion_rate" >= (0)::numeric) AND ("avg_completion_rate" <= (1)::numeric))),
    CONSTRAINT "recipe_analytics_click_through_rate_check" CHECK ((("click_through_rate" >= (0)::numeric) AND ("click_through_rate" <= (1)::numeric)))
);


ALTER TABLE "public"."recipe_analytics" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_analytics" IS 'Aggregated analytics snapshot per recipe. Updated by triggers.';



CREATE TABLE IF NOT EXISTS "public"."recipe_ingredients" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "quantity" "text",
    "index" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "quantity_value" numeric(10,3),
    "quantity_unit" "text",
    "display_quantity" "text",
    "is_optional" boolean DEFAULT false NOT NULL,
    "group_name" "text",
    "preparation_note" "text",
    CONSTRAINT "recipe_ingredients_index_check" CHECK (("index" >= 0)),
    CONSTRAINT "recipe_ingredients_quantity_unit_check" CHECK ((("quantity_unit" IS NULL) OR ("quantity_unit" = ANY (ARRAY['g'::"text", 'kg'::"text", 'ml'::"text", 'l'::"text", 'cup'::"text", 'tsp'::"text", 'tbsp'::"text", 'pinch'::"text", 'piece'::"text", 'oz'::"text", 'lb'::"text", 'fl_oz'::"text", 'quart'::"text"]))))
);


ALTER TABLE "public"."recipe_ingredients" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_ingredients" IS 'Ordered ingredient list for each recipe.';



COMMENT ON COLUMN "public"."recipe_ingredients"."quantity_value" IS 'Numeric quantity (e.g. 2.5).';



COMMENT ON COLUMN "public"."recipe_ingredients"."quantity_unit" IS 'Unit of measurement (g | kg | ml | cup | tsp …).';



COMMENT ON COLUMN "public"."recipe_ingredients"."display_quantity" IS 'Human-readable quantity string (e.g. "2½ cups"). Shown in UI.';



COMMENT ON COLUMN "public"."recipe_ingredients"."is_optional" IS 'TRUE = ingredient is optional or for garnish.';



COMMENT ON COLUMN "public"."recipe_ingredients"."group_name" IS 'Ingredient group header (e.g. "For the sauce").';



COMMENT ON COLUMN "public"."recipe_ingredients"."preparation_note" IS 'Preparation hint shown inline (e.g. "finely chopped").';



CREATE TABLE IF NOT EXISTS "public"."recipe_steps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "step_content" "text" NOT NULL,
    "step_number" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_steps_step_content_check" CHECK (("length"(TRIM(BOTH FROM "step_content")) >= 5)),
    CONSTRAINT "recipe_steps_step_number_check" CHECK (("step_number" > 0))
);


ALTER TABLE "public"."recipe_steps" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_steps" IS 'Numbered cooking steps for each recipe.';



CREATE TABLE IF NOT EXISTS "public"."recipe_videos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "video_url" "text" NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "thumbnail_url" "text",
    "duration_seconds" integer,
    "resolution" "text",
    "bitrate_kbps" integer,
    "mime_type" "text" DEFAULT 'video/mp4'::"text",
    "encoding_format" "text",
    "subtitles_url" "text",
    "captions_url" "text",
    "file_size" bigint,
    "is_processed" boolean DEFAULT false NOT NULL,
    CONSTRAINT "recipe_videos_bitrate_kbps_check" CHECK (("bitrate_kbps" >= 0)),
    CONSTRAINT "recipe_videos_duration_seconds_check" CHECK (("duration_seconds" >= 0)),
    CONSTRAINT "recipe_videos_file_size_check" CHECK (("file_size" >= 0))
);


ALTER TABLE "public"."recipe_videos" OWNER TO "postgres";


COMMENT ON COLUMN "public"."recipe_videos"."duration_seconds" IS 'Video duration in seconds.';



COMMENT ON COLUMN "public"."recipe_videos"."resolution" IS 'e.g. 1920x1080.';



COMMENT ON COLUMN "public"."recipe_videos"."bitrate_kbps" IS 'Video bitrate in kilobits per second.';



COMMENT ON COLUMN "public"."recipe_videos"."is_processed" IS 'TRUE once transcoding pipeline finishes.';



CREATE OR REPLACE VIEW "public"."recipe_details_view" AS
 SELECT "r"."id",
    "r"."chef_id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."prep_time_minutes",
    "r"."cook_time_minutes",
    "r"."total_time_minutes",
    "r"."calories_int",
    "r"."servings_int",
    "r"."cuisine",
    "r"."difficulty",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."status",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."nutrition_info",
    "r"."search_vector",
    "r"."deleted_at",
    "r"."created_at",
    "r"."updated_at",
    "c"."name" AS "chef_name",
    "c"."bio" AS "chef_bio",
    "c"."avatar_url" AS "chef_avatar",
    "c"."followers_count" AS "chef_followers",
    "c"."is_verified" AS "chef_verified",
    (COALESCE(( SELECT "json_agg"("json_build_object"('id', "img"."id", 'url', "img"."image_url", 'is_primary', "img"."is_primary", 'display_order', "img"."display_order", 'blur_hash', "img"."blur_hash") ORDER BY "img"."display_order") AS "json_agg"
           FROM "public"."recipe_images" "img"
          WHERE (("img"."recipe_id" = "r"."id") AND ("img"."deleted_at" IS NULL))), '[]'::json))::"jsonb" AS "images",
    (COALESCE(( SELECT "json_agg"("json_build_object"('id', "vid"."id", 'url', "vid"."video_url")) AS "json_agg"
           FROM "public"."recipe_videos" "vid"
          WHERE (("vid"."recipe_id" = "r"."id") AND ("vid"."deleted_at" IS NULL))), '[]'::json))::"jsonb" AS "videos",
    (COALESCE(( SELECT "json_agg"("recipe_ingredients"."name" ORDER BY "recipe_ingredients"."index") AS "json_agg"
           FROM "public"."recipe_ingredients"
          WHERE ("recipe_ingredients"."recipe_id" = "r"."id")), '[]'::json))::"jsonb" AS "ingredients_list",
    (COALESCE(( SELECT "json_agg"("recipe_steps"."step_content" ORDER BY "recipe_steps"."step_number") AS "json_agg"
           FROM "public"."recipe_steps"
          WHERE ("recipe_steps"."recipe_id" = "r"."id")), '[]'::json))::"jsonb" AS "steps_list"
   FROM ("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
  WHERE ("r"."deleted_at" IS NULL);


ALTER VIEW "public"."recipe_details_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "action" "text" NOT NULL,
    "changed_by" "uuid",
    "old_data" "jsonb",
    "new_data" "jsonb",
    "changed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_history_action_check" CHECK (("action" = ANY (ARRAY['INSERT'::"text", 'UPDATE'::"text", 'DELETE'::"text", 'SOFT_DELETE'::"text"])))
);


ALTER TABLE "public"."recipe_history" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_history" IS 'Append-only audit trail for recipe CRUD.';



CREATE MATERIALIZED VIEW "public"."recipe_leaderboard_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."rating",
    "r"."reviews_count",
    "r"."saves_count",
    "r"."views_count",
    "r"."engagement_score",
    "r"."popularity_score",
    "r"."trending_score",
    "r"."difficulty",
    "r"."cuisine",
    "r"."created_at",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."deleted_at" IS NULL) AND ("r"."status" = 'published'::"text"))
  ORDER BY "r"."popularity_score" DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."recipe_leaderboard_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "notes_content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."recipe_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_nutrition" (
    "recipe_id" "uuid" NOT NULL,
    "calories" numeric(8,2),
    "protein_g" numeric(8,2),
    "fat_g" numeric(8,2),
    "carbs_g" numeric(8,2),
    "fiber_g" numeric(8,2),
    "sugar_g" numeric(8,2),
    "sodium_mg" numeric(8,2),
    "cholesterol_mg" numeric(8,2),
    "potassium_mg" numeric(8,2),
    "calcium_mg" numeric(8,2),
    "iron_mg" numeric(8,2),
    "vitamin_a_iu" numeric(8,2),
    "vitamin_c_mg" numeric(8,2),
    "per_serving" boolean DEFAULT true NOT NULL,
    "source" "text" DEFAULT 'manual'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_nutrition_calcium_mg_check" CHECK (("calcium_mg" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_calories_check" CHECK (("calories" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_carbs_g_check" CHECK (("carbs_g" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_cholesterol_mg_check" CHECK (("cholesterol_mg" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_fat_g_check" CHECK (("fat_g" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_fiber_g_check" CHECK (("fiber_g" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_iron_mg_check" CHECK (("iron_mg" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_potassium_mg_check" CHECK (("potassium_mg" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_protein_g_check" CHECK (("protein_g" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_sodium_mg_check" CHECK (("sodium_mg" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_source_check" CHECK (("source" = ANY (ARRAY['manual'::"text", 'ai'::"text", 'usda'::"text", 'calculated'::"text"]))),
    CONSTRAINT "recipe_nutrition_sugar_g_check" CHECK (("sugar_g" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_vitamin_a_iu_check" CHECK (("vitamin_a_iu" >= (0)::numeric)),
    CONSTRAINT "recipe_nutrition_vitamin_c_mg_check" CHECK (("vitamin_c_mg" >= (0)::numeric))
);


ALTER TABLE "public"."recipe_nutrition" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_nutrition" IS 'Detailed per-recipe nutrition data. One row per recipe.';



COMMENT ON COLUMN "public"."recipe_nutrition"."per_serving" IS 'TRUE = values are per single serving. FALSE = whole recipe.';



COMMENT ON COLUMN "public"."recipe_nutrition"."source" IS 'How the nutrition data was calculated (manual | ai | usda | calculated).';



CREATE TABLE IF NOT EXISTS "public"."recipe_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "reported_by" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "description" "text",
    "evidence_urls" "text"[],
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "action_taken" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_reports_reason_check" CHECK (("reason" = ANY (ARRAY['spam'::"text", 'inappropriate'::"text", 'copyright'::"text", 'misleading'::"text", 'other'::"text"]))),
    CONSTRAINT "recipe_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."recipe_reports" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_reports" IS 'User-submitted recipe content reports.';



CREATE TABLE IF NOT EXISTS "public"."recipe_tags" (
    "recipe_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL
);


ALTER TABLE "public"."recipe_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."recipe_translations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "language" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "translated_by" "text" DEFAULT 'auto'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "recipe_translations_translated_by_check" CHECK (("translated_by" = ANY (ARRAY['auto'::"text", 'human'::"text", 'verified'::"text"])))
);


ALTER TABLE "public"."recipe_translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."recipe_translations" IS 'Localised recipe titles and descriptions.';



CREATE TABLE IF NOT EXISTS "public"."recipe_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "duration_seconds" integer,
    CONSTRAINT "recipe_views_duration_seconds_check" CHECK (("duration_seconds" >= 0))
);


ALTER TABLE "public"."recipe_views" OWNER TO "postgres";


CREATE MATERIALIZED VIEW "public"."recommended_recipes_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."cuisine",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."nutrition_info",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."created_at",
    "c"."id" AS "chef_id",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "c"."is_verified" AS "chef_verified",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."is_recommended" = true) AND ("r"."status" = 'published'::"text") AND ("r"."deleted_at" IS NULL))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."recommended_recipes_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."review_helpful_votes" (
    "user_id" "uuid" NOT NULL,
    "review_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."review_helpful_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."review_media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "review_id" "uuid" NOT NULL,
    "media_type" "text" NOT NULL,
    "media_url" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "review_media_media_type_check" CHECK (("media_type" = ANY (ARRAY['image'::"text", 'video'::"text"])))
);


ALTER TABLE "public"."review_media" OWNER TO "postgres";


COMMENT ON TABLE "public"."review_media" IS 'Photos/videos attached to a review.';



CREATE TABLE IF NOT EXISTS "public"."reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "recipe_id" "uuid" NOT NULL,
    "rating" integer NOT NULL,
    "content" "text",
    "helpful_count" integer DEFAULT 0 NOT NULL,
    "parent_id" "uuid",
    "edited_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_verified_cook" boolean DEFAULT false NOT NULL,
    "edit_count" integer DEFAULT 0 NOT NULL,
    "is_spoiler" boolean DEFAULT false NOT NULL,
    "is_flagged" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "reviews_content_check" CHECK ((("content" IS NULL) OR ("length"(TRIM(BOTH FROM "content")) >= 5))),
    CONSTRAINT "reviews_edit_count_check" CHECK (("edit_count" >= 0)),
    CONSTRAINT "reviews_helpful_count_check" CHECK (("helpful_count" >= 0)),
    CONSTRAINT "reviews_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."reviews" OWNER TO "postgres";


COMMENT ON TABLE "public"."reviews" IS 'User ratings and comments. parent_id enables threaded replies.';



COMMENT ON COLUMN "public"."reviews"."parent_id" IS 'Self-referencing FK for nested comment replies.';



CREATE TABLE IF NOT EXISTS "public"."schema_versions" (
    "id" integer NOT NULL,
    "version" "text" NOT NULL,
    "description" "text",
    "applied_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."schema_versions" OWNER TO "postgres";


COMMENT ON TABLE "public"."schema_versions" IS 'Tracks every applied SQL migration.';



CREATE SEQUENCE IF NOT EXISTS "public"."schema_versions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."schema_versions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."schema_versions_id_seq" OWNED BY "public"."schema_versions"."id";



CREATE TABLE IF NOT EXISTS "public"."search_analytics" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "query" "text" NOT NULL,
    "results_count" integer DEFAULT 0 NOT NULL,
    "had_results" boolean DEFAULT true NOT NULL,
    "search_duration_ms" integer,
    "clicked_recipe_id" "uuid",
    "sort_by" "text",
    "filters_applied" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "click_position" integer,
    "session_id" "text",
    "source" "text" DEFAULT 'main'::"text" NOT NULL,
    CONSTRAINT "search_analytics_click_position_check" CHECK (("click_position" >= 1)),
    CONSTRAINT "search_analytics_results_count_check" CHECK (("results_count" >= 0)),
    CONSTRAINT "search_analytics_search_duration_ms_check" CHECK (("search_duration_ms" >= 0)),
    CONSTRAINT "search_analytics_source_check" CHECK (("source" = ANY (ARRAY['main'::"text", 'suggestion'::"text", 'autocomplete'::"text", 'filter'::"text", 'ai'::"text"])))
);


ALTER TABLE "public"."search_analytics" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."search_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "query" "text" NOT NULL,
    "normalised_query" "text" GENERATED ALWAYS AS ("lower"(TRIM(BOTH FROM "query"))) STORED,
    "frequency" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "search_history_frequency_check" CHECK (("frequency" >= 1))
);


ALTER TABLE "public"."search_history" OWNER TO "postgres";


COMMENT ON COLUMN "public"."search_history"."normalised_query" IS 'Lower-cased trimmed query for deduplication.';



COMMENT ON COLUMN "public"."search_history"."frequency" IS 'How many times this user searched this term.';



CREATE TABLE IF NOT EXISTS "public"."search_synonym_candidates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "term" "text" NOT NULL,
    "frequency" integer DEFAULT 1 NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "approved_as" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "search_synonym_candidates_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."search_synonym_candidates" OWNER TO "postgres";


COMMENT ON TABLE "public"."search_synonym_candidates" IS 'Zero-result search terms flagged for synonym learning.';



CREATE TABLE IF NOT EXISTS "public"."search_synonyms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "term" "text" NOT NULL,
    "synonyms" "text"[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."search_synonyms" OWNER TO "postgres";


COMMENT ON TABLE "public"."search_synonyms" IS 'Food synonym map for query expansion.';



CREATE TABLE IF NOT EXISTS "public"."shopping_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "item_name" "text" NOT NULL,
    "quantity" "text",
    "recipe_id" "uuid",
    "purchased" boolean DEFAULT false NOT NULL,
    "purchased_at" timestamp with time zone,
    "cost" numeric(8,2),
    "currency" "text" DEFAULT 'USD'::"text",
    "store_name" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."shopping_history" OWNER TO "postgres";


COMMENT ON TABLE "public"."shopping_history" IS 'History of items bought from shopping lists. Used for analytics and re-order suggestions.';



CREATE TABLE IF NOT EXISTS "public"."shopping_lists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "item_name" "text" NOT NULL,
    "quantity" "text",
    "is_completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    CONSTRAINT "shopping_lists_item_name_check" CHECK (("length"(TRIM(BOTH FROM "item_name")) >= 1))
);


ALTER TABLE "public"."shopping_lists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "tags_type_check" CHECK (("type" = ANY (ARRAY['dietary'::"text", 'cuisine'::"text", 'meal_type'::"text", 'nutrition'::"text"])))
);


ALTER TABLE "public"."tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."tags" IS 'Global tag library: dietary, cuisine, meal_type, nutrition.';



CREATE MATERIALIZED VIEW "public"."trending_recipes_view" AS
 SELECT "r"."id",
    "r"."title",
    "r"."description",
    "r"."rating",
    "r"."reviews_count",
    "r"."prep_time",
    "r"."cook_time",
    "r"."total_time",
    "r"."calories",
    "r"."servings",
    "r"."difficulty",
    "r"."cuisine",
    "r"."spice_level",
    "r"."estimated_cost",
    "r"."nutrition_info",
    "r"."is_featured",
    "r"."is_trending",
    "r"."is_recommended",
    "r"."created_at",
    "c"."id" AS "chef_id",
    "c"."name" AS "chef_name",
    "c"."avatar_url" AS "chef_avatar",
    "c"."is_verified" AS "chef_verified",
    "img"."image_url" AS "primary_image_url"
   FROM (("public"."recipes" "r"
     LEFT JOIN "public"."chefs" "c" ON ((("r"."chef_id" = "c"."id") AND ("c"."deleted_at" IS NULL))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE (("r"."is_trending" = true) AND ("r"."status" = 'published'::"text") AND ("r"."deleted_at" IS NULL))
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."trending_recipes_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trending_searches" (
    "query" "text" NOT NULL,
    "search_count" integer DEFAULT 1 NOT NULL,
    "daily_count" integer DEFAULT 0 NOT NULL,
    "weekly_count" integer DEFAULT 0 NOT NULL,
    "monthly_count" integer DEFAULT 0 NOT NULL,
    "last_searched_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "trending_searches_daily_count_check" CHECK (("daily_count" >= 0)),
    CONSTRAINT "trending_searches_monthly_count_check" CHECK (("monthly_count" >= 0)),
    CONSTRAINT "trending_searches_search_count_check" CHECK (("search_count" >= 1)),
    CONSTRAINT "trending_searches_weekly_count_check" CHECK (("weekly_count" >= 0))
);


ALTER TABLE "public"."trending_searches" OWNER TO "postgres";


COMMENT ON TABLE "public"."trending_searches" IS 'Aggregated trending search terms with time-window counts.';



CREATE TABLE IF NOT EXISTS "public"."user_achievements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "achievement_id" "uuid" NOT NULL,
    "progress" integer DEFAULT 0 NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_achievements_progress_check" CHECK (("progress" >= 0))
);


ALTER TABLE "public"."user_achievements" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_achievements" IS 'Per-user achievement progress and completion status.';



CREATE TABLE IF NOT EXISTS "public"."user_activity" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "activity_type" "text" NOT NULL,
    "meta_data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_activity" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "badge_id" "uuid" NOT NULL,
    "awarded_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_badges" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_badges" IS 'Badges earned by each user.';



CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "device_id" "text" NOT NULL,
    "fcm_token" "text",
    "platform" "text" NOT NULL,
    "device_model" "text",
    "os_version" "text",
    "app_version" "text",
    "push_enabled" boolean DEFAULT true NOT NULL,
    "last_active" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_devices_platform_check" CHECK (("platform" = ANY (ARRAY['ios'::"text", 'android'::"text", 'web'::"text"])))
);


ALTER TABLE "public"."user_devices" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_devices" IS 'Registered user devices for push notifications and analytics.';



CREATE TABLE IF NOT EXISTS "public"."user_follows" (
    "follower_id" "uuid" NOT NULL,
    "following_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_follows_check" CHECK (("follower_id" <> "following_id"))
);


ALTER TABLE "public"."user_follows" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_follows" IS 'Social follow graph between users.';



CREATE TABLE IF NOT EXISTS "public"."user_preferences" (
    "user_id" "uuid" NOT NULL,
    "push_notifications" boolean DEFAULT true NOT NULL,
    "email_newsletters" boolean DEFAULT false NOT NULL,
    "active_theme" "text" DEFAULT 'system'::"text" NOT NULL,
    "language_preference" "text" DEFAULT 'en'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_preferences" IS 'Per-user app preferences (theme, language, notifications).';



CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "name" "text" NOT NULL,
    "avatar_url" "text" DEFAULT 'user-avatars/default.png'::"text" NOT NULL,
    "chef_level" "text" DEFAULT 'Home Chef Level 1'::"text" NOT NULL,
    "saved_count" integer DEFAULT 0 NOT NULL,
    "cooked_count" integer DEFAULT 0 NOT NULL,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "display_name" "text",
    "username" "text",
    "bio" "text",
    "cover_image_url" "text",
    "location" "text",
    "country" "text",
    "timezone" "text" DEFAULT 'UTC'::"text" NOT NULL,
    "website" "text",
    "instagram" "text",
    "youtube" "text",
    "facebook" "text",
    "tiktok" "text",
    "profile_completed" boolean DEFAULT false NOT NULL,
    "onboarding_completed" boolean DEFAULT false NOT NULL,
    "login_provider" "text" DEFAULT 'email'::"text" NOT NULL,
    "last_login" timestamp with time zone,
    "last_seen" timestamp with time zone,
    "device_language" "text" DEFAULT 'en'::"text" NOT NULL,
    "preferred_units" "text" DEFAULT 'metric'::"text" NOT NULL,
    "preferred_diet" "text",
    "preferred_cuisine" "text",
    "email_verified_at" timestamp with time zone,
    "follower_count" integer DEFAULT 0 NOT NULL,
    "following_count" integer DEFAULT 0 NOT NULL,
    "recipe_count" integer DEFAULT 0 NOT NULL,
    "total_likes_received" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "users_cooked_count_check" CHECK (("cooked_count" >= 0)),
    CONSTRAINT "users_follower_count_check" CHECK (("follower_count" >= 0)),
    CONSTRAINT "users_following_count_check" CHECK (("following_count" >= 0)),
    CONSTRAINT "users_login_provider_check" CHECK (("login_provider" = ANY (ARRAY['email'::"text", 'google'::"text", 'apple'::"text", 'facebook'::"text"]))),
    CONSTRAINT "users_preferred_units_check" CHECK (("preferred_units" = ANY (ARRAY['metric'::"text", 'imperial'::"text"]))),
    CONSTRAINT "users_recipe_count_check" CHECK (("recipe_count" >= 0)),
    CONSTRAINT "users_saved_count_check" CHECK (("saved_count" >= 0)),
    CONSTRAINT "users_total_likes_received_check" CHECK (("total_likes_received" >= 0)),
    CONSTRAINT "users_website_check" CHECK ((("website" IS NULL) OR ("website" ~ '^https?://'::"text")))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON TABLE "public"."users" IS 'Core profile for every registered user.';



COMMENT ON COLUMN "public"."users"."deleted_at" IS 'NULL = active. Non-NULL = soft-deleted.';



COMMENT ON COLUMN "public"."users"."display_name" IS 'Public display name (can differ from internal name).';



COMMENT ON COLUMN "public"."users"."username" IS 'Unique handle e.g. @gordon_ramsay. URL-safe.';



COMMENT ON COLUMN "public"."users"."bio" IS 'Short user biography shown on profile.';



COMMENT ON COLUMN "public"."users"."cover_image_url" IS 'Profile banner / cover image URL.';



COMMENT ON COLUMN "public"."users"."onboarding_completed" IS 'TRUE once user finishes the onboarding flow.';



COMMENT ON COLUMN "public"."users"."login_provider" IS 'Primary authentication provider.';



COMMENT ON COLUMN "public"."users"."preferred_units" IS 'metric | imperial — used for ingredient quantities.';



CREATE OR REPLACE VIEW "public"."user_profile_view" AS
 SELECT "u"."id",
    "u"."email",
    "u"."name",
    "u"."avatar_url",
    "u"."chef_level",
    "u"."saved_count",
    "u"."cooked_count",
    "u"."deleted_at",
    "u"."created_at",
    "u"."updated_at",
    "up"."push_notifications",
    "up"."email_newsletters",
    "up"."active_theme",
    "up"."language_preference"
   FROM ("public"."users" "u"
     LEFT JOIN "public"."user_preferences" "up" ON (("u"."id" = "up"."user_id")))
  WHERE ("u"."deleted_at" IS NULL);


ALTER VIEW "public"."user_profile_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reported_user" "uuid" NOT NULL,
    "reported_by" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "action_taken" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_reports_check" CHECK (("reported_user" <> "reported_by")),
    CONSTRAINT "user_reports_reason_check" CHECK (("reason" = ANY (ARRAY['harassment'::"text", 'spam'::"text", 'impersonation'::"text", 'inappropriate'::"text", 'other'::"text"]))),
    CONSTRAINT "user_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."user_reports" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_reports" IS 'User-submitted user behaviour reports.';



CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "granted_by" "uuid",
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_roles_role_check" CHECK (("role" = ANY (ARRAY['admin'::"text", 'moderator'::"text", 'editor'::"text"])))
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_roles" IS 'RBAC: admin | moderator | editor assignments.';



CREATE TABLE IF NOT EXISTS "storage"."buckets" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "public" boolean DEFAULT false,
    "avif_autodetection" boolean DEFAULT false,
    "file_size_limit" bigint,
    "allowed_mime_types" "text"[],
    "owner_id" "text",
    "type" "storage"."buckettype" DEFAULT 'STANDARD'::"storage"."buckettype" NOT NULL
);


ALTER TABLE "storage"."buckets" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."buckets"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."buckets_analytics" (
    "name" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'ANALYTICS'::"storage"."buckettype" NOT NULL,
    "format" "text" DEFAULT 'ICEBERG'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "storage"."buckets_analytics" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."buckets_vectors" (
    "id" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'VECTOR'::"storage"."buckettype" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."buckets_vectors" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."migrations" (
    "id" integer NOT NULL,
    "name" character varying(100) NOT NULL,
    "hash" character varying(40) NOT NULL,
    "executed_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "storage"."migrations" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bucket_id" "text",
    "name" "text",
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_accessed_at" timestamp with time zone DEFAULT "now"(),
    "metadata" "jsonb",
    "path_tokens" "text"[] GENERATED ALWAYS AS ("string_to_array"("name", '/'::"text")) STORED,
    "version" "text",
    "owner_id" "text",
    "user_metadata" "jsonb"
);


ALTER TABLE "storage"."objects" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."objects"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads" (
    "id" "text" NOT NULL,
    "in_progress_size" bigint DEFAULT 0 NOT NULL,
    "upload_signature" "text" NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "version" "text" NOT NULL,
    "owner_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_metadata" "jsonb",
    "metadata" "jsonb"
);


ALTER TABLE "storage"."s3_multipart_uploads" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads_parts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "upload_id" "text" NOT NULL,
    "size" bigint DEFAULT 0 NOT NULL,
    "part_number" integer NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "etag" "text" NOT NULL,
    "owner_id" "text",
    "version" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."s3_multipart_uploads_parts" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."vector_indexes" (
    "id" "text" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL COLLATE "pg_catalog"."C",
    "bucket_id" "text" NOT NULL,
    "data_type" "text" NOT NULL,
    "dimension" integer NOT NULL,
    "distance_metric" "text" NOT NULL,
    "metadata_configuration" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."vector_indexes" OWNER TO "supabase_storage_admin";


ALTER TABLE ONLY "auth"."refresh_tokens" ALTER COLUMN "id" SET DEFAULT "nextval"('"auth"."refresh_tokens_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."schema_versions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."schema_versions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."chefs"
    ADD CONSTRAINT "chefs_pkey" PRIMARY KEY ("id");



CREATE MATERIALIZED VIEW "public"."chef_profile_view" AS
 SELECT "c"."id",
    "c"."name",
    "c"."bio",
    "c"."website",
    "c"."instagram",
    "c"."avatar_url",
    "c"."followers_count",
    "c"."recipes_count",
    "c"."average_rating",
    "c"."is_verified",
    "c"."created_at",
    COALESCE("json_agg"("json_build_object"('id', "r"."id", 'title', "r"."title", 'rating', "r"."rating", 'image', "img"."image_url", 'difficulty', "r"."difficulty") ORDER BY "r"."rating" DESC) FILTER (WHERE ("r"."id" IS NOT NULL)), '[]'::json) AS "top_recipes"
   FROM (("public"."chefs" "c"
     LEFT JOIN "public"."recipes" "r" ON ((("r"."chef_id" = "c"."id") AND ("r"."deleted_at" IS NULL) AND ("r"."status" = 'published'::"text"))))
     LEFT JOIN "public"."recipe_images" "img" ON ((("img"."recipe_id" = "r"."id") AND ("img"."is_primary" = true) AND ("img"."deleted_at" IS NULL))))
  WHERE ("c"."deleted_at" IS NULL)
  GROUP BY "c"."id"
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."chef_profile_view" OWNER TO "postgres";


CREATE MATERIALIZED VIEW "public"."top_chefs_view" AS
 SELECT "c"."id",
    "c"."name",
    "c"."bio",
    "c"."avatar_url",
    "c"."followers_count",
    "c"."recipes_count",
    "c"."average_rating",
    "c"."is_verified",
    "count"(DISTINCT "f"."user_id") AS "recent_followers"
   FROM ("public"."chefs" "c"
     LEFT JOIN "public"."chef_followers" "f" ON ((("f"."chef_id" = "c"."id") AND ("f"."created_at" > ("now"() - '30 days'::interval)))))
  WHERE ("c"."deleted_at" IS NULL)
  GROUP BY "c"."id"
  ORDER BY "c"."followers_count" DESC, "c"."average_rating" DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW "public"."top_chefs_view" OWNER TO "postgres";


ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "amr_id_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."audit_log_entries"
    ADD CONSTRAINT "audit_log_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_identifier_key" UNIQUE ("identifier");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."flow_state"
    ADD CONSTRAINT "flow_state_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_provider_id_provider_unique" UNIQUE ("provider_id", "provider");



ALTER TABLE ONLY "auth"."instances"
    ADD CONSTRAINT "instances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_authentication_method_pkey" UNIQUE ("session_id", "authentication_method");



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_last_challenged_at_key" UNIQUE ("last_challenged_at");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_code_key" UNIQUE ("authorization_code");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_id_key" UNIQUE ("authorization_id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_client_states"
    ADD CONSTRAINT "oauth_client_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_client_unique" UNIQUE ("user_id", "client_id");



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_token_unique" UNIQUE ("token");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_entity_id_key" UNIQUE ("entity_id");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."schema_migrations"
    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_providers"
    ADD CONSTRAINT "sso_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."achievements"
    ADD CONSTRAINT "achievements_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."achievements"
    ADD CONSTRAINT "achievements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_actions"
    ADD CONSTRAINT "admin_actions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_logs"
    ADD CONSTRAINT "admin_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_settings"
    ADD CONSTRAINT "admin_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."app_settings"
    ADD CONSTRAINT "app_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."banners"
    ADD CONSTRAINT "banners_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."categories"
    ADD CONSTRAINT "categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."category_views"
    ADD CONSTRAINT "category_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."chef_followers"
    ADD CONSTRAINT "chef_followers_pkey" PRIMARY KEY ("user_id", "chef_id");



ALTER TABLE ONLY "public"."chefs"
    ADD CONSTRAINT "chefs_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."collection_followers"
    ADD CONSTRAINT "collection_followers_pkey" PRIMARY KEY ("user_id", "collection_id");



ALTER TABLE ONLY "public"."collection_likes"
    ADD CONSTRAINT "collection_likes_pkey" PRIMARY KEY ("user_id", "collection_id");



ALTER TABLE ONLY "public"."collection_recipes"
    ADD CONSTRAINT "collection_recipes_pkey" PRIMARY KEY ("collection_id", "recipe_id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_user_id_name_key" UNIQUE ("user_id", "name");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_pkey" PRIMARY KEY ("user_id", "recipe_id");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_flag_name_key" UNIQUE ("flag_name");



ALTER TABLE ONLY "public"."feature_flags"
    ADD CONSTRAINT "feature_flags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."meal_plan_recipes"
    ADD CONSTRAINT "meal_plan_recipes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."meal_plan_recipes"
    ADD CONSTRAINT "meal_plan_recipes_plan_id_plan_date_meal_type_recipe_id_key" UNIQUE ("plan_id", "plan_date", "meal_type", "recipe_id");



ALTER TABLE ONLY "public"."meal_plans"
    ADD CONSTRAINT "meal_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."moderation_queue"
    ADD CONSTRAINT "moderation_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_changes"
    ADD CONSTRAINT "profile_changes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recently_viewed"
    ADD CONSTRAINT "recently_viewed_pkey" PRIMARY KEY ("user_id", "recipe_id");



ALTER TABLE ONLY "public"."recipe_ai_tags"
    ADD CONSTRAINT "recipe_ai_tags_pkey" PRIMARY KEY ("recipe_id");



ALTER TABLE ONLY "public"."recipe_analytics"
    ADD CONSTRAINT "recipe_analytics_pkey" PRIMARY KEY ("recipe_id");



ALTER TABLE ONLY "public"."recipe_categories"
    ADD CONSTRAINT "recipe_categories_pkey" PRIMARY KEY ("recipe_id", "category_id");



ALTER TABLE ONLY "public"."recipe_history"
    ADD CONSTRAINT "recipe_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_images"
    ADD CONSTRAINT "recipe_images_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_ingredients"
    ADD CONSTRAINT "recipe_ingredients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_notes"
    ADD CONSTRAINT "recipe_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_notes"
    ADD CONSTRAINT "recipe_notes_user_id_recipe_id_key" UNIQUE ("user_id", "recipe_id");



ALTER TABLE ONLY "public"."recipe_nutrition"
    ADD CONSTRAINT "recipe_nutrition_pkey" PRIMARY KEY ("recipe_id");



ALTER TABLE ONLY "public"."recipe_reports"
    ADD CONSTRAINT "recipe_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_steps"
    ADD CONSTRAINT "recipe_steps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_steps"
    ADD CONSTRAINT "recipe_steps_recipe_id_step_number_key" UNIQUE ("recipe_id", "step_number");



ALTER TABLE ONLY "public"."recipe_tags"
    ADD CONSTRAINT "recipe_tags_pkey" PRIMARY KEY ("recipe_id", "tag_id");



ALTER TABLE ONLY "public"."recipe_translations"
    ADD CONSTRAINT "recipe_translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_translations"
    ADD CONSTRAINT "recipe_translations_recipe_id_language_key" UNIQUE ("recipe_id", "language");



ALTER TABLE ONLY "public"."recipe_videos"
    ADD CONSTRAINT "recipe_videos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipe_views"
    ADD CONSTRAINT "recipe_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipes"
    ADD CONSTRAINT "recipes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."recipes"
    ADD CONSTRAINT "recipes_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."review_helpful_votes"
    ADD CONSTRAINT "review_helpful_votes_pkey" PRIMARY KEY ("user_id", "review_id");



ALTER TABLE ONLY "public"."review_media"
    ADD CONSTRAINT "review_media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_user_id_recipe_id_key" UNIQUE ("user_id", "recipe_id");



ALTER TABLE ONLY "public"."schema_versions"
    ADD CONSTRAINT "schema_versions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."schema_versions"
    ADD CONSTRAINT "schema_versions_version_key" UNIQUE ("version");



ALTER TABLE ONLY "public"."search_analytics"
    ADD CONSTRAINT "search_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."search_history"
    ADD CONSTRAINT "search_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."search_history"
    ADD CONSTRAINT "search_history_user_id_normalised_query_key" UNIQUE ("user_id", "normalised_query");



ALTER TABLE ONLY "public"."search_synonym_candidates"
    ADD CONSTRAINT "search_synonym_candidates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."search_synonym_candidates"
    ADD CONSTRAINT "search_synonym_candidates_term_key" UNIQUE ("term");



ALTER TABLE ONLY "public"."search_synonyms"
    ADD CONSTRAINT "search_synonyms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."search_synonyms"
    ADD CONSTRAINT "search_synonyms_term_key" UNIQUE ("term");



ALTER TABLE ONLY "public"."shopping_history"
    ADD CONSTRAINT "shopping_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trending_searches"
    ADD CONSTRAINT "trending_searches_pkey" PRIMARY KEY ("query");



ALTER TABLE ONLY "public"."user_achievements"
    ADD CONSTRAINT "user_achievements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_achievements"
    ADD CONSTRAINT "user_achievements_user_id_achievement_id_key" UNIQUE ("user_id", "achievement_id");



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_badge_id_key" UNIQUE ("user_id", "badge_id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_device_id_key" UNIQUE ("user_id", "device_id");



ALTER TABLE ONLY "public"."user_follows"
    ADD CONSTRAINT "user_follows_pkey" PRIMARY KEY ("follower_id", "following_id");



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_role_key" UNIQUE ("user_id", "role");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_username_key" UNIQUE ("username");



ALTER TABLE ONLY "storage"."buckets_analytics"
    ADD CONSTRAINT "buckets_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets"
    ADD CONSTRAINT "buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets_vectors"
    ADD CONSTRAINT "buckets_vectors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_name_key" UNIQUE ("name");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_pkey" PRIMARY KEY ("id");



CREATE INDEX "audit_logs_instance_id_idx" ON "auth"."audit_log_entries" USING "btree" ("instance_id");



CREATE UNIQUE INDEX "confirmation_token_idx" ON "auth"."users" USING "btree" ("confirmation_token") WHERE (("confirmation_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "custom_oauth_providers_created_at_idx" ON "auth"."custom_oauth_providers" USING "btree" ("created_at");



CREATE INDEX "custom_oauth_providers_enabled_idx" ON "auth"."custom_oauth_providers" USING "btree" ("enabled");



CREATE INDEX "custom_oauth_providers_identifier_idx" ON "auth"."custom_oauth_providers" USING "btree" ("identifier");



CREATE INDEX "custom_oauth_providers_provider_type_idx" ON "auth"."custom_oauth_providers" USING "btree" ("provider_type");



CREATE UNIQUE INDEX "email_change_token_current_idx" ON "auth"."users" USING "btree" ("email_change_token_current") WHERE (("email_change_token_current")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "email_change_token_new_idx" ON "auth"."users" USING "btree" ("email_change_token_new") WHERE (("email_change_token_new")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "factor_id_created_at_idx" ON "auth"."mfa_factors" USING "btree" ("user_id", "created_at");



CREATE INDEX "flow_state_created_at_idx" ON "auth"."flow_state" USING "btree" ("created_at" DESC);



CREATE INDEX "identities_email_idx" ON "auth"."identities" USING "btree" ("email" "text_pattern_ops");



COMMENT ON INDEX "auth"."identities_email_idx" IS 'Auth: Ensures indexed queries on the email column';



CREATE INDEX "identities_user_id_idx" ON "auth"."identities" USING "btree" ("user_id");



CREATE INDEX "idx_auth_code" ON "auth"."flow_state" USING "btree" ("auth_code");



CREATE INDEX "idx_oauth_client_states_created_at" ON "auth"."oauth_client_states" USING "btree" ("created_at");



CREATE INDEX "idx_user_id_auth_method" ON "auth"."flow_state" USING "btree" ("user_id", "authentication_method");



CREATE INDEX "idx_users_created_at_desc" ON "auth"."users" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_users_email" ON "auth"."users" USING "btree" ("email");



CREATE INDEX "idx_users_last_sign_in_at_desc" ON "auth"."users" USING "btree" ("last_sign_in_at" DESC);



CREATE INDEX "idx_users_name" ON "auth"."users" USING "btree" ((("raw_user_meta_data" ->> 'name'::"text"))) WHERE (("raw_user_meta_data" ->> 'name'::"text") IS NOT NULL);



CREATE INDEX "mfa_challenge_created_at_idx" ON "auth"."mfa_challenges" USING "btree" ("created_at" DESC);



CREATE UNIQUE INDEX "mfa_factors_user_friendly_name_unique" ON "auth"."mfa_factors" USING "btree" ("friendly_name", "user_id") WHERE (TRIM(BOTH FROM "friendly_name") <> ''::"text");



CREATE INDEX "mfa_factors_user_id_idx" ON "auth"."mfa_factors" USING "btree" ("user_id");



CREATE INDEX "oauth_auth_pending_exp_idx" ON "auth"."oauth_authorizations" USING "btree" ("expires_at") WHERE ("status" = 'pending'::"auth"."oauth_authorization_status");



CREATE INDEX "oauth_clients_deleted_at_idx" ON "auth"."oauth_clients" USING "btree" ("deleted_at");



CREATE INDEX "oauth_consents_active_client_idx" ON "auth"."oauth_consents" USING "btree" ("client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_active_user_client_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_user_order_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "granted_at" DESC);



CREATE INDEX "one_time_tokens_relates_to_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("relates_to");



CREATE INDEX "one_time_tokens_token_hash_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("token_hash");



CREATE UNIQUE INDEX "one_time_tokens_user_id_token_type_key" ON "auth"."one_time_tokens" USING "btree" ("user_id", "token_type");



CREATE UNIQUE INDEX "reauthentication_token_idx" ON "auth"."users" USING "btree" ("reauthentication_token") WHERE (("reauthentication_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "recovery_token_idx" ON "auth"."users" USING "btree" ("recovery_token") WHERE (("recovery_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "refresh_tokens_instance_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id");



CREATE INDEX "refresh_tokens_instance_id_user_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id", "user_id");



CREATE INDEX "refresh_tokens_parent_idx" ON "auth"."refresh_tokens" USING "btree" ("parent");



CREATE INDEX "refresh_tokens_session_id_revoked_idx" ON "auth"."refresh_tokens" USING "btree" ("session_id", "revoked");



CREATE INDEX "refresh_tokens_updated_at_idx" ON "auth"."refresh_tokens" USING "btree" ("updated_at" DESC);



CREATE INDEX "saml_providers_sso_provider_id_idx" ON "auth"."saml_providers" USING "btree" ("sso_provider_id");



CREATE INDEX "saml_relay_states_created_at_idx" ON "auth"."saml_relay_states" USING "btree" ("created_at" DESC);



CREATE INDEX "saml_relay_states_for_email_idx" ON "auth"."saml_relay_states" USING "btree" ("for_email");



CREATE INDEX "saml_relay_states_sso_provider_id_idx" ON "auth"."saml_relay_states" USING "btree" ("sso_provider_id");



CREATE INDEX "sessions_not_after_idx" ON "auth"."sessions" USING "btree" ("not_after" DESC);



CREATE INDEX "sessions_oauth_client_id_idx" ON "auth"."sessions" USING "btree" ("oauth_client_id");



CREATE INDEX "sessions_user_id_idx" ON "auth"."sessions" USING "btree" ("user_id");



CREATE UNIQUE INDEX "sso_domains_domain_idx" ON "auth"."sso_domains" USING "btree" ("lower"("domain"));



CREATE INDEX "sso_domains_sso_provider_id_idx" ON "auth"."sso_domains" USING "btree" ("sso_provider_id");



CREATE UNIQUE INDEX "sso_providers_resource_id_idx" ON "auth"."sso_providers" USING "btree" ("lower"("resource_id"));



CREATE INDEX "sso_providers_resource_id_pattern_idx" ON "auth"."sso_providers" USING "btree" ("resource_id" "text_pattern_ops");



CREATE UNIQUE INDEX "unique_phone_factor_per_user" ON "auth"."mfa_factors" USING "btree" ("user_id", "phone");



CREATE INDEX "user_id_created_at_idx" ON "auth"."sessions" USING "btree" ("user_id", "created_at");



CREATE UNIQUE INDEX "users_email_partial_key" ON "auth"."users" USING "btree" ("email") WHERE ("is_sso_user" = false);



COMMENT ON INDEX "auth"."users_email_partial_key" IS 'Auth: A partial unique index that applies only when is_sso_user is false';



CREATE INDEX "users_instance_id_email_idx" ON "auth"."users" USING "btree" ("instance_id", "lower"(("email")::"text"));



CREATE INDEX "users_instance_id_idx" ON "auth"."users" USING "btree" ("instance_id");



CREATE INDEX "users_is_anonymous_idx" ON "auth"."users" USING "btree" ("is_anonymous");



CREATE INDEX "webauthn_challenges_expires_at_idx" ON "auth"."webauthn_challenges" USING "btree" ("expires_at");



CREATE INDEX "webauthn_challenges_user_id_idx" ON "auth"."webauthn_challenges" USING "btree" ("user_id");



CREATE UNIQUE INDEX "webauthn_credentials_credential_id_key" ON "auth"."webauthn_credentials" USING "btree" ("credential_id");



CREATE INDEX "webauthn_credentials_user_id_idx" ON "auth"."webauthn_credentials" USING "btree" ("user_id");



CREATE INDEX "idx_admin_actions_date" ON "public"."admin_actions" USING "btree" ("acted_at" DESC);



CREATE INDEX "idx_admin_logs_admin_id" ON "public"."admin_logs" USING "btree" ("admin_id", "created_at" DESC);



CREATE INDEX "idx_admin_logs_target" ON "public"."admin_logs" USING "btree" ("target_type", "target_id");



CREATE INDEX "idx_ai_tags_dietary" ON "public"."recipe_ai_tags" USING "gin" ("dietary_labels");



CREATE INDEX "idx_ai_tags_health" ON "public"."recipe_ai_tags" USING "btree" ("health_score" DESC);



CREATE INDEX "idx_ai_tags_keywords" ON "public"."recipe_ai_tags" USING "gin" ("ai_keywords");



CREATE INDEX "idx_ai_tags_quality" ON "public"."recipe_ai_tags" USING "btree" ("quality_score" DESC);



CREATE INDEX "idx_ai_tags_season" ON "public"."recipe_ai_tags" USING "gin" ("season");



CREATE INDEX "idx_categories_active" ON "public"."categories" USING "btree" ("name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_categories_name_trgm" ON "public"."categories" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_chef_followers_chef" ON "public"."chef_followers" USING "btree" ("chef_id");



CREATE INDEX "idx_chefs_active" ON "public"."chefs" USING "btree" ("name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_chefs_name_trgm" ON "public"."chefs" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_collection_followers_col" ON "public"."collection_followers" USING "btree" ("collection_id");



CREATE INDEX "idx_collection_likes_col" ON "public"."collection_likes" USING "btree" ("collection_id");



CREATE INDEX "idx_collection_recipes" ON "public"."collection_recipes" USING "btree" ("collection_id");



CREATE INDEX "idx_collection_recipes_r" ON "public"."collection_recipes" USING "btree" ("recipe_id");



CREATE INDEX "idx_collections_user" ON "public"."collections" USING "btree" ("user_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_favorites_user" ON "public"."favorites" USING "btree" ("user_id", "recipe_id");



CREATE INDEX "idx_helpful_votes_review" ON "public"."review_helpful_votes" USING "btree" ("review_id");



CREATE INDEX "idx_meal_plan_date_type" ON "public"."meal_plan_recipes" USING "btree" ("plan_date", "meal_type");



CREATE INDEX "idx_meal_plan_recipes_date" ON "public"."meal_plan_recipes" USING "btree" ("plan_date");



CREATE INDEX "idx_meal_plan_recipes_plan" ON "public"."meal_plan_recipes" USING "btree" ("plan_id", "plan_date");



CREATE INDEX "idx_meal_plans_user" ON "public"."meal_plans" USING "btree" ("user_id", "week_start" DESC);



CREATE INDEX "idx_mod_queue_assigned" ON "public"."moderation_queue" USING "btree" ("assigned_to") WHERE ("assigned_to" IS NOT NULL);



CREATE INDEX "idx_mod_queue_status" ON "public"."moderation_queue" USING "btree" ("status", "priority" DESC, "created_at");



CREATE INDEX "idx_mv_catrecipe_cat" ON "public"."category_recipe_view" USING "btree" ("category_id");



CREATE UNIQUE INDEX "idx_mv_chef_profile_id" ON "public"."chef_profile_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_featured_id" ON "public"."featured_recipes_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_home_id" ON "public"."home_dashboard_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_latest_id" ON "public"."latest_recipes_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_leaderboard_id" ON "public"."recipe_leaderboard_view" USING "btree" ("id");



CREATE INDEX "idx_mv_leaderboard_score" ON "public"."recipe_leaderboard_view" USING "btree" ("popularity_score" DESC);



CREATE UNIQUE INDEX "idx_mv_recommended_id" ON "public"."recommended_recipes_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_top_chefs_id" ON "public"."top_chefs_view" USING "btree" ("id");



CREATE UNIQUE INDEX "idx_mv_trending_id" ON "public"."trending_recipes_view" USING "btree" ("id");



CREATE INDEX "idx_notifications_active" ON "public"."notifications" USING "btree" ("user_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_notifications_expires" ON "public"."notifications" USING "btree" ("expires_at") WHERE ("expires_at" IS NOT NULL);



CREATE INDEX "idx_notifications_type_user" ON "public"."notifications" USING "btree" ("user_id", "notification_type", "created_at" DESC);



CREATE INDEX "idx_notifications_unread" ON "public"."notifications" USING "btree" ("user_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_notifications_user_created" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_profile_changes_user" ON "public"."profile_changes" USING "btree" ("user_id", "changed_at" DESC);



CREATE INDEX "idx_recently_viewed_user" ON "public"."recently_viewed" USING "btree" ("user_id", "viewed_at" DESC);



CREATE INDEX "idx_recipe_analytics_saves" ON "public"."recipe_analytics" USING "btree" ("total_saves" DESC);



CREATE INDEX "idx_recipe_analytics_views" ON "public"."recipe_analytics" USING "btree" ("total_views" DESC);



CREATE INDEX "idx_recipe_categories_cat" ON "public"."recipe_categories" USING "btree" ("category_id", "recipe_id");



CREATE INDEX "idx_recipe_categories_recipe" ON "public"."recipe_categories" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_history_id" ON "public"."recipe_history" USING "btree" ("recipe_id", "changed_at" DESC);



CREATE INDEX "idx_recipe_images_compression" ON "public"."recipe_images" USING "btree" ("compression_status") WHERE ("compression_status" <> 'done'::"text");



CREATE INDEX "idx_recipe_images_order" ON "public"."recipe_images" USING "btree" ("recipe_id", "display_order") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipe_images_primary" ON "public"."recipe_images" USING "btree" ("recipe_id") WHERE (("is_primary" = true) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_recipe_images_recipe" ON "public"."recipe_images" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_ingredients_lower" ON "public"."recipe_ingredients" USING "btree" ("lower"("name"));



CREATE INDEX "idx_recipe_ingredients_name" ON "public"."recipe_ingredients" USING "gin" ("name" "public"."gin_trgm_ops");



CREATE INDEX "idx_recipe_ingredients_recipe" ON "public"."recipe_ingredients" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_notes_recipe" ON "public"."recipe_notes" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_notes_user" ON "public"."recipe_notes" USING "btree" ("user_id");



CREATE INDEX "idx_recipe_nutrition_calories" ON "public"."recipe_nutrition" USING "btree" ("calories");



CREATE INDEX "idx_recipe_nutrition_protein" ON "public"."recipe_nutrition" USING "btree" ("protein_g");



CREATE INDEX "idx_recipe_reports_recipe" ON "public"."recipe_reports" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_reports_status" ON "public"."recipe_reports" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "idx_recipe_steps_recipe" ON "public"."recipe_steps" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_tags_recipe" ON "public"."recipe_tags" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipe_tags_tag" ON "public"."recipe_tags" USING "btree" ("tag_id");



CREATE INDEX "idx_recipe_translations_lang" ON "public"."recipe_translations" USING "btree" ("language");



CREATE INDEX "idx_recipe_translations_recipe_lang" ON "public"."recipe_translations" USING "btree" ("recipe_id", "language");



CREATE INDEX "idx_recipe_videos_recipe" ON "public"."recipe_videos" USING "btree" ("recipe_id");



CREATE INDEX "idx_recipes_active" ON "public"."recipes" USING "btree" ("created_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipes_calories" ON "public"."recipes" USING "btree" ("calories_int") WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_chef_created" ON "public"."recipes" USING "btree" ("chef_id", "created_at" DESC);



CREATE INDEX "idx_recipes_cuisine_lower" ON "public"."recipes" USING "btree" ("lower"("cuisine")) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipes_desc_trgm" ON "public"."recipes" USING "gin" ("description" "public"."gin_trgm_ops");



CREATE INDEX "idx_recipes_difficulty" ON "public"."recipes" USING "btree" ("difficulty") WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_featured" ON "public"."recipes" USING "btree" ("is_featured", "created_at" DESC) WHERE (("is_featured" = true) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_recipes_language" ON "public"."recipes" USING "btree" ("language");



CREATE INDEX "idx_recipes_moderation" ON "public"."recipes" USING "btree" ("moderation_status") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipes_moderation_status_pub" ON "public"."recipes" USING "btree" ("moderation_status", "published_at" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_popularity_score" ON "public"."recipes" USING "btree" ("popularity_score" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_published_at" ON "public"."recipes" USING "btree" ("published_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipes_rating" ON "public"."recipes" USING "btree" ("rating" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_recommended" ON "public"."recipes" USING "btree" ("is_recommended", "created_at" DESC) WHERE (("is_recommended" = true) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_recipes_scheduled_pub" ON "public"."recipes" USING "btree" ("scheduled_publish_at") WHERE (("scheduled_publish_at" IS NOT NULL) AND ("status" = 'draft'::"text") AND ("deleted_at" IS NULL));



CREATE INDEX "idx_recipes_search_vector" ON "public"."recipes" USING "gin" ("search_vector");



CREATE INDEX "idx_recipes_seo_keywords" ON "public"."recipes" USING "gin" ("seo_keywords") WHERE ("seo_keywords" IS NOT NULL);



CREATE INDEX "idx_recipes_slug" ON "public"."recipes" USING "btree" ("slug") WHERE ("slug" IS NOT NULL);



CREATE INDEX "idx_recipes_status_created" ON "public"."recipes" USING "btree" ("status", "created_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_recipes_title_trgm" ON "public"."recipes" USING "gin" ("title" "public"."gin_trgm_ops");



CREATE INDEX "idx_recipes_total_time" ON "public"."recipes" USING "btree" ("total_time_minutes") WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_trending" ON "public"."recipes" USING "btree" ("is_trending", "created_at" DESC) WHERE (("is_trending" = true) AND ("deleted_at" IS NULL));



CREATE INDEX "idx_recipes_trending_score" ON "public"."recipes" USING "btree" ("trending_score" DESC) WHERE (("deleted_at" IS NULL) AND ("status" = 'published'::"text"));



CREATE INDEX "idx_recipes_visibility" ON "public"."recipes" USING "btree" ("visibility") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_review_media_review" ON "public"."review_media" USING "btree" ("review_id");



CREATE INDEX "idx_review_media_type" ON "public"."review_media" USING "btree" ("review_id", "media_type");



CREATE INDEX "idx_reviews_active" ON "public"."reviews" USING "btree" ("recipe_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_reviews_parent_id" ON "public"."reviews" USING "btree" ("parent_id");



CREATE INDEX "idx_reviews_recipe_id" ON "public"."reviews" USING "btree" ("recipe_id");



CREATE INDEX "idx_reviews_recipe_rating" ON "public"."reviews" USING "btree" ("recipe_id", "rating" DESC) WHERE ("parent_id" IS NULL);



CREATE INDEX "idx_reviews_user_id" ON "public"."reviews" USING "btree" ("user_id");



CREATE INDEX "idx_rv_recipe" ON "public"."recipe_views" USING "btree" ("recipe_id");



CREATE INDEX "idx_sa_no_results" ON "public"."search_analytics" USING "btree" ("had_results", "created_at" DESC) WHERE ("had_results" = false);



CREATE INDEX "idx_sa_user_created" ON "public"."search_analytics" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_search_history_norm" ON "public"."search_history" USING "btree" ("user_id", "normalised_query");



CREATE INDEX "idx_search_history_user" ON "public"."search_history" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_shopping_history_recipe" ON "public"."shopping_history" USING "btree" ("recipe_id") WHERE ("recipe_id" IS NOT NULL);



CREATE INDEX "idx_shopping_history_user" ON "public"."shopping_history" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_shopping_lists_active" ON "public"."shopping_lists" USING "btree" ("user_id") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_shopping_user" ON "public"."shopping_lists" USING "btree" ("user_id");



CREATE INDEX "idx_synonym_candidates_status" ON "public"."search_synonym_candidates" USING "btree" ("status", "frequency" DESC);



CREATE INDEX "idx_synonyms_term" ON "public"."search_synonyms" USING "btree" ("term");



CREATE INDEX "idx_tags_name_lower" ON "public"."tags" USING "btree" ("lower"("name"));



CREATE INDEX "idx_tags_type_name" ON "public"."tags" USING "btree" ("type", "lower"("name"));



CREATE INDEX "idx_trending_daily" ON "public"."trending_searches" USING "btree" ("daily_count" DESC, "last_searched_at" DESC);



CREATE INDEX "idx_trending_monthly" ON "public"."trending_searches" USING "btree" ("monthly_count" DESC, "last_searched_at" DESC);



CREATE INDEX "idx_trending_query_lower" ON "public"."trending_searches" USING "btree" ("lower"("query"));



CREATE INDEX "idx_trending_query_trgm" ON "public"."trending_searches" USING "gin" ("lower"("query") "public"."gin_trgm_ops");



CREATE INDEX "idx_trending_weekly" ON "public"."trending_searches" USING "btree" ("weekly_count" DESC, "last_searched_at" DESC);



CREATE INDEX "idx_user_achievements_completed" ON "public"."user_achievements" USING "btree" ("user_id", "completed") WHERE ("completed" = true);



CREATE INDEX "idx_user_achievements_user" ON "public"."user_achievements" USING "btree" ("user_id");



CREATE INDEX "idx_user_badges_user" ON "public"."user_badges" USING "btree" ("user_id");



CREATE INDEX "idx_user_devices_fcm" ON "public"."user_devices" USING "btree" ("fcm_token") WHERE ("fcm_token" IS NOT NULL);



CREATE INDEX "idx_user_devices_push" ON "public"."user_devices" USING "btree" ("user_id", "platform") WHERE ("push_enabled" = true);



CREATE INDEX "idx_user_devices_user_id" ON "public"."user_devices" USING "btree" ("user_id");



CREATE INDEX "idx_user_follows_follower" ON "public"."user_follows" USING "btree" ("follower_id");



CREATE INDEX "idx_user_follows_following" ON "public"."user_follows" USING "btree" ("following_id");



CREATE INDEX "idx_user_reports_status" ON "public"."user_reports" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "idx_user_roles_role" ON "public"."user_roles" USING "btree" ("role");



CREATE INDEX "idx_user_roles_user_id" ON "public"."user_roles" USING "btree" ("user_id");



CREATE INDEX "idx_users_active" ON "public"."users" USING "btree" ("created_at" DESC) WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_users_country" ON "public"."users" USING "btree" ("country") WHERE ("country" IS NOT NULL);



CREATE INDEX "idx_users_last_seen" ON "public"."users" USING "btree" ("last_seen" DESC);



CREATE INDEX "idx_users_updated_at" ON "public"."users" USING "btree" ("updated_at" DESC);



CREATE INDEX "idx_users_username" ON "public"."users" USING "btree" ("username") WHERE ("username" IS NOT NULL);



CREATE INDEX "idx_users_username_trgm" ON "public"."users" USING "gin" ("username" "public"."gin_trgm_ops") WHERE ("username" IS NOT NULL);



CREATE UNIQUE INDEX "bname" ON "storage"."buckets" USING "btree" ("name");



CREATE UNIQUE INDEX "bucketid_objname" ON "storage"."objects" USING "btree" ("bucket_id", "name");



CREATE UNIQUE INDEX "buckets_analytics_unique_name_idx" ON "storage"."buckets_analytics" USING "btree" ("name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_multipart_uploads_list" ON "storage"."s3_multipart_uploads" USING "btree" ("bucket_id", "key", "created_at");



CREATE INDEX "idx_objects_bucket_id_name" ON "storage"."objects" USING "btree" ("bucket_id", "name" COLLATE "C");



CREATE INDEX "idx_objects_bucket_id_name_lower" ON "storage"."objects" USING "btree" ("bucket_id", "lower"("name") COLLATE "C");



CREATE INDEX "name_prefix_search" ON "storage"."objects" USING "btree" ("name" "text_pattern_ops");



CREATE UNIQUE INDEX "vector_indexes_name_bucket_id_idx" ON "storage"."vector_indexes" USING "btree" ("name", "bucket_id");



CREATE OR REPLACE TRIGGER "on_auth_user_created" AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_user"();



CREATE OR REPLACE TRIGGER "on_chef_follow_change" AFTER INSERT OR DELETE ON "public"."chef_followers" FOR EACH ROW EXECUTE FUNCTION "public"."sync_chef_followers"();



CREATE OR REPLACE TRIGGER "on_collection_recipe_change" AFTER INSERT OR DELETE ON "public"."collection_recipes" FOR EACH ROW EXECUTE FUNCTION "public"."sync_collection_count"();



CREATE OR REPLACE TRIGGER "on_favorite_change" AFTER INSERT OR DELETE ON "public"."favorites" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_saved_count"();



CREATE OR REPLACE TRIGGER "on_recipe_chef_change" AFTER INSERT OR DELETE OR UPDATE OF "chef_id" ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."sync_chef_stats"();



CREATE OR REPLACE TRIGGER "on_review_change" AFTER INSERT OR DELETE OR UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."sync_recipe_stats"();



CREATE OR REPLACE TRIGGER "trg_auto_slug" BEFORE INSERT OR UPDATE OF "title" ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."auto_assign_slug"();



CREATE OR REPLACE TRIGGER "trg_category_search_cascade" AFTER INSERT OR DELETE OR UPDATE ON "public"."recipe_categories" FOR EACH ROW EXECUTE FUNCTION "public"."cascade_search_on_category_change"();



CREATE OR REPLACE TRIGGER "trg_collection_likes" AFTER INSERT OR DELETE ON "public"."collection_likes" FOR EACH ROW EXECUTE FUNCTION "public"."sync_collection_likes"();



CREATE OR REPLACE TRIGGER "trg_ingredient_search_cascade" AFTER INSERT OR DELETE OR UPDATE ON "public"."recipe_ingredients" FOR EACH ROW EXECUTE FUNCTION "public"."cascade_search_on_ingredient_change"();



CREATE OR REPLACE TRIGGER "trg_init_recipe_analytics" AFTER INSERT ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."init_recipe_analytics"();



CREATE OR REPLACE TRIGGER "trg_profile_audit" AFTER UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."log_profile_change"();



CREATE OR REPLACE TRIGGER "trg_recipe_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."log_recipe_change"();



CREATE OR REPLACE TRIGGER "trg_review_helpful" AFTER INSERT OR DELETE ON "public"."review_helpful_votes" FOR EACH ROW EXECUTE FUNCTION "public"."sync_review_helpful_count"();



CREATE OR REPLACE TRIGGER "trg_set_published_at" BEFORE UPDATE ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."set_published_at"();



CREATE OR REPLACE TRIGGER "trg_sync_recipe_view" AFTER INSERT ON "public"."recipe_views" FOR EACH ROW EXECUTE FUNCTION "public"."sync_recipe_view_count"();



CREATE OR REPLACE TRIGGER "trg_tag_search_cascade" AFTER INSERT OR DELETE OR UPDATE ON "public"."recipe_tags" FOR EACH ROW EXECUTE FUNCTION "public"."cascade_search_on_tag_change"();



CREATE OR REPLACE TRIGGER "trg_user_follow_counts" AFTER INSERT OR DELETE ON "public"."user_follows" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_follow_counts"();



CREATE OR REPLACE TRIGGER "trigger_update_recipe_search_vector" BEFORE INSERT OR UPDATE ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."update_recipe_search_vector"();



CREATE OR REPLACE TRIGGER "upd_meal_plans_modtime" BEFORE UPDATE ON "public"."meal_plans" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "upd_recipe_translations_modtime" BEFORE UPDATE ON "public"."recipe_translations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "upd_user_achievements_modtime" BEFORE UPDATE ON "public"."user_achievements" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "upd_user_devices_modtime" BEFORE UPDATE ON "public"."user_devices" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_banners_modtime" BEFORE UPDATE ON "public"."banners" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_categories_modtime" BEFORE UPDATE ON "public"."categories" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_chefs_modtime" BEFORE UPDATE ON "public"."chefs" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_collections_modtime" BEFORE UPDATE ON "public"."collections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_recipe_notes_modtime" BEFORE UPDATE ON "public"."recipe_notes" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_recipes_modtime" BEFORE UPDATE ON "public"."recipes" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_reviews_modtime" BEFORE UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_shopping_lists_modtime" BEFORE UPDATE ON "public"."shopping_lists" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_preferences_modtime" BEFORE UPDATE ON "public"."user_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_users_modtime" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "enforce_bucket_name_length_trigger" BEFORE INSERT OR UPDATE OF "name" ON "storage"."buckets" FOR EACH ROW EXECUTE FUNCTION "storage"."enforce_bucket_name_length"();



CREATE OR REPLACE TRIGGER "protect_buckets_delete" BEFORE DELETE ON "storage"."buckets" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "protect_objects_delete" BEFORE DELETE ON "storage"."objects" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "update_objects_updated_at" BEFORE UPDATE ON "storage"."objects" FOR EACH ROW EXECUTE FUNCTION "storage"."update_updated_at_column"();



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_auth_factor_id_fkey" FOREIGN KEY ("factor_id") REFERENCES "auth"."mfa_factors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_flow_state_id_fkey" FOREIGN KEY ("flow_state_id") REFERENCES "auth"."flow_state"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_oauth_client_id_fkey" FOREIGN KEY ("oauth_client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_actions"
    ADD CONSTRAINT "admin_actions_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."admin_logs"
    ADD CONSTRAINT "admin_logs_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."admin_settings"
    ADD CONSTRAINT "admin_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."category_views"
    ADD CONSTRAINT "category_views_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."category_views"
    ADD CONSTRAINT "category_views_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."chef_followers"
    ADD CONSTRAINT "chef_followers_chef_id_fkey" FOREIGN KEY ("chef_id") REFERENCES "public"."chefs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."chef_followers"
    ADD CONSTRAINT "chef_followers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_followers"
    ADD CONSTRAINT "collection_followers_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_followers"
    ADD CONSTRAINT "collection_followers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_likes"
    ADD CONSTRAINT "collection_likes_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_likes"
    ADD CONSTRAINT "collection_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_recipes"
    ADD CONSTRAINT "collection_recipes_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "public"."collections"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collection_recipes"
    ADD CONSTRAINT "collection_recipes_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."meal_plan_recipes"
    ADD CONSTRAINT "meal_plan_recipes_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."meal_plans"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."meal_plan_recipes"
    ADD CONSTRAINT "meal_plan_recipes_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."meal_plans"
    ADD CONSTRAINT "meal_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."moderation_queue"
    ADD CONSTRAINT "moderation_queue_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."moderation_queue"
    ADD CONSTRAINT "moderation_queue_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recently_viewed"
    ADD CONSTRAINT "recently_viewed_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recently_viewed"
    ADD CONSTRAINT "recently_viewed_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_ai_tags"
    ADD CONSTRAINT "recipe_ai_tags_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_analytics"
    ADD CONSTRAINT "recipe_analytics_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_categories"
    ADD CONSTRAINT "recipe_categories_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."categories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_categories"
    ADD CONSTRAINT "recipe_categories_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_history"
    ADD CONSTRAINT "recipe_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."recipe_images"
    ADD CONSTRAINT "recipe_images_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_images"
    ADD CONSTRAINT "recipe_images_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."recipe_ingredients"
    ADD CONSTRAINT "recipe_ingredients_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_notes"
    ADD CONSTRAINT "recipe_notes_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_notes"
    ADD CONSTRAINT "recipe_notes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_nutrition"
    ADD CONSTRAINT "recipe_nutrition_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_reports"
    ADD CONSTRAINT "recipe_reports_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_reports"
    ADD CONSTRAINT "recipe_reports_reported_by_fkey" FOREIGN KEY ("reported_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_reports"
    ADD CONSTRAINT "recipe_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."recipe_steps"
    ADD CONSTRAINT "recipe_steps_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_tags"
    ADD CONSTRAINT "recipe_tags_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_tags"
    ADD CONSTRAINT "recipe_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_translations"
    ADD CONSTRAINT "recipe_translations_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_videos"
    ADD CONSTRAINT "recipe_videos_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_views"
    ADD CONSTRAINT "recipe_views_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."recipe_views"
    ADD CONSTRAINT "recipe_views_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."recipes"
    ADD CONSTRAINT "recipes_chef_id_fkey" FOREIGN KEY ("chef_id") REFERENCES "public"."chefs"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."review_helpful_votes"
    ADD CONSTRAINT "review_helpful_votes_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "public"."reviews"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."review_helpful_votes"
    ADD CONSTRAINT "review_helpful_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."review_media"
    ADD CONSTRAINT "review_media_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "public"."reviews"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."reviews"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."search_analytics"
    ADD CONSTRAINT "search_analytics_clicked_recipe_id_fkey" FOREIGN KEY ("clicked_recipe_id") REFERENCES "public"."recipes"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."search_analytics"
    ADD CONSTRAINT "search_analytics_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."search_history"
    ADD CONSTRAINT "search_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_history"
    ADD CONSTRAINT "shopping_history_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."shopping_history"
    ADD CONSTRAINT "shopping_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shopping_lists"
    ADD CONSTRAINT "shopping_lists_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_achievements"
    ADD CONSTRAINT "user_achievements_achievement_id_fkey" FOREIGN KEY ("achievement_id") REFERENCES "public"."achievements"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_achievements"
    ADD CONSTRAINT "user_achievements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_activity"
    ADD CONSTRAINT "user_activity_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_follows"
    ADD CONSTRAINT "user_follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_follows"
    ADD CONSTRAINT "user_follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_by_fkey" FOREIGN KEY ("reported_by") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_user_fkey" FOREIGN KEY ("reported_user") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_granted_by_fkey" FOREIGN KEY ("granted_by") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_upload_id_fkey" FOREIGN KEY ("upload_id") REFERENCES "storage"."s3_multipart_uploads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets_vectors"("id");



ALTER TABLE "auth"."audit_log_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."flow_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."identities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."instances" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_amr_claims" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_factors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."one_time_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."refresh_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_relay_states" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."schema_migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_domains" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."achievements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_actions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_admin_actions" ON "public"."admin_actions" FOR SELECT USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_categories" ON "public"."categories" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text")));



CREATE POLICY "admin_chefs" ON "public"."chefs" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text")));



ALTER TABLE "public"."admin_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_manage_recipe_report" ON "public"."recipe_reports" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



CREATE POLICY "admin_manage_synonym_candidates" ON "public"."search_synonym_candidates" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_manage_user_report" ON "public"."user_reports" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



CREATE POLICY "admin_profile_changes" ON "public"."profile_changes" FOR SELECT USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_read_logs" ON "public"."admin_logs" FOR SELECT USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_read_write_admin_settings" ON "public"."admin_settings" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_recipe_history" ON "public"."recipe_history" FOR SELECT USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



CREATE POLICY "admin_recipes" ON "public"."recipes" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



CREATE POLICY "admin_reviews" ON "public"."reviews" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



CREATE POLICY "admin_roles" ON "public"."user_roles" USING ("public"."has_role"('admin'::"text"));



ALTER TABLE "public"."admin_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_write_achievements" ON "public"."achievements" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_achievements_u" ON "public"."user_achievements" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_ai_tags" ON "public"."recipe_ai_tags" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text")));



CREATE POLICY "admin_write_app_settings" ON "public"."app_settings" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_badges" ON "public"."badges" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_flags" ON "public"."feature_flags" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_nutrition" ON "public"."recipe_nutrition" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text")));



CREATE POLICY "admin_write_recipe_analytics" ON "public"."recipe_analytics" USING ("public"."has_role"('admin'::"text"));



CREATE POLICY "admin_write_translations" ON "public"."recipe_translations" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text")));



CREATE POLICY "admin_write_user_badges" ON "public"."user_badges" USING ("public"."has_role"('admin'::"text"));



ALTER TABLE "public"."app_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."banners" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."category_views" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chef_followers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."chefs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."collection_followers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."collection_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."collection_recipes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."collections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."favorites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feature_flags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."meal_plan_recipes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."meal_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."moderation_queue" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "moderator_manage_queue" ON "public"."moderation_queue" USING (("public"."has_role"('admin'::"text") OR "public"."has_role"('moderator'::"text")));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "own_collection_follows" ON "public"."collection_followers" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_collection_likes" ON "public"."collection_likes" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_collection_recipes" ON "public"."collection_recipes" USING ((EXISTS ( SELECT 1
   FROM "public"."collections"
  WHERE (("collections"."id" = "collection_recipes"."collection_id") AND ("collections"."user_id" = "auth"."uid"())))));



CREATE POLICY "own_collections" ON "public"."collections" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_delete_review" ON "public"."reviews" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_devices" ON "public"."user_devices" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_edit_review" ON "public"."reviews" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_followers" ON "public"."chef_followers" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_helpful_vote" ON "public"."review_helpful_votes" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_manage_user_follows" ON "public"."user_follows" USING (("auth"."uid"() = "follower_id"));



CREATE POLICY "own_meal_plan_recipes" ON "public"."meal_plan_recipes" USING ((EXISTS ( SELECT 1
   FROM "public"."meal_plans"
  WHERE (("meal_plans"."id" = "meal_plan_recipes"."plan_id") AND ("meal_plans"."user_id" = "auth"."uid"())))));



CREATE POLICY "own_meal_plans" ON "public"."meal_plans" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_modify_favorites" ON "public"."favorites" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_notifications" ON "public"."notifications" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_read_achievements" ON "public"."user_achievements" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_read_recipe_report" ON "public"."recipe_reports" FOR SELECT USING (("auth"."uid"() = "reported_by"));



CREATE POLICY "own_read_user" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "own_recently_viewed" ON "public"."recently_viewed" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_recipe_notes" ON "public"."recipe_notes" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_search_history" ON "public"."search_history" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_select_favorites" ON "public"."favorites" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_select_prefs" ON "public"."user_preferences" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_shopping" ON "public"."shopping_lists" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_shopping_history" ON "public"."shopping_history" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_submit_recipe_report" ON "public"."recipe_reports" FOR INSERT WITH CHECK (("auth"."uid"() = "reported_by"));



CREATE POLICY "own_submit_user_report" ON "public"."user_reports" FOR INSERT WITH CHECK (("auth"."uid"() = "reported_by"));



CREATE POLICY "own_update_prefs" ON "public"."user_preferences" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_update_user" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "own_write_review" ON "public"."reviews" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "own_write_review_media" ON "public"."review_media" USING ((EXISTS ( SELECT 1
   FROM "public"."reviews" "r"
  WHERE (("r"."id" = "review_media"."review_id") AND ("r"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."profile_changes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pub_read_achievements" ON "public"."achievements" FOR SELECT USING (true);



CREATE POLICY "pub_read_ai_tags" ON "public"."recipe_ai_tags" FOR SELECT USING (true);



CREATE POLICY "pub_read_app_settings" ON "public"."app_settings" FOR SELECT USING (true);



CREATE POLICY "pub_read_badges" ON "public"."badges" FOR SELECT USING (true);



CREATE POLICY "pub_read_banners" ON "public"."banners" FOR SELECT USING (true);



CREATE POLICY "pub_read_categories" ON "public"."categories" FOR SELECT USING (("deleted_at" IS NULL));



CREATE POLICY "pub_read_chefs" ON "public"."chefs" FOR SELECT USING (("deleted_at" IS NULL));



CREATE POLICY "pub_read_flags" ON "public"."feature_flags" FOR SELECT USING (true);



CREATE POLICY "pub_read_followers" ON "public"."chef_followers" FOR SELECT USING (true);



CREATE POLICY "pub_read_ingredients" ON "public"."recipe_ingredients" FOR SELECT USING (true);



CREATE POLICY "pub_read_nutrition" ON "public"."recipe_nutrition" FOR SELECT USING (true);



CREATE POLICY "pub_read_recipe_analytics" ON "public"."recipe_analytics" FOR SELECT USING (true);



CREATE POLICY "pub_read_recipe_cats" ON "public"."recipe_categories" FOR SELECT USING (true);



CREATE POLICY "pub_read_recipe_images" ON "public"."recipe_images" FOR SELECT USING (("deleted_at" IS NULL));



CREATE POLICY "pub_read_recipe_tags" ON "public"."recipe_tags" FOR SELECT USING (true);



CREATE POLICY "pub_read_recipe_videos" ON "public"."recipe_videos" FOR SELECT USING (("deleted_at" IS NULL));



CREATE POLICY "pub_read_recipes" ON "public"."recipes" FOR SELECT USING ((("deleted_at" IS NULL) AND ("status" = 'published'::"text")));



CREATE POLICY "pub_read_review_media" ON "public"."review_media" FOR SELECT USING (true);



CREATE POLICY "pub_read_reviews" ON "public"."reviews" FOR SELECT USING (true);



CREATE POLICY "pub_read_steps" ON "public"."recipe_steps" FOR SELECT USING (true);



CREATE POLICY "pub_read_synonyms" ON "public"."search_synonyms" FOR SELECT USING (true);



CREATE POLICY "pub_read_tags" ON "public"."tags" FOR SELECT USING (true);



CREATE POLICY "pub_read_translations" ON "public"."recipe_translations" FOR SELECT USING (true);



CREATE POLICY "pub_read_user_badges" ON "public"."user_badges" FOR SELECT USING (true);



CREATE POLICY "pub_read_user_follows" ON "public"."user_follows" FOR SELECT USING (true);



CREATE POLICY "pub_read_users" ON "public"."users" FOR SELECT USING (("deleted_at" IS NULL));



ALTER TABLE "public"."recently_viewed" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_ai_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_analytics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_images" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_ingredients" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_nutrition" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_steps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_translations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_videos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipe_views" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."recipes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."review_helpful_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."review_media" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."schema_versions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_analytics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_synonym_candidates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."search_synonyms" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shopping_lists" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."trending_searches" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_achievements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_activity" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_devices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_follows" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_delete_objects" ON "storage"."objects" FOR DELETE USING ((("auth"."role"() = 'authenticated'::"text") AND "public"."has_role"('admin'::"text")));



CREATE POLICY "admin_upload_banners" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'banner-images'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND "public"."has_role"('admin'::"text")));



CREATE POLICY "admin_upload_cat_imgs" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'category-images'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND ("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text"))));



CREATE POLICY "admin_upload_chef_avs" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'chef-avatars'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND "public"."has_role"('admin'::"text")));



CREATE POLICY "admin_upload_recipe_imgs" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'recipe-images'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND ("public"."has_role"('admin'::"text") OR "public"."has_role"('editor'::"text"))));



ALTER TABLE "storage"."buckets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_analytics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_vectors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."objects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "own_access_exports" ON "storage"."objects" USING ((("bucket_id" = 'recipe-exports'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "own_upload_review_media" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'review-media'::"text") AND ("auth"."role"() = 'authenticated'::"text")));



CREATE POLICY "own_upload_temp" ON "storage"."objects" WITH CHECK ((("bucket_id" = 'temp-uploads'::"text") AND ("auth"."role"() = 'authenticated'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "own_upload_user_avatar" ON "storage"."objects" USING ((("bucket_id" = 'user-avatars'::"text") AND ("auth"."role"() = 'authenticated'::"text")));



CREATE POLICY "own_upload_user_cover" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'user-covers'::"text") AND ("auth"."role"() = 'authenticated'::"text")));



CREATE POLICY "pub_read_badge_icons" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'badge-icons'::"text"));



CREATE POLICY "pub_read_banner_img_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'banner-images'::"text"));



CREATE POLICY "pub_read_cat_img_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'category-images'::"text"));



CREATE POLICY "pub_read_chef_avatar_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'chef-avatars'::"text"));



CREATE POLICY "pub_read_recipe_img_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'recipe-images'::"text"));



CREATE POLICY "pub_read_recipe_vid_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'recipe-videos'::"text"));



CREATE POLICY "pub_read_review_media" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'review-media'::"text"));



CREATE POLICY "pub_read_user_avatar_obj" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'user-avatars'::"text"));



CREATE POLICY "pub_read_user_covers" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'user-covers'::"text"));



ALTER TABLE "storage"."s3_multipart_uploads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."s3_multipart_uploads_parts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."vector_indexes" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "auth" TO "anon";
GRANT USAGE ON SCHEMA "auth" TO "authenticated";
GRANT USAGE ON SCHEMA "auth" TO "service_role";
GRANT ALL ON SCHEMA "auth" TO "supabase_auth_admin";
GRANT ALL ON SCHEMA "auth" TO "dashboard_user";
GRANT USAGE ON SCHEMA "auth" TO "postgres";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT USAGE ON SCHEMA "storage" TO "postgres" WITH GRANT OPTION;
GRANT USAGE ON SCHEMA "storage" TO "anon";
GRANT USAGE ON SCHEMA "storage" TO "authenticated";
GRANT USAGE ON SCHEMA "storage" TO "service_role";
GRANT ALL ON SCHEMA "storage" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON SCHEMA "storage" TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."email"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."jwt"() TO "postgres";
GRANT ALL ON FUNCTION "auth"."jwt"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."role"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."uid"() TO "dashboard_user";



GRANT ALL ON FUNCTION "public"."auto_assign_slug"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_assign_slug"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_assign_slug"() TO "service_role";



GRANT ALL ON FUNCTION "public"."autocomplete_ingredients"("p_query" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."autocomplete_ingredients"("p_query" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."autocomplete_ingredients"("p_query" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."capture_zero_result_searches"() TO "anon";
GRANT ALL ON FUNCTION "public"."capture_zero_result_searches"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."capture_zero_result_searches"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cascade_search_on_category_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."cascade_search_on_category_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cascade_search_on_category_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cascade_search_on_ingredient_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."cascade_search_on_ingredient_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cascade_search_on_ingredient_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cascade_search_on_tag_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."cascade_search_on_tag_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cascade_search_on_tag_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."clear_search_history"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."clear_search_history"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."clear_search_history"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_search_history_item"("p_user_id" "uuid", "p_history_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_search_history_item"("p_user_id" "uuid", "p_history_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_search_history_item"("p_user_id" "uuid", "p_history_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."expand_synonyms"("p_term" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."expand_synonyms"("p_term" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."expand_synonyms"("p_term" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_recent_searches"("p_user_id" "uuid", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_recent_searches"("p_user_id" "uuid", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_recent_searches"("p_user_id" "uuid", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_recipe_by_slug"("p_slug" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_trending_searches"("p_window" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_trending_searches"("p_window" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_trending_searches"("p_window" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_zero_result_searches"("p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_zero_result_searches"("p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_zero_result_searches"("p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_role"("p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_role"("p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_role"("p_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."init_recipe_analytics"() TO "anon";
GRANT ALL ON FUNCTION "public"."init_recipe_analytics"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."init_recipe_analytics"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_profile_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_profile_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_profile_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_recipe_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_recipe_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_recipe_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_search_event"("p_user_id" "uuid", "p_query" "text", "p_results_count" integer, "p_had_results" boolean, "p_search_duration_ms" integer, "p_clicked_recipe_id" "uuid", "p_sort_by" "text", "p_filters_applied" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_search_event"("p_user_id" "uuid", "p_query" "text", "p_results_count" integer, "p_had_results" boolean, "p_search_duration_ms" integer, "p_clicked_recipe_id" "uuid", "p_sort_by" "text", "p_filters_applied" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_search_event"("p_user_id" "uuid", "p_query" "text", "p_results_count" integer, "p_had_results" boolean, "p_search_duration_ms" integer, "p_clicked_recipe_id" "uuid", "p_sort_by" "text", "p_filters_applied" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."recompute_recipe_scores"("p_recipe_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_all_materialized_views"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_all_materialized_views"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_all_materialized_views"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_recipe_search_vector"("p_recipe_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_recipe_search_vector"("p_recipe_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_recipe_search_vector"("p_recipe_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."reset_daily_trending_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."reset_daily_trending_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reset_daily_trending_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."reset_monthly_trending_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."reset_monthly_trending_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reset_monthly_trending_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."reset_weekly_trending_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."reset_weekly_trending_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."reset_weekly_trending_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."search_categories"("p_query" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_categories"("p_query" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_categories"("p_query" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_chefs"("p_query" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_chefs"("p_query" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_chefs"("p_query" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_ingredients"("p_ingredients" "text", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_ingredients"("p_ingredients" "text", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_ingredients"("p_ingredients" "text", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_recipes"("p_query" "text", "p_category_id" "uuid", "p_cuisine" "text", "p_difficulty" "text", "p_max_time_min" integer, "p_max_calories" integer, "p_min_rating" numeric, "p_meal_type" "text", "p_dietary" "text"[], "p_sort_by" "text", "p_limit" integer, "p_offset" integer, "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."search_recipes"("p_query" "text", "p_category_id" "uuid", "p_cuisine" "text", "p_difficulty" "text", "p_max_time_min" integer, "p_max_calories" integer, "p_min_rating" numeric, "p_meal_type" "text", "p_dietary" "text"[], "p_sort_by" "text", "p_limit" integer, "p_offset" integer, "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_recipes"("p_query" "text", "p_category_id" "uuid", "p_cuisine" "text", "p_difficulty" "text", "p_max_time_min" integer, "p_max_calories" integer, "p_min_rating" numeric, "p_meal_type" "text", "p_dietary" "text"[], "p_sort_by" "text", "p_limit" integer, "p_offset" integer, "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_recipes_phonetic"("p_query" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."search_suggestions"("p_query" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_suggestions"("p_query" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_suggestions"("p_query" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_published_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_published_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_published_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."slugify"("p_title" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."slugify"("p_title" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."slugify"("p_title" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_chef_followers"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_chef_followers"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_chef_followers"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_chef_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_chef_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_chef_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_collection_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_collection_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_collection_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_collection_likes"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_collection_likes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_collection_likes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_recipe_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_recipe_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_recipe_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_recipe_view_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_recipe_view_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_recipe_view_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_review_helpful_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_review_helpful_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_review_helpful_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_follow_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_follow_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_follow_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_saved_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_saved_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_saved_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_recipe_search_vector"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_recipe_search_vector"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_recipe_search_vector"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_search_history"("p_user_id" "uuid", "p_query" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_search_history"("p_user_id" "uuid", "p_query" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_search_history"("p_user_id" "uuid", "p_query" "text") TO "service_role";



GRANT ALL ON TABLE "auth"."audit_log_entries" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."audit_log_entries" TO "postgres";
GRANT SELECT ON TABLE "auth"."audit_log_entries" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "postgres";
GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."flow_state" TO "postgres";
GRANT SELECT ON TABLE "auth"."flow_state" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."flow_state" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."identities" TO "postgres";
GRANT SELECT ON TABLE "auth"."identities" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."identities" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."instances" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."instances" TO "postgres";
GRANT SELECT ON TABLE "auth"."instances" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_amr_claims" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_amr_claims" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_amr_claims" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_challenges" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_challenges" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_challenges" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_factors" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_factors" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_factors" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_client_states" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_client_states" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_clients" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_clients" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_consents" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_consents" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."one_time_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."one_time_tokens" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."one_time_tokens" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."refresh_tokens" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."refresh_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."refresh_tokens" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "dashboard_user";
GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "postgres";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_relay_states" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_relay_states" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_relay_states" TO "dashboard_user";



GRANT SELECT ON TABLE "auth"."schema_migrations" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sessions" TO "postgres";
GRANT SELECT ON TABLE "auth"."sessions" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sessions" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_domains" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_domains" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_domains" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_providers" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."users" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."users" TO "postgres";
GRANT SELECT ON TABLE "auth"."users" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "dashboard_user";



GRANT ALL ON TABLE "public"."achievements" TO "anon";
GRANT ALL ON TABLE "public"."achievements" TO "authenticated";
GRANT ALL ON TABLE "public"."achievements" TO "service_role";



GRANT ALL ON TABLE "public"."admin_actions" TO "anon";
GRANT ALL ON TABLE "public"."admin_actions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_actions" TO "service_role";



GRANT ALL ON TABLE "public"."admin_logs" TO "anon";
GRANT ALL ON TABLE "public"."admin_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_logs" TO "service_role";



GRANT ALL ON TABLE "public"."admin_settings" TO "anon";
GRANT ALL ON TABLE "public"."admin_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_settings" TO "service_role";



GRANT ALL ON TABLE "public"."app_settings" TO "anon";
GRANT ALL ON TABLE "public"."app_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."app_settings" TO "service_role";



GRANT ALL ON TABLE "public"."badges" TO "anon";
GRANT ALL ON TABLE "public"."badges" TO "authenticated";
GRANT ALL ON TABLE "public"."badges" TO "service_role";



GRANT ALL ON TABLE "public"."banners" TO "anon";
GRANT ALL ON TABLE "public"."banners" TO "authenticated";
GRANT ALL ON TABLE "public"."banners" TO "service_role";



GRANT ALL ON TABLE "public"."categories" TO "anon";
GRANT ALL ON TABLE "public"."categories" TO "authenticated";
GRANT ALL ON TABLE "public"."categories" TO "service_role";



GRANT ALL ON TABLE "public"."chefs" TO "anon";
GRANT ALL ON TABLE "public"."chefs" TO "authenticated";
GRANT ALL ON TABLE "public"."chefs" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_categories" TO "anon";
GRANT ALL ON TABLE "public"."recipe_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_categories" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_images" TO "anon";
GRANT ALL ON TABLE "public"."recipe_images" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_images" TO "service_role";



GRANT ALL ON TABLE "public"."recipes" TO "anon";
GRANT ALL ON TABLE "public"."recipes" TO "authenticated";
GRANT ALL ON TABLE "public"."recipes" TO "service_role";



GRANT ALL ON TABLE "public"."category_recipe_view" TO "anon";
GRANT ALL ON TABLE "public"."category_recipe_view" TO "authenticated";
GRANT ALL ON TABLE "public"."category_recipe_view" TO "service_role";



GRANT ALL ON TABLE "public"."category_views" TO "anon";
GRANT ALL ON TABLE "public"."category_views" TO "authenticated";
GRANT ALL ON TABLE "public"."category_views" TO "service_role";



GRANT ALL ON TABLE "public"."chef_followers" TO "anon";
GRANT ALL ON TABLE "public"."chef_followers" TO "authenticated";
GRANT ALL ON TABLE "public"."chef_followers" TO "service_role";



GRANT ALL ON TABLE "public"."collection_followers" TO "anon";
GRANT ALL ON TABLE "public"."collection_followers" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_followers" TO "service_role";



GRANT ALL ON TABLE "public"."collection_likes" TO "anon";
GRANT ALL ON TABLE "public"."collection_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_likes" TO "service_role";



GRANT ALL ON TABLE "public"."collection_recipes" TO "anon";
GRANT ALL ON TABLE "public"."collection_recipes" TO "authenticated";
GRANT ALL ON TABLE "public"."collection_recipes" TO "service_role";



GRANT ALL ON TABLE "public"."collections" TO "anon";
GRANT ALL ON TABLE "public"."collections" TO "authenticated";
GRANT ALL ON TABLE "public"."collections" TO "service_role";



GRANT ALL ON TABLE "public"."favorites" TO "anon";
GRANT ALL ON TABLE "public"."favorites" TO "authenticated";
GRANT ALL ON TABLE "public"."favorites" TO "service_role";



GRANT ALL ON TABLE "public"."feature_flags" TO "anon";
GRANT ALL ON TABLE "public"."feature_flags" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_flags" TO "service_role";



GRANT ALL ON TABLE "public"."featured_recipes_view" TO "anon";
GRANT ALL ON TABLE "public"."featured_recipes_view" TO "authenticated";
GRANT ALL ON TABLE "public"."featured_recipes_view" TO "service_role";



GRANT ALL ON TABLE "public"."home_dashboard_view" TO "anon";
GRANT ALL ON TABLE "public"."home_dashboard_view" TO "authenticated";
GRANT ALL ON TABLE "public"."home_dashboard_view" TO "service_role";



GRANT ALL ON TABLE "public"."latest_recipes_view" TO "anon";
GRANT ALL ON TABLE "public"."latest_recipes_view" TO "authenticated";
GRANT ALL ON TABLE "public"."latest_recipes_view" TO "service_role";



GRANT ALL ON TABLE "public"."meal_plan_recipes" TO "anon";
GRANT ALL ON TABLE "public"."meal_plan_recipes" TO "authenticated";
GRANT ALL ON TABLE "public"."meal_plan_recipes" TO "service_role";



GRANT ALL ON TABLE "public"."meal_plans" TO "anon";
GRANT ALL ON TABLE "public"."meal_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."meal_plans" TO "service_role";



GRANT ALL ON TABLE "public"."moderation_queue" TO "anon";
GRANT ALL ON TABLE "public"."moderation_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."moderation_queue" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."profile_changes" TO "anon";
GRANT ALL ON TABLE "public"."profile_changes" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_changes" TO "service_role";



GRANT ALL ON TABLE "public"."recently_viewed" TO "anon";
GRANT ALL ON TABLE "public"."recently_viewed" TO "authenticated";
GRANT ALL ON TABLE "public"."recently_viewed" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_ai_tags" TO "anon";
GRANT ALL ON TABLE "public"."recipe_ai_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_ai_tags" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_analytics" TO "anon";
GRANT ALL ON TABLE "public"."recipe_analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_analytics" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_ingredients" TO "anon";
GRANT ALL ON TABLE "public"."recipe_ingredients" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_ingredients" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_steps" TO "anon";
GRANT ALL ON TABLE "public"."recipe_steps" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_steps" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_videos" TO "anon";
GRANT ALL ON TABLE "public"."recipe_videos" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_videos" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_details_view" TO "anon";
GRANT ALL ON TABLE "public"."recipe_details_view" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_details_view" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_history" TO "anon";
GRANT ALL ON TABLE "public"."recipe_history" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_history" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_leaderboard_view" TO "anon";
GRANT ALL ON TABLE "public"."recipe_leaderboard_view" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_leaderboard_view" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_notes" TO "anon";
GRANT ALL ON TABLE "public"."recipe_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_notes" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_nutrition" TO "anon";
GRANT ALL ON TABLE "public"."recipe_nutrition" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_nutrition" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_reports" TO "anon";
GRANT ALL ON TABLE "public"."recipe_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_reports" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_tags" TO "anon";
GRANT ALL ON TABLE "public"."recipe_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_tags" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_translations" TO "anon";
GRANT ALL ON TABLE "public"."recipe_translations" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_translations" TO "service_role";



GRANT ALL ON TABLE "public"."recipe_views" TO "anon";
GRANT ALL ON TABLE "public"."recipe_views" TO "authenticated";
GRANT ALL ON TABLE "public"."recipe_views" TO "service_role";



GRANT ALL ON TABLE "public"."recommended_recipes_view" TO "anon";
GRANT ALL ON TABLE "public"."recommended_recipes_view" TO "authenticated";
GRANT ALL ON TABLE "public"."recommended_recipes_view" TO "service_role";



GRANT ALL ON TABLE "public"."review_helpful_votes" TO "anon";
GRANT ALL ON TABLE "public"."review_helpful_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."review_helpful_votes" TO "service_role";



GRANT ALL ON TABLE "public"."review_media" TO "anon";
GRANT ALL ON TABLE "public"."review_media" TO "authenticated";
GRANT ALL ON TABLE "public"."review_media" TO "service_role";



GRANT ALL ON TABLE "public"."reviews" TO "anon";
GRANT ALL ON TABLE "public"."reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."reviews" TO "service_role";



GRANT ALL ON TABLE "public"."schema_versions" TO "anon";
GRANT ALL ON TABLE "public"."schema_versions" TO "authenticated";
GRANT ALL ON TABLE "public"."schema_versions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."schema_versions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."schema_versions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."schema_versions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."search_analytics" TO "anon";
GRANT ALL ON TABLE "public"."search_analytics" TO "authenticated";
GRANT ALL ON TABLE "public"."search_analytics" TO "service_role";



GRANT ALL ON TABLE "public"."search_history" TO "anon";
GRANT ALL ON TABLE "public"."search_history" TO "authenticated";
GRANT ALL ON TABLE "public"."search_history" TO "service_role";



GRANT ALL ON TABLE "public"."search_synonym_candidates" TO "anon";
GRANT ALL ON TABLE "public"."search_synonym_candidates" TO "authenticated";
GRANT ALL ON TABLE "public"."search_synonym_candidates" TO "service_role";



GRANT ALL ON TABLE "public"."search_synonyms" TO "anon";
GRANT ALL ON TABLE "public"."search_synonyms" TO "authenticated";
GRANT ALL ON TABLE "public"."search_synonyms" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_history" TO "anon";
GRANT ALL ON TABLE "public"."shopping_history" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_history" TO "service_role";



GRANT ALL ON TABLE "public"."shopping_lists" TO "anon";
GRANT ALL ON TABLE "public"."shopping_lists" TO "authenticated";
GRANT ALL ON TABLE "public"."shopping_lists" TO "service_role";



GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";



GRANT ALL ON TABLE "public"."trending_recipes_view" TO "anon";
GRANT ALL ON TABLE "public"."trending_recipes_view" TO "authenticated";
GRANT ALL ON TABLE "public"."trending_recipes_view" TO "service_role";



GRANT ALL ON TABLE "public"."trending_searches" TO "anon";
GRANT ALL ON TABLE "public"."trending_searches" TO "authenticated";
GRANT ALL ON TABLE "public"."trending_searches" TO "service_role";



GRANT ALL ON TABLE "public"."user_achievements" TO "anon";
GRANT ALL ON TABLE "public"."user_achievements" TO "authenticated";
GRANT ALL ON TABLE "public"."user_achievements" TO "service_role";



GRANT ALL ON TABLE "public"."user_activity" TO "anon";
GRANT ALL ON TABLE "public"."user_activity" TO "authenticated";
GRANT ALL ON TABLE "public"."user_activity" TO "service_role";



GRANT ALL ON TABLE "public"."user_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_badges" TO "service_role";



GRANT ALL ON TABLE "public"."user_devices" TO "anon";
GRANT ALL ON TABLE "public"."user_devices" TO "authenticated";
GRANT ALL ON TABLE "public"."user_devices" TO "service_role";



GRANT ALL ON TABLE "public"."user_follows" TO "anon";
GRANT ALL ON TABLE "public"."user_follows" TO "authenticated";
GRANT ALL ON TABLE "public"."user_follows" TO "service_role";



GRANT ALL ON TABLE "public"."user_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."user_profile_view" TO "anon";
GRANT ALL ON TABLE "public"."user_profile_view" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profile_view" TO "service_role";



GRANT ALL ON TABLE "public"."user_reports" TO "anon";
GRANT ALL ON TABLE "public"."user_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."user_reports" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



REVOKE ALL ON TABLE "storage"."buckets" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."buckets" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."buckets" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets" TO "anon";
GRANT ALL ON TABLE "storage"."buckets" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."buckets_analytics" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "anon";



GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "service_role";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "authenticated";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "anon";



REVOKE ALL ON TABLE "storage"."objects" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."objects" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."objects" TO "service_role";
GRANT ALL ON TABLE "storage"."objects" TO "authenticated";
GRANT ALL ON TABLE "storage"."objects" TO "anon";
GRANT ALL ON TABLE "storage"."objects" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."s3_multipart_uploads" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "anon";



GRANT ALL ON TABLE "storage"."s3_multipart_uploads_parts" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "anon";



GRANT SELECT ON TABLE "storage"."vector_indexes" TO "service_role";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "authenticated";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "anon";



GRANT ALL ON TABLE "public"."chef_profile_view" TO "anon";
GRANT ALL ON TABLE "public"."chef_profile_view" TO "authenticated";
GRANT ALL ON TABLE "public"."chef_profile_view" TO "service_role";



GRANT ALL ON TABLE "public"."top_chefs_view" TO "anon";
GRANT ALL ON TABLE "public"."top_chefs_view" TO "authenticated";
GRANT ALL ON TABLE "public"."top_chefs_view" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "service_role";




