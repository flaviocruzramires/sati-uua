-- Seed de desenvolvimento (rotina 10) — NUNCA rodar em produção.
-- 1 usuário GERENCIA no setor "TI" para testar o novo papel de ponta a ponta.
--
-- Login: gerente.ti   |   Senha: admin123
-- (mesmo hash bcrypt de desenvolvimento usado no 0001_seed_admin.sql — troque
-- a senha em qualquer ambiente que não seja local).
--
-- Depende de: 0005_papel_gerencia.sql (enum já estendido) e do setor "TI" do
-- 0001_seed_admin.sql.

INSERT INTO usuarios (nome, email, login, senha_hash, setor_id, papel, ativo)
SELECT
  'Gerente TI',
  'gerente.ti@uems.br',
  'gerente.ti',
  '$2b$10$tP0QAi774KoASEA0bTcG6eOaRL5ff.4p7/iwODSnpWNYlPUIJNQ7O',
  s.id,
  'GERENCIA',
  true
FROM setores s
WHERE s.nome = 'TI'
ON CONFLICT (login) DO NOTHING;
