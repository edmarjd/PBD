import os

import streamlit as st
import pandas as pd
import psycopg2


TABELAS = [
    "departamento",
    "curso",
    "professor",
    "aluno",
    "disciplina",
    "turma",
    "ministra",
    "matricula_turma",
    "avaliacao",
]


@st.cache_resource
def conectar():
    return psycopg2.connect(
        host="127.0.0.1",
        port=5432,
        dbname="banco_uf",
        user="postgres",
        password="1234",
    )
def obter_colunas(tabela):
    sql = '''
        SELECT
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = %s
        ORDER BY ordinal_position;
    '''

    conexao = conectar()

    with conexao.cursor() as cursor:
        cursor.execute(sql, (tabela,))
        return cursor.fetchall()


def carregar_tabela(tabela):
    conexao = conectar()
    return pd.read_sql_query(
        f'SELECT * FROM "{tabela}" ORDER BY 1;',
        conexao,
    )


def pesquisar_tabela(tabela, termo):
    colunas = obter_colunas(tabela)
    nomes_colunas = [coluna[0] for coluna in colunas]

    condicoes = [
        f'CAST("{nome}" AS TEXT) ILIKE %s'
        for nome in nomes_colunas
    ]

    sql = f'''
        SELECT *
        FROM "{tabela}"
        WHERE {" OR ".join(condicoes)}
        ORDER BY 1;
    '''

    parametros = [f"%{termo}%"] * len(nomes_colunas)

    conexao = conectar()

    return pd.read_sql_query(
        sql,
        conexao,
        params=parametros,
    )


def converter_valor(valor, tipo):
    if valor == "":
        return None

    if tipo in ("integer", "bigint", "smallint"):
        return int(valor)

    if tipo in ("numeric", "decimal", "real", "double precision"):
        return float(valor)

    if tipo == "boolean":
        return valor.lower() in ("true", "1", "sim", "s")

    return valor


def inserir_registro(tabela, dados):
    colunas = list(dados.keys())
    valores = list(dados.values())

    nomes = ", ".join(f'"{coluna}"' for coluna in colunas)
    marcadores = ", ".join(["%s"] * len(colunas))

    sql = f'''
        INSERT INTO "{tabela}" ({nomes})
        VALUES ({marcadores});
    '''

    conexao = conectar()

    try:
        with conexao.cursor() as cursor:
            cursor.execute(sql, valores)

        conexao.commit()

    except Exception:
        conexao.rollback()
        raise


st.set_page_config(
    page_title="Sistema Acadêmico",
    layout="wide",
)

st.title("Sistema Acadêmico")

tabela = st.sidebar.selectbox(
    "Escolha uma tabela",
    TABELAS,
)

aba_visualizar, aba_pesquisar, aba_adicionar = st.tabs(
    ["Visualizar", "Pesquisar", "Adicionar"]
)


with aba_visualizar:
    st.subheader(f"Dados da tabela: {tabela}")

    try:
        dados = carregar_tabela(tabela)

        st.dataframe(
            dados,
            use_container_width=True,
            hide_index=True,
        )

        st.caption(
            f"{len(dados)} registro(s) encontrado(s)."
        )

    except Exception as erro:
        st.error(
            f"Erro ao carregar a tabela: {erro}"
        )


with aba_pesquisar:
    st.subheader(f"Pesquisar em: {tabela}")

    termo = st.text_input(
        "Digite um nome, número ou palavra",
        key="campo_pesquisa",
    )

    if termo:
        try:
            resultado = pesquisar_tabela(
                tabela,
                termo,
            )

            st.dataframe(
                resultado,
                use_container_width=True,
                hide_index=True,
            )

            st.caption(
                f"{len(resultado)} resultado(s) encontrado(s)."
            )

        except Exception as erro:
            st.error(
                f"Erro durante a pesquisa: {erro}"
            )
    else:
        st.info(
            "Digite algo para iniciar a pesquisa."
        )


with aba_adicionar:
    st.subheader(
        f"Adicionar registro em: {tabela}"
    )

    try:
        colunas = obter_colunas(tabela)

        colunas_formulario = [
            coluna
            for coluna in colunas
            if not (
                coluna[3]
                and str(coluna[3]).startswith("nextval")
            )
        ]

        with st.form(
            "formulario_adicionar",
            clear_on_submit=True,
        ):
            dados_novos = {}

            for nome, tipo, aceita_nulo, valor_padrao in colunas_formulario:
                obrigatorio = (
                    aceita_nulo == "NO"
                    and valor_padrao is None
                )

                asterisco = " *" if obrigatorio else ""

                if tipo == "text":
                    valor = st.text_area(
                        f"{nome}{asterisco}"
                    )
                else:
                    valor = st.text_input(
                        f"{nome}{asterisco}",
                        help=f"Tipo no banco: {tipo}",
                    )

                dados_novos[nome] = (
                    valor,
                    tipo,
                    obrigatorio,
                )

            enviar = st.form_submit_button(
                "Adicionar"
            )

        if enviar:
            dados_convertidos = {}
            campos_vazios = []

            for nome, dados_campo in dados_novos.items():
                valor, tipo, obrigatorio = dados_campo
                valor = valor.strip()

                if obrigatorio and valor == "":
                    campos_vazios.append(nome)
                else:
                    dados_convertidos[nome] = converter_valor(
                        valor,
                        tipo,
                    )

            if campos_vazios:
                st.warning(
                    "Preencha os campos obrigatórios: "
                    + ", ".join(campos_vazios)
                )
            else:
                try:
                    inserir_registro(
                        tabela,
                        dados_convertidos,
                    )

                    st.success(
                        "Registro adicionado com sucesso!"
                    )

                except Exception as erro:
                    st.error(
                        "Não foi possível adicionar o registro: "
                        f"{erro}"
                    )

    except Exception as erro:
        st.error(
            f"Erro ao montar o formulário: {erro}"
        )