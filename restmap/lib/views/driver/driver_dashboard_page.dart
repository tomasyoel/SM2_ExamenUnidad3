import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restmap/services/firebase_auth_service.dart';
//import 'package:restmap/views/driver/mapadriver.dart';
import 'package:restmap/views/driver/pedidosdriver.dart';
import 'package:restmap/views/driver/pedidoencamino.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({Key? key}) : super(key: key);

  @override
  _DriverDashboardPageState createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  String _selectedPage = 'home';
  final FirebaseAuthService _authService = FirebaseAuthService();
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentOrder();
  }

  Future<void> _fetchCurrentOrder() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final driverOrders = await FirebaseFirestore.instance
          .collection('pedidos')
          .where('driverId', isEqualTo: user.uid)
          .where('orderStatus', isEqualTo: 'en camino')
          .get();
      if (driverOrders.docs.isNotEmpty) {
        setState(() {
          _currentOrderId = driverOrders.docs.first.id;
          _selectedPage = 'pedidoEnCamino';
        });
      }
    }
  }

  void _onSelectPage(String page) {
    setState(() {
      _selectedPage = page;
    });
    Navigator.pop(context);
  }

  void _onOrderSelected(String orderId) {
    setState(() {
      _currentOrderId = orderId;
      _selectedPage = 'pedidoEnCamino';
    });
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
        title: Text("Menú Principal Conductor"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text('Pedidos'),
              onTap: () => _onSelectPage('pedidos'),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Salir'),
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
      case 'pedidos':
        return PedidosDriverPage(onOrderSelected: _onOrderSelected);
      case 'pedidoEnCamino':
        return _currentOrderId != null
            ? PedidoEnCaminoPage(orderId: _currentOrderId!)
            : Center(child: Text("No hay pedidos en camino"));
      case 'home':
      default:
        return Center(child: Text("Bienvenido a la página principal"));
    }
  }
}



// import 'package:belihanpiyapp2/services/firebase_auth_service.dart';
// import 'package:belihanpiyapp2/services/location_service.dart';
// import 'package:belihanpiyapp2/views/driver/perfildriver.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class DriverDashboardPage extends StatefulWidget {
//   const DriverDashboardPage({Key? key}) : super(key: key);

//   @override
//   _DriverDashboardPageState createState() => _DriverDashboardPageState();
// }

// class _DriverDashboardPageState extends State<DriverDashboardPage> {
//   Position? _currentPosition;
//   late GoogleMapController _mapController;
//   String _selectedPage = 'orders';
//   late Stream<Position> positionStream;

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//     _startLocationStream();
//   }

//   Future<void> _getCurrentLocation() async {
//     LocationService locationService = LocationService();

//     try {
//       Position position = await locationService.getCurrentLocation();
//       setState(() {
//         _currentPosition = position;
//         _mapController.animateCamera(
//           CameraUpdate.newLatLng(
//             LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//           ),
//         );
//       });
//     } catch (e) {
//       print('Could not get the location: $e');
//     }
//   }

//   void _startLocationStream() {
//     LocationSettings locationSettings = LocationSettings(
//       accuracy: LocationAccuracy.high,
//       distanceFilter: 10,
//     );

//     positionStream =
//         Geolocator.getPositionStream(locationSettings: locationSettings);
//     positionStream.listen((Position position) {
//       setState(() {
//         _currentPosition = position;
//         _mapController.animateCamera(
//           CameraUpdate.newLatLng(
//             LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//           ),
//         );
//       });
//     });
//   }

//   void _onSelectPage(String page) {
//     setState(() {
//       _selectedPage = page;
//     });
//     Navigator.pop(context); // Close the drawer
//   }

//   void _signOut() async {
//     final authService = FirebaseAuthService();
//     await authService.signOut();
//     Navigator.pushReplacementNamed(context, '/signIn');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Menú Principal Conductor'),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.green,
//               ),
//               child: Text(
//                 'Menú',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.assignment),
//               title: const Text('Pedidos'),
//               onTap: () => _onSelectPage('orders'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.map),
//               title: const Text('Mapa'),
//               onTap: () => _onSelectPage('map'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Perfil'),
//               onTap: () => _onSelectPage('profile'),
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
//       case 'orders':
//         return const Center(
//             child: Text('Aquí se mostrarán los pedidos asignados.'));
//       case 'map':
//         return _currentPosition == null
//             ? const Center(child: CircularProgressIndicator())
//             : GoogleMap(
//                 onMapCreated: (controller) {
//                   _mapController = controller;
//                 },
//                 initialCameraPosition: CameraPosition(
//                   target: LatLng(
//                       _currentPosition!.latitude, _currentPosition!.longitude),
//                   zoom: 15.0,
//                 ),
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: true,
//               );
//       case 'profile':
//         return DriverProfilePage();
//       default:
//         return const Center(child: Text('Seleccione una opción del menú.'));
//     }
//   }
// }
