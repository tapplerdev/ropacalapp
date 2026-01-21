import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    final rememberMe = useState(false);
    final authState = ref.watch(authNotifierProvider);
    final isPreloading = useState(false);
    final hasStartedPreload = useState(false); // Prevent duplicate runs

    // Load saved email on first build
    useEffect(() {
      Future<void> loadSavedEmail() async {
        try {
          final storage = const FlutterSecureStorage();
          final savedEmail = await storage.read(key: 'remembered_email');
          if (savedEmail != null && savedEmail.isNotEmpty) {
            emailController.text = savedEmail;
            rememberMe.value = true;
          }
        } catch (e) {
          AppLogger.general('Error loading saved email: $e');
        }
      }
      loadSavedEmail();
      return null;
    }, []);

    // Note: Location tracking is now started in preloadAndNavigate() after login
    // This avoids starting GPS before user is authenticated

    // Handle Remember Me storage
    Future<void> handleRememberMe() async {
      try {
        const storage = FlutterSecureStorage();
        if (rememberMe.value) {
          await storage.write(key: 'remembered_email', value: emailController.text);
          AppLogger.general('✅ Email saved to secure storage');
        } else {
          await storage.delete(key: 'remembered_email');
          AppLogger.general('🗑️  Saved email cleared from storage');
        }
      } catch (e) {
        AppLogger.general('⚠️  Error handling Remember Me: $e');
      }
    }

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

      // Fetch current shift from backend after login
      // This ensures we have the latest shift state (not cached data)
      try {
        AppLogger.general('🔄 Fetching current shift from backend...');
        await ref.read(shiftNotifierProvider.notifier).fetchCurrentShift();
        AppLogger.general('✅ Current shift fetched successfully');
      } catch (e) {
        AppLogger.general('❌ Failed to fetch current shift: $e');
        // Continue to home page anyway - shift will be inactive
      }

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
                  SvgPicture.asset(
                    'assets/images/binly_logo.svg',
                    height: 280,
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
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
                        await handleRememberMe();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Remember Me checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe.value,
                        onChanged: (value) {
                          rememberMe.value = value ?? false;
                        },
                      ),
                      const Text('Remember Me'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Show preload loading state
                  if (isPreloading.value) ...[
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5E9646).withValues(alpha: 0.5), // Faded green
                            const Color(0xFF4AA0B5).withValues(alpha: 0.5), // Faded blue
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: const ElevatedButton(
                        onPressed: null,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                          shadowColor: WidgetStatePropertyAll(Colors.transparent),
                        ),
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
                            Text(
                              'Loading...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                        return Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5E9646), // Brand Green
                                Color(0xFF4AA0B5), // Brand Blue
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                          child: ElevatedButton(
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
                              await handleRememberMe();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF5E9646).withValues(alpha: 0.5),
                              const Color(0xFF4AA0B5).withValues(alpha: 0.5),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: const ElevatedButton(
                          onPressed: null,
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                            shadowColor: WidgetStatePropertyAll(Colors.transparent),
                          ),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
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
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF5E9646), // Brand Green
                                  Color(0xFF4AA0B5), // Brand Blue
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: ElevatedButton(
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
                                await handleRememberMe();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Forgot Password / Sign Up links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to forgot password page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot Password feature coming soon'),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '|',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to sign up page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign Up feature coming soon'),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
