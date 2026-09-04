-- ==============================================================================
-- Carga Inicial de Dados Administrativos Governamentais
-- Simulação de Sistemas de Gestão Pública para Testes de Auditoria Contínua
-- ==============================================================================

-- Inserção de Órgãos Públicos
INSERT INTO orgaos (codigo_ug, nome, sigla, esfera) VALUES
('210001', 'Secretaria de Estado de Fazenda', 'SEFAZ', 'ESTADUAL'),
('210002', 'Secretaria de Estado de Educação', 'SEDUC', 'ESTADUAL'),
('210003', 'Secretaria de Estado de Saúde', 'SES', 'ESTADUAL'),
('210004', 'Controladoria Geral do Estado', 'CGE', 'ESTADUAL'),
('210005', 'Secretaria de Estado de Segurança Pública', 'SESP', 'ESTADUAL')
ON CONFLICT (codigo_ug) DO NOTHING;

-- Inserção de Credores / Fornecedores
INSERT INTO credores (cpf_cnpj, razao_social, tipo_pessoa, municipio, uf, situacao_cadastral) VALUES
('01.234.567/0001-89', 'TechGov Soluções em Tecnologia da Informação Ltda', 'PJ', 'Cuiabá', 'MT', 'REGULAR'),
('12.345.678/0001-90', 'Construtora e Pavimentação Centro-Oeste S/A', 'PJ', 'Várzea Grande', 'MT', 'REGULAR'),
('23.456.789/0001-01', 'Distribuidora Farmacêutica Vida & Saúde Ltda', 'PJ', 'Rondonópolis', 'MT', 'REGULAR'),
('34.567.890/0001-12', 'Editora e Distribuidora de Livros Didáticos do Brasil', 'PJ', 'São Paulo', 'SP', 'REGULAR'),
('45.678.901/0001-23', 'Segurança Integrada e Vigilância Armada Ltda', 'PJ', 'Cuiabá', 'MT', 'REGULAR')
ON CONFLICT (cpf_cnpj) DO NOTHING;

-- Inserção de Empenhos Iniciais
INSERT INTO empenhos (numero_empenho, ano_exercicio, orgao_id, credor_id, modalidade_licitacao, numero_processo, valor_empenhado, descricao_objeto, status) VALUES
('2026NE000142', 2026, 1, 1, 'PREGÃO ELETRÔNICO', 'PRO-10293/2026', 154000.00, 'Prestação de serviços de sustentação de infraestrutura em nuvem e lakehouse.', 'LIQUIDADO'),
('2026NE000143', 2026, 2, 4, 'PREGÃO ELETRÔNICO', 'PRO-10455/2026', 420000.00, 'Aquisição de material didático e kits escolares para a rede pública de ensino.', 'PARCIALMENTE_LIQUIDADO'),
('2026NE000144', 2026, 3, 3, 'DISPENSA DE LICITAÇÃO', 'PRO-10882/2026', 890000.00, 'Fornecimento emergencial de insumos hospitalares e medicamentos essenciais.', 'LIQUIDADO'),
('2026NE000145', 2026, 4, 1, 'PREGÃO ELETRÔNICO', 'PRO-11002/2026', 75000.00, 'Licenciamento de software para trilhas de auditoria contínua e análise preditiva.', 'PAGO'),
('2026NE000146', 2026, 5, 5, 'PREGÃO ELETRÔNICO', 'PRO-11230/2026', 310000.00, 'Serviços continuados de monitoramento eletrônico e vigilância patrimonial.', 'EMITIDO')
ON CONFLICT (numero_empenho) DO NOTHING;

-- Inserção de Liquidações Iniciais
INSERT INTO liquidacoes (numero_liquidacao, empenho_id, valor_liquidado, numero_nota_fiscal, atestado_por) VALUES
('2026NL000085', 1, 154000.00, 'NFE-89410', 'Fiscal de Contrato - Matrícula 58291'),
('2026NL000086', 2, 210000.00, 'NFE-10294', 'Comissão de Recebimento de Materiais SEDUC'),
('2026NL000087', 3, 890000.00, 'NFE-55421', 'Diretoria de Farmácia e Suprimentos SES'),
('2026NL000088', 4, 75000.00, 'NFE-99214', 'Auditor Governamental CGE - Matrícula 9821')
ON CONFLICT (numero_liquidacao) DO NOTHING;

-- Inserção de Pagamentos Iniciais
INSERT INTO pagamentos (numero_ordem_bancaria, liquidacao_id, valor_pago, agencia_origem, conta_origem, status) VALUES
('2026OB000051', 1, 154000.00, '3321-0', '10928-1', 'EFETIVADO'),
('2026OB000052', 3, 890000.00, '3321-0', '10928-1', 'EFETIVADO'),
('2026OB000053', 4, 75000.00, '3321-0', '10928-1', 'EFETIVADO')
ON CONFLICT (numero_ordem_bancaria) DO NOTHING;
