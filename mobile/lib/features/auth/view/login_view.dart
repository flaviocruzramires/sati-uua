import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/forms/app_checkbox_row.dart';
import '../../../core/widgets/forms/app_text_field.dart';
import '../../../core/widgets/surfaces/section_divider.dart';
import '../view_model/login_view_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _loginCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _lembrar = false;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loginCtrl.text.trim().isEmpty || _senhaCtrl.text.isEmpty) return;
    final ok = await ref
        .read(loginViewModelProvider.notifier)
        .login(_loginCtrl.text, _senhaCtrl.text);
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      body: isDesktop
          ? _DesktopLayout(
              loginCtrl: _loginCtrl,
              senhaCtrl: _senhaCtrl,
              lembrar: _lembrar,
              onLembrarChanged: (v) => setState(() => _lembrar = v),
              onSubmit: _submit,
              state: state,
            )
          : _MobileLayout(
              loginCtrl: _loginCtrl,
              senhaCtrl: _senhaCtrl,
              lembrar: _lembrar,
              onLembrarChanged: (v) => setState(() => _lembrar = v),
              onSubmit: _submit,
              state: state,
            ),
    );
  }
}

// ── Desktop: split-screen 42/58 ─────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.loginCtrl,
    required this.senhaCtrl,
    required this.lembrar,
    required this.onLembrarChanged,
    required this.onSubmit,
    required this.state,
  });

  final TextEditingController loginCtrl;
  final TextEditingController senhaCtrl;
  final bool lembrar;
  final ValueChanged<bool> onLembrarChanged;
  final VoidCallback onSubmit;
  final LoginState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Painel esquerdo — 42%
        Flexible(flex: 42, child: _BrandPanel()),
        // Painel direito — 58%
        Flexible(
          flex: 58,
          child: Container(
            color: AppColors.bg,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _FormContent(
                  loginCtrl: loginCtrl,
                  senhaCtrl: senhaCtrl,
                  lembrar: lembrar,
                  onLembrarChanged: onLembrarChanged,
                  onSubmit: onSubmit,
                  state: state,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo placeholder + título
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                color: Colors.white,
                padding: const EdgeInsets.all(5),
                child: const FlutterLogo(),
              ),
              const SizedBox(width: AppSpacing.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SATI-UUA',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: AppColors.bg),
                  ),
                  Text(
                    'UEMS Aquidauana',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.bg.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Sistema de Atendimento de\nTecnologia da Informação',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.bg,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Registre, acompanhe e resolva solicitações de TI\nde forma rápida e organizada.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.bg.withAlpha(199),
            ),
          ),
          const Spacer(),
          Divider(color: Colors.white.withAlpha(56), thickness: 2),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'UEMS · Unidade Universitária Aquidauana',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.bg.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile: bloco superior + formulário ─────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.loginCtrl,
    required this.senhaCtrl,
    required this.lembrar,
    required this.onLembrarChanged,
    required this.onSubmit,
    required this.state,
  });

  final TextEditingController loginCtrl;
  final TextEditingController senhaCtrl;
  final bool lembrar;
  final ValueChanged<bool> onLembrarChanged;
  final VoidCallback onSubmit;
  final LoginState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bloco superior navy
        Container(
          width: double.infinity,
          height: 250,
          color: AppColors.navy,
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                color: Colors.white,
                padding: const EdgeInsets.all(5),
                child: const FlutterLogo(),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'SATI-UUA',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppColors.bg),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Sistema de Atendimento de TI — UEMS Aquidauana',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.bg.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
        // Formulário
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: AppSpacing.s6,
            ),
            child: _FormContent(
              loginCtrl: loginCtrl,
              senhaCtrl: senhaCtrl,
              lembrar: lembrar,
              onLembrarChanged: onLembrarChanged,
              onSubmit: onSubmit,
              state: state,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Formulário compartilhado ─────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.loginCtrl,
    required this.senhaCtrl,
    required this.lembrar,
    required this.onLembrarChanged,
    required this.onSubmit,
    required this.state,
  });

  final TextEditingController loginCtrl;
  final TextEditingController senhaCtrl;
  final bool lembrar;
  final ValueChanged<bool> onLembrarChanged;
  final VoidCallback onSubmit;
  final LoginState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Entrar', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.s1),
        Text(
          'Acesse com seu usuário institucional.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s6),
        AppTextField(
          label: 'Login',
          controller: loginCtrl,
          obrigatorio: true,
          hint: 'usuario.sobrenome',
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.s4),
        AppTextField(
          label: 'Senha',
          controller: senhaCtrl,
          obrigatorio: true,
          obscure: true,
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            AppCheckboxRow(
              label: 'Lembrar-me',
              value: lembrar,
              onChanged: onLembrarChanged,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'Esqueci minha senha',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.navy),
              ),
            ),
          ],
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            color: Colors.red.shade50,
            child: Text(
              state.errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red.shade700),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        AppButton(
          label: 'Entrar',
          onPressed: onSubmit,
          loading: state.loading,
          block: true,
          centerLabel: true,
        ),
        const SizedBox(height: AppSpacing.s6),
        const SectionDivider(),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Precisa de acesso? Fale com o Administrador de TI.',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
