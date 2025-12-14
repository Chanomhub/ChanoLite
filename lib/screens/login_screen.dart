import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/screens/registration_screen.dart';
import 'package:chanolite/services/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _showAccountForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AuthManager auth) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    try {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _showAccountForm = false;
        _emailController.clear();
        _passwordController.clear();
      });
      await _maybePopOnSuccess();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    }
  }

  Future<void> _handleSelectAccount(AuthManager auth, User user) async {
    try {
      await auth.setActiveAccount(user);
      await _maybePopOnSuccess();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to switch account: $error')),
      );
    }
  }

  Future<void> _handleSignOutAll(AuthManager auth) async {
    await auth.signOutAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _showAccountForm = true;
    });
  }

  Future<void> _maybePopOnSuccess() async {
    if (!mounted) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _handleGoogleSignIn(AuthManager auth) async {
    try {
      await auth.loginWithGoogle();
      if (!mounted) {
        return;
      }
      setState(() {
        _showAccountForm = false;
      });
      await _maybePopOnSuccess();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $error')),
      );
    }
  }

  Widget _buildAvatar(ThemeData theme, User user) {
    final background = theme.colorScheme.primaryContainer;
    final foreground = theme.colorScheme.onPrimaryContainer;
    final imageUrl = user.image ?? '';
    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person, color: foreground),
              ),
            )
          : Icon(Icons.person, color: foreground),
    );
  }

  Widget _buildAccountList(AuthManager auth, ThemeData theme) {
    final accounts = auth.accounts;
    return ListView(
      key: const ValueKey('account-list'),
      children: [
        ...accounts.map(
          (user) => Card(
            child: ListTile(
              leading: _buildAvatar(theme, user),
              title: Text(user.username),
              subtitle: Text(user.email),
              trailing: auth.activeAccount?.username == user.username
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: auth.isLoading ? null : () => _handleSelectAccount(auth, user),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _showAccountForm = true;
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add another account'),
        ),
        TextButton(
          onPressed: auth.accounts.isEmpty || auth.isLoading ? null : () => _handleSignOutAll(auth),
          child: const Text('Sign out of all accounts'),
        ),
      ],
    );
  }

  Widget _buildSignInForm(AuthManager auth, ThemeData theme, bool hasAccounts) {
    return Form(
      key: _formKey,
      child: ListView(
        key: const ValueKey('sign-in-form'),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password too short';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : () => _handleSubmit(auth),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ),
          // Google SSO Button - only show if Supabase is available
          if (SupabaseAuthService.instance.isAvailable) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: auth.isLoading ? null : () => _handleGoogleSignIn(auth),
                icon: Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.login),
                ),
                label: const Text('Sign in with Google'),
              ),
            ),
          ],
          TextButton(
            onPressed: auth.isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(),
                      ),
                    );
                  },
            child: const Text("Don't have an account? Sign up"),
          ),
          if (hasAccounts)
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () {
                      setState(() {
                        _showAccountForm = false;
                      });
                    },
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AuthManager>(
      builder: (context, auth, _) {
        final accounts = auth.accounts;
        final showForm = accounts.isEmpty || _showAccountForm;

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (auth.isLoading)
                    const LinearProgressIndicator(),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.videogame_asset,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ChanoLite',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showForm ? 'Sign in to continue' : 'Choose an account',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: showForm
                          ? _buildSignInForm(auth, theme, accounts.isNotEmpty)
                          : _buildAccountList(auth, theme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
