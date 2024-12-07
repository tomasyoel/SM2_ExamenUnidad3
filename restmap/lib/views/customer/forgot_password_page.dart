// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:restmap/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  void _sendPasswordResetEmail() async {
    await _authService.sendPasswordResetEmail(_emailController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Correo de restablecimiento de contraseña enviado")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restablecer contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              child: const Text("Enviar correo de restablecimiento"),
            ),
          ],
        ),
      ),
    );
  }
}
