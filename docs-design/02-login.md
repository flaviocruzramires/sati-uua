# 02 — Login

Requisito: acesso (rotina 01 — autenticação JWT). Pré-login, sem shell.
Mockup: `Login.dc.html`.

## Objetivo
Autenticar com **login** + **senha** institucionais. Erro genérico 401 (não
dizer se errou login ou senha).

## Layout Web (split-screen)
- **Painel esquerdo (42%, fundo `accent` navy, texto `bg`):**
  - Topo: logo (52×52, fundo branco padding 5) + "SATI-UUA" (h5) + "UEMS Aquidauana".
  - Meio: h1 34px "Sistema de Atendimento de Tecnologia da Informação" + parágrafo
    de apoio (opacidade .78, máx 380px).
  - Rodapé: régua 2px (branco 22%) + "UEMS · Unidade Universitária Aquidauana".
- **Painel direito (58%, fundo `bg`, form centralizado máx 360px):**
  - h2 "Entrar" + subtítulo muted "Acesse com seu usuário institucional."
  - Campo **Login** (`input`, placeholder `usuario.sobrenome`).
  - Campo **Senha** (`input type=password`).
  - Linha: checkbox "Lembrar-me" + link ghost "Esqueci minha senha".
  - Botão **primário block** "Entrar" (navy).
  - Régua `hr` + nota 12px muted "Precisa de acesso? Fale com o Administrador de TI".

## Layout Mobile
- Bloco superior (250px, fundo navy): logo 56×56, "SATI-UUA", tagline centralizada.
- Folha inferior (fundo `bg`, padding 28×24): h3 "Entrar" + subtítulo, campos
  Login e Senha, link "Esqueci minha senha", botão primário block, nota final.

## Componentes DS
`.field`+`label`+`.input`, `.btn.btn-primary.btn-block`, `.btn-ghost`, `.hr`.

## Campos / validação
| Campo | Tipo | Regra |
|---|---|---|
| login | texto | obrigatório |
| senha | password | obrigatório; força mín. 8 no cadastro (aqui só presença) |
| lembrar-me | checkbox | opcional (armazenamento seguro do token) |

## Estados
- Loading no botão durante autenticação.
- Erro: banner/inline **genérico** ("Login ou senha inválidos"), sem detalhar.
- Sucesso: redireciona à rota inicial conforme papel.

## Flutter
`LoginView` + `LoginViewModel` (Riverpod `AsyncNotifier`); token em
`flutter_secure_storage`; `LayoutBuilder` alterna split (web) × empilhado (mobile).
