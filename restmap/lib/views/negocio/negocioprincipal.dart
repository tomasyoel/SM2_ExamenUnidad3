import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restmap/services/firebase_auth_service.dart';

class NegocioPrincipalPage extends StatefulWidget {
  const NegocioPrincipalPage({super.key});

  @override
  _NegocioPrincipalPageState createState() => _NegocioPrincipalPageState();
}

class _NegocioPrincipalPageState extends State<NegocioPrincipalPage> {
  final String _selectedPage = 'home';
  final FirebaseAuthService _authService = FirebaseAuthService();
  Map<String, dynamic>? negocioData;

  @override
  void initState() {
    super.initState();
    _loadNegocioData();
  }

  Future<void> _loadNegocioData() async {
    User? currentUser = _authService.getCurrentUser();

    if (currentUser != null) {
      try {
      
        QuerySnapshot negocioSnapshot = await FirebaseFirestore.instance
            .collection('negocios')
            .where('encargado', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (negocioSnapshot.docs.isNotEmpty) {
          DocumentSnapshot negocioDoc = negocioSnapshot.docs.first;


          String negocioId = negocioDoc.id;

      
          setState(() {
            negocioData = negocioDoc.data() as Map<String, dynamic>?;
            negocioData!['id'] = negocioId;
          });


          print('Negocio ID: $negocioId');
        } else {
          print("No se encontró ningún negocio para este usuario.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
          );
        }
      } catch (e) {
        print("Error al cargar la información del negocio: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el negocio: $e')),
        );
      }
    }
  }


  void _navigateToAgregarProducto() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/agregarProducto',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToGestionarProductos() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/gestionarProductos',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToGestionarCarta() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/gestionCarta',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToGestionarHorarios() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/gestionarHorarios',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToAgregarCatProd() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/agregarCatProd',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToGestionarCatProd() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/gestionarCatProd',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }


  void _navigateToGestionarCupones() {
    if (negocioData != null && negocioData!['id'] != null) {
      Navigator.pushNamed(
        context,
        '/gestionarCupones',
        arguments: negocioData!['id'],
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
      );
    }
  }

  void _navigateToPedidos() {
  if (negocioData != null && negocioData!['id'] != null) {
    Navigator.pushNamed(
      context,
      '/listaPedidosNegocio',
      arguments: negocioData!['id'],
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
    );
  }
}




  void _navigateTo(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signIn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Principal del Negocio"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
          
                  negocioData != null && negocioData!['logo'] != null
                      ? Image.network(
                          negocioData!['logo'],
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported, size: 100),
                  const SizedBox(height: 10),
           
                  Text(
                    negocioData != null
                        ? negocioData!['nombre'] ?? 'Sin nombre'
                        : 'Cargando negocio...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Agregar Producto'),
              onTap: () => _navigateToAgregarProducto(),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Gestionar Productos'),
              onTap: () => _navigateToGestionarProductos(),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Gestionar Carta'),
              onTap: () => _navigateToGestionarCarta(),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Gestionar Horarios'),
              onTap: () => _navigateToGestionarHorarios(),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Gestionar Pedidos'),
              onTap: () => _navigateToPedidos(),
            ),
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Gestionar Cupones'),
              onTap: () => _navigateToGestionarCupones(),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Agregar Categoría de Producto'),
              onTap: () => _navigateToAgregarCatProd(),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Gestionar Categorías de Producto'),
              onTap: () => _navigateToGestionarCatProd(),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil del Negocio'),
              onTap: () => _navigateTo('/perfilNegocio'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Salir'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_selectedPage) {
      case 'couponList':
        return const Center(child: Text("Página de Gestión de Cupones"));
      case 'home':
      default:
        return const Center(child: Text("Bienvenido a la página principal del Negocio"));
    }
  }
}





// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:restmap/services/firebase_auth_service.dart';

// class NegocioPrincipalPage extends StatefulWidget {
//   const NegocioPrincipalPage({Key? key}) : super(key: key);

//   @override
//   _NegocioPrincipalPageState createState() => _NegocioPrincipalPageState();
// }

