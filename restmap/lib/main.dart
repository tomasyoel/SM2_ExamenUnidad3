import 'package:flutter/material.dart';
import 'package:restmap/services/bloqueopantalla.dart';
import 'package:restmap/services/versionchecker.dart';
import 'package:restmap/views/admin/agregartipococina.dart';
import 'package:restmap/views/customer/perfilcliente.dart';
import 'package:restmap/views/negocio/agregarcatprod.dart';
import 'package:restmap/views/negocio/gestionarcarta.dart';
import 'package:restmap/views/admin/principaladmin.dart';
import 'package:restmap/firebase_options.dart';
// import 'package:restmap/views/admin/gestionartipococina.dart';
import 'package:restmap/views/negocio/cupones.dart';
import 'package:restmap/views/customer/customer_home_page.dart';
import 'package:restmap/views/customer/forgot_password_page.dart';
import 'package:restmap/views/customer/sign_in_page.dart';
import 'package:restmap/views/customer/sign_up_page.dart';
import 'package:restmap/views/customer/user_location_page.dart';
import 'package:restmap/views/negocio/agregarproducto.dart';
import 'package:restmap/views/negocio/gestionarcatprod.dart';
import 'package:restmap/views/negocio/gestionarproductos.dart';
import 'package:restmap/views/negocio/horario.dart';
import 'package:restmap/views/negocio/listapedidosnegocio.dart';
import 'package:restmap/views/negocio/negocioprincipal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:restmap/views/negocio/perfilnegocio.dart';

