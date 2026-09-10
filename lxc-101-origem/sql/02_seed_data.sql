-- ==============================================================================
-- Carga Massiva de Dados Administrativos Governamentais
-- Simulação de Sistemas de Gestão Pública para Testes de Auditoria Contínua
-- ==============================================================================

-- 1. Inserção de Órgãos Públicos (Ampliando o escopo estadual)
INSERT INTO orgaos (codigo_ug, nome, sigla, esfera) VALUES
('210001', 'Secretaria de Estado de Fazenda', 'SEFAZ', 'ESTADUAL'),
('210002', 'Secretaria de Estado de Educação', 'SEDUC', 'ESTADUAL'),
('210003', 'Secretaria de Estado de Saúde', 'SES', 'ESTADUAL'),
('210004', 'Controladoria Geral do Estado', 'CGE', 'ESTADUAL'),
('210005', 'Secretaria de Estado de Segurança Pública', 'SESP', 'ESTADUAL'),
('210006', 'Secretaria de Estado de Infraestrutura e Logística', 'SINFRA', 'ESTADUAL'),
('210007', 'Secretaria de Estado de Meio Ambiente', 'SEMA', 'ESTADUAL'),
('210008', 'Departamento Estadual de Trânsito', 'DETRAN', 'ESTADUAL'),
('210009', 'Secretaria de Estado de Assistência Social', 'SETASC', 'ESTADUAL'),
('210010', 'Casa Civil', 'CC', 'ESTADUAL'),
('210011', 'Secretaria de Estado de Planejamento e Gestão', 'SEPLAG', 'ESTADUAL'),
('210012', 'Universidade do Estado', 'UNEMAT', 'ESTADUAL'),
('210013', 'Procuradoria Geral do Estado', 'PGE', 'ESTADUAL'),
('210014', 'Instituto de Defesa Agropecuária', 'INDEA', 'ESTADUAL'),
('210015', 'Secretaria de Estado de Cultura e Esporte', 'SECEL', 'ESTADUAL')
ON CONFLICT (codigo_ug) DO NOTHING;

-- 2. Inserção de Credores / Fornecedores (Diversificando setores econômicos)
INSERT INTO credores (cpf_cnpj, razao_social, tipo_pessoa, municipio, uf, situacao_cadastral) VALUES
('01.234.567/0001-89', 'TechGov Soluções em Tecnologia da Informação Ltda', 'PJ', 'Cuiabá', 'MT', 'REGULAR'),
('12.345.678/0001-90', 'Construtora e Pavimentação Centro-Oeste S/A', 'PJ', 'Várzea Grande', 'MT', 'REGULAR'),
('23.456.789/0001-01', 'Distribuidora Farmacêutica Vida & Saúde Ltda', 'PJ', 'Rondonópolis', 'MT', 'REGULAR'),
('34.567.890/0001-12', 'Editora e Distribuidora de Livros Didáticos do Brasil', 'PJ', 'São Paulo', 'SP', 'REGULAR'),
('45.678.901/0001-23', 'Segurança Integrada e Vigilância Armada Ltda', 'PJ', 'Cuiabá', 'MT', 'REGULAR'),
('56.789.012/0001-34', 'LocaFrota Aluguel de Veículos Eireli', 'PJ', 'Cuiabá', 'MT', 'REGULAR'),
('67.890.123/0001-45', 'AgroAlimentos Nutrição Escolar Ltda', 'PJ', 'Sinop', 'MT', 'REGULAR'),
('78.901.234/0001-56', 'CleanMax Serviços de Limpeza e Conservação S/A', 'PJ', 'Goiânia', 'GO', 'REGULAR'),
('89.012.345/0001-67', 'EcoConsult Auditoria e Gestão Ambiental Ltda', 'PJ', 'Curitiba', 'PR', 'REGULAR'),
('90.123.456/0001-78', 'Posto de Combustíveis Rota 163 S/A', 'PJ', 'Sorriso', 'MT', 'IRREGULAR'),
('09.876.543/0001-21', 'Móveis e Equipamentos Escritório Nobre Ltda', 'PJ', 'São Paulo', 'SP', 'REGULAR'),
('18.765.432/0001-10', 'InfraObras Engenharia e Pontes S/A', 'PJ', 'Belo Horizonte', 'MG', 'REGULAR'),
('27.654.321/0001-09', 'Eventos & Estruturas Tendas MT Ltda', 'PJ', 'Cuiabá', 'MT', 'REGULAR'),
('36.543.210/0001-98', 'Central de Ar Condicionado e Refrigeração Ltda', 'PJ', 'Várzea Grande', 'MT', 'REGULAR'),
('45.432.109/0001-87', 'João da Silva Consultoria ME', 'PF', 'Cuiabá', 'MT', 'REGULAR')
ON CONFLICT (cpf_cnpj) DO NOTHING;

