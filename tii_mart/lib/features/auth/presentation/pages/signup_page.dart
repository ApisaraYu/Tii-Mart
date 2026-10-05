import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../state/auth_providers.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _wantsShop = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // สำเร็จแล้วระบบล็อกอินให้เอง และ router จะพาไปหน้าตามบทบาท
    await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text,
          password: _password.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
          phone: _phone.text,
          username: _username.text,
          wantsShop: _wantsShop,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final loading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _firstName,
                      label: 'ชื่อจริง',
                      validator: (v) => Validators.required(v, 'ชื่อจริง'),
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _lastName,
                      label: 'นามสกุล',
                      validator: (v) => Validators.required(v, 'นามสกุล'),
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _phone,
                      label: 'เบอร์โทรศัพท์',
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _username,
                      label: 'ชื่อผู้ใช้',
                      validator: Validators.username,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _email,
                      label: 'อีเมล',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      enabled: !loading,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _password,
                      label: 'รหัสผ่าน (อย่างน้อย 6 ตัวอักษร)',
                      obscure: true,
                      validator: Validators.password,
                      enabled: !loading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      value: _wantsShop,
                      onChanged: loading
                          ? null
                          : (v) => setState(() => _wantsShop = v ?? false),
                      title: const Text('ต้องการเปิดร้านค้า'),
                      subtitle: const Text('เจ้าของร้านจะมีหน้าจัดการร้านเพิ่มเติม'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'สมัครสมาชิก',
                      loading: loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading ? null : () => context.go('/login'),
                      child: const Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'),
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
