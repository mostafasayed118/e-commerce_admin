import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/result.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../router/admin_session.dart';

/// The admin gate: shows a "set a PIN" form on first run or an "enter PIN"
/// form afterwards (the repository decides which). On success it unlocks the
/// [AdminSession] and the router guard lets navigation through.
///
/// Deliberately a plain StatefulWidget, not a Cubit (Section C.3): the gate
/// is a single two-branch form with one action — the same judgment as the
/// checkout screen. A state machine would be ceremony for a set/enter flow.
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  late final Future<bool> _pinSetFuture;
  final TextEditingController _pinController = TextEditingController();
  bool _submitting = false;
  String? _error;

  SettingsRepository get _settings => getIt<SettingsRepository>();

  @override
  void initState() {
    super.initState();
    _pinSetFuture = _settings.isPinSet().then((result) => result.fold(
      onSuccess: (isSet) => isSet,
      // A read failure defaults to the ENTER branch, deliberately: the other
      // direction (show "set a PIN") could let a user overwrite an existing
      // PIN after a failed read; entering and failing is recoverable.
      onFailure: (_) => true,
    ));
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isSetting) async {
    final pin = _pinController.text;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final result =
        isSetting ? await _settings.setPin(pin) : await _settings.verifyPin(pin);

    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        getIt<AdminSession>().unlocked = true;
        context.go('/admin/overview');
      },
      onFailure: (error) {
        setState(() {
          _submitting = false;
          _error = error.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<bool>(
              future: _pinSetFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Could not check PIN status. Please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final isSetting = !snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined,
                        size: 56, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      isSetting ? 'Set an admin PIN' : 'Enter admin PIN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSetting
                          ? 'Create a 4-6 digit PIN to lock the dashboard.'
                          : 'Unlock the dashboard with your PIN.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(isSetting),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : () => _submit(isSetting),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isSetting ? 'Set PIN' : 'Unlock'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
