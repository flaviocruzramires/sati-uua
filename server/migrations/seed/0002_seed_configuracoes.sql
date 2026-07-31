-- Seed de configuracoes padrao editaveis pela interface.
-- Chaves sensiveis (DB_*, JWT_SECRET, SMTP) nunca entram aqui.

INSERT INTO configuracoes (chave, valor, descricao, tipo) VALUES
  ('LOG_LEVEL',             'INFO',           'Nivel de log do servidor (DEBUG, INFO, WARN, ERROR)', 'string'),
  ('PAGINACAO_PADRAO',      '20',             'Quantidade de itens por pagina padrao',               'int'),
  ('TITULO_SISTEMA',        'SATI-UUA',       'Titulo exibido no cabecalho do sistema',              'string'),
  ('MENSAGEM_BOAS_VINDAS',  'Bem-vindo ao SATI-UUA. Faca login para continuar.', 'Mensagem exibida na tela de login', 'string'),
  ('SLA_HORAS_RESPOSTA',    '24',             'SLA em horas para primeira resposta ao chamado',      'int')
ON CONFLICT (chave) DO NOTHING;
