import 'package:flutter/material.dart';
import 'OtpVerificationScreen.dart';
import 'services/api_service.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({Key? key}) : super(key: key);

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color.fromRGBO(74, 157, 77, 1),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(74, 157, 77, 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Enter your email to reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              cursorColor: const Color.fromRGBO(74, 157, 77, 1),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.email,
                  color: Color.fromRGBO(74, 157, 77, 1),
                ),
                hintText: 'Email',
                filled: true,
                fillColor: const Color.fromRGBO(201, 201, 201, 100),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color.fromRGBO(62, 102, 67, 1),
              ),
              child: MaterialButton(
                height: 50,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Send verification code to your email'),
                      ),
                    );

                    try {
                      String? token = await SecureStorage.read(key: 'token');
                      print("📦 التوكن المُخزن: $token");

                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You must be logged in first'),
                          ),
                        );
                        return;
                      }

                      final result = await ApiService.sendOtp(
                        email: emailController.text.trim(),
                      );

                      print("📥 رد إرسال OTP: $result");

                      if (result["success"] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('The code sent successfully'),
                          ),
                        );
                        await Future.delayed(Duration(seconds: 5));

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => OtpVerificationScreen(
                                  email: emailController.text.trim(),
                                ),
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
                            content: Text('Sending failed: $errorMessage'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('⚠️ خطأ: $e')));
                    }
                  }
                },

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Send Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
