import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(String email, String password,
      Map<String, dynamic> additionalInfo) async {
    try {
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'correo': email,
          ...additionalInfo,
        });
      }

      return user;
    } catch (e) {
      //print(e);
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return user;
    } catch (e) {
      //print(e);
      return null;
    }
  }

  // Future<User?> signInWithGoogle({required String role}) async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser != null) {
  //       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //       final OAuthCredential credential = GoogleAuthProvider.credential(
  //         accessToken: googleAuth.accessToken,
  //         idToken: googleAuth.idToken,
  //       );
  //       final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
  //       User? user = userCredential.user;

  //       if (user != null && userCredential.additionalUserInfo!.isNewUser) {
  //         await _firestore.collection('usuarios').doc(user.uid).set({
  //           'correo': user.email,
  //           'nombre': user.displayName,
  //           'rol': role,
  //           'approved': role == 'cliente' ? true : false,
  //         });
  //       }

  //       return user;
  //     }
  //     return null;
  //   } catch (e) {
  //     print(e);
  //     return null;
  //   }
  // }

  Future<void> deleteUserByEmail(String email) async {
    try {
      User? currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) throw Exception("No hay usuario autenticado");

      // Sign in as the user to delete
      await _firebaseAuth.signOut();
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: '123456');

      // Delete the user
      User? userToDelete = _firebaseAuth.currentUser;
      if (userToDelete != null) {
        await userToDelete.delete();
      }

      // Delete the user's document from Firestore
      QuerySnapshot userDocs = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: email)
          .get();
      for (QueryDocumentSnapshot doc in userDocs.docs) {
        await doc.reference.delete();
      }

      // Sign in again as the admin
      await _firebaseAuth.signInWithEmailAndPassword(
          email: currentUser.email!,
          password: 'adminPassword'); // Replace with actual password
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      //print(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> sendEmailVerification() async {
    User? user = _firebaseAuth.currentUser;
    await user?.sendEmailVerification();
  }

  void showWelcomeMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("¡Bienvenido!")));
  }

  Future<DocumentSnapshot> getUserById(String id) async {
    return await _firestore.collection('usuarios').doc(id).get();
  }

  Future<bool> checkAdminExists() async {
    final querySnapshot = await _firestore
        .collection('usuarios')
        .where('rol', isEqualTo: 'administrador')
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
