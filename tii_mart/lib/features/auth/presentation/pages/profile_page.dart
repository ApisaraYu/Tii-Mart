import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../state/auth_providers.dart';

/// แก้ไขโปรไฟล์ + ออกจากระบบ
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _username;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _username = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          uid: uid,
          firstName: _firstName.text,
          lastName: _lastName.text,
          phone: _phone.text,
          username: _username.text,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกโปรไฟล์เรียบร้อย')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ออกจากระบบแล้ว (ผู้ใช้เป็น null) → กลับหน้าแรกแบบผู้เยี่ยมชมทันที
    ref.listen(currentUserProvider, (prev, next) {
      if (next == null) context.go('/');
    });
    ref.listen<AsyncValue<void>>(authControllerProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(errorMessage(next.error))));
      }
    });
    final loading = ref.watch(authControllerProvider).isLoading;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ของฉัน')),
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: Text(user.email),
                      subtitle: Text('สถานะ: ${user.role.label}'),
                    ),
                    const SizedBox(height: 8),
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
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'บันทึก',
                      loading: loading,
                      onPressed: () => _save(user.uid),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: loading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('ออกจากระบบ'),
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
