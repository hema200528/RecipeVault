--
-- PostgreSQL database dump
--

\restrict maJHv55sspIIIqivCSLimDJgOUSYDZTFG4RULoAwymkuZlCf1UbKcCAMIn0wW7o

-- Dumped from database version 18.3 (Homebrew)
-- Dumped by pg_dump version 18.3 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ingredient; Type: TABLE; Schema: public; Owner: HemaMalini
--

CREATE TABLE public.ingredient (
    ingredient_id integer NOT NULL,
    name character varying(100) NOT NULL,
    category character varying(50)
);


ALTER TABLE public.ingredient OWNER TO "HemaMalini";

--
-- Name: ingredient_ingredient_id_seq; Type: SEQUENCE; Schema: public; Owner: HemaMalini
--

CREATE SEQUENCE public.ingredient_ingredient_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingredient_ingredient_id_seq OWNER TO "HemaMalini";

--
-- Name: ingredient_ingredient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: HemaMalini
--

ALTER SEQUENCE public.ingredient_ingredient_id_seq OWNED BY public.ingredient.ingredient_id;


--
-- Name: ner_tag; Type: TABLE; Schema: public; Owner: HemaMalini
--

CREATE TABLE public.ner_tag (
    ner_id integer NOT NULL,
    recipe_id integer NOT NULL,
    tag character varying(50) NOT NULL
);


ALTER TABLE public.ner_tag OWNER TO "HemaMalini";

--
-- Name: ner_tag_ner_id_seq; Type: SEQUENCE; Schema: public; Owner: HemaMalini
--

CREATE SEQUENCE public.ner_tag_ner_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ner_tag_ner_id_seq OWNER TO "HemaMalini";

--
-- Name: ner_tag_ner_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: HemaMalini
--

ALTER SEQUENCE public.ner_tag_ner_id_seq OWNED BY public.ner_tag.ner_id;


--
-- Name: recipe; Type: TABLE; Schema: public; Owner: HemaMalini
--

CREATE TABLE public.recipe (
    recipe_id integer NOT NULL,
    title character varying(255) NOT NULL,
    directions text NOT NULL,
    link character varying(500),
    source character varying(255),
    occasion character varying(50),
    flavour_profile character varying(50)
);


ALTER TABLE public.recipe OWNER TO "HemaMalini";

--
-- Name: recipe_ingredient; Type: TABLE; Schema: public; Owner: HemaMalini
--

CREATE TABLE public.recipe_ingredient (
    recipe_id integer NOT NULL,
    ingredient_id integer NOT NULL,
    quantity character varying(50),
    unit character varying(50)
);


ALTER TABLE public.recipe_ingredient OWNER TO "HemaMalini";

--
-- Name: recipe_recipe_id_seq; Type: SEQUENCE; Schema: public; Owner: HemaMalini
--

CREATE SEQUENCE public.recipe_recipe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recipe_recipe_id_seq OWNER TO "HemaMalini";

--
-- Name: recipe_recipe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: HemaMalini
--

ALTER SEQUENCE public.recipe_recipe_id_seq OWNED BY public.recipe.recipe_id;


--
-- Name: step; Type: TABLE; Schema: public; Owner: HemaMalini
--

CREATE TABLE public.step (
    step_id integer NOT NULL,
    recipe_id integer NOT NULL,
    step_number integer NOT NULL,
    description text NOT NULL,
    CONSTRAINT step_step_number_check CHECK ((step_number > 0))
);


ALTER TABLE public.step OWNER TO "HemaMalini";

--
-- Name: step_step_id_seq; Type: SEQUENCE; Schema: public; Owner: HemaMalini
--

CREATE SEQUENCE public.step_step_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.step_step_id_seq OWNER TO "HemaMalini";

--
-- Name: step_step_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: HemaMalini
--

ALTER SEQUENCE public.step_step_id_seq OWNED BY public.step.step_id;


--
-- Name: ingredient ingredient_id; Type: DEFAULT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ingredient ALTER COLUMN ingredient_id SET DEFAULT nextval('public.ingredient_ingredient_id_seq'::regclass);


--
-- Name: ner_tag ner_id; Type: DEFAULT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ner_tag ALTER COLUMN ner_id SET DEFAULT nextval('public.ner_tag_ner_id_seq'::regclass);


--
-- Name: recipe recipe_id; Type: DEFAULT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe ALTER COLUMN recipe_id SET DEFAULT nextval('public.recipe_recipe_id_seq'::regclass);


--
-- Name: step step_id; Type: DEFAULT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.step ALTER COLUMN step_id SET DEFAULT nextval('public.step_step_id_seq'::regclass);


--
-- Name: ingredient ingredient_name_key; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ingredient
    ADD CONSTRAINT ingredient_name_key UNIQUE (name);


--
-- Name: ingredient ingredient_pkey; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ingredient
    ADD CONSTRAINT ingredient_pkey PRIMARY KEY (ingredient_id);


--
-- Name: ner_tag ner_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ner_tag
    ADD CONSTRAINT ner_tag_pkey PRIMARY KEY (ner_id);


--
-- Name: recipe_ingredient recipe_ingredient_pkey; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe_ingredient
    ADD CONSTRAINT recipe_ingredient_pkey PRIMARY KEY (recipe_id, ingredient_id);


--
-- Name: recipe recipe_pkey; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe
    ADD CONSTRAINT recipe_pkey PRIMARY KEY (recipe_id);


--
-- Name: recipe recipe_title_key; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe
    ADD CONSTRAINT recipe_title_key UNIQUE (title);


--
-- Name: step step_pkey; Type: CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.step
    ADD CONSTRAINT step_pkey PRIMARY KEY (step_id);


--
-- Name: ner_tag ner_tag_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.ner_tag
    ADD CONSTRAINT ner_tag_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(recipe_id) ON DELETE CASCADE;


--
-- Name: recipe_ingredient recipe_ingredient_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe_ingredient
    ADD CONSTRAINT recipe_ingredient_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.ingredient(ingredient_id) ON DELETE CASCADE;


--
-- Name: recipe_ingredient recipe_ingredient_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.recipe_ingredient
    ADD CONSTRAINT recipe_ingredient_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(recipe_id) ON DELETE CASCADE;


--
-- Name: step step_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: HemaMalini
--

ALTER TABLE ONLY public.step
    ADD CONSTRAINT step_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipe(recipe_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict maJHv55sspIIIqivCSLimDJgOUSYDZTFG4RULoAwymkuZlCf1UbKcCAMIn0wW7o

