import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Solicitar permiso para notificaciones
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Obtener el token FCM
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      
      // Guardar el token en Firestore
      if (token != null) {
        await saveTokenToFirestore(token);
      }
    }

    // Configurar el manejo de notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}, ${message.notification?.body}');
    });
  }

  Future<void> saveTokenToFirestore(String token) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference userRef = FirebaseFirestore.instance.collection('usuarios').doc(userId);
    await userRef.update({'fcmToken': token});
  }
}