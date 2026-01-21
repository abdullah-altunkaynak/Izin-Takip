import 'package:flutter/material.dart';
import '../../../core/routing/app_routes.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService().login(
        email: _email.text.trim(),
        password: _password.text,
      );
      // altta context üstte api olduğu için mounted kullanmak called after dispose hatası için
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
    } on AuthInvalidCredentialsException {
      setState(() => _error = "E-posta veya şifre hatalı.");
    } on AuthTokenMissingException {
      setState(() => _error = "Token alınamadı. Lütfen tekrar deneyin.");
    } catch (e, s) {
      debugPrint("LOGIN ERROR: $e");
      if(mounted) setState(() => _error = "Hata: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surface,
                  cs.surfaceContainerHighest,
                ],
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.event_available_outlined, color: cs.onPrimaryContainer),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "İzin Takip",
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Devam etmek için giriş yapın",
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _error == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                key: const ValueKey("err"),
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: cs.onErrorContainer),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(color: cs.onErrorContainer),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_error != null) const SizedBox(height: 12),

                            TextFormField(
                              controller: _email,
                              focusNode: _emailFocus,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: "E-posta",
                                prefixIcon: Icon(Icons.mail_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final value = (v ?? "").trim();
                                if (value.isEmpty) return "E-posta gerekli.";
                                if (!value.contains("@")) return "Geçerli bir e-posta girin.";
                                return null;
                              },
                              onFieldSubmitted: (_) => _passFocus.requestFocus(),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _password,
                              focusNode: _passFocus,
                              enabled: !_loading,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: "Şifre",
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  onPressed: _loading ? null : () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (v) {
                                if ((v ?? "").isEmpty) return "Şifre gerekli.";
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 16),

                            // Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: const Text("Giriş Yap"),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "Giriş yaparken token alınana kadar beklenir.",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.18),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text("Giriş yapılıyor..."),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthInvalidCredentialsException implements Exception {}

class AuthTokenMissingException implements Exception {}