// class _NegocioPrincipalPageState extends State<NegocioPrincipalPage> {
//   String _selectedPage = 'home';
//   final FirebaseAuthService _authService = FirebaseAuthService();
//   Map<String, dynamic>? negocioData;

//   @override
//   void initState() {
//     super.initState();
//     _loadNegocioData();
//   }

//   Future<void> _loadNegocioData() async {
//     User? currentUser = _authService.getCurrentUser();

//     if (currentUser != null) {
//       try {
//         // Buscar el negocio donde el campo 'encargado' coincida con el UID del usuario
//         QuerySnapshot negocioSnapshot = await FirebaseFirestore.instance
//             .collection('negocios')
//             .where('encargado', isEqualTo: currentUser.uid)
//             .limit(1)
//             .get();

//         if (negocioSnapshot.docs.isNotEmpty) {
//           DocumentSnapshot negocioDoc = negocioSnapshot.docs.first;

//           // Obtener el negocioId del documento
//           String negocioId = negocioDoc.id;

//           // Actualizar el estado con el negocioId y los datos del negocio
//           setState(() {
//             negocioData = negocioDoc.data() as Map<String, dynamic>?;
//             negocioData!['id'] = negocioId; // Agregar el ID al negocioData
//           });

//           // Imprimir para verificar que el ID se ha cargado correctamente
//           print('Negocio ID: $negocioId');
//         } else {
//           print("No se encontró ningún negocio para este usuario.");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
//           );
//         }
//       } catch (e) {
//         print("Error al cargar la información del negocio: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error al cargar el negocio: $e')),
//         );
//       }
//     }
//   }

//   void _navigateToAgregarProducto() {
//     if (negocioData != null && negocioData!['id'] != null) {
//       Navigator.pushNamed(
//         context,
//         '/agregarProducto',
//         arguments: negocioData!['id'], // Pasa el ID del negocio aquí
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
//       );
//     }
//   }

//   void _navigateToGestionarProductos() {
//     if (negocioData != null && negocioData!['id'] != null) {
//       Navigator.pushNamed(
//         context,
//         '/gestionarProductos',
//         arguments: negocioData!['id'], // Pasa el ID del negocio aquí
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error: No se pudo obtener el ID del negocio.')),
//       );
//     }
//   }

//   void _navigateTo(String route) {
//     Navigator.pop(context); // Cierra el Drawer
//     Navigator.pushNamed(context, route);
//   }

//   void _signOut() async {
//     await _authService.signOut();
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, '/signIn');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Menú Principal del Negocio"),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 color: Colors.green,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Mostrar logo del negocio si está disponible
//                   negocioData != null && negocioData!['logo'] != null
//                       ? Image.network(
//                           negocioData!['logo'],
//                           height: 100,
//                           width: 100,
//                           fit: BoxFit.cover,
//                         )
//                       : const Icon(Icons.image_not_supported, size: 100),
//                   const SizedBox(height: 10),
//                   // Mostrar nombre del negocio
//                   Text(
//                     negocioData != null
//                         ? negocioData!['nombre'] ?? 'Sin nombre'
//                         : 'Cargando negocio...',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 24,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.add),
//               title: const Text('Agregar Producto'),
//               onTap: () => _navigateToAgregarProducto(),
//             ),
//             ListTile(
//               leading: const Icon(Icons.list),
//               title: const Text('Gestionar Productos'),
//               onTap: () => _navigateToGestionarProductos(),
//             ),
//             ListTile(
//               leading: const Icon(Icons.restaurant_menu),
//               title: const Text('Gestionar Carta'),
//               onTap: () => _navigateTo('/gestionCarta'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Perfil del Negocio'),
//               onTap: () => _navigateTo('/perfilNegocio'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.exit_to_app),
//               title: const Text('Salir'),
//               onTap: _signOut,
//             ),
//           ],
//         ),
//       ),
//       body: _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     switch (_selectedPage) {
//       case 'couponList':
//         return const Center(child: Text("Página de Gestión de Cupones"));
//       case 'home':
//       default:
//         return const Center(child: Text("Bienvenido a la página principal del Negocio"));
//     }
//   }
// }