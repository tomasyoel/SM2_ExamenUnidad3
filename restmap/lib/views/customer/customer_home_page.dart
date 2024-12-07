// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_types_as_parameter_names, unused_element

import 'dart:async';
import 'package:restmap/services/firebase_auth_service.dart';
import 'package:restmap/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:restmap/views/customer/detallepedido.dart';
// import 'package:restmap/views/admin/mapadmin.dart';
import 'package:restmap/views/customer/negociolista.dart';
import 'package:restmap/views/customer/perfilprincipal.dart';
import 'package:restmap/views/customer/user_location_page.dart';
import 'package:restmap/views/mapa/mapabase.dart';
import 'package:restmap/views/customer/listapedidos.dart';

// import 'cart_page.dart';
import 'carta.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _userData;
  String? _userAddress;
  StreamSubscription? _connectionSubscription;
  bool _hasConnection = true;
  int _selectedIndex = 0;
  String? userId; // Definir el userId aquí

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _checkConnection();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    _connectionSubscription =
        Stream.periodic(const Duration(seconds: 5)).asyncMap(
      (_) async {
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            await transaction.get(FirebaseFirestore.instance.doc('test/test'));
          });
          if (!_hasConnection) {
            if (mounted) {
              setState(() {
                _hasConnection = true;
              });
              _showSnackbar(
                  'Ya tienes conexión de nuevo 🌱🤍', Colors.green, Icons.wifi);
            }
          }
        } catch (e) {
          if (_hasConnection) {
            if (mounted) {
              setState(() {
                _hasConnection = false;
              });
              _showSnackbar('Lo siento, perdiste la conexión 🥹🌱', Colors.grey,
                  Icons.wifi_off_outlined);
            }
          }
        }
      },
    ).listen((_) {});
  }

  void _showSnackbar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _getCurrentUser() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot userDoc = await _firestoreService.getUserById(user.uid);

      if (mounted) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;

          // Buscar la dirección predeterminada
          if (_userData != null && _userData!.containsKey('direcciones')) {
            List<dynamic> direcciones = _userData!['direcciones'];

            // Buscar la dirección predeterminada
            var direccionPredeterminada = direcciones.firstWhere(
              (direccion) => direccion['predeterminada'] == true,
              orElse: () => null,
            );

            // Si hay dirección predeterminada, mostrarla, si no, mostrar '--------'
            _userAddress = direccionPredeterminada != null
                ? direccionPredeterminada['direccion']
                : '--------';
          } else {
            _userAddress = '--------'; // No hay direcciones añadidas
          }
        });
      }
    }
  }

  Future<void> _loadCarrito() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final carrito = userData['carrito'] ?? [];
        final negocioId = userData['negocioId'];

        if (carrito.isNotEmpty && negocioId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetallePedidoPage(
                negocioId: negocioId,
                productosSeleccionados:
                    List<Map<String, dynamic>>.from(carrito),
                total: carrito.fold(0.0,
                    (sum, item) => sum + (item['precio'] * item['cantidad'])),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El carrito está vacío.')),
          );
        }
      }
    }
  }

  // Método que navega hacia la página del carrito
  // void _navigateToCartPage() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       // builder: (context) => CartPage(orderProducts: []),
  //       builder: (context) => PaginaPrincipalAdmin(),
  //     ),
  //   );
  // }

  // Modificar el método _showLocationModal
  void _showLocationModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return const FractionallySizedBox(
          heightFactor: 0.8,
          child: UserLocationPage(),
        );
      },
    );

    // Si el resultado es true, actualiza la dirección
    if (result == true) {
      await _updateUserAddress();
    }
  }

  // Asegúrate de que este método esté definido en tu clase
  Future<void> _updateUserAddress() async {
    User? user = _authService.getCurrentUser();
    if (user != null) {
      DocumentSnapshot userDoc = await _firestoreService.getUserById(user.uid);

      if (mounted) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;

          if (_userData != null && _userData!.containsKey('direcciones')) {
            List<dynamic> direcciones = _userData!['direcciones'];

            var direccionPredeterminada = direcciones.firstWhere(
              (direccion) => direccion['predeterminada'] == true,
              orElse: () => null,
            );

            _userAddress = direccionPredeterminada != null
                ? direccionPredeterminada['direccion']
                : '--------';
          } else {
            _userAddress = '--------';
          }
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MapaBasePage(),
        ),
      );
    } else if (_selectedIndex == 4) {
      // Pedidos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ListaPedidosPage(),
        ),
      );
    } else if (_selectedIndex == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // builder: (context) => CustomerProfilePage(),
          builder: (context) => const PerfilPrincipalPage(),
        ),
      );
    }
  }

  void _navigateToAddressManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserLocationPage(),
      ),
    );
  }

  Widget _loadingWidget() {
    return Center(
      child: Image.asset(
        'assets/loadingbeli.gif',
        width: 100,
        height: 100,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NegocioListaPage(
                      userId: _authService.getCurrentUser()!.uid,
                    ),
                  ),
                );
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/restaurantes.png',
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Restaurantes",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "La comida que te gusta",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Acción para Envíos
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/envios.png',
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Envíos",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "De puerta a puerta",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('negocios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: _loadingWidget());
        }

        var negocios = snapshot.data!.docs;

        if (negocios.isEmpty) {
          return const Center(child: Text('No hay promociones disponibles'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Promociones Exclusivas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              itemCount: negocios.length,
              itemBuilder: (context, index) {
                var negocio = negocios[index].data() as Map<String, dynamic>;

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('cartasnegocio')
                      .where('negocioId', isEqualTo: negocios[index].id)
                      .get(),
                  builder: (context, cartaSnapshot) {
                    if (!cartaSnapshot.hasData) return _loadingWidget();

                    if (cartaSnapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // var carta = cartaSnapshot.data!.docs.first;
                    // var productos = carta['carta'] as List;

                    var carta = cartaSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;

                    // Verificar si el array "carta" existe y tiene al menos un elemento
                    if (carta['carta'] == null || carta['carta'].isEmpty) {
                      return const SizedBox.shrink();
                    }

                    var productos = carta['carta'] as List;

                    var productosPromocion = productos
                        .where((producto) => producto['estado'] == 'promocion')
                        .toList();

                    if (productosPromocion.isNotEmpty) {
                      var productoPromocion = productosPromocion.reduce(
                        (curr, next) =>
                            curr['precio'] < next['precio'] ? curr : next,
                      );

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CartaPage(
                                negocioId: negocios[index].id,
                                userId: userId!,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              productoPromocion['urlImagen'] != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Image.network(
                                        productoPromocion['urlImagen'],
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    negocio['logo'] != null
                                        ? Image.network(negocio['logo'],
                                            width: 50, height: 50)
                                        : const Icon(Icons.store, size: 50),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            negocio['nombre'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(height: 5),
                                          const Text(
                                            '15-30 min • Envío S/4.20',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Acción para suscribirse
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        backgroundColor: Colors.purple.shade100,
                                      ),
                                      child: const Text('Suscribirse',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) {
                return DraggableScrollableSheet(
                  expand: false,
                  maxChildSize: 0.5,
                  minChildSize: 0.3,
                  builder: (context, scrollController) {
                    // return UserLocationPage(userId: 'userId');
                    return const UserLocationPage();
                  },
                );
              },
            );

            if (result == true) {
              await _updateUserAddress();
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _userAddress != null && _userAddress!.isNotEmpty
                        ? (_userAddress!.length > 25
                            ? '${_userAddress!.substring(0, 25)}...'
                            : _userAddress!)
                        : '-----------',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(IconlyLight.notification),
                    onPressed: () {
                      // Acción para notificaciones
                    },
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.buy),
                    onPressed: () {
                      // _navigateToCartPage();
                      _loadCarrito();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar Restaurante',
                  prefixIcon: const Icon(IconlyLight.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildActionButtons(),
            const SizedBox(height: 10),
            _buildPromotions(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(IconlyBold.buy), label: 'Súper'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.discount), label: 'Promociones'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.location), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(IconlyBold.bag), label: 'Pedidos'),
          BottomNavigationBarItem(
              icon: Icon(IconlyBold.profile), label: 'Mi perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[700],
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