-- 3. Inserção de Empenhos (Simulando diferentes modalidades e estágios)
-- Assumindo que os IDs dos órgãos vão de 1 a 15 e dos credores de 1 a 15
INSERT INTO empenhos (numero_empenho, ano_exercicio, orgao_id, credor_id, modalidade_licitacao, numero_processo, valor_empenhado, descricao_objeto, status) VALUES
-- Dados Originais Mantidos
('2026NE000142', 2026, 1, 1, 'PREGÃO ELETRÔNICO', 'PRO-10293/2026', 154000.00, 'Prestação de serviços de sustentação de infraestrutura em nuvem e lakehouse.', 'PAGO'),
('2026NE000143', 2026, 2, 4, 'PREGÃO ELETRÔNICO', 'PRO-10455/2026', 420000.00, 'Aquisição de material didático e kits escolares para a rede pública de ensino.', 'PARCIALMENTE_LIQUIDADO'),
('2026NE000144', 2026, 3, 3, 'DISPENSA DE LICITAÇÃO', 'PRO-10882/2026', 890000.00, 'Fornecimento emergencial de insumos hospitalares e medicamentos essenciais.', 'PAGO'),
('2026NE000145', 2026, 4, 1, 'INEXIGIBILIDADE', 'PRO-11002/2026', 75000.00, 'Licenciamento de software para trilhas de auditoria contínua e análise preditiva.', 'PAGO'),
('2026NE000146', 2026, 5, 5, 'PREGÃO ELETRÔNICO', 'PRO-11230/2026', 310000.00, 'Serviços continuados de monitoramento eletrônico e vigilância patrimonial.', 'LIQUIDADO'),
('2026NE000147', 2026, 6, 12, 'CONCORRÊNCIA PÚBLICA', 'PRO-12001/2026', 4500000.00, 'Obras de pavimentação e recuperação asfáltica da rodovia MT-251.', 'PARCIALMENTE_LIQUIDADO'),
('2026NE000148', 2026, 6, 2, 'CONCORRÊNCIA PÚBLICA', 'PRO-12005/2026', 2100000.00, 'Construção de ponte de concreto sobre o Rio Cuiabá.', 'EMITIDO'),
('2026NE000149', 2026, 2, 7, 'PREGÃO ELETRÔNICO', 'PRO-13010/2026', 850000.00, 'Fornecimento de gêneros alimentícios para merenda escolar.', 'LIQUIDADO'),
('2026NE000150', 2026, 11, 8, 'PREGÃO ELETRÔNICO', 'PRO-14022/2026', 560000.00, 'Serviço continuado de limpeza, conservação e higienização.', 'PAGO'),
('2026NE000151', 2026, 7, 9, 'TOMADA DE PREÇOS', 'PRO-15033/2026', 125000.00, 'Consultoria técnica para elaboração de relatórios de impacto ambiental (RIMA).', 'PAGO'),
('2026NE000152', 2026, 8, 6, 'PREGÃO ELETRÔNICO', 'PRO-16044/2026', 430000.00, 'Locação de frota de veículos leves para fiscalização de trânsito.', 'LIQUIDADO'),
('2026NE000153', 2026, 5, 10, 'PREGÃO ELETRÔNICO', 'PRO-17055/2026', 620000.00, 'Fornecimento parcelado de combustíveis (gasolina, diesel e etanol) para viaturas.', 'ANULADO'),
('2026NE000154', 2026, 12, 11, 'PREGÃO ELETRÔNICO', 'PRO-18066/2026', 95000.00, 'Aquisição de mobiliário ergonômico para os laboratórios e salas de aula.', 'PAGO'),
('2026NE000155', 2026, 15, 13, 'PREGÃO ELETRÔNICO', 'PRO-19077/2026', 150000.00, 'Locação de tendas, palcos e estrutura para festival regional de cultura.', 'LIQUIDADO'),
('2026NE000156', 2026, 9, 7, 'DISPENSA DE LICITAÇÃO', 'PRO-20088/2026', 340000.00, 'Aquisição emergencial de cestas básicas para atendimento a famílias vulneráveis.', 'PAGO'),
('2026NE000157', 2026, 3, 14, 'PREGÃO ELETRÔNICO', 'PRO-21099/2026', 88000.00, 'Manutenção preventiva e corretiva do sistema de refrigeração central do hospital regional.', 'EMITIDO'),
('2026NE000158', 2026, 13, 15, 'INEXIGIBILIDADE', 'PRO-22011/2026', 45000.00, 'Contratação de parecerista especializado em direito tributário internacional.', 'PAGO'),
('2026NE000159', 2026, 14, 6, 'PREGÃO ELETRÔNICO', 'PRO-23022/2026', 275000.00, 'Locação de caminhonetes 4x4 para fiscalização em áreas rurais.', 'PARCIALMENTE_LIQUIDADO'),
('2026NE000160', 2026, 1, 1, 'PREGÃO ELETRÔNICO', 'PRO-24033/2026', 315000.00, 'Expansão de licenças de banco de dados e suporte técnico nível 3.', 'EMITIDO')
ON CONFLICT (numero_empenho) DO NOTHING;

