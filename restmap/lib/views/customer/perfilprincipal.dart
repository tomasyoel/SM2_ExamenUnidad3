import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PerfilPrincipalPage extends StatelessWidget {
  const PerfilPrincipalPage({super.key});

  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/signIn');
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    }
    return {};
  }

  Future<void> _abrirWhatsApp(BuildContext context) async {
  const phoneNumber = '+51900205498'; // Número de WhatsApp de soporte
  const message = 'Hola, tengo una pregunta sobre '; // Mensaje preconfigurado

  final whatsappUrl = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
  final whatsappUrlScheme = "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}";

  try {
    bool launched = await launch(whatsappUrlScheme);
    if (!launched) {
      await launch(whatsappUrl);
    }
  } on Exception catch (e) {
    print("No se pudo lanzar WhatsApp: ${e.toString()}");
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = FirebaseAuth.instance.currentUser;
          final userData = snapshot.data ?? {};

          final nombre = userData['nombre'] ?? 'Sin nombre';
          final correo = user?.email ?? 'Sin correo';
          final fotoUrl = userData['photoUrl'];

          return SingleChildScrollView(
            child: Column(
              children: [
                // Banner de "Suscríbete a Plus"
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.purple[50],
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Suscríbete a Plus",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Disfruta de descuentos y envíos gratis ilimitados.",
                              style: TextStyle(fontSize: 14, color: Colors.brown),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Acción para suscribirse a Plus
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text("Suscribirme"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Información de perfil
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: fotoUrl != null
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl == null
                            ? const Icon(Icons.image, size: 40, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            correo,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sección de opciones
                const Divider(),
                _seccionTitulo("Perfil"),
                _opcionPerfil(
                  icon: Icons.person,
                  text: "Información personal",
                  onTap: () {
                    Navigator.of(context).pushNamed('/informacionPersonal');
                  },
                ),
                _opcionPerfil(
                  icon: Icons.favorite,
                  text: "Favoritos",
                  onTap: () {
                    Navigator.of(context).pushNamed('/favoritos');
                  },
                ),
                _opcionPerfil(
                  icon: Icons.card_giftcard,
                  text: "Cupones",
                  onTap: () {
                    Navigator.of(context).pushNamed('/cupones');
                  },
                ),
                _opcionPerfil(
                  icon: Icons.motorcycle_sharp,
                  text: "Bocatto Plus",
                  onTap: () {
                    // Acción para Bocatto Plus
                  },
                ),

                const Divider(),
                _seccionTitulo("Configuración"),
                _opcionPerfil(
                  icon: Icons.support_agent,
                  text: "Soporte en Línea",
                  onTap: () {
                    _abrirWhatsApp(context);
                  },
                ),
                _opcionPerfil(
                  icon: Icons.logout,
                  text: "Cerrar sesión",
                  onTap: () {
                    _cerrarSesion(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _opcionPerfil({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class PerfilPrincipalPage extends StatelessWidget {
//   const PerfilPrincipalPage({Key? key}) : super(key: key);

//   void _cerrarSesion(BuildContext context) async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.of(context).pushReplacementNamed('/signIn');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mi Perfil"),
//         backgroundColor: Colors.orange,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Banner de "Suscríbete a Plus"
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               color: Colors.purple[50],
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text(
//                           "Suscríbete a Plus",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.brown,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           "Disfruta de descuentos y envíos gratis ilimitados.",
//                           style: TextStyle(fontSize: 14, color: Colors.brown),
//                         ),
//                       ],
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Acción para suscribirse a Plus
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                     child: const Text("Suscribirme"),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Información de perfil
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 40,
//                     backgroundImage: NetworkImage(
//                       // URL de ejemplo para la imagen de perfil
//                       'https://via.placeholder.com/150', // Cambia por la URL real del usuario
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: const [
//                       Text(
//                         "Nombre del Usuario", // Cambia por el nombre real del usuario
//                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         "correo@ejemplo.com", // Cambia por el correo real del usuario
//                         style: TextStyle(fontSize: 14, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Sección de opciones
//             const Divider(),
//             _seccionTitulo("Perfil"),
//             _opcionPerfil(
//               icon: Icons.person,
//               text: "Información personal",
//               onTap: () {
//                 Navigator.of(context).pushNamed('/informacionPersonal');
//               },
//             ),
//             _opcionPerfil(
//               icon: Icons.location_on,
//               text: "Direcciones",
//               onTap: () {
//                 Navigator.of(context).pushNamed('/direcciones');
//               },
//             ),
//             _opcionPerfil(
//               icon: Icons.favorite,
//               text: "Favoritos",
//               onTap: () {
//                 Navigator.of(context).pushNamed('/favoritos');
//               },
//             ),
//             _opcionPerfil(
//               icon: Icons.card_giftcard,
//               text: "Cupones",
//               onTap: () {
//                 Navigator.of(context).pushNamed('/cupones');
//               },
//             ),
//             _opcionPerfil(
//               icon: Icons.motorcycle_sharp,
//               text: "Bocatto Plus",
//               onTap: () {
//                 // Acción para Bocatto Plus
//               },
//             ),

//             const Divider(),
//             _seccionTitulo("Configuración"),
//             _opcionPerfil(
//               icon: Icons.support_agent,
//               text: "Soporte en Línea",
//               onTap: () {
//                 Navigator.of(context).pushNamed('/soporteEnLinea');
//               },
//             ),
//             _opcionPerfil(
//               icon: Icons.logout,
//               text: "Cerrar sesión",
//               onTap: () {
//                 _cerrarSesion(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _seccionTitulo(String titulo) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Text(
//         titulo,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//           color: Colors.black54,
//         ),
//       ),
//     );
//   }

//   Widget _opcionPerfil({
//     required IconData icon,
//     required String text,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.orange),
//       title: Text(
//         text,
//         style: const TextStyle(fontSize: 16),
//       ),
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: onTap,
//     );
//   }
// }
