-- ==============================================================================
-- Script de Inicialização da Origem Transacional (PostgreSQL)
-- Criação de Usuários de Replicação CDC, Permissões e Esquema Governamental
-- ==============================================================================

-- 1. Criação do Usuário de Replicação para o Debezium
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'debezium') THEN
        CREATE ROLE debezium WITH REPLICATION LOGIN PASSWORD 'dbz_secure_pwd';
    END IF;
END
$$;

-- 2. Concessão de Privilégios no Banco e Esquema
GRANT CONNECT ON DATABASE gestao_publica TO debezium;
GRANT USAGE ON SCHEMA public TO debezium;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium;

-- 3. Criação da Estrutura Relacional (Execução Orçamentária e Financeira Pública)

-- Tabela de Órgãos e Unidades Gestoras Governamentais
CREATE TABLE IF NOT EXISTS orgaos (
    id SERIAL PRIMARY KEY,
    codigo_ug VARCHAR(10) NOT NULL UNIQUE,
    nome VARCHAR(150) NOT NULL,
    sigla VARCHAR(20) NOT NULL,
    esfera VARCHAR(20) DEFAULT 'ESTADUAL',
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Credores / Fornecedores da Administração Pública
CREATE TABLE IF NOT EXISTS credores (
    id SERIAL PRIMARY KEY,
    cpf_cnpj VARCHAR(18) NOT NULL UNIQUE,
    razao_social VARCHAR(200) NOT NULL,
    tipo_pessoa VARCHAR(2) NOT NULL CHECK (tipo_pessoa IN ('PF', 'PJ')),
    municipio VARCHAR(100),
    uf VARCHAR(2),
    situacao_cadastral VARCHAR(30) DEFAULT 'REGULAR',
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Empenhos de Despesa Pública
CREATE TABLE IF NOT EXISTS empenhos (
    id BIGSERIAL PRIMARY KEY,
    numero_empenho VARCHAR(30) NOT NULL UNIQUE,
    ano_exercicio INT NOT NULL,
    orgao_id INT NOT NULL REFERENCES orgaos(id),
    credor_id INT NOT NULL REFERENCES credores(id),
    modalidade_licitacao VARCHAR(50) NOT NULL,
    numero_processo VARCHAR(50),
    valor_empenhado NUMERIC(15, 2) NOT NULL,
    valor_anulado NUMERIC(15, 2) DEFAULT 0.00,
    descricao_objeto TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'EMITIDO' CHECK (status IN ('EMITIDO', 'PARCIALMENTE_LIQUIDADO', 'LIQUIDADO', 'PAGO', 'ANULADO')),
    data_emissao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Liquidações (Comprovação da entrega do bem/serviço)
CREATE TABLE IF NOT EXISTS liquidacoes (
    id BIGSERIAL PRIMARY KEY,
    numero_liquidacao VARCHAR(30) NOT NULL UNIQUE,
    empenho_id BIGINT NOT NULL REFERENCES empenhos(id) ON DELETE CASCADE,
    valor_liquidado NUMERIC(15, 2) NOT NULL,
    numero_nota_fiscal VARCHAR(60),
    atestado_por VARCHAR(100) NOT NULL,
    data_liquidacao TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Ordens Bancárias e Pagamentos Efetuados
CREATE TABLE IF NOT EXISTS pagamentos (
    id BIGSERIAL PRIMARY KEY,
    numero_ordem_bancaria VARCHAR(30) NOT NULL UNIQUE,
    liquidacao_id BIGINT NOT NULL REFERENCES liquidacoes(id) ON DELETE CASCADE,
    valor_pago NUMERIC(15, 2) NOT NULL,
    banco_origem VARCHAR(10) DEFAULT '001',
    agencia_origem VARCHAR(10),
    conta_origem VARCHAR(20),
    data_pagamento TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'EFETIVADO' CHECK (status IN ('EFETIVADO', 'ESTORNADO', 'PENDENTE')),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Permissões de Leitura para o Debezium em todas as tabelas
GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;

-- 5. Configuração de Identidade de Réplica Completa (REPLICA IDENTITY FULL)
-- Garante que o Debezium receba a imagem anterior completa ("before") em eventos de UPDATE e DELETE
ALTER TABLE orgaos REPLICA IDENTITY FULL;
ALTER TABLE credores REPLICA IDENTITY FULL;
ALTER TABLE empenhos REPLICA IDENTITY FULL;
ALTER TABLE liquidacoes REPLICA IDENTITY FULL;
ALTER TABLE pagamentos REPLICA IDENTITY FULL;

-- 6. Criação da Publicação PostgreSQL para o conector Debezium
-- A publicação agrupa as tabelas que terão suas mutações emitidas via WAL lógico
DROP PUBLICATION IF EXISTS dbz_publication;
CREATE PUBLICATION dbz_publication FOR TABLE orgaos, credores, empenhos, liquidacoes, pagamentos;
