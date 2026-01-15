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

--
-- Name: configmetarefrigerador(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configmetarefrigerador() RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
x record;
count INTEGER;
cliente character varying(1);
BEGIN
 FOR x in (SELECT v.*, e.acao_id, nf.refrigerador_id, t.possui_nis FROM vistoria_PNGD v 
  LEFT JOIN triagem_pngd t ON t.id = v.triagem_d_id 
  LEFT JOIN clientes_eventos_contratos cec ON cec.id = t.cliente_evento_contrato_id 
  LEFT JOIN eventos e ON e.id = cec.evento_id
  LEFT JOIN nota_fabricantes_nota_saidas nfns ON nfns.id = v.nota_fabricante_nota_saida_id
  LEFT JOIN nota_fabricantes nf ON nf.id = nfns.nota_fabricante_id) 
 LOOP
 count = 0;
 cliente = CASE WHEN x.possui_nis = 'S' THEN 'B' ELSE 'R' END;
 count = (SELECT count(m.id) from meta_refrigeradors m WHERE m.ano = '2015' AND m.refrigerador_id = x.refrigerador_id AND m.tipo_cliente = cliente AND m.acao_id = x.acao_id);
 IF(count > 0) THEN
  UPDATE meta_refrigeradors SET quantidade_atual = (quantidade_atual - 1) WHERE ano = 2015 AND refrigerador_id = x.refrigerador_id AND tipo_cliente = cliente AND acao_id = x.acao_id;
 ELSE 
  INSERT INTO meta_refrigeradors (ano, refrigerador_id, tipo_cliente, quantidade, quantidade_atual, acao_id) VALUES 
      (2015, x.refrigerador_id, cliente, 10000, 10000-1, x.acao_id);
 END IF;
 count = 0;
 END LOOP;
 RETURN 'OK';
END;
$$;


--
-- Name: configpermissoes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.configpermissoes() RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
x record;
y record;
BEGIN
 FOR x in select * from menus LOOP
	FOR y in select * from modulos LOOP
		insert into menus_modulos (menu_id, modulo_id) values (x.id, y.id);
	END LOOP;
 END LOOP;

 FOR x in select * from menus LOOP
	FOR y in select * from perfils LOOP
		insert into menus_perfils (menu_id, perfil_id) values (x.id, y.id);
	END LOOP;
 END LOOP;

 FOR x in select * from perfils LOOP
	FOR y in select * from modulos LOOP
		insert into perfils_modulos (perfil_id, modulo_id) values (x.id, y.id);
	END LOOP;
 END LOOP;

RETURN 'OK';
END;

$$;


--
-- Name: contratoementregas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.contratoementregas() RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
x record;
y record;
z record;

BEGIN

 FOR x in (SELECT con.id contrato, cee.id as cli_ev_entrega_id
		  FROM clientes_eventos_contratos cec
		  INNER JOIN  clientes_evento_entregas cee ON cee.cliente_id = cec.cliente_id OR cee.contrato_id = cec.contrato_id
		  INNER JOIN evento_entregas ee ON ee.id = cee.evento_entrega_id
		  INNER JOIN eventos e ON e.id = ee.evento_id
		  INNER JOIN clientes cli ON cli.id = cee.cliente_id AND cli.id = cec.cliente_id
		  INNER JOIN contratos con ON con.id = cec.contrato_id
		  INNER JOIN (select cliente_Id, evento_id from clientes_eventos_contratos where modulo_id = 3
				group by cliente_id, evento_id
				having count(cliente_id)  > 1 AND count(evento_id)  > 1
				order by 1,2) as repeat ON repeat.cliente_id = cec.cliente_id and repeat.evento_id = cec.evento_id
		WHERE cec.modulo_id = 3) 
 LOOP
	
	UPDATE clientes_evento_entregas SET contrato_id = x.contrato 
	 WHERE id = x.cli_ev_entrega_id AND contrato_id is null;
	   
	
 END LOOP;

 FOR y in (SELECT contrato_id, cliente_id from clientes_eventos_contratos where modulo_id = 1) 
 LOOP
	UPDATE clientes_evento_entregas SET contrato_id = y.contrato_id WHERE contrato_id is null AND cliente_id = y.cliente_id AND y.contrato_id NOT IN (SELECT contrato_id from clientes_evento_entregas where contrato_id is not null);
	--UPDATE clientes_evento_entregas cee SET contrato_id = (SELECT cec.contrato_id from clientes_eventos_contratos cec where cec.cliente_id = cee.cliente_id AND modulo_id = 3 AND cee.contrato_id is null);
 END LOOP;

 FOR z in (SELECT contrato_id, cliente_id from clientes_eventos_contratos where modulo_id = 3) 
 LOOP
	--UPDATE clientes_evento_entregas cee SET contrato_id = z.contrato_id;
	UPDATE clientes_evento_entregas SET contrato_id = z.contrato_id WHERE contrato_id is null AND cliente_id = z.cliente_id AND z.contrato_id NOT IN (SELECT contrato_id from clientes_evento_entregas where contrato_id is not null);
 END LOOP;

 
 RETURN 'OK';
END;
$$;


--
-- Name: mask_name_lgpd(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mask_name_lgpd(input_name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
    IF LENGTH(input_name) <= 3 THEN
        -- For very short names (3 or fewer characters), mask with asterisks
        RETURN '***';
    ELSIF LENGTH(input_name) <= 5 THEN
        -- For short names (4 to 5 characters), show the first 3 and mask the rest
        RETURN SUBSTR(input_name, 1, 3) || '**';
    ELSE
        -- For longer names, apply the 3_FIRST_LETTERS_****************_2_LAST_LETTERS pattern
        RETURN SUBSTR(input_name, 1, 3) || '****************' || SUBSTR(input_name, LENGTH(input_name) - 1);
    END IF;
END;
$$;


--
-- Name: powerbi(integer, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.powerbi(form_id integer, data_inicial date DEFAULT NULL::date, data_final date DEFAULT NULL::date) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE
        form_item record;
        resposta record;

        index int := 1;

        build_columns text := '';
        initial_insert text := '';
        build_inserts text := '';
        _column text = '';
        valor_item text = '';

        item_resposta record;

        last_executed boolean := false;
    BEGIN
        -- version: 1.0.1

        -- computa todas as colunas
        FOR form_item IN (
            SELECT *
            FROM bi_form_items
            WHERE bi_form_id = form_id
              and status = 'A'
            ORDER BY id
        ) LOOP
            -- coloca a coluna build_columns, todas as colunas tem tipo text
            build_columns := build_columns || ',"' || form_item.titulo || '" ' || CASE WHEN form_item.tipo = 'data' THEN 'date' ELSE 'text' END;
        END LOOP;

        -- cria a tabela temporária
        EXECUTE 'CREATE TEMP TABLE pivot_bi (resposta_id int, "Carimbo de data/hora" timestamp without time zone' || build_columns || ')';

        initial_insert := 'INSERT INTO pivot_bi (resposta_id, "Carimbo de data/hora"' || REPLACE(REPLACE(build_columns, ' date', ''), ' text', '') || ') VALUES ';

        FOR resposta IN (
            SELECT *
            FROM bi_form_respostas
            WHERE bi_form_id = form_id
              AND (data_inicial IS NULL OR data_cadastro >= data_inicial::date)
              AND to_timestamp(to_char(data_cadastro, 'DD-MM-YYYY HH24:MI:SS'), 'DD-MM-YYYY HH24:MI:SS') <=
                  to_timestamp(to_char(data_final,'DD-MM-YYYY') || ' ' || '23:59:59', 'DD-MM-YYYY HH24:MI:SS')
        ) LOOP
            -- coloca o bracket da linha, se já teve um INSERT nesse bloco, coloca uma virgula
            -- resultado final esperado INSERT INTO ... (coluna1, coluna2) VALUES (val1, val2), (val1, val2)
            IF index = 1 THEN
                build_inserts := initial_insert || '(' || resposta.id || ','''|| resposta.data_cadastro ||'''';
            ELSE
                build_inserts := build_inserts || ',(' || resposta.id || ','''|| resposta.data_cadastro ||'''';
            END IF;

            FOR _column IN (
                SELECT column_name::TEXT
                FROM information_schema.COLUMNS
                WHERE
                      table_name = 'pivot_bi' AND
                      column_name <> 'resposta_id' and column_name <> 'Carimbo de data/hora'
                    order by ordinal_position
            ) LOOP

                -- só para garantir que vai estar tudo zerado
                item_resposta := null;

                -- pega a resposta para essa coluna
                SELECT
                    bi_form_items.tipo as tipo,
                    bfis.value as select_value,
                    comunidades.nome as comunidade_value,
                    cidades.nome as cidade_value,
                    bairros.nome as bairro_value,
                    bi_form_item_respostas.valor as plaintext_value
                INTO item_resposta
                FROM bi_form_item_respostas
                    LEFT JOIN cidades ON bi_form_item_respostas.cidade_id = cidades.id
                    LEFT JOIN bairros on bi_form_item_respostas.bairro_id = bairros.id
                    LEFT JOIN comunidades ON bi_form_item_respostas.comunidade_id = comunidades.id
                    LEFT JOIN bi_form_item_selects bfis on bfis.id = bi_form_item_respostas.bi_select_id
                    INNER JOIN bi_form_items ON bi_form_item_respostas.bi_form_item_id = bi_form_items.id
                WHERE
                      titulo = _column AND
                      bi_form_items.status = 'A' AND
                      bi_form_resposta_id = resposta.id AND
                      bi_form_id = form_id;

                IF item_resposta.tipo = 'select' THEN
                    valor_item := item_resposta.select_value; -- value está na tabela bi_form_item_selects
                ELSIF item_resposta.tipo = 'comunidade' THEN
                    valor_item := item_resposta.comunidade_value; -- nome está na tabela COMUNIDADES
                ELSIF item_resposta.tipo = 'city' THEN
                    valor_item := item_resposta.cidade_value;
                ELSIF item_resposta.tipo = 'bairro' THEN
                    valor_item := item_resposta.bairro_value;
                ELSE
                    valor_item := item_resposta.plaintext_value;
                END IF;

                -- transforma o valor recebido para colocar no build_inserts
                valor_item :=
                    CASE WHEN valor_item IS NOT NULL THEN
                        ''''||  REPLACE(valor_item, '''', '`') || ''''
                    ELSE
                        'null'
                    END;

                -- insere o valor
                build_inserts := build_inserts || ', ' || valor_item;
            END LOOP;

            -- ) final
            build_inserts := build_inserts || ')';

            -- se o index for < 1000 processa mais uma linha antes de executar
            -- isso faz com que seja feito 1000 inserts de uma só vez
            IF index < 1000 THEN
                last_executed := false;
                index := index + 1;
            ELSE
                raise notice '%', build_inserts;
                -- se atingir o limite de 1000 linhas executa o insert e reseta a query
                EXECUTE build_inserts;
                last_executed := true;
                index := 1;
            END IF;
        END LOOP;
        -- se as ultimas respostas não executaram antes executa agora
        -- isso acontece sempre que o ultimo bloco for menor que 100
        IF last_executed = false THEN
            raise notice '%', build_inserts;
            EXECUTE build_inserts;
        END IF;
    RETURN QUERY SELECT * FROM pivot_bi;
    DROP TABLE pivot_bi;
END;
$$;


--
-- Name: uppercaseall(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uppercaseall() RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
x record;
BEGIN
 FOR x in select * from comunidades 
 LOOP
	update comunidades set nome = upper(x.nome) where id = x.id;
 END LOOP;

 FOR x in select * from bairros 
 LOOP
	update bairros set nome = upper(x.nome) where id = x.id;
 END LOOP;
 
 FOR x in select * from cidades 
 LOOP
	update cidades set nome = upper(x.nome) where id = x.id;
 END LOOP;

 FOR x in select * from ufs 
 LOOP
	update ufs set nome = upper(x.nome) where id = x.id;
 END LOOP;
 RETURN upper(x.nome);
END;

$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: menus_perfils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menus_perfils (
    id integer NOT NULL,
    menu_id integer NOT NULL,
    perfil_id integer NOT NULL
);


--
-- Name: MenuPerfils_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."MenuPerfils_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: MenuPerfils_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."MenuPerfils_id_seq" OWNED BY public.menus_perfils.id;


--
-- Name: perfils_modulos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfils_modulos (
    id integer NOT NULL,
    perfil_id integer NOT NULL,
    modulo_id integer NOT NULL
);


--
-- Name: PerfilProjetos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."PerfilProjetos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: PerfilProjetos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."PerfilProjetos_id_seq" OWNED BY public.perfils_modulos.id;


--
-- Name: projetos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projetos (
    id integer NOT NULL,
    nome character varying(45) NOT NULL,
    sigla character varying(10),
    ativo integer DEFAULT 1 NOT NULL
);


--
-- Name: Projetos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Projetos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Projetos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Projetos_id_seq" OWNED BY public.projetos.id;


--
-- Name: acaos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acaos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    projeto_id integer,
    tipo_acao_id integer,
    integracao_auto character(1) DEFAULT 'N'::bpchar
);


--
-- Name: acaos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.acaos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acaos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.acaos_id_seq OWNED BY public.acaos.id;


--
-- Name: agendamentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agendamentos (
    id integer NOT NULL,
    observacao text NOT NULL,
    data date NOT NULL,
    contato character varying(45) NOT NULL,
    telefone character varying(13) NOT NULL,
    refrigerador_id integer,
    triagem_pngv_id integer NOT NULL,
    visita_ok character(1) DEFAULT 'N'::bpchar NOT NULL
);


--
-- Name: COLUMN agendamentos.visita_ok; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.agendamentos.visita_ok IS 'S = sim
N = não';


--
-- Name: agendamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agendamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: agendamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agendamentos_id_seq OWNED BY public.agendamentos.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: arquivos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos (
    id integer DEFAULT nextval('public.arquivos_id_seq'::regclass) NOT NULL,
    nome character varying(255) NOT NULL,
    model character varying(50) NOT NULL,
    registro_id integer NOT NULL,
    link character varying(255),
    data_cadastro timestamp without time zone NOT NULL
);


--
-- Name: arquivos_eventos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos_eventos (
    id bigint NOT NULL,
    nome character varying(100),
    evento_id integer NOT NULL
);


--
-- Name: arquivos_eventos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_eventos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos_eventos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arquivos_eventos_id_seq OWNED BY public.arquivos_eventos.id;


--
-- Name: arquivos_triagem_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos_triagem_pngd (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    triagem_pngd_id integer NOT NULL
);


--
-- Name: arquivos_triagem_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_triagem_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos_triagem_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arquivos_triagem_pngd_id_seq OWNED BY public.arquivos_triagem_pngd.id;


--
-- Name: arquivos_triagems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos_triagems (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    triagem_pngv_id integer NOT NULL
);


--
-- Name: arquivos_triagems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_triagems_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos_triagems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arquivos_triagems_id_seq OWNED BY public.arquivos_triagems.id;


--
-- Name: arquivos_vendas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos_vendas (
    id bigint NOT NULL,
    nome character varying(80),
    venda_id integer
);


--
-- Name: arquivos_vendas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_vendas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos_vendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arquivos_vendas_id_seq OWNED BY public.arquivos_vendas.id;


--
-- Name: arquivos_vistoria_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arquivos_vistoria_pngd (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    vistoria_pngd_id integer NOT NULL
);


--
-- Name: arquivos_vistoria_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arquivos_vistoria_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arquivos_vistoria_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arquivos_vistoria_pngd_id_seq OWNED BY public.arquivos_vistoria_pngd.id;


--
-- Name: b_i_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.b_i_forms (
    id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: b_i_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.b_i_forms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: b_i_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.b_i_forms_id_seq OWNED BY public.b_i_forms.id;


--
-- Name: bairros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bairros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bairros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bairros (
    id integer DEFAULT nextval('public.bairros_id_seq'::regclass) NOT NULL,
    cidade_id integer NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: bi_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_contratos (
    id integer NOT NULL,
    nome character varying NOT NULL,
    data_inicial date NOT NULL,
    data_final date NOT NULL,
    permitir_uso_dados_bi boolean DEFAULT false,
    permitir_uso_metas_bi boolean DEFAULT false NOT NULL
);


--
-- Name: bi_contratos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_contratos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_contratos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_contratos_id_seq OWNED BY public.bi_contratos.id;


--
-- Name: bi_form_item_bairros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_item_bairros (
    id integer NOT NULL,
    bi_form_item_id integer NOT NULL,
    bairro_id integer NOT NULL
);


--
-- Name: bi_form_item_bairros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_item_bairros_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_item_bairros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_item_bairros_id_seq OWNED BY public.bi_form_item_bairros.id;


--
-- Name: bi_form_item_cidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_item_cidades (
    id integer NOT NULL,
    bi_form_item_id integer NOT NULL,
    cidade_id integer NOT NULL
);


--
-- Name: bi_form_item_cidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_item_cidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_item_cidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_item_cidades_id_seq OWNED BY public.bi_form_item_cidades.id;


--
-- Name: bi_form_item_comunidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_item_comunidades (
    id integer NOT NULL,
    bi_form_item_id integer NOT NULL,
    comunidade_id integer NOT NULL
);


--
-- Name: bi_form_item_comunidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_item_comunidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_item_comunidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_item_comunidades_id_seq OWNED BY public.bi_form_item_comunidades.id;


--
-- Name: bi_form_item_respostas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_item_respostas (
    id integer NOT NULL,
    bi_form_item_id integer NOT NULL,
    valor character varying,
    comunidade_id integer,
    bi_select_id integer,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    bi_form_resposta_id integer,
    cidade_id integer,
    bairro_id integer
);


--
-- Name: bi_form_item_resposta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_item_resposta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_item_resposta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_item_resposta_id_seq OWNED BY public.bi_form_item_respostas.id;


--
-- Name: bi_form_item_selects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_item_selects (
    id integer NOT NULL,
    value character varying NOT NULL,
    form_item_id integer NOT NULL,
    enabled boolean DEFAULT true,
    label character varying
);


--
-- Name: bi_form_item_selects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_item_selects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_item_selects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_item_selects_id_seq OWNED BY public.bi_form_item_selects.id;


--
-- Name: bi_form_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_items (
    id integer NOT NULL,
    titulo character varying NOT NULL,
    tipo character varying NOT NULL,
    bi_form_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status character(1) DEFAULT 'A'::bpchar NOT NULL,
    obrigatorio boolean DEFAULT false NOT NULL,
    stepper_id integer,
    searchable boolean DEFAULT false NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    file_name character varying,
    tamanho integer
);


--
-- Name: bi_form_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_items_id_seq OWNED BY public.bi_form_items.id;


--
-- Name: bi_form_respostas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_respostas (
    id integer NOT NULL,
    bi_form_id integer NOT NULL,
    usuario_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: bi_form_resposta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_resposta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_resposta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_resposta_id_seq OWNED BY public.bi_form_respostas.id;


--
-- Name: bi_form_resposta_reciclagens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_resposta_reciclagens (
    id integer NOT NULL,
    bi_resposta_id integer NOT NULL,
    reciclagem_id integer NOT NULL
);


--
-- Name: bi_form_resposta_reciclagens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_resposta_reciclagens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_resposta_reciclagens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_resposta_reciclagens_id_seq OWNED BY public.bi_form_resposta_reciclagens.id;


--
-- Name: bi_form_steppers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_form_steppers (
    id integer NOT NULL,
    bi_form_id integer NOT NULL,
    title character varying,
    status character varying DEFAULT 'A'::character varying NOT NULL
);


--
-- Name: bi_form_steppers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_form_steppers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_form_steppers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_form_steppers_id_seq OWNED BY public.bi_form_steppers.id;


--
-- Name: bi_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_forms (
    id integer NOT NULL,
    nome character varying NOT NULL,
    key character varying NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status character(1) DEFAULT 'A'::bpchar NOT NULL,
    mobile boolean DEFAULT true NOT NULL,
    editavel boolean DEFAULT false NOT NULL,
    mobile_clientes boolean DEFAULT false NOT NULL
);


--
-- Name: bi_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_forms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_forms_id_seq OWNED BY public.bi_forms.id;


--
-- Name: bi_metas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bi_metas (
    id integer NOT NULL,
    data date NOT NULL,
    meta double precision,
    meta_ee double precision NOT NULL,
    meta_rdp double precision NOT NULL,
    meta_beneficios double precision NOT NULL,
    meta_rcb double precision NOT NULL,
    custo double precision,
    bi_contrato_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: bi_metas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bi_metas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bi_metas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bi_metas_id_seq OWNED BY public.bi_metas.id;


--
-- Name: campanhas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.campanhas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: campanhas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campanhas (
    id integer DEFAULT nextval('public.campanhas_id_seq'::regclass) NOT NULL,
    nome character varying(255) NOT NULL,
    status character varying(1) NOT NULL,
    data_inicial timestamp without time zone,
    data_final timestamp without time zone,
    modulo_id integer NOT NULL
);


--
-- Name: cidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cidades (
    uf_id integer NOT NULL,
    id integer NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: cliente_estabelecimento_entregas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cliente_estabelecimento_entregas (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    estabelecimento_entrega_id integer NOT NULL
);


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id integer NOT NULL,
    nis character(11),
    cpf character varying(14),
    nome character varying(120) NOT NULL,
    documento character varying(20),
    "dataNascimento" date,
    "estadoCivil" character(1),
    "conheceTSEE" character(1),
    rg_uf_id integer,
    regiao character(1),
    telefone character varying(14),
    celular character varying(14),
    email character varying(255),
    "tipoDocumento" character varying(15),
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    como_conheceu character(10) DEFAULT 'N'::bpchar,
    evento_id integer,
    usuario_id integer,
    recebe_fatura character(1) DEFAULT 'N'::bpchar NOT NULL
);


--
-- Name: COLUMN clientes.cpf; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.cpf IS 'CPF ou CNPJ do cliente (mantido como cpf por compatibilidade). CPF: 11 dígitos, CNPJ: 14 dígitos';


--
-- Name: COLUMN clientes."estadoCivil"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes."estadoCivil" IS 'C = Casado
S = solteiro
D = divorciado
V = viuvo
U = união estável';


--
-- Name: COLUMN clientes."conheceTSEE"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes."conheceTSEE" IS 'S = sim
N = não';


--
-- Name: COLUMN clientes.regiao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.regiao IS 'C - Capital;
I - Interior;';


--
-- Name: COLUMN clientes."tipoDocumento"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes."tipoDocumento" IS 'RG, CNH, CTPS, Passaporte...';


--
-- Name: COLUMN clientes.como_conheceu; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.clientes.como_conheceu IS 'MOB = MOBILIZAÇAO, IND = INDICAÇÃO, MID = MÍDIA ,N  = NÃO SE APLICA, COM = COMUNICADO_LIGHT, outros = (CAMPO DIGITADO) ';


--
-- Name: clientes_contratos_projetos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_contratos_projetos (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    projeto_id integer NOT NULL,
    contrato_id integer NOT NULL,
    data_cadastro timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL
);


--
-- Name: clientes_contratos_projetos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_contratos_projetos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_contratos_projetos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_contratos_projetos_id_seq OWNED BY public.clientes_contratos_projetos.id;


--
-- Name: clientes_estabelecimento_entregas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_estabelecimento_entregas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_estabelecimento_entregas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_estabelecimento_entregas_id_seq OWNED BY public.cliente_estabelecimento_entregas.id;


--
-- Name: clientes_evento_entregas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_evento_entregas (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    evento_entrega_id integer NOT NULL,
    contrato_id integer
);


--
-- Name: clientes_evento_entregas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_evento_entregas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_evento_entregas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_evento_entregas_id_seq OWNED BY public.clientes_evento_entregas.id;


--
-- Name: clientes_eventos_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes_eventos_contratos (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    evento_id integer NOT NULL,
    contrato_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    modulo_id integer NOT NULL,
    status character(1) DEFAULT 'A'::bpchar
);


--
-- Name: clientes_eventos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_eventos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_eventos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_eventos_id_seq OWNED BY public.clientes_eventos_contratos.id;


--
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- Name: comunidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comunidades (
    id integer NOT NULL,
    nome character varying(50) NOT NULL,
    acao_id integer,
    bairro_id integer,
    uf_id integer,
    latitude character varying(50),
    longitude character varying(50),
    logradouro character varying(100) DEFAULT NULL::character varying,
    complemento character varying(150) DEFAULT NULL::character varying,
    parceiro_id integer,
    cep character(8),
    uf text,
    cidade text,
    bairro text,
    tipo_id integer,
    status character(1) DEFAULT 'A'::bpchar NOT NULL
);


--
-- Name: COLUMN comunidades.acao_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.comunidades.acao_id IS 'Id da ação serve para determinar qual será o local quando ol local for para ação Educativo CV ou Museu';


--
-- Name: comunidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comunidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comunidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comunidades_id_seq OWNED BY public.comunidades.id;


--
-- Name: comunidades_tipos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comunidades_tipos (
    id integer NOT NULL,
    nome character varying NOT NULL
);


--
-- Name: comunidades_tipos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comunidades_tipos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comunidades_tipos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comunidades_tipos_id_seq OWNED BY public.comunidades_tipos.id;


--
-- Name: configuracao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracao_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuracao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracao (
    id integer DEFAULT nextval('public.configuracao_id_seq'::regclass) NOT NULL,
    chave character varying(20) NOT NULL,
    valor character varying(20) NOT NULL,
    modulo_id integer
);


--
-- Name: contratos_campanhas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contratos_campanhas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: contrato_campanhas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contrato_campanhas (
    id integer DEFAULT nextval('public.contratos_campanhas_id_seq'::regclass) NOT NULL,
    contrato_id integer NOT NULL,
    campanha_id integer NOT NULL,
    data_cadastro timestamp without time zone NOT NULL,
    model_id integer NOT NULL,
    registro_id integer NOT NULL
);


--
-- Name: contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contratos (
    id integer NOT NULL,
    numero character varying(45) NOT NULL,
    "numeroMedidor" character varying(20),
    tensao character(1),
    complemento character varying(255),
    "referenciaEndereco" text,
    logradouro character varying(255) NOT NULL,
    numero_endereco character varying(45),
    bairro character varying(255),
    cidade character varying(255),
    uf_id integer,
    "nomeTitular" character varying(120) NOT NULL,
    cpf_cnpj_titular character varying(18),
    cep character(8),
    "numeroParceiro" character varying(20),
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    bairro_id integer,
    observacoes text,
    status character varying(1) DEFAULT 'A'::character varying NOT NULL,
    cliente_id integer,
    contrato_tipo_id integer DEFAULT 1 NOT NULL,
    local_cadastro_id integer,
    uf text,
    nuc_novo character varying(20)
);


--
-- Name: COLUMN contratos.tensao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contratos.tensao IS '1 = 110v
2 = 220v';


--
-- Name: COLUMN contratos.cpf_cnpj_titular; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.contratos.cpf_cnpj_titular IS 'CPF ou CNPJ do titular do contrato. CPF: 11 dígitos, CNPJ: 14 dígitos';


--
-- Name: contratos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: contratos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contratos_id_seq OWNED BY public.contratos.id;


--
-- Name: contratos_tipos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contratos_tipos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contratos_tipos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contratos_tipos (
    id integer DEFAULT nextval('public.contratos_tipos_id_seq'::regclass) NOT NULL,
    status character varying(1) NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: doacao_historicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doacao_historicos (
    id bigint NOT NULL,
    vistoria_pngd_id integer,
    data_alteracao timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_alteracao integer,
    descricao text
);


--
-- Name: doacao_historico_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doacao_historico_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: doacao_historico_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doacao_historico_id_seq OWNED BY public.doacao_historicos.id;


--
-- Name: doacao_lampada_historicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doacao_lampada_historicos (
    id integer NOT NULL,
    data_alteracao timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_alteracao integer NOT NULL,
    descricao text NOT NULL,
    doacao_lampada_ids text NOT NULL
);


--
-- Name: doacao_lampada_historicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doacao_lampada_historicos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doacao_lampada_historicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doacao_lampada_historicos_id_seq OWNED BY public.doacao_lampada_historicos.id;


--
-- Name: doacao_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doacao_lampadas (
    id integer NOT NULL,
    quantidade integer NOT NULL,
    data timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    evento_id integer,
    cliente_id integer NOT NULL,
    projeto_id integer NOT NULL,
    lampada_id integer NOT NULL,
    contrato_id integer NOT NULL,
    servico_id integer,
    evento_entrega_id integer,
    modulo_id integer NOT NULL,
    cliente_tipo character varying(1) NOT NULL,
    nis character(11),
    participa_mev character varying(1) DEFAULT 'N'::character varying,
    evento_doacao_lampada_id integer,
    CONSTRAINT doacao_lampadas_participa_mev_check CHECK ((((participa_mev)::text = 'S'::text) OR ((participa_mev)::text = 'N'::text))),
    CONSTRAINT unsigned_doacao_lampadas_quantidade CHECK ((quantidade > 0))
);


--
-- Name: COLUMN doacao_lampadas.cliente_tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.doacao_lampadas.cliente_tipo IS 'R = Residencial
B = Baixa renda';


--
-- Name: COLUMN doacao_lampadas.participa_mev; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.doacao_lampadas.participa_mev IS 'Campo que serve para o vale luz e define se o cliente participa de projeto M&V
''S'' = Sim ou ''N'' = Não';


--
-- Name: doacao_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doacao_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: doacao_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doacao_lampadas_id_seq OWNED BY public.doacao_lampadas.id;


--
-- Name: equipamentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipamentos (
    id bigint NOT NULL,
    nome character varying(35),
    data_cadastro timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: equipamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipamentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: equipamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipamentos_id_seq OWNED BY public.equipamentos.id;


--
-- Name: esqueci_senha; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.esqueci_senha (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    codigo integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    status character(1) DEFAULT 'A'::bpchar NOT NULL
);


--
-- Name: esqueci_senha_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.esqueci_senha_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: esqueci_senha_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.esqueci_senha_id_seq OWNED BY public.esqueci_senha.id;


--
-- Name: estabelecimento_entregas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estabelecimento_entregas (
    id integer NOT NULL,
    data date NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer NOT NULL,
    turno character(1) NOT NULL,
    estabelecimento_id integer NOT NULL,
    CONSTRAINT unsigned_estabelecimento_entregas_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT unsigned_estabelecimento_entregas_quantidade_atual CHECK ((quantidade_atual >= 0))
);


--
-- Name: COLUMN estabelecimento_entregas.turno; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.estabelecimento_entregas.turno IS 'M = manhã
T = tarde';


--
-- Name: estabelecimento_entregas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estabelecimento_entregas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: estabelecimento_entregas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estabelecimento_entregas_id_seq OWNED BY public.estabelecimento_entregas.id;


--
-- Name: estabelecimentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estabelecimentos (
    id integer NOT NULL,
    nome character varying(45) NOT NULL,
    endereco character varying(255) NOT NULL,
    "numeroEndereco" character varying(45) NOT NULL,
    "bairroEndereco" character varying(255) NOT NULL,
    "cidadeEndereco" character varying(255) NOT NULL,
    "complementoEndereco" character varying(255),
    "referenciaEndereco" character varying(255),
    endereco_uf_id integer NOT NULL,
    cep character(8),
    regiao character(1) NOT NULL
);


--
-- Name: COLUMN estabelecimentos.regiao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.estabelecimentos.regiao IS 'C - Capital;
I - Interior;';


--
-- Name: estabelecimentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estabelecimentos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: estabelecimentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estabelecimentos_id_seq OWNED BY public.estabelecimentos.id;


--
-- Name: evento_doacao_lampada_reserva_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_doacao_lampada_reserva_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_doacao_lampada_reserva_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_doacao_lampada_reserva_lampadas (
    id integer DEFAULT nextval('public.evento_doacao_lampada_reserva_lampadas_id_seq'::regclass) NOT NULL,
    evento_doacao_lampada_id integer NOT NULL,
    reserva_lampada_id integer NOT NULL
);


--
-- Name: evento_doacao_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_doacao_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_doacao_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_doacao_lampadas (
    id integer DEFAULT nextval('public.evento_doacao_lampadas_id_seq'::regclass) NOT NULL,
    evento_id integer NOT NULL,
    consumo_minimo double precision,
    qtd_por_cliente integer NOT NULL,
    possui_sucatas boolean,
    possui_servico boolean,
    saldo_livre boolean
);


--
-- Name: evento_entrega_nota_saidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_entrega_nota_saidas (
    id bigint NOT NULL,
    evento_entrega_id integer,
    nota_saida_id integer
);


--
-- Name: evento_entregas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_entregas (
    id integer NOT NULL,
    data date NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer NOT NULL,
    evento_id integer NOT NULL,
    local_entrega integer,
    instituicao_id integer,
    turno character(1),
    CONSTRAINT unsigned_evento_entregas_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT unsigned_evento_entregas_quantidade_atual CHECK ((quantidade_atual >= 0))
);


--
-- Name: COLUMN evento_entregas.turno; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.evento_entregas.turno IS 'M = manhã
T = tarde';


--
-- Name: evento_entregas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_entregas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_entregas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_entregas_id_seq OWNED BY public.evento_entregas.id;


--
-- Name: evento_entregas_nota_saidas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_entregas_nota_saidas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_entregas_nota_saidas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_entregas_nota_saidas_id_seq OWNED BY public.evento_entrega_nota_saidas.id;


--
-- Name: evento_escalacaos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_escalacaos (
    id bigint NOT NULL,
    usuario_operador_id integer NOT NULL,
    data_inicio timestamp without time zone,
    usuario_id integer NOT NULL,
    data_criacao timestamp without time zone,
    evento_id integer NOT NULL,
    data_fim timestamp without time zone
);


--
-- Name: evento_escalacaos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_escalacaos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_escalacaos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_escalacaos_id_seq OWNED BY public.evento_escalacaos.id;


--
-- Name: evento_historicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_historicos (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    data_alteracao timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_alteracao integer,
    descricao text
);


--
-- Name: evento_historicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_historicos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_historicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_historicos_id_seq OWNED BY public.evento_historicos.id;


--
-- Name: evento_horario_ecopontos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_horario_ecopontos (
    id bigint NOT NULL,
    evento_id integer NOT NULL,
    manha_hora_inicial character varying NOT NULL,
    manha_hora_final character varying NOT NULL,
    data_cadastro timestamp with time zone DEFAULT now() NOT NULL,
    dia_semana integer NOT NULL,
    status boolean DEFAULT true NOT NULL,
    data_atualizacao timestamp with time zone DEFAULT now(),
    tarde_hora_inicial character varying,
    tarde_hora_final character varying
);


--
-- Name: evento_horario_ecopontos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_horario_ecopontos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_horario_ecopontos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_horario_ecopontos_id_seq OWNED BY public.evento_horario_ecopontos.id;


--
-- Name: evento_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_lampadas (
    id bigint NOT NULL,
    evento_id integer NOT NULL,
    quantidade_lampadas integer,
    lampada_id integer NOT NULL
);


--
-- Name: evento_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_lampadas_id_seq OWNED BY public.evento_lampadas.id;


--
-- Name: eventos_parceiros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_parceiros_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_parceiros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_parceiros (
    id integer DEFAULT nextval('public.eventos_parceiros_id_seq'::regclass) NOT NULL,
    evento_id integer NOT NULL,
    vigencia_id integer NOT NULL,
    instituicao_id integer,
    bonus_saldo double precision NOT NULL,
    data_cadastro date NOT NULL,
    status character(1),
    dt_inativacao timestamp without time zone,
    contrato_id integer,
    contrato_origem_id integer,
    CONSTRAINT eventos_parceiros_check_quantidade CHECK ((bonus_saldo > (0)::double precision))
);


--
-- Name: evento_reciclador_vigencias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_reciclador_vigencias_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_reciclador_vigencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_reciclador_vigencias (
    id integer DEFAULT nextval('public.evento_reciclador_vigencias_id_seq'::regclass) NOT NULL,
    evento_id integer NOT NULL,
    reciclador_id integer NOT NULL,
    vigencia_id integer NOT NULL,
    status character varying(1),
    data_cadastro timestamp without time zone DEFAULT now(),
    data_inativacao timestamp without time zone
);


--
-- Name: evento_recursos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evento_recursos (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    recurso_id integer NOT NULL,
    quantidade integer NOT NULL,
    valor integer NOT NULL,
    data_cadastro date NOT NULL,
    CONSTRAINT evento_recursos_check_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT evento_recursos_valor CHECK ((valor > 0))
);


--
-- Name: evento_recursos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evento_recursos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evento_recursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evento_recursos_id_seq OWNED BY public.evento_recursos.id;


--
-- Name: eventos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos (
    id integer NOT NULL,
    data_inicial timestamp without time zone NOT NULL,
    data_final timestamp without time zone NOT NULL,
    status character(1) NOT NULL,
    "qtdPlanejadoRefrigerador" integer,
    local_acao integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    acao_id integer NOT NULL,
    itinerante boolean DEFAULT false NOT NULL,
    modulo_id integer NOT NULL
);


--
-- Name: COLUMN eventos.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.eventos.status IS 'C = cadastro
E = entrega
F = finalizado';


--
-- Name: COLUMN eventos.itinerante; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.eventos.itinerante IS 'True = Sim, False = Não';


--
-- Name: eventos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_id_seq OWNED BY public.eventos.id;


--
-- Name: eventos_nota_saidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_nota_saidas (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    nota_saida_id integer NOT NULL
);


--
-- Name: eventos_nota_saidas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_nota_saidas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_nota_saidas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_nota_saidas_id_seq OWNED BY public.eventos_nota_saidas.id;


--
-- Name: eventos_reserva_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eventos_reserva_lampadas (
    id integer NOT NULL,
    evento_id integer NOT NULL,
    reserva_lampada_id integer NOT NULL
);


--
-- Name: eventos_reserva_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eventos_reserva_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: eventos_reserva_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eventos_reserva_lampadas_id_seq OWNED BY public.eventos_reserva_lampadas.id;


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: historicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historicos (
    id integer NOT NULL,
    data_inscricao date,
    nota_fiscal character varying(10),
    sucata character varying(200),
    refrigerador character varying(200),
    local_inscricao character varying(100),
    cliente_id integer NOT NULL,
    contrato_id integer NOT NULL,
    quantidade_lampadas integer,
    projeto_id integer,
    evento_id integer,
    responsavel_compra character varying(100),
    cpf_responsavel character(11),
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    venda_doacao_id integer,
    status character(1) DEFAULT 'B'::bpchar NOT NULL,
    modulo_id integer NOT NULL,
    doacao_lampada_id integer
);


--
-- Name: COLUMN historicos.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.historicos.status IS 'B = Bonificado - C = Cancelado';


--
-- Name: historico_ev_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historico_ev_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: historico_ev_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historico_ev_id_seq OWNED BY public.historicos.id;


--
-- Name: instituicaos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instituicaos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    bairro_id integer NOT NULL,
    contato character varying(100),
    uf_id integer NOT NULL,
    cidade_id integer NOT NULL,
    responsavel character varying(100),
    cnpj character varying(14) NOT NULL,
    telefone character varying(60),
    status character varying(1)
);


--
-- Name: instituicaos_contratos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.instituicaos_contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: instituicaos_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instituicaos_contratos (
    id integer DEFAULT nextval('public.instituicaos_contratos_id_seq'::regclass) NOT NULL,
    instituicao_id integer NOT NULL,
    contrato_id integer NOT NULL
);


--
-- Name: instituicaos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.instituicaos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: instituicaos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.instituicaos_id_seq OWNED BY public.instituicaos.id;


--
-- Name: item_resposta; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_resposta (
    tipo character varying,
    select_value character varying,
    comunidade_value character varying(50),
    cidade_value character varying(255),
    bairro_value character varying(255),
    plaintext_value character varying
);


--
-- Name: lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lampadas (
    id bigint NOT NULL,
    lampada_tipo_id integer,
    lampada_modelo_id integer,
    potencia double precision
);


--
-- Name: COLUMN lampadas.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas.id IS 'Tabela que assume o conjunto das informações, Tipo, Modelo, potência';


--
-- Name: COLUMN lampadas.lampada_tipo_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas.lampada_tipo_id IS 'FK para tipo de lâmpada';


--
-- Name: COLUMN lampadas.lampada_modelo_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas.lampada_modelo_id IS 'FK para modelo de lâmpada';


--
-- Name: COLUMN lampadas.potencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas.potencia IS 'valor para potência';


--
-- Name: lampadas_tipo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lampadas_tipo (
    id integer NOT NULL,
    descricao character varying(45) NOT NULL,
    troca character varying(1) DEFAULT 'N'::character varying,
    potencia character varying(10),
    CONSTRAINT troca_ck CHECK ((((troca)::text = 'S'::text) OR ((troca)::text = 'N'::text)))
);


--
-- Name: COLUMN lampadas_tipo.troca; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas_tipo.troca IS 'Campo para informar se a lâmpada é aceita para troca, devolução...utilizado inicialmente pleo Vale Luz';


--
-- Name: lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lampadas_id_seq OWNED BY public.lampadas_tipo.id;


--
-- Name: lampadas_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lampadas_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lampadas_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lampadas_id_seq1 OWNED BY public.lampadas.id;


--
-- Name: lampadas_modelo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lampadas_modelo (
    id integer NOT NULL,
    descricao character varying(45) NOT NULL
);


--
-- Name: TABLE lampadas_modelo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.lampadas_modelo IS 'Tabela que guarda as infomações dos modelos de lâmpadas possíveis: Tubular, Espiral, Bulbo';


--
-- Name: COLUMN lampadas_modelo.descricao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lampadas_modelo.descricao IS 'Nome do modelo';


--
-- Name: lampadas_modelo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lampadas_modelo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lampadas_modelo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lampadas_modelo_id_seq OWNED BY public.lampadas_modelo.id;


--
-- Name: localidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.localidades (
    id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: localidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.localidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: localidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.localidades_id_seq OWNED BY public.localidades.id;


--
-- Name: locals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locals (
    id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: locals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locals_id_seq OWNED BY public.locals.id;


--
-- Name: lock_monitor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.lock_monitor AS
 SELECT COALESCE(((blockingl.relation)::regclass)::text, blockingl.locktype) AS locked_item,
    (now() - blockeda.query_start) AS waiting_duration,
    blockeda.pid AS blocked_pid,
    blockeda.query AS blocked_query,
    blockedl.mode AS blocked_mode,
    blockinga.pid AS blocking_pid,
    blockinga.query AS blocking_query,
    blockingl.mode AS blocking_mode
   FROM (((pg_locks blockedl
     JOIN pg_stat_activity blockeda ON ((blockedl.pid = blockeda.pid)))
     JOIN pg_locks blockingl ON ((((blockingl.transactionid = blockedl.transactionid) OR ((blockingl.relation = blockedl.relation) AND (blockingl.locktype = blockedl.locktype))) AND (blockedl.pid <> blockingl.pid))))
     JOIN pg_stat_activity blockinga ON (((blockingl.pid = blockinga.pid) AND (blockinga.datid = blockeda.datid))))
  WHERE ((NOT blockedl.granted) AND (blockinga.datname = current_database()));


--
-- Name: log_chatbot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_chatbot (
    id bigint NOT NULL,
    req_palavra character varying(255) NOT NULL,
    intencao character varying(255) NOT NULL,
    resposta text NOT NULL,
    data_req timestamp without time zone NOT NULL,
    data_res timestamp without time zone NOT NULL,
    usuario_id integer
);


--
-- Name: log_chatbot_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_chatbot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_chatbot_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_chatbot_id_seq OWNED BY public.log_chatbot.id;


--
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id integer DEFAULT nextval('public.log_id_seq'::regclass) NOT NULL,
    nome_model character varying NOT NULL,
    data_alteracao timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_alteracao integer,
    descricao text,
    registro_id integer
);


--
-- Name: marca_refrigeradors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marca_refrigeradors (
    id integer NOT NULL,
    nome character varying(50) NOT NULL
);


--
-- Name: marca_refrigeradors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marca_refrigeradors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marca_refrigeradors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marca_refrigeradors_id_seq OWNED BY public.marca_refrigeradors.id;


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menus (
    id integer NOT NULL,
    controller character varying(50),
    action character varying(50),
    nome character varying(50) NOT NULL,
    imagem oid,
    menu_pai_id integer,
    nome_imagem character varying(100),
    parametros character varying(100)
);


--
-- Name: menus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menus_id_seq OWNED BY public.menus.id;


--
-- Name: menus_modulos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.menus_modulos (
    id integer NOT NULL,
    modulo_id integer NOT NULL,
    menu_id integer NOT NULL
);


--
-- Name: menus_projetos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.menus_projetos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: menus_projetos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.menus_projetos_id_seq OWNED BY public.menus_modulos.id;


--
-- Name: message_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_deliveries (
    id bigint NOT NULL,
    channel character varying NOT NULL,
    provider character varying NOT NULL,
    recipient character varying NOT NULL,
    deliverable_type character varying,
    deliverable_id bigint,
    subject character varying,
    body text,
    metadata jsonb DEFAULT '{}'::jsonb,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    attempts integer DEFAULT 0,
    external_id character varying,
    error_message text,
    delivered_at timestamp(6) without time zone,
    failed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: message_deliveries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.message_deliveries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_deliveries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.message_deliveries_id_seq OWNED BY public.message_deliveries.id;


--
-- Name: meta_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_lampadas (
    id integer NOT NULL,
    ano integer NOT NULL,
    lampada_id integer NOT NULL,
    tipo_cliente character varying(1) NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer NOT NULL,
    acao_id integer NOT NULL,
    CONSTRAINT unsigned_meta_lampadas_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT unsigned_meta_lampadas_quantidade_atual CHECK ((quantidade_atual >= 0))
);


--
-- Name: COLUMN meta_lampadas.tipo_cliente; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.meta_lampadas.tipo_cliente IS 'R = Residencial
B = Baixa renda';


--
-- Name: meta_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.meta_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meta_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.meta_lampadas_id_seq OWNED BY public.meta_lampadas.id;


--
-- Name: meta_refrigeradors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_refrigeradors (
    id integer NOT NULL,
    ano integer NOT NULL,
    refrigerador_id integer,
    tipo_cliente character varying(1) NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer NOT NULL,
    acao_id integer NOT NULL,
    equipamento_id integer,
    CONSTRAINT unsigned_meta_refrigeradors_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT unsigned_meta_refrigeradors_quantidade_atual CHECK ((quantidade_atual >= 0))
);


--
-- Name: COLUMN meta_refrigeradors.tipo_cliente; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.meta_refrigeradors.tipo_cliente IS 'R = Residencial
B = Baixa renda';


--
-- Name: meta_refrigeradors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.meta_refrigeradors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meta_refrigeradors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.meta_refrigeradors_id_seq OWNED BY public.meta_refrigeradors.id;


--
-- Name: metas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.metas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: metas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metas (
    id integer DEFAULT nextval('public.metas_id_seq'::regclass) NOT NULL,
    ano integer NOT NULL,
    periodo_inicial timestamp without time zone NOT NULL,
    periodo_final timestamp without time zone NOT NULL,
    modulo_id integer NOT NULL,
    acao_id integer NOT NULL,
    model character varying,
    registro_id integer,
    cliente_tipo character varying(1),
    previsto double precision NOT NULL,
    realizado double precision NOT NULL,
    data_cadastro timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT unsigned_metas_previsto CHECK ((previsto > (0)::double precision)),
    CONSTRAINT unsigned_metas_realizado CHECK ((realizado >= (0)::double precision))
);


--
-- Name: COLUMN metas.cliente_tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.metas.cliente_tipo IS 'R = Residencial
	B = Baixa renda';


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: models_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.models_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.models (
    id integer DEFAULT nextval('public.models_id_seq'::regclass) NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: modulos_projetos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modulos_projetos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: modulo_projetos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modulo_projetos (
    id integer DEFAULT nextval('public.modulos_projetos_id_seq'::regclass) NOT NULL,
    modulo_id integer NOT NULL,
    projeto_id integer NOT NULL
);


--
-- Name: modulos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modulos (
    id integer NOT NULL,
    nome character varying(50) NOT NULL,
    nome_imagem character varying(255) NOT NULL,
    nome_imagem_svg character varying(50),
    sigla character varying(10)
);


--
-- Name: modulos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.modulos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modulos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.modulos_id_seq OWNED BY public.modulos.id;


--
-- Name: n_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.n_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: n_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.n_log (
    id integer DEFAULT nextval('public.n_log_id_seq'::regclass) NOT NULL,
    model character varying NOT NULL,
    data_cadastro timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_id integer,
    descricao text,
    registro_id integer,
    tipo character(1),
    nome_log character(50),
    ip character varying(16)
);


--
-- Name: COLUMN n_log.tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.n_log.tipo IS 'I = INSERT, U = UPDATE, D = DELETE';


--
-- Name: nota_fabricantes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_fabricantes (
    id integer NOT NULL,
    numero character varying(20) NOT NULL,
    quantidade integer NOT NULL,
    data_emissao date NOT NULL,
    arquivo character varying(255) NOT NULL,
    refrigerador_id integer NOT NULL,
    quantidade_atual integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    CONSTRAINT unsigned_nota_fabricante_quantidade CHECK ((quantidade > 0))
);


--
-- Name: nota_fabricante_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nota_fabricante_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: nota_fabricante_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nota_fabricante_id_seq OWNED BY public.nota_fabricantes.id;


--
-- Name: nota_fabricantes_nota_saidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_fabricantes_nota_saidas (
    id integer NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer DEFAULT 0 NOT NULL,
    nota_saida_id integer NOT NULL,
    nota_fabricante_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    CONSTRAINT unsigned_nota_fabricantes_nota_saidas_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT unsigned_nota_fabricantes_nota_saidas_quantidade_atual CHECK ((quantidade_atual >= 0))
);


--
-- Name: nota_fabricantes_nota_saidas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nota_fabricantes_nota_saidas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: nota_fabricantes_nota_saidas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nota_fabricantes_nota_saidas_id_seq OWNED BY public.nota_fabricantes_nota_saidas.id;


--
-- Name: nota_saidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nota_saidas (
    id integer NOT NULL,
    numero character varying(20) NOT NULL,
    data_emissao date NOT NULL,
    projeto character(1),
    arquivo character varying(255) NOT NULL,
    qtd_nota_saida integer,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    status character varying(1) DEFAULT 'A'::character varying NOT NULL,
    CONSTRAINT unsigned_qtd_nota_saida CHECK ((qtd_nota_saida > 0))
);


--
-- Name: COLUMN nota_saidas.projeto; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.nota_saidas.projeto IS 'N = PNG
D = PDR';


--
-- Name: nota_saidas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nota_saidas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: nota_saidas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nota_saidas_id_seq OWNED BY public.nota_saidas.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id character varying(100) NOT NULL,
    user_id integer,
    client_id integer NOT NULL,
    name character varying(255),
    scopes text,
    revoked boolean NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone
);


--
-- Name: oauth_auth_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_auth_codes (
    id character varying(100) NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    scopes text,
    revoked boolean NOT NULL,
    expires_at timestamp(0) without time zone
);


--
-- Name: oauth_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_clients (
    id integer NOT NULL,
    user_id integer,
    name character varying(255) NOT NULL,
    secret character varying(100) NOT NULL,
    redirect text NOT NULL,
    personal_access_client boolean NOT NULL,
    password_client boolean NOT NULL,
    revoked boolean NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: oauth_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_clients_id_seq OWNED BY public.oauth_clients.id;


--
-- Name: oauth_personal_access_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_personal_access_clients (
    id integer NOT NULL,
    client_id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: oauth_personal_access_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_personal_access_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_personal_access_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_personal_access_clients_id_seq OWNED BY public.oauth_personal_access_clients.id;


--
-- Name: oauth_refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_refresh_tokens (
    id character varying(100) NOT NULL,
    access_token_id character varying(100) NOT NULL,
    revoked boolean NOT NULL,
    expires_at timestamp(0) without time zone
);


--
-- Name: parceiros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parceiros (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    bairro_id integer,
    contato character varying(100),
    uf_id integer,
    cidade_id integer,
    responsavel character varying(100),
    cnpj character varying(14),
    parceiro_tipo_id integer,
    status character varying(1)
);


--
-- Name: parceiros_contratos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parceiros_contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: parceiros_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parceiros_contratos (
    id integer DEFAULT nextval('public.parceiros_contratos_id_seq'::regclass) NOT NULL,
    parceiro_id integer NOT NULL,
    contrato_id integer NOT NULL
);


--
-- Name: parceiros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parceiros_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: parceiros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parceiros_id_seq OWNED BY public.parceiros.id;


--
-- Name: parceiros_tipos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parceiros_tipos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parceiros_tipos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parceiros_tipos (
    id integer DEFAULT nextval('public.parceiros_tipos_id_seq'::regclass) NOT NULL,
    status character varying(1) NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: perfil_permissao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfil_permissao (
    id integer NOT NULL,
    perfil_id integer,
    permissao_id integer
);


--
-- Name: perfil_permissao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfil_permissao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: perfil_permissao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfil_permissao_id_seq OWNED BY public.perfil_permissao.id;


--
-- Name: perfils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfils (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    status character varying(1) DEFAULT 'A'::character varying
);


--
-- Name: perfils_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfils_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: perfils_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfils_id_seq OWNED BY public.perfils.id;


--
-- Name: permissoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissoes (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    codigo character varying(50) NOT NULL
);


--
-- Name: permissoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissoes_id_seq OWNED BY public.permissoes.id;


--
-- Name: potencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.potencias (
    id bigint NOT NULL,
    nome character varying(5)
);


--
-- Name: COLUMN potencias.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.potencias.nome IS 'Descrição da potência da lâmpada';


--
-- Name: potencias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.potencias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: potencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.potencias_id_seq OWNED BY public.potencias.id;


--
-- Name: programacao_estabelecimentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programacao_estabelecimentos (
    id integer NOT NULL,
    data_inicial date NOT NULL,
    data_final date NOT NULL,
    estabelecimento_id integer NOT NULL
);


--
-- Name: programacao_estabelecimentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.programacao_estabelecimentos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: programacao_estabelecimentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.programacao_estabelecimentos_id_seq OWNED BY public.programacao_estabelecimentos.id;


--
-- Name: promotors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promotors (
    id integer NOT NULL,
    nome character varying(45) NOT NULL
);


--
-- Name: promotors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promotors_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: promotors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promotors_id_seq OWNED BY public.promotors.id;


--
-- Name: recicladors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recicladors_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: recicladors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recicladors (
    id integer DEFAULT nextval('public.recicladors_id_seq'::regclass) NOT NULL,
    nome character varying(100) NOT NULL,
    bairro_id integer,
    contato character varying(100),
    telefone character varying(60),
    uf_id integer,
    cidade_id integer,
    responsavel character varying(100),
    cnpj character varying(14),
    status character varying(1) DEFAULT 'A'::character varying
);


--
-- Name: reciclagem_integracao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reciclagem_integracao_id_seq
    START WITH 75
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reciclagem_integracao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reciclagem_integracao (
    id integer DEFAULT nextval('public.reciclagem_integracao_id_seq'::regclass) NOT NULL,
    sequencial integer NOT NULL,
    arquivo character varying(50) NOT NULL,
    status character varying(1) NOT NULL,
    qt_registros integer NOT NULL,
    bonus_total double precision NOT NULL,
    data_geracao timestamp without time zone,
    tipo character(1) NOT NULL
);


--
-- Name: reciclagem_recursos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reciclagem_recursos_id_seq
    START WITH 162065
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: reciclagem_recursos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reciclagem_recursos (
    id integer DEFAULT nextval('public.reciclagem_recursos_id_seq'::regclass) NOT NULL,
    reciclagem_id integer NOT NULL,
    recurso_id integer NOT NULL,
    quantidade numeric NOT NULL,
    bonus_valor double precision NOT NULL,
    reciclador_id integer,
    vigencia_id integer
);


--
-- Name: reciclagems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reciclagems_id_seq
    START WITH 11
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reciclagems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reciclagems (
    id integer DEFAULT nextval('public.reciclagems_id_seq'::regclass) NOT NULL,
    codigo character varying(255) NOT NULL,
    status character varying(1) NOT NULL,
    cliente_evento_contrato_id integer NOT NULL,
    bonus_total double precision NOT NULL,
    data_cadastro timestamp without time zone,
    bonus_percentual character varying(5) DEFAULT '100'::character varying NOT NULL,
    recibo_status character(20) DEFAULT NULL::bpchar,
    contrato_origem_id integer,
    veiculo_id integer,
    integracao_id integer
);


--
-- Name: COLUMN reciclagems.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reciclagems.status IS 'R = Recebido; T = Trasmitido; N = Não Trasmitido; X = Cancelado';


--
-- Name: recovery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recovery (
    id integer NOT NULL,
    type character varying(255) DEFAULT 'sms'::character varying NOT NULL,
    code character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity_id integer NOT NULL,
    entity text NOT NULL,
    used boolean DEFAULT false NOT NULL
);


--
-- Name: recovery_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recovery_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recovery_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recovery_id_seq OWNED BY public.recovery.id;


--
-- Name: recursos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recursos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    unidade_medida_id integer NOT NULL,
    tipo_recurso_id integer NOT NULL,
    data_cadastro date NOT NULL,
    status character varying(1) NOT NULL
);


--
-- Name: recursos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recursos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recursos_id_seq OWNED BY public.recursos.id;


--
-- Name: refrigeradors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refrigeradors (
    id integer NOT NULL,
    modelo character varying(30) NOT NULL,
    ativo integer DEFAULT 1 NOT NULL,
    tensao character(1),
    cor character varying(20),
    volume double precision,
    marca_refrigerador_id integer NOT NULL,
    tipo character varying(20),
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    equipamento_id integer DEFAULT 1 NOT NULL,
    valor_bonus integer,
    CONSTRAINT unsigned_refrigeradors_volume CHECK ((volume > (0)::double precision))
);


--
-- Name: COLUMN refrigeradors.modelo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.refrigeradors.modelo IS 'Nome do modelo da Geladeira. Ex: CRA30F, RCD37 ';


--
-- Name: COLUMN refrigeradors.tensao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.refrigeradors.tensao IS '1 = 110v
2 = 220v';


--
-- Name: COLUMN refrigeradors.tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.refrigeradors.tipo IS 'Simples,Duplex através de uma combo';


--
-- Name: refrigeradors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refrigeradors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refrigeradors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refrigeradors_id_seq OWNED BY public.refrigeradors.id;


--
-- Name: regionals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regionals (
    id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: regionals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regionals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regionals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regionals_id_seq OWNED BY public.regionals.id;


--
-- Name: reserva_lampada_vendas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reserva_lampada_vendas (
    id integer NOT NULL,
    venda_id integer NOT NULL,
    reserva_lampada_id integer NOT NULL,
    quantidade integer NOT NULL
);


--
-- Name: reserva_lampada_vendas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reserva_lampada_vendas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reserva_lampada_vendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reserva_lampada_vendas_id_seq OWNED BY public.reserva_lampada_vendas.id;


--
-- Name: reserva_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reserva_lampadas (
    id integer NOT NULL,
    numero character varying(10) NOT NULL,
    quantidade integer NOT NULL,
    quantidade_atual integer NOT NULL,
    lampada_id integer NOT NULL,
    projeto_id integer NOT NULL,
    status character varying(1) DEFAULT 'A'::character varying NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    quantidade_avaria integer DEFAULT 0 NOT NULL,
    doados integer DEFAULT 0 NOT NULL,
    CONSTRAINT unsigned_reserva_lampadas_quantidade CHECK ((quantidade > 0)),
    CONSTRAINT "unsigned_reserva_lampadas_quantidadeAtual" CHECK ((quantidade_atual >= 0))
);


--
-- Name: reserva_lampadas_doacao_lampadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reserva_lampadas_doacao_lampadas (
    id integer NOT NULL,
    doacao_lampada_id integer NOT NULL,
    reserva_lampada_id integer NOT NULL,
    quantidade integer NOT NULL
);


--
-- Name: reserva_lampadas_doacao_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reserva_lampadas_doacao_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: reserva_lampadas_doacao_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reserva_lampadas_doacao_lampadas_id_seq OWNED BY public.reserva_lampadas_doacao_lampadas.id;


--
-- Name: reserva_lampadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reserva_lampadas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: reserva_lampadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reserva_lampadas_id_seq OWNED BY public.reserva_lampadas.id;


--
-- Name: reserva_lampadas_vistoria_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reserva_lampadas_vistoria_pngd (
    id integer NOT NULL,
    vistoria_d_id integer NOT NULL,
    reserva_lampada_id integer NOT NULL,
    quantidade integer NOT NULL
);


--
-- Name: reserva_lampadas_vistoria_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reserva_lampadas_vistoria_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: reserva_lampadas_vistoria_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reserva_lampadas_vistoria_pngd_id_seq OWNED BY public.reserva_lampadas_vistoria_pngd.id;


--
-- Name: ruas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ruas (
    id integer NOT NULL,
    bairro_id integer NOT NULL,
    nome character varying(255) NOT NULL,
    cep character(8) NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: servicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    parceiro_id integer NOT NULL
);


--
-- Name: servicos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.servicos_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: servicos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.servicos_id_seq OWNED BY public.servicos.id;


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    concurrency_key character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    error text,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    class_name character varying NOT NULL,
    arguments text,
    priority integer DEFAULT 0 NOT NULL,
    active_job_id character varying,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    queue_name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    supervisor_id bigint,
    pid integer NOT NULL,
    hostname character varying,
    metadata text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    task_key character varying NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    key character varying NOT NULL,
    schedule character varying NOT NULL,
    command character varying(2048),
    class_name character varying,
    arguments text,
    queue_name character varying,
    priority integer DEFAULT 0,
    static boolean DEFAULT true NOT NULL,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    queue_name character varying NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    key character varying NOT NULL,
    value integer DEFAULT 1 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: sucata_entradas_itens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucata_entradas_itens (
    id integer NOT NULL,
    sucata_pngv_id integer,
    contrato_id integer,
    cliente_id integer,
    lote_id integer,
    sucata_pngd_id integer
);


--
-- Name: sucata_entradas_itens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucata_entradas_itens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucata_entradas_itens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucata_entradas_itens_id_seq OWNED BY public.sucata_entradas_itens.id;


--
-- Name: sucata_entradas_lote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucata_entradas_lote (
    id integer NOT NULL,
    numero_lote character varying(50),
    usuario_recebimento integer,
    parceiro_id integer,
    data_recebimento timestamp without time zone,
    situacao character varying(1) DEFAULT 'A'::"char",
    modulo_id integer
);


--
-- Name: sucata_entradas_lote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucata_entradas_lote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucata_entradas_lote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucata_entradas_lote_id_seq OWNED BY public.sucata_entradas_lote.id;


--
-- Name: sucata_saidas_itens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucata_saidas_itens (
    id integer NOT NULL,
    lote_id integer,
    item_entrada_id integer
);


--
-- Name: sucata_saidas_itens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucata_saidas_itens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucata_saidas_itens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucata_saidas_itens_id_seq OWNED BY public.sucata_saidas_itens.id;


--
-- Name: sucata_saidas_lote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucata_saidas_lote (
    id integer NOT NULL,
    numero_lote character varying(50),
    data_saida timestamp without time zone,
    usuario_saida integer,
    situacao character varying(1),
    parceiro_id integer,
    modulo_id integer
);


--
-- Name: sucata_saidas_lote_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucata_saidas_lote_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucata_saidas_lote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucata_saidas_lote_id_seq OWNED BY public.sucata_saidas_lote.id;


--
-- Name: sucatas_lampada_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucatas_lampada_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucatas_lampada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucatas_lampada (
    id bigint DEFAULT nextval('public.sucatas_lampada_id_seq'::regclass) NOT NULL,
    lampada_id integer NOT NULL,
    quantidade integer NOT NULL,
    doacao_lampada_id bigint NOT NULL,
    potencia integer
);


--
-- Name: COLUMN sucatas_lampada.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_lampada.id IS 'PK';


--
-- Name: COLUMN sucatas_lampada.lampada_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_lampada.lampada_id IS 'Lâmpada sucata usada na troca por novas no projeto Vale Luz';


--
-- Name: COLUMN sucatas_lampada.quantidade; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_lampada.quantidade IS 'Quantidade de lampadas trocadas';


--
-- Name: COLUMN sucatas_lampada.potencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_lampada.potencia IS 'descrição da potência, aceita apenas números';


--
-- Name: sucatas_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucatas_pngd (
    id integer NOT NULL,
    cor character varying(45) NOT NULL,
    estado_conservacao character varying(10) NOT NULL,
    triagem_d_id integer NOT NULL,
    marca_refrigerador_id integer NOT NULL,
    equipamento_id integer DEFAULT 1 NOT NULL,
    tipo character varying(15)
);


--
-- Name: COLUMN sucatas_pngd.estado_conservacao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_pngd.estado_conservacao IS 'Bom, Regular, Ruim';


--
-- Name: COLUMN sucatas_pngd.tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_pngd.tipo IS 'Simples, Duplex através de combos';


--
-- Name: sucatas_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucatas_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucatas_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucatas_pngd_id_seq OWNED BY public.sucatas_pngd.id;


--
-- Name: sucatas_pngv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sucatas_pngv (
    id integer NOT NULL,
    cor character varying(45) NOT NULL,
    estado_conservacao character varying(10) NOT NULL,
    triagem_pngv_id integer NOT NULL,
    equip_entregue character(1) DEFAULT 'N'::bpchar NOT NULL,
    data_recebimento date,
    marca_refrigerador_id integer NOT NULL,
    equipamento_id integer DEFAULT 1 NOT NULL,
    tipo character varying(20)
);


--
-- Name: COLUMN sucatas_pngv.estado_conservacao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_pngv.estado_conservacao IS 'B = Bom
R = Regular
U = Ruim';


--
-- Name: COLUMN sucatas_pngv.equip_entregue; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_pngv.equip_entregue IS 'S = Sim
N = Não';


--
-- Name: COLUMN sucatas_pngv.tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sucatas_pngv.tipo IS 'Simples, Duplex através de combos';


--
-- Name: sucatas_pngv_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sucatas_pngv_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: sucatas_pngv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sucatas_pngv_id_seq OWNED BY public.sucatas_pngv.id;


--
-- Name: tipo_acaos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_acaos (
    id integer NOT NULL,
    nome character varying(50) NOT NULL
);


--
-- Name: tipo_acaos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_acaos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_acaos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_acaos_id_seq OWNED BY public.tipo_acaos.id;


--
-- Name: tipo_recursos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_recursos (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    indice double precision
);


--
-- Name: tipo_recursos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_recursos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_recursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_recursos_id_seq OWNED BY public.tipo_recursos.id;


--
-- Name: tipo_veiculo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_veiculo (
    id bigint NOT NULL,
    descricao character varying(200) NOT NULL,
    status boolean DEFAULT true NOT NULL,
    is_editable boolean DEFAULT true NOT NULL,
    data_cadastro timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: tipo_veiculo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_veiculo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_veiculo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_veiculo_id_seq OWNED BY public.tipo_veiculo.id;


--
-- Name: tipos_acaos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_acaos (
    id integer NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: tipos_acaos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_acaos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_acaos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_acaos_id_seq OWNED BY public.tipos_acaos.id;


--
-- Name: triagem_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.triagem_pngd (
    id integer NOT NULL,
    data_ultima_fatura date NOT NULL,
    pendencia character(1),
    possui_nis character(1) NOT NULL,
    consumo1 double precision NOT NULL,
    consumo2 double precision NOT NULL,
    consumo3 double precision NOT NULL,
    data_cadastro date DEFAULT ('now'::text)::date NOT NULL,
    observacoes text,
    validado character(1) DEFAULT 'N'::bpchar NOT NULL,
    cliente_evento_contrato_id integer NOT NULL,
    negociado character(1),
    nis character(11),
    CONSTRAINT triagem_pngd_consumos_check CHECK (((consumo1 >= (0)::double precision) AND (consumo2 >= (0)::double precision) AND (consumo3 >= (0)::double precision))),
    CONSTRAINT triagem_pngd_negociado_check CHECK ((negociado = ANY (ARRAY['S'::bpchar, 'N'::bpchar])))
);


--
-- Name: COLUMN triagem_pngd.pendencia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngd.pendencia IS 'S = Sim
N = Não';


--
-- Name: COLUMN triagem_pngd.possui_nis; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngd.possui_nis IS 'S = Sim
N = Não';


--
-- Name: COLUMN triagem_pngd.validado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngd.validado IS 'S = Sim
N = Não';


--
-- Name: COLUMN triagem_pngd.negociado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngd.negociado IS 'S - Participante que está em negociação. É apenas demonstrativo
N - Indica Participante não está em negociação';


--
-- Name: triagem_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.triagem_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: triagem_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.triagem_pngd_id_seq OWNED BY public.triagem_pngd.id;


--
-- Name: triagem_pngv; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.triagem_pngv (
    id integer NOT NULL,
    possui_nis character(1) NOT NULL,
    consumo1 double precision NOT NULL,
    consumo2 double precision NOT NULL,
    consumo3 double precision NOT NULL,
    situacao_nis character(1),
    situacao_cliente character(1) NOT NULL,
    "dataUltimoConsumo" date NOT NULL,
    estabelecimento_id integer,
    negociado character(1),
    cliente_contrato_projeto_id integer NOT NULL,
    nis character(11),
    nota_fiscal character(20),
    data_emissao date,
    compra_direta character(1),
    CONSTRAINT triagem_pngv_consumos_check CHECK (((consumo1 >= (0)::double precision) AND (consumo2 >= (0)::double precision) AND (consumo3 >= (0)::double precision))),
    CONSTRAINT triagem_pngv_negociado_check CHECK ((negociado = ANY (ARRAY['S'::bpchar, 'N'::bpchar])))
);


--
-- Name: COLUMN triagem_pngv.possui_nis; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngv.possui_nis IS 'S = sim
N = não';


--
-- Name: COLUMN triagem_pngv.situacao_nis; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngv.situacao_nis IS 'V = válido
I = Inválido';


--
-- Name: COLUMN triagem_pngv.situacao_cliente; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngv.situacao_cliente IS 'A = apto
I = inapto';


--
-- Name: COLUMN triagem_pngv.negociado; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngv.negociado IS 'S - É um participante que foi negociado;
N - Paciente não Negociado.';


--
-- Name: COLUMN triagem_pngv.compra_direta; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.triagem_pngv.compra_direta IS 'S = sim
N = não';


--
-- Name: triagem_pngv_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.triagem_pngv_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: triagem_pngv_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.triagem_pngv_id_seq OWNED BY public.triagem_pngv.id;


--
-- Name: ufs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ufs (
    id integer NOT NULL,
    sigla character(2) NOT NULL,
    nome character varying(255) NOT NULL
);


--
-- Name: unidade_medidas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unidade_medidas (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    sigla character(4)
);


--
-- Name: unidade_medidas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unidade_medidas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unidade_medidas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unidade_medidas_id_seq OWNED BY public.unidade_medidas.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    login character varying(20) NOT NULL,
    senha character(64) NOT NULL,
    perfil_id integer,
    nome character varying(45) NOT NULL,
    status character varying(1) DEFAULT 'A'::character varying NOT NULL,
    email character varying(255),
    push_token character varying(255) DEFAULT NULL::character varying,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone
);


--
-- Name: COLUMN usuarios.push_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usuarios.push_token IS 'Código para mensagens push do app';


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: veiculo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.veiculo (
    id bigint NOT NULL,
    ano numeric(4,0),
    tipo_veiculo_id integer NOT NULL,
    modelo character varying(100) NOT NULL,
    marca character varying(20) NOT NULL,
    placa character varying(7) NOT NULL,
    status boolean DEFAULT true NOT NULL,
    is_editable boolean DEFAULT true NOT NULL,
    data_cadastro timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: veiculo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.veiculo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: veiculo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.veiculo_id_seq OWNED BY public.veiculo.id;


--
-- Name: venda_historicos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venda_historicos (
    id bigint NOT NULL,
    vendas_id integer NOT NULL,
    data_alteracao timestamp with time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    usuario_alteracao integer,
    descricao text
);


--
-- Name: vendas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendas (
    id integer NOT NULL,
    "nomeResponsavel" character varying(45) NOT NULL,
    "cpfResponsavel" character(11) NOT NULL,
    data timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    "numeroPedidoCompra" character varying(45),
    observacao text,
    lampada_id integer NOT NULL,
    estabelecimento_id integer NOT NULL,
    refrigerador_id integer NOT NULL,
    sucata_pngv_id integer NOT NULL,
    status character(1) DEFAULT 'P'::bpchar NOT NULL,
    quantidade_lampadas integer,
    usuario_id integer NOT NULL,
    nota_fiscal character varying(20),
    numero_cartao character(20),
    valor_bonus integer,
    motivo_cancelamento text,
    data_cancelamento timestamp with time zone
);


--
-- Name: COLUMN vendas.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vendas.status IS 'P = Pendente
B = Bonificado
R = Resolvido';


--
-- Name: vendas_historico_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendas_historico_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendas_historico_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendas_historico_id_seq OWNED BY public.venda_historicos.id;


--
-- Name: vendas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendas_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: vendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendas_id_seq OWNED BY public.vendas.id;


--
-- Name: vigencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vigencias (
    id integer NOT NULL,
    data_inicial date NOT NULL,
    data_final date,
    valor double precision NOT NULL,
    registro_id integer NOT NULL,
    status character varying(1) NOT NULL,
    model character(90),
    CONSTRAINT check_vigencia_valor CHECK (
CASE model
    WHEN 'Recurso'::bpchar THEN (valor > (0)::double precision)
    ELSE NULL::boolean
END)
);


--
-- Name: vigencias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vigencias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vigencias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vigencias_id_seq OWNED BY public.vigencias.id;


--
-- Name: vistoria_pngd; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vistoria_pngd (
    id integer NOT NULL,
    numero_sequencial character varying(20) NOT NULL,
    numero_serie character varying(20) NOT NULL,
    triagem_d_id integer NOT NULL,
    nota_fabricante_nota_saida_id integer NOT NULL,
    quantidade_lampadas integer NOT NULL,
    usuario_id integer NOT NULL,
    data_cadastro timestamp without time zone DEFAULT timezone('BRT'::text, now()) NOT NULL,
    remover_kit character varying(1) DEFAULT 'S'::character varying NOT NULL
);


--
-- Name: vistoria_pngd_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vistoria_pngd_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


--
-- Name: vistoria_pngd_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vistoria_pngd_id_seq OWNED BY public.vistoria_pngd.id;


--
-- Name: acaos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acaos ALTER COLUMN id SET DEFAULT nextval('public.acaos_id_seq'::regclass);


--
-- Name: agendamentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agendamentos ALTER COLUMN id SET DEFAULT nextval('public.agendamentos_id_seq'::regclass);


--
-- Name: arquivos_eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_eventos ALTER COLUMN id SET DEFAULT nextval('public.arquivos_eventos_id_seq'::regclass);


--
-- Name: arquivos_triagem_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagem_pngd ALTER COLUMN id SET DEFAULT nextval('public.arquivos_triagem_pngd_id_seq'::regclass);


--
-- Name: arquivos_triagems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagems ALTER COLUMN id SET DEFAULT nextval('public.arquivos_triagems_id_seq'::regclass);


--
-- Name: arquivos_vendas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vendas ALTER COLUMN id SET DEFAULT nextval('public.arquivos_vendas_id_seq'::regclass);


--
-- Name: arquivos_vistoria_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vistoria_pngd ALTER COLUMN id SET DEFAULT nextval('public.arquivos_vistoria_pngd_id_seq'::regclass);


--
-- Name: b_i_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.b_i_forms ALTER COLUMN id SET DEFAULT nextval('public.b_i_forms_id_seq'::regclass);


--
-- Name: bi_contratos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_contratos ALTER COLUMN id SET DEFAULT nextval('public.bi_contratos_id_seq'::regclass);


--
-- Name: bi_form_item_bairros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_bairros ALTER COLUMN id SET DEFAULT nextval('public.bi_form_item_bairros_id_seq'::regclass);


--
-- Name: bi_form_item_cidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_cidades ALTER COLUMN id SET DEFAULT nextval('public.bi_form_item_cidades_id_seq'::regclass);


--
-- Name: bi_form_item_comunidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_comunidades ALTER COLUMN id SET DEFAULT nextval('public.bi_form_item_comunidades_id_seq'::regclass);


--
-- Name: bi_form_item_respostas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas ALTER COLUMN id SET DEFAULT nextval('public.bi_form_item_resposta_id_seq'::regclass);


--
-- Name: bi_form_item_selects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_selects ALTER COLUMN id SET DEFAULT nextval('public.bi_form_item_selects_id_seq'::regclass);


--
-- Name: bi_form_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_items ALTER COLUMN id SET DEFAULT nextval('public.bi_form_items_id_seq'::regclass);


--
-- Name: bi_form_resposta_reciclagens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_resposta_reciclagens ALTER COLUMN id SET DEFAULT nextval('public.bi_form_resposta_reciclagens_id_seq'::regclass);


--
-- Name: bi_form_respostas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_respostas ALTER COLUMN id SET DEFAULT nextval('public.bi_form_resposta_id_seq'::regclass);


--
-- Name: bi_form_steppers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_steppers ALTER COLUMN id SET DEFAULT nextval('public.bi_form_steppers_id_seq'::regclass);


--
-- Name: bi_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_forms ALTER COLUMN id SET DEFAULT nextval('public.bi_forms_id_seq'::regclass);


--
-- Name: bi_metas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_metas ALTER COLUMN id SET DEFAULT nextval('public.bi_metas_id_seq'::regclass);


--
-- Name: cliente_estabelecimento_entregas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_estabelecimento_entregas ALTER COLUMN id SET DEFAULT nextval('public.clientes_estabelecimento_entregas_id_seq'::regclass);


--
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- Name: clientes_contratos_projetos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_contratos_projetos ALTER COLUMN id SET DEFAULT nextval('public.clientes_contratos_projetos_id_seq'::regclass);


--
-- Name: clientes_evento_entregas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas ALTER COLUMN id SET DEFAULT nextval('public.clientes_evento_entregas_id_seq'::regclass);


--
-- Name: clientes_eventos_contratos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos ALTER COLUMN id SET DEFAULT nextval('public.clientes_eventos_id_seq'::regclass);


--
-- Name: comunidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades ALTER COLUMN id SET DEFAULT nextval('public.comunidades_id_seq'::regclass);


--
-- Name: comunidades_tipos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades_tipos ALTER COLUMN id SET DEFAULT nextval('public.comunidades_tipos_id_seq'::regclass);


--
-- Name: contratos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos ALTER COLUMN id SET DEFAULT nextval('public.contratos_id_seq'::regclass);


--
-- Name: doacao_historicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_historicos ALTER COLUMN id SET DEFAULT nextval('public.doacao_historico_id_seq'::regclass);


--
-- Name: doacao_lampada_historicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampada_historicos ALTER COLUMN id SET DEFAULT nextval('public.doacao_lampada_historicos_id_seq'::regclass);


--
-- Name: doacao_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas ALTER COLUMN id SET DEFAULT nextval('public.doacao_lampadas_id_seq'::regclass);


--
-- Name: equipamentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipamentos ALTER COLUMN id SET DEFAULT nextval('public.equipamentos_id_seq'::regclass);


--
-- Name: esqueci_senha id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esqueci_senha ALTER COLUMN id SET DEFAULT nextval('public.esqueci_senha_id_seq'::regclass);


--
-- Name: estabelecimento_entregas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimento_entregas ALTER COLUMN id SET DEFAULT nextval('public.estabelecimento_entregas_id_seq'::regclass);


--
-- Name: estabelecimentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimentos ALTER COLUMN id SET DEFAULT nextval('public.estabelecimentos_id_seq'::regclass);


--
-- Name: evento_entrega_nota_saidas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entrega_nota_saidas ALTER COLUMN id SET DEFAULT nextval('public.evento_entregas_nota_saidas_id_seq'::regclass);


--
-- Name: evento_entregas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas ALTER COLUMN id SET DEFAULT nextval('public.evento_entregas_id_seq'::regclass);


--
-- Name: evento_escalacaos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_escalacaos ALTER COLUMN id SET DEFAULT nextval('public.evento_escalacaos_id_seq'::regclass);


--
-- Name: evento_historicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_historicos ALTER COLUMN id SET DEFAULT nextval('public.evento_historicos_id_seq'::regclass);


--
-- Name: evento_horario_ecopontos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_horario_ecopontos ALTER COLUMN id SET DEFAULT nextval('public.evento_horario_ecopontos_id_seq'::regclass);


--
-- Name: evento_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas ALTER COLUMN id SET DEFAULT nextval('public.evento_lampadas_id_seq'::regclass);


--
-- Name: evento_recursos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_recursos ALTER COLUMN id SET DEFAULT nextval('public.evento_recursos_id_seq'::regclass);


--
-- Name: eventos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos ALTER COLUMN id SET DEFAULT nextval('public.eventos_id_seq'::regclass);


--
-- Name: eventos_nota_saidas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nota_saidas ALTER COLUMN id SET DEFAULT nextval('public.eventos_nota_saidas_id_seq'::regclass);


--
-- Name: eventos_reserva_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reserva_lampadas ALTER COLUMN id SET DEFAULT nextval('public.eventos_reserva_lampadas_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: historicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos ALTER COLUMN id SET DEFAULT nextval('public.historico_ev_id_seq'::regclass);


--
-- Name: instituicaos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos ALTER COLUMN id SET DEFAULT nextval('public.instituicaos_id_seq'::regclass);


--
-- Name: lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas ALTER COLUMN id SET DEFAULT nextval('public.lampadas_id_seq1'::regclass);


--
-- Name: lampadas_modelo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas_modelo ALTER COLUMN id SET DEFAULT nextval('public.lampadas_modelo_id_seq'::regclass);


--
-- Name: lampadas_tipo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas_tipo ALTER COLUMN id SET DEFAULT nextval('public.lampadas_id_seq'::regclass);


--
-- Name: localidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades ALTER COLUMN id SET DEFAULT nextval('public.localidades_id_seq'::regclass);


--
-- Name: locals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locals ALTER COLUMN id SET DEFAULT nextval('public.locals_id_seq'::regclass);


--
-- Name: log_chatbot id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_chatbot ALTER COLUMN id SET DEFAULT nextval('public.log_chatbot_id_seq'::regclass);


--
-- Name: marca_refrigeradors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marca_refrigeradors ALTER COLUMN id SET DEFAULT nextval('public.marca_refrigeradors_id_seq'::regclass);


--
-- Name: menus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus ALTER COLUMN id SET DEFAULT nextval('public.menus_id_seq'::regclass);


--
-- Name: menus_modulos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_modulos ALTER COLUMN id SET DEFAULT nextval('public.menus_projetos_id_seq'::regclass);


--
-- Name: menus_perfils id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_perfils ALTER COLUMN id SET DEFAULT nextval('public."MenuPerfils_id_seq"'::regclass);


--
-- Name: message_deliveries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_deliveries ALTER COLUMN id SET DEFAULT nextval('public.message_deliveries_id_seq'::regclass);


--
-- Name: meta_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_lampadas ALTER COLUMN id SET DEFAULT nextval('public.meta_lampadas_id_seq'::regclass);


--
-- Name: meta_refrigeradors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors ALTER COLUMN id SET DEFAULT nextval('public.meta_refrigeradors_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: modulos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulos ALTER COLUMN id SET DEFAULT nextval('public.modulos_id_seq'::regclass);


--
-- Name: nota_fabricantes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes ALTER COLUMN id SET DEFAULT nextval('public.nota_fabricante_id_seq'::regclass);


--
-- Name: nota_fabricantes_nota_saidas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes_nota_saidas ALTER COLUMN id SET DEFAULT nextval('public.nota_fabricantes_nota_saidas_id_seq'::regclass);


--
-- Name: nota_saidas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saidas ALTER COLUMN id SET DEFAULT nextval('public.nota_saidas_id_seq'::regclass);


--
-- Name: oauth_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_clients ALTER COLUMN id SET DEFAULT nextval('public.oauth_clients_id_seq'::regclass);


--
-- Name: oauth_personal_access_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_personal_access_clients ALTER COLUMN id SET DEFAULT nextval('public.oauth_personal_access_clients_id_seq'::regclass);


--
-- Name: parceiros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros ALTER COLUMN id SET DEFAULT nextval('public.parceiros_id_seq'::regclass);


--
-- Name: perfil_permissao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissao ALTER COLUMN id SET DEFAULT nextval('public.perfil_permissao_id_seq'::regclass);


--
-- Name: perfils id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils ALTER COLUMN id SET DEFAULT nextval('public.perfils_id_seq'::regclass);


--
-- Name: perfils_modulos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils_modulos ALTER COLUMN id SET DEFAULT nextval('public."PerfilProjetos_id_seq"'::regclass);


--
-- Name: permissoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissoes ALTER COLUMN id SET DEFAULT nextval('public.permissoes_id_seq'::regclass);


--
-- Name: potencias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.potencias ALTER COLUMN id SET DEFAULT nextval('public.potencias_id_seq'::regclass);


--
-- Name: programacao_estabelecimentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programacao_estabelecimentos ALTER COLUMN id SET DEFAULT nextval('public.programacao_estabelecimentos_id_seq'::regclass);


--
-- Name: projetos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projetos ALTER COLUMN id SET DEFAULT nextval('public."Projetos_id_seq"'::regclass);


--
-- Name: promotors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotors ALTER COLUMN id SET DEFAULT nextval('public.promotors_id_seq'::regclass);


--
-- Name: recovery id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recovery ALTER COLUMN id SET DEFAULT nextval('public.recovery_id_seq'::regclass);


--
-- Name: recursos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recursos ALTER COLUMN id SET DEFAULT nextval('public.recursos_id_seq'::regclass);


--
-- Name: refrigeradors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refrigeradors ALTER COLUMN id SET DEFAULT nextval('public.refrigeradors_id_seq'::regclass);


--
-- Name: regionals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regionals ALTER COLUMN id SET DEFAULT nextval('public.regionals_id_seq'::regclass);


--
-- Name: reserva_lampada_vendas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampada_vendas ALTER COLUMN id SET DEFAULT nextval('public.reserva_lampada_vendas_id_seq'::regclass);


--
-- Name: reserva_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas ALTER COLUMN id SET DEFAULT nextval('public.reserva_lampadas_id_seq'::regclass);


--
-- Name: reserva_lampadas_doacao_lampadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_doacao_lampadas ALTER COLUMN id SET DEFAULT nextval('public.reserva_lampadas_doacao_lampadas_id_seq'::regclass);


--
-- Name: reserva_lampadas_vistoria_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_vistoria_pngd ALTER COLUMN id SET DEFAULT nextval('public.reserva_lampadas_vistoria_pngd_id_seq'::regclass);


--
-- Name: servicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicos ALTER COLUMN id SET DEFAULT nextval('public.servicos_id_seq'::regclass);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: sucata_entradas_itens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens ALTER COLUMN id SET DEFAULT nextval('public.sucata_entradas_itens_id_seq'::regclass);


--
-- Name: sucata_entradas_lote id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote ALTER COLUMN id SET DEFAULT nextval('public.sucata_entradas_lote_id_seq'::regclass);


--
-- Name: sucata_saidas_itens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_itens ALTER COLUMN id SET DEFAULT nextval('public.sucata_saidas_itens_id_seq'::regclass);


--
-- Name: sucata_saidas_lote id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote ALTER COLUMN id SET DEFAULT nextval('public.sucata_saidas_lote_id_seq'::regclass);


--
-- Name: sucatas_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd ALTER COLUMN id SET DEFAULT nextval('public.sucatas_pngd_id_seq'::regclass);


--
-- Name: sucatas_pngv id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngv ALTER COLUMN id SET DEFAULT nextval('public.sucatas_pngv_id_seq'::regclass);


--
-- Name: tipo_acaos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_acaos ALTER COLUMN id SET DEFAULT nextval('public.tipo_acaos_id_seq'::regclass);


--
-- Name: tipo_recursos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_recursos ALTER COLUMN id SET DEFAULT nextval('public.tipo_recursos_id_seq'::regclass);


--
-- Name: tipo_veiculo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_veiculo ALTER COLUMN id SET DEFAULT nextval('public.tipo_veiculo_id_seq'::regclass);


--
-- Name: tipos_acaos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_acaos ALTER COLUMN id SET DEFAULT nextval('public.tipos_acaos_id_seq'::regclass);


--
-- Name: triagem_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngd ALTER COLUMN id SET DEFAULT nextval('public.triagem_pngd_id_seq'::regclass);


--
-- Name: triagem_pngv id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngv ALTER COLUMN id SET DEFAULT nextval('public.triagem_pngv_id_seq'::regclass);


--
-- Name: unidade_medidas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidade_medidas ALTER COLUMN id SET DEFAULT nextval('public.unidade_medidas_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: veiculo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.veiculo ALTER COLUMN id SET DEFAULT nextval('public.veiculo_id_seq'::regclass);


--
-- Name: venda_historicos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_historicos ALTER COLUMN id SET DEFAULT nextval('public.vendas_historico_id_seq'::regclass);


--
-- Name: vendas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas ALTER COLUMN id SET DEFAULT nextval('public.vendas_id_seq'::regclass);


--
-- Name: vigencias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vigencias ALTER COLUMN id SET DEFAULT nextval('public.vigencias_id_seq'::regclass);


--
-- Name: vistoria_pngd id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd ALTER COLUMN id SET DEFAULT nextval('public.vistoria_pngd_id_seq'::regclass);


--
-- Name: recovery PK_47b2530af2d597ff1b210847140; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recovery
    ADD CONSTRAINT "PK_47b2530af2d597ff1b210847140" PRIMARY KEY (id);


--
-- Name: log_chatbot PK_7fc608fae28c583b23eb9dda5b7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_chatbot
    ADD CONSTRAINT "PK_7fc608fae28c583b23eb9dda5b7" PRIMARY KEY (id);


--
-- Name: perfil_permissao PK_9746d9535955bc7115726a86ace; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissao
    ADD CONSTRAINT "PK_9746d9535955bc7115726a86ace" PRIMARY KEY (id);


--
-- Name: permissoes PK_b7a10ac8cfae51fca698df8528d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissoes
    ADD CONSTRAINT "PK_b7a10ac8cfae51fca698df8528d" PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: arquivos_eventos arquivos_eventos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_eventos
    ADD CONSTRAINT arquivos_eventos_pkey PRIMARY KEY (id);


--
-- Name: arquivos_vendas arquivos_venda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vendas
    ADD CONSTRAINT arquivos_venda_pkey PRIMARY KEY (id);


--
-- Name: b_i_forms b_i_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.b_i_forms
    ADD CONSTRAINT b_i_forms_pkey PRIMARY KEY (id);


--
-- Name: bi_contratos bi_contratos_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_contratos
    ADD CONSTRAINT bi_contratos_pk PRIMARY KEY (id);


--
-- Name: bi_form_item_bairros bi_form_item_bairros_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_bairros
    ADD CONSTRAINT bi_form_item_bairros_pk PRIMARY KEY (id);


--
-- Name: bi_form_item_cidades bi_form_item_cidades_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_cidades
    ADD CONSTRAINT bi_form_item_cidades_pk PRIMARY KEY (id);


--
-- Name: bi_form_item_comunidades bi_form_item_comunidades_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_comunidades
    ADD CONSTRAINT bi_form_item_comunidades_pk PRIMARY KEY (id);


--
-- Name: bi_form_item_respostas bi_form_item_resposta_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_resposta_pk PRIMARY KEY (id);


--
-- Name: bi_form_item_respostas bi_form_item_respostas_bi_form_item_id_bi_form_resposta_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_respostas_bi_form_item_id_bi_form_resposta_id_key UNIQUE (bi_form_item_id, bi_form_resposta_id);


--
-- Name: bi_form_item_selects bi_form_item_selects_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_selects
    ADD CONSTRAINT bi_form_item_selects_pk PRIMARY KEY (id);


--
-- Name: bi_form_items bi_form_items_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_items
    ADD CONSTRAINT bi_form_items_pk PRIMARY KEY (id);


--
-- Name: bi_form_respostas bi_form_resposta_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_respostas
    ADD CONSTRAINT bi_form_resposta_pk PRIMARY KEY (id);


--
-- Name: bi_form_resposta_reciclagens bi_form_resposta_reciclagens_bi_resposta_id_uk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_resposta_reciclagens
    ADD CONSTRAINT bi_form_resposta_reciclagens_bi_resposta_id_uk UNIQUE (bi_resposta_id);


--
-- Name: bi_form_resposta_reciclagens bi_form_resposta_reciclagens_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_resposta_reciclagens
    ADD CONSTRAINT bi_form_resposta_reciclagens_pk PRIMARY KEY (id);


--
-- Name: bi_form_resposta_reciclagens bi_form_resposta_reciclagens_reciclagem_id_uk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_resposta_reciclagens
    ADD CONSTRAINT bi_form_resposta_reciclagens_reciclagem_id_uk UNIQUE (reciclagem_id);


--
-- Name: bi_form_steppers bi_form_steppers_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_steppers
    ADD CONSTRAINT bi_form_steppers_pk PRIMARY KEY (id);


--
-- Name: bi_forms bi_forms_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_forms
    ADD CONSTRAINT bi_forms_pk PRIMARY KEY (id);


--
-- Name: bi_metas bi_metas_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_metas
    ADD CONSTRAINT bi_metas_pk PRIMARY KEY (id);


--
-- Name: comunidades comunidades_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades
    ADD CONSTRAINT comunidades_nome_key UNIQUE (nome);


--
-- Name: comunidades_tipos comunidades_tipos_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades_tipos
    ADD CONSTRAINT comunidades_tipos_pk PRIMARY KEY (id);


--
-- Name: doacao_historicos doacao_historico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_historicos
    ADD CONSTRAINT doacao_historico_pkey PRIMARY KEY (id);


--
-- Name: equipamentos equipamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipamentos
    ADD CONSTRAINT equipamentos_pkey PRIMARY KEY (id);


--
-- Name: esqueci_senha esqueci_senha_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esqueci_senha
    ADD CONSTRAINT esqueci_senha_pkey PRIMARY KEY (id);


--
-- Name: evento_entrega_nota_saidas evento_entregas_nota_saidas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entrega_nota_saidas
    ADD CONSTRAINT evento_entregas_nota_saidas_pkey PRIMARY KEY (id);


--
-- Name: evento_escalacaos evento_escalacaos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_escalacaos
    ADD CONSTRAINT evento_escalacaos_pkey PRIMARY KEY (id);


--
-- Name: evento_lampadas evento_lampadas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas
    ADD CONSTRAINT evento_lampadas_pkey PRIMARY KEY (id);


--
-- Name: evento_historicos eventos_historico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_historicos
    ADD CONSTRAINT eventos_historico_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: evento_horario_ecopontos horario_ecopontos_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_horario_ecopontos
    ADD CONSTRAINT horario_ecopontos_pk PRIMARY KEY (id);


--
-- Name: lampadas lamp_tipo_modelo_potencia_uk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas
    ADD CONSTRAINT lamp_tipo_modelo_potencia_uk UNIQUE (lampada_tipo_id, lampada_modelo_id, potencia);


--
-- Name: lampadas lampadas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas
    ADD CONSTRAINT lampadas_pkey PRIMARY KEY (id);


--
-- Name: localidades localidades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT localidades_pkey PRIMARY KEY (id);


--
-- Name: locals locals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locals
    ADD CONSTRAINT locals_pkey PRIMARY KEY (id);


--
-- Name: logs log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- Name: message_deliveries message_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_deliveries
    ADD CONSTRAINT message_deliveries_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: n_log n_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n_log
    ADD CONSTRAINT n_log_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_auth_codes oauth_auth_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_auth_codes
    ADD CONSTRAINT oauth_auth_codes_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_personal_access_clients oauth_personal_access_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_personal_access_clients
    ADD CONSTRAINT oauth_personal_access_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_refresh_tokens oauth_refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_refresh_tokens
    ADD CONSTRAINT oauth_refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: acaos pk_acaos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acaos
    ADD CONSTRAINT pk_acaos PRIMARY KEY (id);


--
-- Name: agendamentos pk_agendamentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agendamentos
    ADD CONSTRAINT pk_agendamentos PRIMARY KEY (id);


--
-- Name: arquivos pk_arquivos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos
    ADD CONSTRAINT pk_arquivos PRIMARY KEY (id);


--
-- Name: arquivos_triagem_pngd pk_arquivos_triagem_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagem_pngd
    ADD CONSTRAINT pk_arquivos_triagem_pngd PRIMARY KEY (id);


--
-- Name: arquivos_triagems pk_arquivos_triagems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagems
    ADD CONSTRAINT pk_arquivos_triagems PRIMARY KEY (id);


--
-- Name: arquivos_vistoria_pngd pk_arquivos_vistoria_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vistoria_pngd
    ADD CONSTRAINT pk_arquivos_vistoria_pngd PRIMARY KEY (id);


--
-- Name: bairros pk_bairros; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bairros
    ADD CONSTRAINT pk_bairros PRIMARY KEY (id);


--
-- Name: campanhas pk_campanhas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campanhas
    ADD CONSTRAINT pk_campanhas PRIMARY KEY (id);


--
-- Name: cidades pk_cidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cidades
    ADD CONSTRAINT pk_cidades PRIMARY KEY (id);


--
-- Name: clientes pk_clientes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT pk_clientes PRIMARY KEY (id);


--
-- Name: cliente_estabelecimento_entregas pk_clientes_estabelecimento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_estabelecimento_entregas
    ADD CONSTRAINT pk_clientes_estabelecimento_entregas PRIMARY KEY (id);


--
-- Name: clientes_evento_entregas pk_clientes_evento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas
    ADD CONSTRAINT pk_clientes_evento_entregas PRIMARY KEY (id);


--
-- Name: clientes_eventos_contratos pk_clientes_eventos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT pk_clientes_eventos PRIMARY KEY (id);


--
-- Name: clientes_contratos_projetos pk_clientes_projetos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_contratos_projetos
    ADD CONSTRAINT pk_clientes_projetos PRIMARY KEY (id);


--
-- Name: comunidades pk_comunidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades
    ADD CONSTRAINT pk_comunidades PRIMARY KEY (id);


--
-- Name: configuracao pk_configuracao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao
    ADD CONSTRAINT pk_configuracao PRIMARY KEY (id);


--
-- Name: contratos pk_contratos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT pk_contratos PRIMARY KEY (id);


--
-- Name: contrato_campanhas pk_contratos_campanhas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato_campanhas
    ADD CONSTRAINT pk_contratos_campanhas PRIMARY KEY (id);


--
-- Name: doacao_lampada_historicos pk_doacao_lampada_historicos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampada_historicos
    ADD CONSTRAINT pk_doacao_lampada_historicos PRIMARY KEY (id);


--
-- Name: doacao_lampadas pk_doacao_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT pk_doacao_lampadas PRIMARY KEY (id);


--
-- Name: estabelecimento_entregas pk_estabelecimento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimento_entregas
    ADD CONSTRAINT pk_estabelecimento_entregas PRIMARY KEY (id);


--
-- Name: estabelecimentos pk_estabelecimentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimentos
    ADD CONSTRAINT pk_estabelecimentos PRIMARY KEY (id);


--
-- Name: evento_doacao_lampada_reserva_lampadas pk_evento_doacao_lampada_reserva_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampada_reserva_lampadas
    ADD CONSTRAINT pk_evento_doacao_lampada_reserva_lampadas PRIMARY KEY (id);


--
-- Name: evento_doacao_lampadas pk_evento_doacao_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampadas
    ADD CONSTRAINT pk_evento_doacao_lampadas PRIMARY KEY (id);


--
-- Name: evento_entregas pk_evento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas
    ADD CONSTRAINT pk_evento_entregas PRIMARY KEY (id);


--
-- Name: evento_reciclador_vigencias pk_evento_reciclador_vigencias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reciclador_vigencias
    ADD CONSTRAINT pk_evento_reciclador_vigencias PRIMARY KEY (id);


--
-- Name: evento_recursos pk_evento_recurso_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_recursos
    ADD CONSTRAINT pk_evento_recurso_id PRIMARY KEY (id);


--
-- Name: eventos pk_eventos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT pk_eventos PRIMARY KEY (id);


--
-- Name: eventos_nota_saidas pk_eventos_nota_saidas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nota_saidas
    ADD CONSTRAINT pk_eventos_nota_saidas PRIMARY KEY (id);


--
-- Name: evento_parceiros pk_eventos_parceiros_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT pk_eventos_parceiros_id PRIMARY KEY (id);


--
-- Name: eventos_reserva_lampadas pk_eventos_reserva_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reserva_lampadas
    ADD CONSTRAINT pk_eventos_reserva_lampadas PRIMARY KEY (id);


--
-- Name: historicos pk_historico_ev; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos
    ADD CONSTRAINT pk_historico_ev PRIMARY KEY (id);


--
-- Name: instituicaos pk_instituicaos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos
    ADD CONSTRAINT pk_instituicaos PRIMARY KEY (id);


--
-- Name: instituicaos_contratos pk_instituicaos_contratos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos_contratos
    ADD CONSTRAINT pk_instituicaos_contratos PRIMARY KEY (id);


--
-- Name: lampadas_tipo pk_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas_tipo
    ADD CONSTRAINT pk_lampadas PRIMARY KEY (id);


--
-- Name: lampadas_modelo pk_lampadas_modelo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas_modelo
    ADD CONSTRAINT pk_lampadas_modelo PRIMARY KEY (id);


--
-- Name: marca_refrigeradors pk_marca_refrigeradors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marca_refrigeradors
    ADD CONSTRAINT pk_marca_refrigeradors PRIMARY KEY (id);


--
-- Name: menus_perfils pk_menuperfils; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_perfils
    ADD CONSTRAINT pk_menuperfils PRIMARY KEY (id);


--
-- Name: menus pk_menus; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT pk_menus PRIMARY KEY (id);


--
-- Name: menus_modulos pk_menus_projetos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_modulos
    ADD CONSTRAINT pk_menus_projetos PRIMARY KEY (id);


--
-- Name: meta_lampadas pk_meta_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_lampadas
    ADD CONSTRAINT pk_meta_lampadas PRIMARY KEY (id);


--
-- Name: meta_refrigeradors pk_meta_refrigeradors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors
    ADD CONSTRAINT pk_meta_refrigeradors PRIMARY KEY (id);


--
-- Name: metas pk_metas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metas
    ADD CONSTRAINT pk_metas PRIMARY KEY (id);


--
-- Name: modulo_projetos pk_modulo_projetos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulo_projetos
    ADD CONSTRAINT pk_modulo_projetos PRIMARY KEY (id);


--
-- Name: modulos pk_modulos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulos
    ADD CONSTRAINT pk_modulos PRIMARY KEY (id);


--
-- Name: nota_fabricantes pk_nota_fabricante; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes
    ADD CONSTRAINT pk_nota_fabricante PRIMARY KEY (id);


--
-- Name: nota_fabricantes_nota_saidas pk_nota_fabricantes_nota_saidas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes_nota_saidas
    ADD CONSTRAINT pk_nota_fabricantes_nota_saidas PRIMARY KEY (id);


--
-- Name: nota_saidas pk_nota_saidas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saidas
    ADD CONSTRAINT pk_nota_saidas PRIMARY KEY (id);


--
-- Name: parceiros pk_parceiros; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT pk_parceiros PRIMARY KEY (id);


--
-- Name: parceiros_contratos pk_parceiros_contratos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros_contratos
    ADD CONSTRAINT pk_parceiros_contratos PRIMARY KEY (id);


--
-- Name: perfils_modulos pk_perfilprojetos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils_modulos
    ADD CONSTRAINT pk_perfilprojetos PRIMARY KEY (id);


--
-- Name: perfils pk_perfils; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils
    ADD CONSTRAINT pk_perfils PRIMARY KEY (id);


--
-- Name: programacao_estabelecimentos pk_programacao_estabelecimentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programacao_estabelecimentos
    ADD CONSTRAINT pk_programacao_estabelecimentos PRIMARY KEY (id);


--
-- Name: projetos pk_projetos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projetos
    ADD CONSTRAINT pk_projetos PRIMARY KEY (id);


--
-- Name: promotors pk_promotors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promotors
    ADD CONSTRAINT pk_promotors PRIMARY KEY (id);


--
-- Name: recicladors pk_recicladors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT pk_recicladors PRIMARY KEY (id);


--
-- Name: reciclagem_integracao pk_reciclagem_integracao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_integracao
    ADD CONSTRAINT pk_reciclagem_integracao PRIMARY KEY (id);


--
-- Name: reciclagem_recursos pk_reciclagem_recursos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_recursos
    ADD CONSTRAINT pk_reciclagem_recursos PRIMARY KEY (id);


--
-- Name: reciclagems pk_reciclagens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagems
    ADD CONSTRAINT pk_reciclagens PRIMARY KEY (id);


--
-- Name: recursos pk_recursos_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT pk_recursos_id PRIMARY KEY (id);


--
-- Name: refrigeradors pk_refrigeradors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refrigeradors
    ADD CONSTRAINT pk_refrigeradors PRIMARY KEY (id);


--
-- Name: reserva_lampada_vendas pk_reserva_lampada_vendas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampada_vendas
    ADD CONSTRAINT pk_reserva_lampada_vendas PRIMARY KEY (id);


--
-- Name: reserva_lampadas pk_reserva_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas
    ADD CONSTRAINT pk_reserva_lampadas PRIMARY KEY (id);


--
-- Name: reserva_lampadas_doacao_lampadas pk_reserva_lampadas_doacao_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_doacao_lampadas
    ADD CONSTRAINT pk_reserva_lampadas_doacao_lampadas PRIMARY KEY (id);


--
-- Name: reserva_lampadas_vistoria_pngd pk_reserva_lampadas_vistoria_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_vistoria_pngd
    ADD CONSTRAINT pk_reserva_lampadas_vistoria_pngd PRIMARY KEY (id);


--
-- Name: ruas pk_ruas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruas
    ADD CONSTRAINT pk_ruas PRIMARY KEY (id);


--
-- Name: servicos pk_servicos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicos
    ADD CONSTRAINT pk_servicos PRIMARY KEY (id);


--
-- Name: sucata_entradas_itens pk_sucata_entradas_itens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT pk_sucata_entradas_itens PRIMARY KEY (id);


--
-- Name: sucata_entradas_lote pk_sucata_entradas_lote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote
    ADD CONSTRAINT pk_sucata_entradas_lote PRIMARY KEY (id);


--
-- Name: sucatas_pngd pk_sucata_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd
    ADD CONSTRAINT pk_sucata_pngd PRIMARY KEY (id);


--
-- Name: sucata_saidas_itens pk_sucata_saidas_itens; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_itens
    ADD CONSTRAINT pk_sucata_saidas_itens PRIMARY KEY (id);


--
-- Name: sucata_saidas_lote pk_sucata_saidas_lote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote
    ADD CONSTRAINT pk_sucata_saidas_lote PRIMARY KEY (id);


--
-- Name: sucatas_pngv pk_sucatas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngv
    ADD CONSTRAINT pk_sucatas PRIMARY KEY (id);


--
-- Name: tipo_acaos pk_tipo_acaos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_acaos
    ADD CONSTRAINT pk_tipo_acaos PRIMARY KEY (id);


--
-- Name: tipo_recursos pk_tipo_recursos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_recursos
    ADD CONSTRAINT pk_tipo_recursos PRIMARY KEY (id);


--
-- Name: contratos_tipos pk_tipos_contratos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos_tipos
    ADD CONSTRAINT pk_tipos_contratos PRIMARY KEY (id);


--
-- Name: parceiros_tipos pk_tipos_parceiros; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros_tipos
    ADD CONSTRAINT pk_tipos_parceiros PRIMARY KEY (id);


--
-- Name: triagem_pngd pk_triagem_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngd
    ADD CONSTRAINT pk_triagem_pngd PRIMARY KEY (id);


--
-- Name: triagem_pngv pk_triagems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngv
    ADD CONSTRAINT pk_triagems PRIMARY KEY (id);


--
-- Name: ufs pk_ufs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ufs
    ADD CONSTRAINT pk_ufs PRIMARY KEY (id);


--
-- Name: unidade_medidas pk_unidade_medidas_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidade_medidas
    ADD CONSTRAINT pk_unidade_medidas_id PRIMARY KEY (id);


--
-- Name: usuarios pk_usuarios; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT pk_usuarios PRIMARY KEY (id);


--
-- Name: vendas pk_vendas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT pk_vendas PRIMARY KEY (id);


--
-- Name: vigencias pk_vigencia_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vigencias
    ADD CONSTRAINT pk_vigencia_id PRIMARY KEY (id);


--
-- Name: vistoria_pngd pk_vistoria_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd
    ADD CONSTRAINT pk_vistoria_pngd PRIMARY KEY (id);


--
-- Name: potencias potencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.potencias
    ADD CONSTRAINT potencia_pkey PRIMARY KEY (id);


--
-- Name: regionals regionals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regionals
    ADD CONSTRAINT regionals_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: sucatas_lampada sucatas_lampada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_lampada
    ADD CONSTRAINT sucatas_lampada_pkey PRIMARY KEY (id);


--
-- Name: tipo_veiculo tipo_veiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_veiculo
    ADD CONSTRAINT tipo_veiculo_pkey PRIMARY KEY (id);


--
-- Name: tipos_acaos tipos_acaos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_acaos
    ADD CONSTRAINT tipos_acaos_pkey PRIMARY KEY (id);


--
-- Name: triagem_pngv triagem_pngv_cliente_contrato_projeto_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngv
    ADD CONSTRAINT triagem_pngv_cliente_contrato_projeto_id_key UNIQUE (cliente_contrato_projeto_id);


--
-- Name: sucata_entradas_lote uk_numero_lote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote
    ADD CONSTRAINT uk_numero_lote UNIQUE (numero_lote, modulo_id);


--
-- Name: sucata_saidas_lote uk_saida_numero_lote; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote
    ADD CONSTRAINT uk_saida_numero_lote UNIQUE (numero_lote, modulo_id);


--
-- Name: sucata_entradas_itens uk_sucata_pngd_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT uk_sucata_pngd_id UNIQUE (sucata_pngd_id, contrato_id, cliente_id);


--
-- Name: sucata_entradas_itens uk_sucata_pngv_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT uk_sucata_pngv_id UNIQUE (sucata_pngv_id, contrato_id, cliente_id);


--
-- Name: acaos unique_acaos_nome_projeto; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acaos
    ADD CONSTRAINT unique_acaos_nome_projeto UNIQUE (nome, projeto_id);


--
-- Name: agendamentos unique_agendamentos_triagems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agendamentos
    ADD CONSTRAINT unique_agendamentos_triagems UNIQUE (triagem_pngv_id);


--
-- Name: contrato_campanhas unique_campanha_contrato; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato_campanhas
    ADD CONSTRAINT unique_campanha_contrato UNIQUE (campanha_id, contrato_id);


--
-- Name: cliente_estabelecimento_entregas unique_cliente_estabelecimento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_estabelecimento_entregas
    ADD CONSTRAINT unique_cliente_estabelecimento_entregas UNIQUE (cliente_id, estabelecimento_entrega_id);


--
-- Name: clientes_evento_entregas unique_clientes_evento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas
    ADD CONSTRAINT unique_clientes_evento_entregas UNIQUE (cliente_id, contrato_id, evento_entrega_id);


--
-- Name: clientes_eventos_contratos unique_clientes_eventos_contratos_contrato_evento_modulo; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT unique_clientes_eventos_contratos_contrato_evento_modulo UNIQUE (contrato_id, evento_id, modulo_id);


--
-- Name: configuracao unique_configuracao; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracao
    ADD CONSTRAINT unique_configuracao UNIQUE (chave, valor);


--
-- Name: contratos unique_contrato_numero; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT unique_contrato_numero UNIQUE (numero);


--
-- Name: evento_entrega_nota_saidas unique_entrega_nota; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entrega_nota_saidas
    ADD CONSTRAINT unique_entrega_nota UNIQUE (evento_entrega_id, nota_saida_id);


--
-- Name: estabelecimento_entregas unique_estabelecimento_entregas_data_turno_estabelecimento; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimento_entregas
    ADD CONSTRAINT unique_estabelecimento_entregas_data_turno_estabelecimento UNIQUE (data, turno, estabelecimento_id);


--
-- Name: evento_doacao_lampadas unique_evento_doacao_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampadas
    ADD CONSTRAINT unique_evento_doacao_lampadas UNIQUE (evento_id);


--
-- Name: evento_entregas unique_evento_entregas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas
    ADD CONSTRAINT unique_evento_entregas UNIQUE (data, evento_id, instituicao_id, turno);


--
-- Name: evento_lampadas unique_evento_lampada; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas
    ADD CONSTRAINT unique_evento_lampada UNIQUE (evento_id, lampada_id);


--
-- Name: evento_lampadas unique_evento_lampada_quantidade; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas
    ADD CONSTRAINT unique_evento_lampada_quantidade UNIQUE (evento_id, quantidade_lampadas, lampada_id);


--
-- Name: evento_reciclador_vigencias unique_evento_reciclador_vigencias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reciclador_vigencias
    ADD CONSTRAINT unique_evento_reciclador_vigencias UNIQUE (evento_id, reciclador_id, vigencia_id);


--
-- Name: eventos unique_eventos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT unique_eventos UNIQUE (acao_id, local_acao, data_inicial);


--
-- Name: eventos unique_eventos_full; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT unique_eventos_full UNIQUE (acao_id, local_acao, data_inicial, data_final);


--
-- Name: menus_modulos unique_menus_modulos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_modulos
    ADD CONSTRAINT unique_menus_modulos UNIQUE (modulo_id, menu_id);


--
-- Name: menus_perfils unique_menus_perfils; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_perfils
    ADD CONSTRAINT unique_menus_perfils UNIQUE (menu_id, perfil_id);


--
-- Name: meta_lampadas unique_meta_lampadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_lampadas
    ADD CONSTRAINT unique_meta_lampadas UNIQUE (ano, lampada_id, tipo_cliente, acao_id);


--
-- Name: meta_refrigeradors unique_meta_refrigeradors; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors
    ADD CONSTRAINT unique_meta_refrigeradors UNIQUE (ano, refrigerador_id, tipo_cliente, acao_id);


--
-- Name: metas unique_metas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metas
    ADD CONSTRAINT unique_metas UNIQUE (ano, periodo_inicial, periodo_final, cliente_tipo, modulo_id, acao_id, model, registro_id);


--
-- Name: models unique_model; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT unique_model UNIQUE (nome);


--
-- Name: tipo_acaos unique_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_acaos
    ADD CONSTRAINT unique_nome UNIQUE (nome);


--
-- Name: tipo_recursos unique_nome_tipo_recursos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_recursos
    ADD CONSTRAINT unique_nome_tipo_recursos UNIQUE (nome);


--
-- Name: recursos unique_nome_tipo_unidade_medida; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT unique_nome_tipo_unidade_medida UNIQUE (nome, unidade_medida_id, tipo_recurso_id);


--
-- Name: nota_fabricantes_nota_saidas unique_nota_fabricantes_nota_saidas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes_nota_saidas
    ADD CONSTRAINT unique_nota_fabricantes_nota_saidas UNIQUE (nota_saida_id, nota_fabricante_id);


--
-- Name: nota_fabricantes unique_nota_fabricantes_numero; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes
    ADD CONSTRAINT unique_nota_fabricantes_numero UNIQUE (numero);


--
-- Name: nota_saidas unique_nota_saidas_numero; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_saidas
    ADD CONSTRAINT unique_nota_saidas_numero UNIQUE (numero);


--
-- Name: parceiros unique_parceiros_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT unique_parceiros_nome UNIQUE (nome);


--
-- Name: perfils_modulos unique_perfils_modulos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils_modulos
    ADD CONSTRAINT unique_perfils_modulos UNIQUE (perfil_id, modulo_id);


--
-- Name: perfils unique_perfils_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils
    ADD CONSTRAINT unique_perfils_nome UNIQUE (nome);


--
-- Name: recicladors unique_recicladors_cnpj; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT unique_recicladors_cnpj UNIQUE (cnpj);


--
-- Name: recicladors unique_recicladors_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT unique_recicladors_nome UNIQUE (nome);


--
-- Name: sucatas_pngd unique_sucatas_pngd_triagem_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd
    ADD CONSTRAINT unique_sucatas_pngd_triagem_pngd UNIQUE (triagem_d_id);


--
-- Name: sucatas_pngv unique_sucatas_triagems; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngv
    ADD CONSTRAINT unique_sucatas_triagems UNIQUE (triagem_pngv_id);


--
-- Name: triagem_pngd unique_triagem_pngd_cliente_evento_contrato_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngd
    ADD CONSTRAINT unique_triagem_pngd_cliente_evento_contrato_id UNIQUE (cliente_evento_contrato_id);


--
-- Name: triagem_pngd unique_triagem_pngd_nis; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngd
    ADD CONSTRAINT unique_triagem_pngd_nis UNIQUE (nis);


--
-- Name: unidade_medidas unique_unidade_medidas_nome; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidade_medidas
    ADD CONSTRAINT unique_unidade_medidas_nome UNIQUE (nome);


--
-- Name: usuarios unique_usuarios_login; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT unique_usuarios_login UNIQUE (login);


--
-- Name: vendas unique_vendas_sucatas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT unique_vendas_sucatas UNIQUE (sucata_pngv_id);


--
-- Name: vistoria_pngd unique_vistoria_pngd_triagem_pngd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd
    ADD CONSTRAINT unique_vistoria_pngd_triagem_pngd UNIQUE (triagem_d_id);


--
-- Name: instituicaos_contratos uq_instituicao_contrato_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos_contratos
    ADD CONSTRAINT uq_instituicao_contrato_id UNIQUE (contrato_id);


--
-- Name: modulo_projetos uq_modulo_projeto_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulo_projetos
    ADD CONSTRAINT uq_modulo_projeto_id UNIQUE (modulo_id, projeto_id);


--
-- Name: parceiros_contratos uq_parceiro_contrato_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros_contratos
    ADD CONSTRAINT uq_parceiro_contrato_id UNIQUE (contrato_id);


--
-- Name: veiculo veiculo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.veiculo
    ADD CONSTRAINT veiculo_pkey PRIMARY KEY (id);


--
-- Name: venda_historicos vendas_historico_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_historicos
    ADD CONSTRAINT vendas_historico_pkey PRIMARY KEY (id);


--
-- Name: bi_form_item_bairros_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_bairros_id_uindex ON public.bi_form_item_bairros USING btree (id);


--
-- Name: bi_form_item_cidades_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_cidades_id_uindex ON public.bi_form_item_cidades USING btree (id);


--
-- Name: bi_form_item_comunidades_bi_form_item_id_comunidade_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_comunidades_bi_form_item_id_comunidade_id_uindex ON public.bi_form_item_comunidades USING btree (bi_form_item_id, comunidade_id);


--
-- Name: bi_form_item_comunidades_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_comunidades_id_uindex ON public.bi_form_item_comunidades USING btree (id);


--
-- Name: bi_form_item_resposta_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_resposta_id_uindex ON public.bi_form_item_respostas USING btree (id);


--
-- Name: bi_form_item_selects_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_item_selects_id_uindex ON public.bi_form_item_selects USING btree (id);


--
-- Name: bi_form_items_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_items_id_uindex ON public.bi_form_items USING btree (id);


--
-- Name: bi_form_resposta_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_resposta_id_uindex ON public.bi_form_respostas USING btree (id);


--
-- Name: bi_form_resposta_reciclagens_bi_resposta_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_resposta_reciclagens_bi_resposta_id_uindex ON public.bi_form_resposta_reciclagens USING btree (bi_resposta_id);


--
-- Name: bi_form_resposta_reciclagens_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_resposta_reciclagens_id_uindex ON public.bi_form_resposta_reciclagens USING btree (id);


--
-- Name: bi_form_resposta_reciclagens_reciclagem_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_resposta_reciclagens_reciclagem_id_uindex ON public.bi_form_resposta_reciclagens USING btree (reciclagem_id);


--
-- Name: bi_form_steppers_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_form_steppers_id_uindex ON public.bi_form_steppers USING btree (id);


--
-- Name: bi_forms_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_forms_id_uindex ON public.bi_forms USING btree (id);


--
-- Name: bi_metas_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bi_metas_id_uindex ON public.bi_metas USING btree (id);


--
-- Name: comunidades_tipos_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX comunidades_tipos_id_uindex ON public.comunidades_tipos USING btree (id);


--
-- Name: comunidades_tipos_nome_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX comunidades_tipos_nome_uindex ON public.comunidades_tipos USING btree (nome);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_message_deliveries_on_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_deliveries_on_channel ON public.message_deliveries USING btree (channel);


--
-- Name: index_message_deliveries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_deliveries_on_created_at ON public.message_deliveries USING btree (created_at);


--
-- Name: index_message_deliveries_on_deliverable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_deliveries_on_deliverable ON public.message_deliveries USING btree (deliverable_type, deliverable_id);


--
-- Name: index_message_deliveries_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_deliveries_on_status ON public.message_deliveries USING btree (status);


--
-- Name: index_message_deliveries_on_status_and_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_deliveries_on_status_and_channel ON public.message_deliveries USING btree (status, channel);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_usuarios_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_usuarios_on_reset_password_token ON public.usuarios USING btree (reset_password_token);


--
-- Name: log_chatbot_pk; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX log_chatbot_pk ON public.log_chatbot USING btree (id);


--
-- Name: oauth_access_tokens_client_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_access_tokens_client_id_index ON public.oauth_access_tokens USING btree (client_id);


--
-- Name: oauth_access_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_access_tokens_user_id_index ON public.oauth_access_tokens USING btree (user_id);


--
-- Name: oauth_clients_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_clients_user_id_index ON public.oauth_clients USING btree (user_id);


--
-- Name: oauth_personal_access_clients_client_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_personal_access_clients_client_id_index ON public.oauth_personal_access_clients USING btree (client_id);


--
-- Name: oauth_refresh_tokens_access_token_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oauth_refresh_tokens_access_token_id_index ON public.oauth_refresh_tokens USING btree (access_token_id);


--
-- Name: reciclagem_recursos_reciclador_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagem_recursos_reciclador_id_index ON public.reciclagem_recursos USING btree (reciclador_id);


--
-- Name: reciclagem_recursos_reciclagem_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagem_recursos_reciclagem_id_index ON public.reciclagem_recursos USING btree (reciclagem_id);


--
-- Name: reciclagem_recursos_recurso_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagem_recursos_recurso_id_index ON public.reciclagem_recursos USING btree (recurso_id);


--
-- Name: reciclagems_cliente_evento_contrato_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagems_cliente_evento_contrato_id_index ON public.reciclagems USING btree (cliente_evento_contrato_id);


--
-- Name: reciclagems_contrato_origem_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagems_contrato_origem_id_index ON public.reciclagems USING btree (contrato_origem_id);


--
-- Name: reciclagems_veiculo_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reciclagems_veiculo_id_index ON public.reciclagems USING btree (veiculo_id);


--
-- Name: recursos_tipo_recurso_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recursos_tipo_recurso_id_index ON public.recursos USING btree (tipo_recurso_id);


--
-- Name: perfil_permissao FK_137296089c30c0eb8ca061a42ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissao
    ADD CONSTRAINT "FK_137296089c30c0eb8ca061a42ea" FOREIGN KEY (perfil_id) REFERENCES public.perfils(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: perfil_permissao FK_60fb34e9d84b870a5a9f5ec7fc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissao
    ADD CONSTRAINT "FK_60fb34e9d84b870a5a9f5ec7fc0" FOREIGN KEY (permissao_id) REFERENCES public.permissoes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: log_chatbot FK_fa38605f4b1973a26e0263a3433; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_chatbot
    ADD CONSTRAINT "FK_fa38605f4b1973a26e0263a3433" FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: arquivos_eventos arquivos_eventos_evento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_eventos
    ADD CONSTRAINT arquivos_eventos_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: arquivos_vendas arquivos_venda_venda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vendas
    ADD CONSTRAINT arquivos_venda_venda_id_fkey FOREIGN KEY (venda_id) REFERENCES public.vendas(id);


--
-- Name: bi_form_item_bairros bi_form_item_bairros_bairros_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_bairros
    ADD CONSTRAINT bi_form_item_bairros_bairros_id_fk FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: bi_form_item_bairros bi_form_item_bairros_bi_form_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_bairros
    ADD CONSTRAINT bi_form_item_bairros_bi_form_items_id_fk FOREIGN KEY (bi_form_item_id) REFERENCES public.bi_form_items(id);


--
-- Name: bi_form_item_cidades bi_form_item_cidades_bi_form_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_cidades
    ADD CONSTRAINT bi_form_item_cidades_bi_form_items_id_fk FOREIGN KEY (bi_form_item_id) REFERENCES public.bi_form_items(id);


--
-- Name: bi_form_item_cidades bi_form_item_cidades_cidades_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_cidades
    ADD CONSTRAINT bi_form_item_cidades_cidades_id_fk FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: bi_form_item_comunidades bi_form_item_comunidades_bi_form_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_comunidades
    ADD CONSTRAINT bi_form_item_comunidades_bi_form_items_id_fk FOREIGN KEY (bi_form_item_id) REFERENCES public.bi_form_items(id);


--
-- Name: bi_form_item_comunidades bi_form_item_comunidades_comunidades_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_comunidades
    ADD CONSTRAINT bi_form_item_comunidades_comunidades_id_fk FOREIGN KEY (comunidade_id) REFERENCES public.comunidades(id);


--
-- Name: bi_form_item_respostas bi_form_item_resposta_bi_form_resposta_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_resposta_bi_form_resposta_id_fk FOREIGN KEY (bi_form_resposta_id) REFERENCES public.bi_form_respostas(id);


--
-- Name: bi_form_item_respostas bi_form_item_respostas_bairros_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_respostas_bairros_id_fk FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: bi_form_item_respostas bi_form_item_respostas_bi_form_item_selects_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_respostas_bi_form_item_selects_id_fk FOREIGN KEY (bi_select_id) REFERENCES public.bi_form_item_selects(id);


--
-- Name: bi_form_item_respostas bi_form_item_respostas_cidades_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_respostas_cidades_id_fk FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: bi_form_item_respostas bi_form_item_respostas_comunidades_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_respostas
    ADD CONSTRAINT bi_form_item_respostas_comunidades_id_fk FOREIGN KEY (comunidade_id) REFERENCES public.comunidades(id);


--
-- Name: bi_form_item_selects bi_form_item_selects_bi_form_items_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_item_selects
    ADD CONSTRAINT bi_form_item_selects_bi_form_items_id_fk FOREIGN KEY (form_item_id) REFERENCES public.bi_form_items(id);


--
-- Name: bi_form_items bi_form_items_bi_form_steppers_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_items
    ADD CONSTRAINT bi_form_items_bi_form_steppers_id_fk FOREIGN KEY (stepper_id) REFERENCES public.bi_form_steppers(id);


--
-- Name: bi_form_items bi_form_items_bi_forms_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_items
    ADD CONSTRAINT bi_form_items_bi_forms_id_fk FOREIGN KEY (bi_form_id) REFERENCES public.bi_forms(id);


--
-- Name: bi_form_respostas bi_form_resposta_bi_forms_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_respostas
    ADD CONSTRAINT bi_form_resposta_bi_forms_id_fk FOREIGN KEY (bi_form_id) REFERENCES public.bi_forms(id);


--
-- Name: bi_form_respostas bi_form_resposta_usuarios_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_respostas
    ADD CONSTRAINT bi_form_resposta_usuarios_id_fk FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: bi_form_steppers bi_form_steppers_bi_forms_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_form_steppers
    ADD CONSTRAINT bi_form_steppers_bi_forms_id_fk FOREIGN KEY (bi_form_id) REFERENCES public.bi_forms(id);


--
-- Name: bi_metas bi_metas_bi_contratos_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bi_metas
    ADD CONSTRAINT bi_metas_bi_contratos_id_fk FOREIGN KEY (bi_contrato_id) REFERENCES public.bi_contratos(id);


--
-- Name: clientes cliente_evento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT cliente_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: clientes_eventos_contratos clientes_eventos_contratos_modulo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT clientes_eventos_contratos_modulo_id_fkey FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: clientes clientes_usuarios_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_usuarios_id_fk FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: comunidades comunidades_acao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades
    ADD CONSTRAINT comunidades_acao_id_fkey FOREIGN KEY (acao_id) REFERENCES public.acaos(id);


--
-- Name: comunidades comunidades_comunidades_tipos_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades
    ADD CONSTRAINT comunidades_comunidades_tipos_id_fk FOREIGN KEY (tipo_id) REFERENCES public.comunidades_tipos(id);


--
-- Name: comunidades comunidades_parceiros_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comunidades
    ADD CONSTRAINT comunidades_parceiros_id_fk FOREIGN KEY (parceiro_id) REFERENCES public.parceiros(id);


--
-- Name: contratos contrato_local_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT contrato_local_fkey FOREIGN KEY (local_cadastro_id) REFERENCES public.comunidades(id);


--
-- Name: doacao_historicos doacao_historico_usuario_alteracao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_historicos
    ADD CONSTRAINT doacao_historico_usuario_alteracao_fkey FOREIGN KEY (usuario_alteracao) REFERENCES public.usuarios(id);


--
-- Name: doacao_historicos doacao_historico_vistoria_pngd_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_historicos
    ADD CONSTRAINT doacao_historico_vistoria_pngd_id_fkey FOREIGN KEY (vistoria_pngd_id) REFERENCES public.vistoria_pngd(id);


--
-- Name: esqueci_senha esqueci_senha_usuario_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.esqueci_senha
    ADD CONSTRAINT esqueci_senha_usuario_id_foreign FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: estabelecimento_entregas estabelecimento_entregas_estabelecimento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimento_entregas
    ADD CONSTRAINT estabelecimento_entregas_estabelecimento_id_fkey FOREIGN KEY (estabelecimento_id) REFERENCES public.estabelecimentos(id) ON DELETE CASCADE;


--
-- Name: evento_doacao_lampadas evento_doacao_lampadas_evento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampadas
    ADD CONSTRAINT evento_doacao_lampadas_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_entregas evento_entregas_comunidade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas
    ADD CONSTRAINT evento_entregas_comunidade_id_fkey FOREIGN KEY (local_entrega) REFERENCES public.comunidades(id);


--
-- Name: evento_entrega_nota_saidas evento_entregas_nota_saidas_evento_entrega_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entrega_nota_saidas
    ADD CONSTRAINT evento_entregas_nota_saidas_evento_entrega_id_fkey FOREIGN KEY (evento_entrega_id) REFERENCES public.evento_entregas(id) ON DELETE CASCADE;


--
-- Name: evento_entrega_nota_saidas evento_entregas_nota_saidas_nota_saida_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entrega_nota_saidas
    ADD CONSTRAINT evento_entregas_nota_saidas_nota_saida_id_fkey FOREIGN KEY (nota_saida_id) REFERENCES public.nota_saidas(id);


--
-- Name: evento_escalacaos evento_escalacao_eventos_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_escalacaos
    ADD CONSTRAINT evento_escalacao_eventos_id_fk FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_escalacaos evento_escalacao_usuarios_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_escalacaos
    ADD CONSTRAINT evento_escalacao_usuarios_id_fk FOREIGN KEY (usuario_operador_id) REFERENCES public.usuarios(id);


--
-- Name: evento_escalacaos evento_escalacao_usuarios_id_fk_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_escalacaos
    ADD CONSTRAINT evento_escalacao_usuarios_id_fk_2 FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: evento_lampadas evento_lampadas_evento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas
    ADD CONSTRAINT evento_lampadas_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_lampadas evento_lampadas_lampada_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_lampadas
    ADD CONSTRAINT evento_lampadas_lampada_id_fkey FOREIGN KEY (lampada_id) REFERENCES public.lampadas(id);


--
-- Name: evento_reciclador_vigencias evento_reciclador_vigencias_evento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reciclador_vigencias
    ADD CONSTRAINT evento_reciclador_vigencias_evento_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_reciclador_vigencias evento_reciclador_vigencias_reciclador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reciclador_vigencias
    ADD CONSTRAINT evento_reciclador_vigencias_reciclador_id_fkey FOREIGN KEY (reciclador_id) REFERENCES public.recicladors(id);


--
-- Name: evento_reciclador_vigencias evento_reciclador_vigencias_vigencia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_reciclador_vigencias
    ADD CONSTRAINT evento_reciclador_vigencias_vigencia_id_fkey FOREIGN KEY (vigencia_id) REFERENCES public.vigencias(id);


--
-- Name: evento_historicos eventos_historico_eventos_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_historicos
    ADD CONSTRAINT eventos_historico_eventos_id_fkey FOREIGN KEY (evento_id) REFERENCES public.eventos(id) ON DELETE CASCADE;


--
-- Name: evento_historicos eventos_historico_usuario_alteracao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_historicos
    ADD CONSTRAINT eventos_historico_usuario_alteracao_fkey FOREIGN KEY (usuario_alteracao) REFERENCES public.usuarios(id);


--
-- Name: acaos fk_acaos_projetos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acaos
    ADD CONSTRAINT fk_acaos_projetos FOREIGN KEY (projeto_id) REFERENCES public.projetos(id);


--
-- Name: agendamentos fk_agendamentos_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agendamentos
    ADD CONSTRAINT fk_agendamentos_refrigeradors FOREIGN KEY (refrigerador_id) REFERENCES public.refrigeradors(id);


--
-- Name: agendamentos fk_agendamentos_triagems; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agendamentos
    ADD CONSTRAINT fk_agendamentos_triagems FOREIGN KEY (triagem_pngv_id) REFERENCES public.triagem_pngv(id) ON DELETE CASCADE;


--
-- Name: arquivos_triagem_pngd fk_arquivos_triagem_pngd_triagems; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagem_pngd
    ADD CONSTRAINT fk_arquivos_triagem_pngd_triagems FOREIGN KEY (triagem_pngd_id) REFERENCES public.triagem_pngd(id) ON DELETE CASCADE;


--
-- Name: arquivos_triagems fk_arquivos_triagems_triagems; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_triagems
    ADD CONSTRAINT fk_arquivos_triagems_triagems FOREIGN KEY (triagem_pngv_id) REFERENCES public.triagem_pngv(id) ON DELETE CASCADE;


--
-- Name: arquivos_vistoria_pngd fk_arquivos_vistoria_pngd_vistoria_pngd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arquivos_vistoria_pngd
    ADD CONSTRAINT fk_arquivos_vistoria_pngd_vistoria_pngd FOREIGN KEY (vistoria_pngd_id) REFERENCES public.vistoria_pngd(id) ON DELETE CASCADE;


--
-- Name: bairros fk_bairros_cidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bairros
    ADD CONSTRAINT fk_bairros_cidades FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: campanhas fk_campanha_modulo_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campanhas
    ADD CONSTRAINT fk_campanha_modulo_id FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: cidades fk_cidades_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cidades
    ADD CONSTRAINT fk_cidades_ufs FOREIGN KEY (uf_id) REFERENCES public.ufs(id);


--
-- Name: clientes_contratos_projetos fk_clientes_contratos_projetos_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_contratos_projetos
    ADD CONSTRAINT fk_clientes_contratos_projetos_contratos FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: cliente_estabelecimento_entregas fk_clientes_estabelecimento_entregas_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_estabelecimento_entregas
    ADD CONSTRAINT fk_clientes_estabelecimento_entregas_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: cliente_estabelecimento_entregas fk_clientes_estabelecimento_entregas_estabelecimento_entregas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cliente_estabelecimento_entregas
    ADD CONSTRAINT fk_clientes_estabelecimento_entregas_estabelecimento_entregas FOREIGN KEY (estabelecimento_entrega_id) REFERENCES public.estabelecimento_entregas(id);


--
-- Name: clientes_evento_entregas fk_clientes_evento_entregas_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas
    ADD CONSTRAINT fk_clientes_evento_entregas_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: clientes_evento_entregas fk_clientes_evento_entregas_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas
    ADD CONSTRAINT fk_clientes_evento_entregas_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: clientes_evento_entregas fk_clientes_evento_entregas_evento_entregas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_evento_entregas
    ADD CONSTRAINT fk_clientes_evento_entregas_evento_entregas FOREIGN KEY (evento_entrega_id) REFERENCES public.evento_entregas(id);


--
-- Name: clientes_eventos_contratos fk_clientes_eventos_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT fk_clientes_eventos_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: clientes_eventos_contratos fk_clientes_eventos_contratos_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT fk_clientes_eventos_contratos_contratos FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: clientes_eventos_contratos fk_clientes_eventos_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_eventos_contratos
    ADD CONSTRAINT fk_clientes_eventos_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: clientes_contratos_projetos fk_clientes_projetos_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_contratos_projetos
    ADD CONSTRAINT fk_clientes_projetos_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: clientes_contratos_projetos fk_clientes_projetos_projetos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes_contratos_projetos
    ADD CONSTRAINT fk_clientes_projetos_projetos FOREIGN KEY (projeto_id) REFERENCES public.projetos(id);


--
-- Name: clientes fk_clientes_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT fk_clientes_ufs FOREIGN KEY (rg_uf_id) REFERENCES public.ufs(id);


--
-- Name: contrato_campanhas fk_contrato_campanhas_campanha_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato_campanhas
    ADD CONSTRAINT fk_contrato_campanhas_campanha_id FOREIGN KEY (campanha_id) REFERENCES public.campanhas(id);


--
-- Name: contrato_campanhas fk_contrato_campanhas_contrato_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contrato_campanhas
    ADD CONSTRAINT fk_contrato_campanhas_contrato_id FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: contratos fk_contrato_contrato_tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contrato_contrato_tipo FOREIGN KEY (contrato_tipo_id) REFERENCES public.contratos_tipos(id);


--
-- Name: evento_parceiros fk_contrato_origem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT fk_contrato_origem FOREIGN KEY (contrato_origem_id) REFERENCES public.contratos(id);


--
-- Name: contratos fk_contratos_bairros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contratos_bairros FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: contratos fk_contratos_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contratos
    ADD CONSTRAINT fk_contratos_ufs FOREIGN KEY (uf_id) REFERENCES public.ufs(id);


--
-- Name: doacao_lampada_historicos fk_doacao_lampada_historicos_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampada_historicos
    ADD CONSTRAINT fk_doacao_lampada_historicos_usuarios FOREIGN KEY (usuario_alteracao) REFERENCES public.usuarios(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_contratos FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_evento_entregas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_evento_entregas FOREIGN KEY (evento_entrega_id) REFERENCES public.evento_entregas(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_lampadas FOREIGN KEY (lampada_id) REFERENCES public.lampadas(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_modulos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_modulos FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_projetos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_projetos FOREIGN KEY (projeto_id) REFERENCES public.projetos(id);


--
-- Name: doacao_lampadas fk_doacao_lampadas_servicos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao_lampadas
    ADD CONSTRAINT fk_doacao_lampadas_servicos FOREIGN KEY (servico_id) REFERENCES public.servicos(id);


--
-- Name: estabelecimentos fk_estabelecimentos_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estabelecimentos
    ADD CONSTRAINT fk_estabelecimentos_ufs FOREIGN KEY (endereco_uf_id) REFERENCES public.ufs(id);


--
-- Name: evento_doacao_lampada_reserva_lampadas fk_evento_doacao_lampadas_reserva_lampadas_edl_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampada_reserva_lampadas
    ADD CONSTRAINT fk_evento_doacao_lampadas_reserva_lampadas_edl_id FOREIGN KEY (evento_doacao_lampada_id) REFERENCES public.evento_doacao_lampadas(id);


--
-- Name: evento_doacao_lampada_reserva_lampadas fk_evento_doacao_lampadas_reserva_lampadas_reserva_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_doacao_lampada_reserva_lampadas
    ADD CONSTRAINT fk_evento_doacao_lampadas_reserva_lampadas_reserva_id FOREIGN KEY (reserva_lampada_id) REFERENCES public.reserva_lampadas(id);


--
-- Name: evento_entregas fk_evento_entregas_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas
    ADD CONSTRAINT fk_evento_entregas_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_entregas fk_evento_entregas_instituicaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_entregas
    ADD CONSTRAINT fk_evento_entregas_instituicaos FOREIGN KEY (instituicao_id) REFERENCES public.instituicaos(id);


--
-- Name: evento_parceiros fk_evento_parceiros_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT fk_evento_parceiros_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: evento_recursos fk_evento_recursos_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_recursos
    ADD CONSTRAINT fk_evento_recursos_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_recursos fk_evento_recursos_recursos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_recursos
    ADD CONSTRAINT fk_evento_recursos_recursos FOREIGN KEY (recurso_id) REFERENCES public.recursos(id);


--
-- Name: eventos fk_eventos_acaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT fk_eventos_acaos FOREIGN KEY (acao_id) REFERENCES public.acaos(id);


--
-- Name: eventos fk_eventos_comunidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT fk_eventos_comunidades FOREIGN KEY (local_acao) REFERENCES public.comunidades(id);


--
-- Name: eventos fk_eventos_modulos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT fk_eventos_modulos FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: eventos_nota_saidas fk_eventos_nota_saidas_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nota_saidas
    ADD CONSTRAINT fk_eventos_nota_saidas_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: eventos_nota_saidas fk_eventos_nota_saidas_nota_saidas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_nota_saidas
    ADD CONSTRAINT fk_eventos_nota_saidas_nota_saidas FOREIGN KEY (nota_saida_id) REFERENCES public.nota_saidas(id);


--
-- Name: evento_parceiros fk_eventos_parceiros_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT fk_eventos_parceiros_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: evento_parceiros fk_eventos_parceiros_instituicaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT fk_eventos_parceiros_instituicaos FOREIGN KEY (instituicao_id) REFERENCES public.instituicaos(id);


--
-- Name: evento_parceiros fk_eventos_parceiros_vigencias; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_parceiros
    ADD CONSTRAINT fk_eventos_parceiros_vigencias FOREIGN KEY (vigencia_id) REFERENCES public.vigencias(id);


--
-- Name: eventos_reserva_lampadas fk_eventos_reserva_lampadas_eventos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reserva_lampadas
    ADD CONSTRAINT fk_eventos_reserva_lampadas_eventos FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: eventos_reserva_lampadas fk_eventos_reserva_lampadas_reserva_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eventos_reserva_lampadas
    ADD CONSTRAINT fk_eventos_reserva_lampadas_reserva_lampadas FOREIGN KEY (reserva_lampada_id) REFERENCES public.reserva_lampadas(id);


--
-- Name: historicos fk_historico_ev_clientes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos
    ADD CONSTRAINT fk_historico_ev_clientes FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: historicos fk_historico_ev_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos
    ADD CONSTRAINT fk_historico_ev_contratos FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: historicos fk_historicos_doacao_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos
    ADD CONSTRAINT fk_historicos_doacao_lampadas FOREIGN KEY (doacao_lampada_id) REFERENCES public.doacao_lampadas(id);


--
-- Name: instituicaos fk_instituicaos_bairros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos
    ADD CONSTRAINT fk_instituicaos_bairros FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: instituicaos fk_instituicaos_cidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos
    ADD CONSTRAINT fk_instituicaos_cidades FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: instituicaos_contratos fk_instituicaos_contratos_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos_contratos
    ADD CONSTRAINT fk_instituicaos_contratos_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: instituicaos_contratos fk_instituicaos_instituicao; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos_contratos
    ADD CONSTRAINT fk_instituicaos_instituicao FOREIGN KEY (instituicao_id) REFERENCES public.instituicaos(id);


--
-- Name: instituicaos fk_instituicaos_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instituicaos
    ADD CONSTRAINT fk_instituicaos_ufs FOREIGN KEY (uf_id) REFERENCES public.ufs(id);


--
-- Name: menus_perfils fk_menuperfils_idMenu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_perfils
    ADD CONSTRAINT "fk_menuperfils_idMenu" FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: menus_perfils fk_menuperfils_idPerfil; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_perfils
    ADD CONSTRAINT "fk_menuperfils_idPerfil" FOREIGN KEY (perfil_id) REFERENCES public.perfils(id);


--
-- Name: menus_modulos fk_menus_modulos_modulos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_modulos
    ADD CONSTRAINT fk_menus_modulos_modulos FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: menus_modulos fk_menus_projetos_menus; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus_modulos
    ADD CONSTRAINT fk_menus_projetos_menus FOREIGN KEY (menu_id) REFERENCES public.menus(id);


--
-- Name: meta_lampadas fk_meta_lampadas_acaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_lampadas
    ADD CONSTRAINT fk_meta_lampadas_acaos FOREIGN KEY (acao_id) REFERENCES public.acaos(id);


--
-- Name: meta_lampadas fk_meta_lampadas_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_lampadas
    ADD CONSTRAINT fk_meta_lampadas_lampadas FOREIGN KEY (lampada_id) REFERENCES public.lampadas(id);


--
-- Name: meta_refrigeradors fk_meta_refrigeradors_acaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors
    ADD CONSTRAINT fk_meta_refrigeradors_acaos FOREIGN KEY (acao_id) REFERENCES public.acaos(id);


--
-- Name: meta_refrigeradors fk_meta_refrigeradors_equipamento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors
    ADD CONSTRAINT fk_meta_refrigeradors_equipamento FOREIGN KEY (equipamento_id) REFERENCES public.equipamentos(id);


--
-- Name: meta_refrigeradors fk_meta_refrigeradors_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_refrigeradors
    ADD CONSTRAINT fk_meta_refrigeradors_refrigeradors FOREIGN KEY (refrigerador_id) REFERENCES public.refrigeradors(id);


--
-- Name: metas fk_metas_acaos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metas
    ADD CONSTRAINT fk_metas_acaos FOREIGN KEY (acao_id) REFERENCES public.acaos(id);


--
-- Name: metas fk_metas_modulos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metas
    ADD CONSTRAINT fk_metas_modulos FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: modulo_projetos fk_modulo_projetos_modulo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulo_projetos
    ADD CONSTRAINT fk_modulo_projetos_modulo FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: modulo_projetos fk_modulo_projetos_projeto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modulo_projetos
    ADD CONSTRAINT fk_modulo_projetos_projeto FOREIGN KEY (projeto_id) REFERENCES public.projetos(id);


--
-- Name: nota_fabricantes fk_nota_fabricante_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes
    ADD CONSTRAINT fk_nota_fabricante_refrigeradors FOREIGN KEY (refrigerador_id) REFERENCES public.refrigeradors(id);


--
-- Name: nota_fabricantes_nota_saidas fk_nota_fabricantes_nota_saidas_nota_fabricantes; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes_nota_saidas
    ADD CONSTRAINT fk_nota_fabricantes_nota_saidas_nota_fabricantes FOREIGN KEY (nota_fabricante_id) REFERENCES public.nota_fabricantes(id);


--
-- Name: nota_fabricantes_nota_saidas fk_nota_fabricantes_nota_saidas_nota_saidas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nota_fabricantes_nota_saidas
    ADD CONSTRAINT fk_nota_fabricantes_nota_saidas_nota_saidas FOREIGN KEY (nota_saida_id) REFERENCES public.nota_saidas(id);


--
-- Name: parceiros fk_parceiros_bairros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT fk_parceiros_bairros FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: parceiros fk_parceiros_cidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT fk_parceiros_cidades FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: parceiros_contratos fk_parceiros_contratos_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros_contratos
    ADD CONSTRAINT fk_parceiros_contratos_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: parceiros_contratos fk_parceiros_contratos_parceiros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros_contratos
    ADD CONSTRAINT fk_parceiros_contratos_parceiros FOREIGN KEY (parceiro_id) REFERENCES public.parceiros(id);


--
-- Name: parceiros fk_parceiros_parceiro_tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT fk_parceiros_parceiro_tipo FOREIGN KEY (parceiro_tipo_id) REFERENCES public.parceiros_tipos(id);


--
-- Name: parceiros fk_parceiros_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parceiros
    ADD CONSTRAINT fk_parceiros_ufs FOREIGN KEY (uf_id) REFERENCES public.ufs(id);


--
-- Name: perfils_modulos fk_perfilprojetos_idPerfil; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils_modulos
    ADD CONSTRAINT "fk_perfilprojetos_idPerfil" FOREIGN KEY (perfil_id) REFERENCES public.perfils(id);


--
-- Name: perfils_modulos fk_perfils_modulos_modulos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfils_modulos
    ADD CONSTRAINT fk_perfils_modulos_modulos FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: programacao_estabelecimentos fk_programacao_estabelecimentos_estabelecimentos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programacao_estabelecimentos
    ADD CONSTRAINT fk_programacao_estabelecimentos_estabelecimentos FOREIGN KEY (estabelecimento_id) REFERENCES public.estabelecimentos(id) ON DELETE CASCADE;


--
-- Name: solid_queue_recurring_executions fk_rails_318a5533ed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT fk_rails_318a5533ed FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_failed_executions fk_rails_39bbc7a631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT fk_rails_39bbc7a631 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_blocked_executions fk_rails_4cd34e2228; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT fk_rails_4cd34e2228 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_ready_executions fk_rails_81fcbd66af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT fk_rails_81fcbd66af FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_claimed_executions fk_rails_9cfe4d4944; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT fk_rails_9cfe4d4944 FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: solid_queue_scheduled_executions fk_rails_c4316f352d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT fk_rails_c4316f352d FOREIGN KEY (job_id) REFERENCES public.solid_queue_jobs(id) ON DELETE CASCADE;


--
-- Name: recicladors fk_recicladors_bairros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT fk_recicladors_bairros FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: recicladors fk_recicladors_cidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT fk_recicladors_cidades FOREIGN KEY (cidade_id) REFERENCES public.cidades(id);


--
-- Name: recicladors fk_recicladors_ufs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recicladors
    ADD CONSTRAINT fk_recicladors_ufs FOREIGN KEY (uf_id) REFERENCES public.ufs(id);


--
-- Name: reciclagems fk_reciclagem_cliente_evento_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagems
    ADD CONSTRAINT fk_reciclagem_cliente_evento_contrato FOREIGN KEY (cliente_evento_contrato_id) REFERENCES public.clientes_eventos_contratos(id);


--
-- Name: reciclagem_recursos fk_reciclagem_recursos_reciclagem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_recursos
    ADD CONSTRAINT fk_reciclagem_recursos_reciclagem FOREIGN KEY (reciclagem_id) REFERENCES public.reciclagems(id);


--
-- Name: reciclagem_recursos fk_reciclagem_recursos_recurso; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_recursos
    ADD CONSTRAINT fk_reciclagem_recursos_recurso FOREIGN KEY (recurso_id) REFERENCES public.recursos(id);


--
-- Name: reciclagems fk_reciclagems_veiculo_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagems
    ADD CONSTRAINT fk_reciclagems_veiculo_id FOREIGN KEY (veiculo_id) REFERENCES public.veiculo(id);


--
-- Name: recursos fk_recursos_tipo_recurso; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT fk_recursos_tipo_recurso FOREIGN KEY (tipo_recurso_id) REFERENCES public.tipo_recursos(id);


--
-- Name: recursos fk_recursos_unidade_medidas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT fk_recursos_unidade_medidas FOREIGN KEY (unidade_medida_id) REFERENCES public.unidade_medidas(id);


--
-- Name: refrigeradors fk_refrigeradors_marca_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refrigeradors
    ADD CONSTRAINT fk_refrigeradors_marca_refrigeradors FOREIGN KEY (marca_refrigerador_id) REFERENCES public.marca_refrigeradors(id);


--
-- Name: reserva_lampada_vendas fk_reserva_lampada_vendas_reserva_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampada_vendas
    ADD CONSTRAINT fk_reserva_lampada_vendas_reserva_lampadas FOREIGN KEY (reserva_lampada_id) REFERENCES public.reserva_lampadas(id);


--
-- Name: reserva_lampada_vendas fk_reserva_lampada_vendas_vendas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampada_vendas
    ADD CONSTRAINT fk_reserva_lampada_vendas_vendas FOREIGN KEY (venda_id) REFERENCES public.vendas(id) ON DELETE CASCADE;


--
-- Name: reserva_lampadas_doacao_lampadas fk_reserva_lampadas_doacao_lampadas_doacao_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_doacao_lampadas
    ADD CONSTRAINT fk_reserva_lampadas_doacao_lampadas_doacao_lampadas FOREIGN KEY (doacao_lampada_id) REFERENCES public.doacao_lampadas(id);


--
-- Name: reserva_lampadas_doacao_lampadas fk_reserva_lampadas_doacao_lampadas_reserva_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_doacao_lampadas
    ADD CONSTRAINT fk_reserva_lampadas_doacao_lampadas_reserva_lampadas FOREIGN KEY (reserva_lampada_id) REFERENCES public.reserva_lampadas(id);


--
-- Name: reserva_lampadas fk_reserva_lampadas_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas
    ADD CONSTRAINT fk_reserva_lampadas_lampadas FOREIGN KEY (lampada_id) REFERENCES public.lampadas(id);


--
-- Name: reserva_lampadas fk_reserva_lampadas_projetos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas
    ADD CONSTRAINT fk_reserva_lampadas_projetos FOREIGN KEY (projeto_id) REFERENCES public.projetos(id);


--
-- Name: reserva_lampadas_vistoria_pngd fk_reserva_lampadas_vistoria_pngd_reserva_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_vistoria_pngd
    ADD CONSTRAINT fk_reserva_lampadas_vistoria_pngd_reserva_lampadas FOREIGN KEY (reserva_lampada_id) REFERENCES public.reserva_lampadas(id);


--
-- Name: ruas fk_ruas_bairros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ruas
    ADD CONSTRAINT fk_ruas_bairros FOREIGN KEY (bairro_id) REFERENCES public.bairros(id);


--
-- Name: servicos fk_servicos_parceiros; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicos
    ADD CONSTRAINT fk_servicos_parceiros FOREIGN KEY (parceiro_id) REFERENCES public.parceiros(id);


--
-- Name: sucatas_pngd fk_sucata_pngd_marca_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd
    ADD CONSTRAINT fk_sucata_pngd_marca_refrigeradors FOREIGN KEY (marca_refrigerador_id) REFERENCES public.marca_refrigeradors(id);


--
-- Name: sucatas_pngd fk_sucata_pngd_triagem_pngd_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd
    ADD CONSTRAINT fk_sucata_pngd_triagem_pngd_id FOREIGN KEY (triagem_d_id) REFERENCES public.triagem_pngd(id) ON DELETE CASCADE;


--
-- Name: sucata_entradas_itens fk_sucatas_entradas_itens_id_cliente; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT fk_sucatas_entradas_itens_id_cliente FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: sucata_entradas_itens fk_sucatas_entradas_itens_id_contrato; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT fk_sucatas_entradas_itens_id_contrato FOREIGN KEY (contrato_id) REFERENCES public.contratos(id);


--
-- Name: sucata_entradas_itens fk_sucatas_entradas_itens_id_lote; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT fk_sucatas_entradas_itens_id_lote FOREIGN KEY (lote_id) REFERENCES public.sucata_entradas_lote(id);


--
-- Name: sucata_entradas_itens fk_sucatas_entradas_itens_id_sucata; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT fk_sucatas_entradas_itens_id_sucata FOREIGN KEY (sucata_pngv_id) REFERENCES public.sucatas_pngv(id);


--
-- Name: sucata_entradas_itens fk_sucatas_entradas_itens_id_sucata_pngd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_itens
    ADD CONSTRAINT fk_sucatas_entradas_itens_id_sucata_pngd FOREIGN KEY (sucata_pngd_id) REFERENCES public.sucatas_pngd(id);


--
-- Name: sucata_entradas_lote fk_sucatas_entradas_lote_id_modulo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote
    ADD CONSTRAINT fk_sucatas_entradas_lote_id_modulo FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: sucata_entradas_lote fk_sucatas_entradas_lote_id_parceiro; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote
    ADD CONSTRAINT fk_sucatas_entradas_lote_id_parceiro FOREIGN KEY (parceiro_id) REFERENCES public.parceiros(id);


--
-- Name: sucata_entradas_lote fk_sucatas_entradas_lote_id_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_entradas_lote
    ADD CONSTRAINT fk_sucatas_entradas_lote_id_usuario FOREIGN KEY (usuario_recebimento) REFERENCES public.usuarios(id);


--
-- Name: sucatas_pngv fk_sucatas_marca_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngv
    ADD CONSTRAINT fk_sucatas_marca_refrigeradors FOREIGN KEY (marca_refrigerador_id) REFERENCES public.marca_refrigeradors(id);


--
-- Name: sucata_saidas_itens fk_sucatas_saidas_itens_id_item; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_itens
    ADD CONSTRAINT fk_sucatas_saidas_itens_id_item FOREIGN KEY (item_entrada_id) REFERENCES public.sucata_entradas_itens(id);


--
-- Name: sucata_saidas_itens fk_sucatas_saidas_itens_id_lote; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_itens
    ADD CONSTRAINT fk_sucatas_saidas_itens_id_lote FOREIGN KEY (lote_id) REFERENCES public.sucata_saidas_lote(id);


--
-- Name: sucata_saidas_lote fk_sucatas_saidas_lote_id_modulo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote
    ADD CONSTRAINT fk_sucatas_saidas_lote_id_modulo FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: sucata_saidas_lote fk_sucatas_saidas_lote_id_parceiro; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote
    ADD CONSTRAINT fk_sucatas_saidas_lote_id_parceiro FOREIGN KEY (parceiro_id) REFERENCES public.parceiros(id);


--
-- Name: sucata_saidas_lote fk_sucatas_saidas_lote_id_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucata_saidas_lote
    ADD CONSTRAINT fk_sucatas_saidas_lote_id_usuario FOREIGN KEY (usuario_saida) REFERENCES public.usuarios(id);


--
-- Name: sucatas_pngv fk_sucatas_triagems; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngv
    ADD CONSTRAINT fk_sucatas_triagems FOREIGN KEY (triagem_pngv_id) REFERENCES public.triagem_pngv(id) ON DELETE CASCADE;


--
-- Name: triagem_pngv fk_triagems_estabelecimentos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngv
    ADD CONSTRAINT fk_triagems_estabelecimentos FOREIGN KEY (estabelecimento_id) REFERENCES public.estabelecimentos(id);


--
-- Name: usuarios fk_usuarios_perfils; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_usuarios_perfils FOREIGN KEY (perfil_id) REFERENCES public.perfils(id);


--
-- Name: vendas fk_vendas_estabelecimentos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT fk_vendas_estabelecimentos FOREIGN KEY (estabelecimento_id) REFERENCES public.estabelecimentos(id);


--
-- Name: vendas fk_vendas_lampadas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT fk_vendas_lampadas FOREIGN KEY (lampada_id) REFERENCES public.lampadas(id);


--
-- Name: vendas fk_vendas_refrigeradors; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT fk_vendas_refrigeradors FOREIGN KEY (refrigerador_id) REFERENCES public.refrigeradors(id);


--
-- Name: vendas fk_vendas_sucatas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT fk_vendas_sucatas FOREIGN KEY (sucata_pngv_id) REFERENCES public.sucatas_pngv(id) ON DELETE CASCADE;


--
-- Name: vendas fk_vendas_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT fk_vendas_usuarios FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: vistoria_pngd fk_vistoria_pngd_nota_fabricante_nota_saida_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd
    ADD CONSTRAINT fk_vistoria_pngd_nota_fabricante_nota_saida_id FOREIGN KEY (nota_fabricante_nota_saida_id) REFERENCES public.nota_fabricantes_nota_saidas(id);


--
-- Name: vistoria_pngd fk_vistoria_pngd_triagem_pngd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd
    ADD CONSTRAINT fk_vistoria_pngd_triagem_pngd FOREIGN KEY (triagem_d_id) REFERENCES public.triagem_pngd(id);


--
-- Name: vistoria_pngd fk_vistoria_pngd_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vistoria_pngd
    ADD CONSTRAINT fk_vistoria_pngd_usuarios FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: historicos historicos_modulo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historicos
    ADD CONSTRAINT historicos_modulo_id_fkey FOREIGN KEY (modulo_id) REFERENCES public.modulos(id);


--
-- Name: evento_horario_ecopontos horario_ecopontos_eventos_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evento_horario_ecopontos
    ADD CONSTRAINT horario_ecopontos_eventos_id_fk FOREIGN KEY (evento_id) REFERENCES public.eventos(id);


--
-- Name: lampadas lampadas_lampada_modelo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas
    ADD CONSTRAINT lampadas_lampada_modelo_id_fkey FOREIGN KEY (lampada_modelo_id) REFERENCES public.lampadas_modelo(id);


--
-- Name: lampadas lampadas_lampada_tipo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lampadas
    ADD CONSTRAINT lampadas_lampada_tipo_id_fkey FOREIGN KEY (lampada_tipo_id) REFERENCES public.lampadas_tipo(id);


--
-- Name: log_chatbot log_chatbot_usuarios_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_chatbot
    ADD CONSTRAINT log_chatbot_usuarios_id_fk FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: logs log_usuario_alteracao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT log_usuario_alteracao_fkey FOREIGN KEY (usuario_alteracao) REFERENCES public.usuarios(id);


--
-- Name: n_log log_usuario_alteracao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.n_log
    ADD CONSTRAINT log_usuario_alteracao_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: reciclagems reciclagems_contratos_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagems
    ADD CONSTRAINT reciclagems_contratos_id_fk FOREIGN KEY (contrato_origem_id) REFERENCES public.contratos(id);


--
-- Name: reciclagems reciclagems_reciclagem_integracao_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagems
    ADD CONSTRAINT reciclagems_reciclagem_integracao_id_fk FOREIGN KEY (integracao_id) REFERENCES public.reciclagem_integracao(id);


--
-- Name: refrigeradors refrigeradors_equipamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refrigeradors
    ADD CONSTRAINT refrigeradors_equipamento_id_fkey FOREIGN KEY (equipamento_id) REFERENCES public.equipamentos(id);


--
-- Name: reserva_lampadas_vistoria_pngd reserva_lampadas_vistoria_pngd_vistoria_d_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reserva_lampadas_vistoria_pngd
    ADD CONSTRAINT reserva_lampadas_vistoria_pngd_vistoria_d_id_fkey FOREIGN KEY (vistoria_d_id) REFERENCES public.vistoria_pngd(id);


--
-- Name: reciclagem_recursos rr_reciclador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_recursos
    ADD CONSTRAINT rr_reciclador_id_fkey FOREIGN KEY (reciclador_id) REFERENCES public.recicladors(id);


--
-- Name: reciclagem_recursos rr_vigencia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reciclagem_recursos
    ADD CONSTRAINT rr_vigencia_id_fkey FOREIGN KEY (vigencia_id) REFERENCES public.vigencias(id);


--
-- Name: sucatas_pngd sucata_pngd_equipamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_pngd
    ADD CONSTRAINT sucata_pngd_equipamento_id_fkey FOREIGN KEY (equipamento_id) REFERENCES public.equipamentos(id);


--
-- Name: sucatas_lampada sucatas_lampadas_doacao_lampada_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_lampada
    ADD CONSTRAINT sucatas_lampadas_doacao_lampada_id_fkey FOREIGN KEY (doacao_lampada_id) REFERENCES public.doacao_lampadas(id) ON DELETE CASCADE;


--
-- Name: sucatas_lampada sucatas_lampadas_lampada_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sucatas_lampada
    ADD CONSTRAINT sucatas_lampadas_lampada_id_fkey FOREIGN KEY (lampada_id) REFERENCES public.lampadas_tipo(id) ON DELETE CASCADE;


--
-- Name: triagem_pngd triagem_pngd_cliente_evento_contrato_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngd
    ADD CONSTRAINT triagem_pngd_cliente_evento_contrato_id_fkey FOREIGN KEY (cliente_evento_contrato_id) REFERENCES public.clientes_eventos_contratos(id) ON DELETE CASCADE;


--
-- Name: triagem_pngv triagem_pngv_cliente_contrato_projeto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.triagem_pngv
    ADD CONSTRAINT triagem_pngv_cliente_contrato_projeto_id_fkey FOREIGN KEY (cliente_contrato_projeto_id) REFERENCES public.clientes_contratos_projetos(id) ON DELETE CASCADE;


--
-- Name: veiculo veiculo_tipo_veiculo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.veiculo
    ADD CONSTRAINT veiculo_tipo_veiculo_id_fkey FOREIGN KEY (tipo_veiculo_id) REFERENCES public.tipo_veiculo(id);


--
-- Name: venda_historicos vendas_historico_usuario_alteracao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_historicos
    ADD CONSTRAINT vendas_historico_usuario_alteracao_fkey FOREIGN KEY (usuario_alteracao) REFERENCES public.usuarios(id);


--
-- Name: venda_historicos vendas_historico_vendas_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venda_historicos
    ADD CONSTRAINT vendas_historico_vendas_id_fkey FOREIGN KEY (vendas_id) REFERENCES public.vendas(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251219200000'),
('20251219174013'),
('20251218192107'),
('20251215134243');

