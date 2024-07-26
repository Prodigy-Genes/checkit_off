// ignore_for_file: use_build_context_synchronously

import 'package:checkit_off/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:checkit_off/user_auth/presentation/screens/home_page.dart';
import 'package:checkit_off/user_auth/presentation/screens/signup.dart';
import 'package:checkit_off/user_auth/presentation/widgets/form_container.dart';
import 'package:checkit_off/user_auth/presentation/widgets/google_signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuthServices _auth = FirebaseAuthServices();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade900,
                      Colors.red.shade700,
                      Colors.orange.shade500,
                    ],
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            FormContainer(
                              controller: _emailController,
                              hintText: "Enter your email",
                              labelText: 'Email',
                              inputType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FormContainer(
                              controller: _passwordController,
                              hintText: 'Enter your password',
                              labelText: 'Password',
                              isPasswordField: true,
                              inputType: TextInputType.visiblePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _login(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.yellow),
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          showToast(context, 'Implement forgot password logic');
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Signup()),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const GoogleSignin(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _login(BuildContext context) async {
  setState(() {
    _isLoading = true;
  });

  String email = _emailController.text;
  String password = _passwordController.text;

  try {
    User? user = await _auth.signinwithemailandpassword(email, password);
    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage = _handleFirebaseAuthException(e);
    showToast(context, errorMessage);
  } catch (e) {
    showToast(context, 'An error occurred. Please try again.');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

String _handleFirebaseAuthException(FirebaseAuthException e) {
  String errorMessage = 'An error occurred.';

  if (e.code == 'user-not-found') {
    errorMessage = 'No user found for that email.';
  } else if (e.code == 'wrong-password') {
    errorMessage = 'Wrong password provided.';
  } else if (e.code == 'invalid-email') {
    errorMessage = 'The email address is not valid.';
  } else if (e.code == 'user-disabled') {
    errorMessage = 'The user account has been disabled.';
  }

  return errorMessage;
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
}