final ValueNotifier<bool> shouldShowBlockScreen = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Inicializa el listener de versiones
  VersionCheckerService().startVersionListener(() {
    shouldShowBlockScreen.value = true;
    FirebaseAuth.instance.signOut(); // Cierra sesión automáticamente si es necesario
  });

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  FirebaseMessagingService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _loadingWidget() {
    return Center(
      child: Image.asset(
        'assets/loadingbeli.gif', // Ruta hacia el archivo GIF en tu carpeta de assets
        width: 100,
        height: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bocatto Bazar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: shouldShowBlockScreen,
        builder: (context, showBlockScreen, child) {
          if (showBlockScreen) {
            return const UpdateBlockScreen();
          }

          // Verifica la versión antes de continuar
          return FutureBuilder<bool>(
            future: VersionCheckerService().isVersionValid(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: _loadingWidget()),
                );
              }

              if (snapshot.hasError || (snapshot.hasData && !snapshot.data!)) {
                return const UpdateBlockScreen();
              }

              return StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    User? user = snapshot.data;
                    if (user == null) {
                      return const SignInPage();
                    }
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(user.uid)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.done) {
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            final role = userData['rol'] ?? 'cliente';
                            switch (role) {
                              case 'administrador':
                                return const PaginaPrincipalAdmin(); // Vista de administrador
                              case 'negocio':
                                return const NegocioPrincipalPage(); // Vista de negocio
                              case 'cliente':
                              default:
                                return const CustomerHomePage(); // Vista de cliente por defecto
                            }
                          } else {
                            return const SignInPage();
                          }
                        }
                        return Scaffold(
                          body: Center(child: _loadingWidget()),
                        );
                      },
                    );
                  }
                  return Scaffold(
                    body: Center(child: _loadingWidget()),
                  );
                },
              );
            },
          );
        },
      ),
      routes: {
        '/signIn': (context) => const SignInPage(),
        '/signUp': (context) => const SignUpPage(role: 'cliente'),
        '/customerDashboard': (context) => const CustomerHomePage(),
        '/adminDashboard': (context) => const PaginaPrincipalAdmin(),
        '/businessDashboard': (context) => const NegocioPrincipalPage(),
        '/userLocation': (context) => const UserLocationPage(),
        // '/productTypeList': (context) => const GestionarTipoCocinaPage(),
        '/addProductType': (context) => const AgregarTipoCocinaPage(),
        '/forgotPassword': (context) => const ForgotPasswordPage(),
        '/gestionarCupones': (context) => CuponesPage(),
        '/perfilNegocio': (context) => const PerfilNegocioPage(),
        '/informacionPersonal': (context) => const CustomerProfilePage(),
        // '/direcciones': (context) => DireccionesPage(),
        // '/favoritos': (context) => FavoritosPage(),
        '/cupones': (context) => CuponesPage(),
        // '/soporteEnLinea': (context) => SoporteEnLineaPage(),
        '/gestionCarta': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return GestionarCartaPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/agregarProducto': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return AgregarProductoPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/gestionarProductos': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return ProductManagementPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/agregarCatProd': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return AgregarCatProdPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/gestionarCatProd': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return GestionarCatProdPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/gestionarHorarios': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return HorarioPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
        '/listaPedidosNegocio': (context) {
          final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
          if (negocioId != null) {
            return ListaPedidosNegocioPage(negocioId: negocioId);
          } else {
            return const Scaffold(
              body: Center(child: Text('Negocio ID no encontrado')),
            );
          }
        },
      },
    );
  }
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void initialize() {
    _firebaseMessaging.requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        const channel = AndroidNotificationChannel(
          'channel_id',
          'channel_name',
        );
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });
  }

  Future<void> sendPushNotification(String token, String title, String body) async {
    try {
      await _firebaseMessaging.sendMessage(
        to: token,
        data: {
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
}









// import 'package:flutter/material.dart';
// import 'package:restmap/views/admin/agregartipococina.dart';
// import 'package:restmap/views/negocio/agregarcatprod.dart';
// import 'package:restmap/views/negocio/gestionarcarta.dart';
// import 'package:restmap/views/admin/principaladmin.dart';
// import 'package:restmap/firebase_options.dart';
// // import 'package:restmap/views/admin/apirecomendaciones.dart';
// // import 'package:restmap/views/admin/gestionpedidos.dart';
// import 'package:restmap/views/admin/gestionartipococina.dart';
// import 'package:restmap/views/negocio/cupones.dart';
// import 'package:restmap/views/customer/customer_home_page.dart';
// import 'package:restmap/views/customer/forgot_password_page.dart';
// import 'package:restmap/views/customer/sign_in_page.dart';
// import 'package:restmap/views/customer/sign_up_page.dart';
// import 'package:restmap/views/customer/user_location_page.dart';
// import 'package:restmap/views/negocio/agregarproducto.dart';
// import 'package:restmap/views/negocio/gestionarcatprod.dart';
// import 'package:restmap/views/negocio/gestionarproductos.dart';
// import 'package:restmap/views/negocio/horario.dart';
// import 'package:restmap/views/negocio/negocioprincipal.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:restmap/views/negocio/perfilnegocio.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (Firebase.apps.isEmpty) {
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   }
//   await FirebaseAppCheck.instance.activate(
//     androidProvider: AndroidProvider.playIntegrity,
//   );
//   FirebaseMessagingService().initialize();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   Widget _loadingWidget() {
//     return Center(
//       child: Image.asset(
//         'assets/loadingbeli.gif',  // Ruta hacia el archivo GIF en tu carpeta de assets
//         width: 100,  // Ajusta el tamaño si es necesario
//         height: 100,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Bocatto Bazar',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.active) {
//             User? user = snapshot.data;
//             if (user == null) {
//               return const SignInPage();
//             }
//             return FutureBuilder<DocumentSnapshot>(
//               future: FirebaseFirestore.instance
//                   .collection('usuarios')
//                   .doc(user.uid)
//                   .get(),
//               builder: (context, userSnapshot) {
//                 if (userSnapshot.connectionState == ConnectionState.done) {
//                   if (userSnapshot.hasData && userSnapshot.data != null) {
//                     final userData =
//                         userSnapshot.data!.data() as Map<String, dynamic>;
//                     final role = userData['rol'] ?? 'cliente';
//                     switch (role) {
//                       case 'administrador':
//                         return const PaginaPrincipalAdmin(); // Vista de administrador
//                       case 'negocio':
//                         return const NegocioPrincipalPage(); // Vista de negocio
//                       case 'cliente':
//                       default:
//                         return const CustomerHomePage(); // Vista de cliente por defecto
//                     }
//                   } else {
//                     return const SignInPage();
//                   }
//                 }
//                 return Scaffold(
//                   body: Center(
//                      child: _loadingWidget(),
//                   ),
//                 );
//               },
//             );
//           }
//           return Scaffold(
//             body: Center(
//               child: _loadingWidget(),
//             ),
//           );
//         },
//       ),
//       routes: {
//         '/signIn': (context) => const SignInPage(),
//         '/signUp': (context) => const SignUpPage(role: 'cliente'),
//         '/customerDashboard': (context) => const CustomerHomePage(),
//         '/adminDashboard': (context) => const PaginaPrincipalAdmin(),
//         '/businessDashboard': (context) => const NegocioPrincipalPage(),
//         // '/orderManagement': (context) => OrderManagementPage(),
//         // '/userLocation': (context) => UserLocationPage(
//         //     userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
//         '/userLocation': (context) => UserLocationPage(),
//         '/productTypeList': (context) => GestionarTipoCocinaPage(),
//         '/addProductType': (context) => const AgregarTipoCocinaPage(),
//         '/forgotPassword': (context) => const ForgotPasswordPage(),
//         '/gestionarCupones': (context) => CuponesPage(),
//         // '/apiRecomendaciones': (context) => ApirecomendacionesPage(),
//         '/perfilNegocio': (context) => const PerfilNegocioPage(), 
//         '/gestionCarta': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return GestionarCartaPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/agregarProducto': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return AgregarProductoPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/gestionarProductos': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return ProductManagementPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/agregarCatProd': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return AgregarCatProdPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/gestionarCatProd': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return GestionarCatProdPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/gestionarHorarios': (context) {  // Agregar esta ruta para gestionar horarios
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return HorarioPage(negocioId: negocioId); // Asegúrate de que HorarioPage esté bien definido
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//       },
//     );
//   }
// }

// class FirebaseMessagingService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   void initialize() {
//     _firebaseMessaging.requestPermission();

//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//     flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       RemoteNotification? notification = message.notification;
//       AndroidNotification? android = message.notification?.android;
//       if (notification != null && android != null) {
//         const channel = AndroidNotificationChannel(
//           'channel_id',
//           'channel_name',
//         );
//         flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               channel.id,
//               channel.name,
//               icon: android.smallIcon,
//             ),
//           ),
//         );
//       }
//     });
//   }

//   Future<void> sendPushNotification(String token, String title, String body) async {
//     try {
//       await _firebaseMessaging.sendMessage(
//         to: token,
//         data: {
//           'title': title,
//           'body': body,
//         },
//       );
//     } catch (e) {
//       print('Error sending push notification: $e');
//     }
//   }
// }



























// import 'package:flutter/material.dart';
// import 'package:restmap/views/admin/agregartipococina.dart';
// import 'package:restmap/views/negocio/gestionarcarta.dart';
// import 'package:restmap/views/admin/principaladmin.dart';
// import 'package:restmap/firebase_options.dart';
// import 'package:restmap/views/admin/apirecomendaciones.dart';
// import 'package:restmap/views/admin/gestionpedidos.dart';
// import 'package:restmap/views/admin/gestionartipococina.dart';
// import 'package:restmap/views/customer/cupones.dart';
// import 'package:restmap/views/customer/customer_home_page.dart';
// import 'package:restmap/views/customer/forgot_password_page.dart';
// import 'package:restmap/views/customer/sign_in_page.dart';
// import 'package:restmap/views/customer/sign_up_page.dart';
// import 'package:restmap/views/customer/user_location_page.dart';
// import 'package:restmap/views/negocio/agregarproducto.dart';
// import 'package:restmap/views/negocio/gestionarproductos.dart';
// import 'package:restmap/views/negocio/negocioprincipal.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:restmap/views/negocio/perfilnegocio.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   if (Firebase.apps.isEmpty) {
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   }
//   await FirebaseAppCheck.instance.activate(
//     androidProvider: AndroidProvider.playIntegrity,
//   );
//   FirebaseMessagingService().initialize();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Bocatto Bazar',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.active) {
//             User? user = snapshot.data;
//             if (user == null) {
//               return const SignInPage();
//             }
//             return FutureBuilder<DocumentSnapshot>(
//               future: FirebaseFirestore.instance
//                   .collection('usuarios')
//                   .doc(user.uid)
//                   .get(),
//               builder: (context, userSnapshot) {
//                 if (userSnapshot.connectionState == ConnectionState.done) {
//                   if (userSnapshot.hasData && userSnapshot.data != null) {
//                     final userData =
//                         userSnapshot.data!.data() as Map<String, dynamic>;
//                     final role = userData['rol'] ?? 'cliente';
//                     switch (role) {
//                       case 'administrador':
//                         return const PaginaPrincipalAdmin(); // Vista de administrador
//                       case 'negocio':
//                         return const NegocioPrincipalPage(); // Vista de negocio
//                       case 'cliente':
//                       default:
//                         return const CustomerHomePage(); // Vista de cliente por defecto
//                     }
//                   } else {
//                     return const SignInPage();
//                   }
//                 }
//                 return const Scaffold(
//                   body: Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 );
//               },
//             );
//           }
//           return const Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         },
//       ),
//       routes: {
//         '/signIn': (context) => const SignInPage(),
//         '/signUp': (context) => const SignUpPage(role: 'cliente'),
//         '/customerDashboard': (context) => const CustomerHomePage(),
//         '/adminDashboard': (context) => const PaginaPrincipalAdmin(),
//         '/businessDashboard': (context) => const NegocioPrincipalPage(), // Nueva ruta para negocio
//         '/orderManagement': (context) => OrderManagementPage(),
//         '/userLocation': (context) => UserLocationPage(
//             userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
//         '/productTypeList': (context) => GestionarTipoCocinaPage(),
//         '/addProductType': (context) => const AgregarTipoCocinaPage(),
//         '/forgotPassword': (context) => const ForgotPasswordPage(),
//         '/cupones': (context) => CuponesPage(),
//         '/apiRecomendaciones': (context) => ApirecomendacionesPage(),
//         '/perfilNegocio': (context) => const PerfilNegocioPage(), // Ruta al perfil del negocio
//         '/gestionCarta': (context) => GestionarCartaPage(), // Ruta para gestionar la carta

//         // Actualización: Manejo de null en argumentos
//         '/agregarProducto': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return AgregarProductoPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//         '/gestionarProductos': (context) {
//           final negocioId = ModalRoute.of(context)?.settings.arguments as String?;
//           if (negocioId != null) {
//             return ProductManagementPage(negocioId: negocioId);
//           } else {
//             return const Scaffold(
//               body: Center(child: Text('Negocio ID no encontrado')),
//             );
//           }
//         },
//       },
//     );
//   }
// }

// class FirebaseMessagingService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//   void initialize() {
//     _firebaseMessaging.requestPermission();

//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//     flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       RemoteNotification? notification = message.notification;
//       AndroidNotification? android = message.notification?.android;
//       if (notification != null && android != null) {
//         const channel = AndroidNotificationChannel(
//           'channel_id',
//           'channel_name',
//         );
//         flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               channel.id,
//               channel.name,
//               icon: android.smallIcon,
//             ),
//           ),
//         );
//       }
//     });
//   }

//   Future<void> sendPushNotification(String token, String title, String body) async {
//     try {
//       await _firebaseMessaging.sendMessage(
//         to: token,
//         data: {
//           'title': title,
//           'body': body,
//         },
//       );
//     } catch (e) {
//       print('Error sending push notification: $e');
//     }
//   }
// }