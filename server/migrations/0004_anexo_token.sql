-- 0004: token público (UUID) para download de anexos.
-- A URL de download é pública (aberta direto no navegador/dispositivo, onde não
-- há como enviar o header Authorization). Para que um curioso não consiga
-- adivinhar/enumerar anexos pelos IDs sequenciais, o download passa a usar este
-- token UUID não-adivinhável em vez do id numérico.

ALTER TABLE chamado_anexos
  ADD COLUMN IF NOT EXISTS token uuid NOT NULL DEFAULT gen_random_uuid();

-- Unicidade do token (identificador público na URL de download).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chamado_anexos_token_key'
  ) THEN
    ALTER TABLE chamado_anexos
      ADD CONSTRAINT chamado_anexos_token_key UNIQUE (token);
  END IF;
END $$;
