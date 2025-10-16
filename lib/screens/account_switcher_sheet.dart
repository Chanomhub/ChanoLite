import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/models/user_model.dart';
import 'package:chanolite/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AuthManager>(
      builder: (context, auth, _) {
        final accounts = auth.accounts;
        final active = auth.activeAccount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Accounts',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final user = accounts[index];
                    return _AccountTile(
                      user: user,
                      active: active?.username == user.username,
                      onTap: () async {
                        await auth.setActiveAccount(user);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      onRemove: () async {
                        await auth.removeAccount(user);
                        if (context.mounted && auth.accounts.isEmpty) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add account'),
                ),
              ),
              TextButton(
                onPressed: auth.accounts.isEmpty
                    ? null
                    : () async {
                        await auth.signOutAll();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: const Text('Sign out of all accounts'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.user,
    required this.active,
    required this.onTap,
    required this.onRemove,
  });

  final User user;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: (user.image ?? '').isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    user.image!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                  ),
                )
              : Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(user.username),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () async {
                final shouldRemove = await showModalBottomSheet<bool>(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Remove account'),
                            onTap: () => Navigator.of(context).pop(true),
                          ),
                          ListTile(
                            leading: const Icon(Icons.close),
                            title: const Text('Cancel'),
                            onTap: () => Navigator.of(context).pop(false),
                          ),
                        ],
                      ),
                    );
                  },
                );
                if (shouldRemove == true) {
                  onRemove();
                }
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
