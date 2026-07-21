import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chanolite/managers/auth_manager.dart';
import 'package:chanolite/screens/account_switcher_sheet.dart';
import 'package:chanolite/screens/login_screen.dart';

class AccountAvatarButton extends StatelessWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthManager>(
      builder: (context, auth, _) {
        final theme = Theme.of(context);
        final user = auth.activeAccount;
        final hasAccounts = auth.accounts.isNotEmpty;

        Widget avatar;
        if (user != null && (user.image?.isNotEmpty ?? false)) {
          avatar = CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(user.image!),
            backgroundColor: theme.colorScheme.primaryContainer,
          );
        } else {
          final label = user?.username.isNotEmpty == true
              ? user!.username[0].toUpperCase()
              : '+';
          avatar = CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(label),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                if (hasAccounts) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const AccountSwitcherSheet(),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: avatar,
              ),
            ),
          ),
        );
      },
    );
  }
}
