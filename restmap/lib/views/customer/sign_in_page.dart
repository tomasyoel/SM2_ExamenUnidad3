// ignore_for_file: library_private_types_in_public_api

import 'package:restmap/services/firebase_auth_service.dart';
import 'package:restmap/services/firestore_service.dart';
import 'package:restmap/views/customer/sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isLoading = false;

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });
    final user = await _authService.signInWithEmailAndPassword(
        _emailController.text, _passwordController.text);

    if (user != null) {
      if (!user.emailVerified) {
        await _authService.signOut();
        _showErrorDialog(
            'Debes verificar tu correo electrónico para ingresar.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestoreService.getUserById(user.uid);
      final role = userDoc['rol'];
      final approved = userDoc['approved'] ?? false;

      if (!approved && role == 'negocio') {
        _showErrorDialog(
            'Tu cuenta de negocio aún no ha sido aprobada. Intenta nuevamente más tarde.');
      } else {
        String? fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .update({
            'fcmToken': fcmToken,
          });
        }

        if (mounted) {
          switch (role) {
            case 'administrador':
              Navigator.pushReplacementNamed(context, '/adminDashboard');
              break;
            case 'negocio':
              Navigator.pushReplacementNamed(context, '/businessDashboard');
              break;
            case 'cliente':
            default:
              Navigator.pushReplacementNamed(context, '/customerDashboard');
              break;
          }
        }
      }
    } else {
      _showErrorDialog('Correo o contraseña incorrectos.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error de Autenticación'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Image.asset(
                'assets/loadingbeli.gif',
                width: 100,
                height: 100,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.brown.shade100],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          'assets/belv1.png',
                          height: 250,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text("Iniciar Sesión"),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SignUpPage(role: 'cliente'),
                              ),
                            );
                          },
                          child:
                              const Text("¿No tienes una cuenta? Regístrate"),
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