-- 4. Inserção de Liquidações (Fases de ateste do serviço/produto)
INSERT INTO liquidacoes (numero_liquidacao, empenho_id, valor_liquidado, numero_nota_fiscal, atestado_por) VALUES
-- Dados Originais Mantidos
('2026NL000085', 1, 154000.00, 'NFE-89410', 'Fiscal de Contrato - Matrícula 58291'),
('2026NL000086', 2, 210000.00, 'NFE-10294', 'Comissão de Recebimento de Materiais SEDUC'),
('2026NL000087', 3, 890000.00, 'NFE-55421', 'Diretoria de Farmácia e Suprimentos SES'),
('2026NL000088', 4, 75000.00, 'NFE-99214', 'Auditor Governamental CGE - Matrícula 9821'),
('2026NL000089', 5, 310000.00, 'NFE-12234', 'Superintendência de Patrimônio SESP'),
('2026NL000090', 6, 1500000.00, 'NFE-55431', 'Engenheiro Fiscal de Obra - CREA/MT 12345'),
('2026NL000091', 6, 1000000.00, 'NFE-55610', 'Engenheiro Fiscal de Obra - CREA/MT 12345'),
('2026NL000092', 8, 850000.00, 'NFE-00921', 'Nutricionista Responsável SEDUC'),
('2026NL000093', 9, 280000.00, 'NFE-11223', 'Gerente de Facilities SEPLAG'), 
('2026NL000094', 9, 280000.00, 'NFE-11456', 'Gerente de Facilities SEPLAG'),
('2026NL000095', 10, 125000.00, 'NFS-2241', 'Coordenador de Licenciamento SEMA'),
('2026NL000096', 11, 215000.00, 'NFE-44321', 'Diretoria de Frotas DETRAN'),
('2026NL000097', 11, 215000.00, 'NFE-44588', 'Diretoria de Frotas DETRAN'),
('2026NL000098', 13, 95000.00, 'NFE-77651', 'Almoxarifado Central UNEMAT'),
('2026NL000099', 14, 150000.00, 'NFS-00812', 'Comissão Organizadora SECEL'),
('2026NL000100', 15, 340000.00, 'NFE-90011', 'Assistente Social Chefe - CRESS/MT 891'),
('2026NL000101', 17, 45000.00, 'NFS-1011', 'Procurador Chefe PGE'),
('2026NL000102', 18, 137500.00, 'NFE-33211', 'Fiscal Administrativo INDEA')
ON CONFLICT (numero_liquidacao) DO NOTHING;

-- 5. Inserção de Pagamentos (Finalizando o ciclo da despesa)
INSERT INTO pagamentos (numero_ordem_bancaria, liquidacao_id, valor_pago, agencia_origem, conta_origem, status) VALUES
-- Dados Originais Mantidos
('2026OB000051', 1, 154000.00, '3321-0', '10928-1', 'EFETIVADO'),
('2026OB000052', 3, 890000.00, '3321-0', '10928-1', 'EFETIVADO'),
('2026OB000053', 4, 75000.00, '3321-0', '10928-1', 'EFETIVADO'),
('2026OB000054', 6, 1500000.00, '3321-0', '22910-X', 'EFETIVADO'),
('2026OB000055', 8, 850000.00, '3321-0', '44102-5', 'EFETIVADO'),
('2026OB000056', 9, 280000.00, '3321-0', '55122-3', 'EFETIVADO'),
('2026OB000057', 10, 280000.00, '3321-0', '55122-3', 'PROGRAMADO'),
('2026OB000058', 11, 125000.00, '3321-0', '88190-2', 'EFETIVADO'),
('2026OB000059', 12, 215000.00, '3321-0', '99120-1', 'EFETIVADO'),
('2026OB000060', 14, 95000.00, '3321-0', '77123-9', 'EFETIVADO'),
('2026OB000061', 16, 340000.00, '3321-0', '11290-8', 'EFETIVADO'),
('2026OB000062', 17, 45000.00, '3321-0', '33412-7', 'EFETIVADO'),
('2026OB000063', 5, 310000.00, '3321-0', '10928-1', 'REJEITADO_BANCO')
ON CONFLICT (numero_ordem_bancaria) DO NOTHING;