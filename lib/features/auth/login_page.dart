import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:ropacalapp/providers/auth_provider.dart';
import 'package:ropacalapp/providers/shift_provider.dart';
import 'package:ropacalapp/core/services/location_tracking_service.dart';
import 'package:ropacalapp/models/user.dart';
import 'package:ropacalapp/core/enums/user_role.dart';
import 'package:ropacalapp/core/utils/app_logger.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isObscured = useState(true);
    final authState = ref.watch(authNotifierProvider);
    final isPreloading = useState(false);
    final hasStartedPreload = useState(false); // Prevent duplicate runs

    // Note: Location tracking is now started in preloadAndNavigate() after login
    // This avoids starting GPS before user is authenticated

    // Pre-load shift data after successful login
    Future<void> preloadAndNavigate(User user) async {
      if (!context.mounted) return;
      if (hasStartedPreload.value) {
        return;
      }

      hasStartedPreload.value = true;
      isPreloading.value = true;

      // Start background location tracking immediately for drivers
      // This allows managers to see driver location and assign routes
      try {
        if (user.role == UserRole.driver) {
          AppLogger.general('📍 Driver logged in - starting background location tracking');
          await ref.read(locationTrackingServiceProvider).startBackgroundTracking();
        }
      } catch (e) {
        AppLogger.general('⚠️  Failed to start background tracking: $e');
      }

      // COMMENTED OUT: preloadRoute functionality not needed with Google Navigation SDK
      // Google Navigation handles all routing internally
      // try {
      //   final success = await ref
      //       .read(shiftNotifierProvider.notifier)
      //       .preloadRoute();
      //   if (success) {
      //     AppLogger.general('✅ Route pre-loaded successfully, navigating to home');
      //   } else {
      //     AppLogger.general('⚠️  Route pre-load failed, navigating anyway');
      //   }
      // } catch (e) {
      //   AppLogger.general('❌ Pre-load error: $e');
      // }

      // Navigate directly to home
      if (context.mounted) {
        isPreloading.value = false;
        context.go('/home');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bin Management',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscured.value,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          isObscured.value = !isObscured.value;
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) async {
                      if (emailController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .login(
                              emailController.text,
                              passwordController.text,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Show preload loading state
                  if (isPreloading.value) ...[
                    const FilledButton(
                      onPressed: null,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Loading...'),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    authState.when(
                      data: (user) {
                        if (user != null && !hasStartedPreload.value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            preloadAndNavigate(user);
                          });
                        }
                        return FilledButton(
                          onPressed: () async {
                            if (emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your email'),
                                ),
                              );
                              return;
                            }

                            if (passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your password'),
                                ),
                              );
                              return;
                            }

                            await ref
                                .read(authNotifierProvider.notifier)
                                .login(
                                  emailController.text,
                                  passwordController.text,
                                );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('Login'),
                          ),
                        );
                      },
                      loading: () => const FilledButton(
                        onPressed: null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (error, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    error.toString(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () async {
                              if (emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter your email'),
                                  ),
                                );
                                return;
                              }

                              if (passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter your password'),
                                  ),
                                );
                                return;
                              }

                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .login(
                                    emailController.text,
                                    passwordController.text,
                                  );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('Login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
