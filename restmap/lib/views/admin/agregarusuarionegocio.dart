import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restmap/services/firebase_auth_service.dart';

class CreateUserNegocioPage extends StatefulWidget {
  const CreateUserNegocioPage({super.key});

  @override
  _CreateUserNegocioPageState createState() => _CreateUserNegocioPageState();
}

class _CreateUserNegocioPageState extends State<CreateUserNegocioPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _createUserNegocio() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los campos deben estar completos para crear el usuario.')),
        );
      }
      return;
    }

    try {
      User? user = await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        {'rol': 'negocio', 'approved': true},
      );

      if (user != null) {
        await user.sendEmailVerification();

        
        await _authService.signInWithEmailAndPassword(
          currentUser!.email!,
          "adminPassword",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario de negocio creado exitosamente.')),
          );

          Navigator.pushReplacementNamed(context, '/adminHome');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el usuario: $e')),
        );
      }
    }

    if (mounted) {
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario Negocio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo del Usuario Negocio'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createUserNegocio,
              child: const Text('Crear Usuario Negocio'),
            ),
          ],
        ),
      ),
    );
  }
}
