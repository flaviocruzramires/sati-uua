-- Seed mínimo de desenvolvimento (rotina 00) — NUNCA rodar em produção.
-- 1 setor "TI" + 1 usuário ADMIN com senha de desenvolvimento conhecida.
--
-- Login: admin.ti   |   Senha: admin123
-- (hash bcrypt gerado com custo 10 — compatível com o pacote `bcrypt` do
-- servidor Dart; troque a senha em qualquer ambiente que não seja local).

INSERT INTO setores (nome)
VALUES ('TI')
ON CONFLICT (nome) DO NOTHING;

INSERT INTO usuarios (nome, email, login, senha_hash, setor_id, papel, ativo)
SELECT
  'Administrador TI',
  'admin.ti@uems.br',
  'admin.ti',
  '$2b$10$tP0QAi774KoASEA0bTcG6eOaRL5ff.4p7/iwODSnpWNYlPUIJNQ7O',
  s.id,
  'ADMIN',
  true
FROM setores s
WHERE s.nome = 'TI'
ON CONFLICT (login) DO NOTHING;
