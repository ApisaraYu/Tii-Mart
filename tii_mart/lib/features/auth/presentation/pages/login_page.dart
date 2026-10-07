import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../state/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // สำเร็จแล้ว router จะพาไปหน้าตามบทบาทเอง ไม่ต้องสั่งเปลี่ยนหน้า
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text.trim()),
    );
    if (email == null) return;
    final ok =
        await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่อีเมลแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ล็อกอินสำเร็จ (มีผู้ใช้) → ไปหน้าตามบทบาททันที ไม่รอ router redirect
    ref.listen(currentUserProvider, (prev, next) {
      if (next == null) return;
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      final backTo = (!next.isSeller &&
              from != null &&
              (from == '/' || from.startsWith('/product/')))
          ? from
          : null;
      context.go(backTo ?? (next.isSeller ? '/seller' : '/'));
    });
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'TiiMart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'เข้าสู่ระบบ',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _email,
                      label: 'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      enabled: !loading,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _password,
                      label: 'รหัสผ่าน',
                      obscure: true,
                      validator: Validators.password,
                      enabled: !loading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.password],
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: loading ? null : _forgotPassword,
                        child: const Text('ลืมรหัสผ่าน'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'เข้าสู่ระบบ',
                      loading: loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading ? null : () => context.push('/signup'),
                      child: const Text('สร้างบัญชีผู้ใช้ใหม่'),
                    ),
                    TextButton(
                      onPressed: loading ? null : () => context.go('/'),
                      child: const Text('ดูสินค้าก่อน'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ลืมรหัสผ่าน'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรอกอีเมลที่ใช้สมัคร ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ให้'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _email,
              label: 'อีเมล',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _email.text.trim());
            }
          },
          child: const Text('ส่งลิงก์'),
        ),
      ],
    );
  }
}
