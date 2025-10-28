import 'package:flutter/material.dart';
import 'homepage.dart';
import 'services/api_service.dart';

bool _obscureNewPassword = true;
bool _obscureConfirmPassword = true;

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Color.fromRGBO(74, 157, 77, 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(74, 157, 77, 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Set a new password for ${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 40),

            TextFormField(
              controller: newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: const Color.fromRGBO(201, 201, 201, 100),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                } else if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                filled: true,
                fillColor: const Color.fromRGBO(201, 201, 201, 100),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                } else if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Reset Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(62, 102, 67, 1),
                  foregroundColor: Colors.white, // هذا هو التعديل المهم
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);

                            final result = await ApiService.resetPassword(
                              email: widget.email,
                              password: newPasswordController.text.trim(),
                              passwordConfirmation:
                                  confirmPasswordController.text.trim(),
                            );

                            setState(() => _isLoading = false);

                            if (result["success"] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    " Password successfully reset!",
                                  ),
                                ),
                              );
                              await Future.delayed(Duration(seconds: 5));
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            } else {
                              final errorMessage =
                                  result["data"] is Map &&
                                          result["data"]["message"] != null
                                      ? result["data"]["message"]
                                      : result["data"].toString();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(" Failed: $errorMessage"),
                                ),
                              );
                            }
                          }
                        },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
