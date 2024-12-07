import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restmap/models/user.dart';
import 'package:restmap/views/customer/map_page.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class UserLocationPage extends StatefulWidget {
  const UserLocationPage({super.key});

  @override
  _UserLocationPageState createState() => _UserLocationPageState();
}

class _UserLocationPageState extends State<UserLocationPage> {
  List<Address> _addresses = [];
  LatLng _currentPosition = const LatLng(0, 0);
  Location location = Location();
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      print("El userId del usuario autenticado es: $_userId");
      _fetchAddresses();  
    } else {
      print("El ID del usuario es nulo, no se puede buscar direcciones.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeLocation() async {
    var userLocation = await location.getLocation();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
      });
    }
  }

  void _fetchAddresses() async {
    if (_userId == null) return;

    try {
      
      print("Buscando el usuario con ID: $_userId en la colección 'usuarios'");
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userId)
          .get();

      if (userSnapshot.exists) {
        print("Usuario encontrado. Datos del usuario: ${userSnapshot.data()}");
        var data = userSnapshot.data() as Map<String, dynamic>?;

        
        if (data != null && data.containsKey('direcciones')) {
          print("Direcciones encontradas: ${data['direcciones']}");
          List<Address> addresses = (data['direcciones'] as List)
              .map((item) {
                var addressData = item as Map<String, dynamic>;

                
                return Address(
                  id: addressData['id'] ?? const Uuid().v4(),
                  name: addressData['nombre'] ?? 'Sin nombre',
                  address: addressData['direccion'] ?? 'Sin dirección',
                  latitude: (addressData['latitud'] as num?)?.toDouble() ?? 0.0,
                  longitude: (addressData['longitud'] as num?)?.toDouble() ?? 0.0,
                  isDefault: addressData['predeterminada'] ?? false,
                );
              })
              .toList();

          
          if (mounted) {
            setState(() {
              _addresses = addresses;
              _isLoading = false;
            });
          }
        } else {
          
          // print("No hay direcciones guardadas en el usuario.");
          if (mounted) {
            setState(() {
              _addresses = [];
              _isLoading = false;
            });
          }
        }
      } else {
        // print('No se encontró el usuario en la base de datos.');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // print('Error al obtener direcciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addNewAddress() async {
  if (_userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se encontró el usuario autenticado')),
    );
    return;
  }

  print("El userId antes de pasar a MapPage es: $_userId");

  
  bool? addressAdded = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MapPage(userId: _userId!), 
    ),
  );

  
  if (addressAdded == true) {
    _fetchAddresses(); 
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se agregó ninguna dirección')),
    );
  }
}

  void _setDefaultAddress(String id) async {
  for (var address in _addresses) {
    address.isDefault = (address.id == id);
  }

  DocumentReference userRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(_userId);

  await userRef.update({
    'direcciones': _addresses.map((addr) => addr.toMap()).toList(),
  });

  
  if (mounted) {
    Navigator.pop(context, true); 
  }
}


  void _deleteAddress(String id) async {
  if (_userId == null) return;

  
  _addresses.removeWhere((address) => address.id == id);

  
  DocumentReference userRef = FirebaseFirestore.instance.collection('usuarios').doc(_userId);
  
  await userRef.update({
    'direcciones': _addresses.map((addr) => addr.toMap()).toList(),
  });

  
  setState(() {});

  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Dirección eliminada')),
  );

  
    Navigator.pop(context, true);
}

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.4, 
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '¿Dónde te encuentras?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(IconlyBold.addUser),
              title: const Text('Nueva dirección'),
              onTap: () {
                _addNewAddress(); 
              },
            ),
            const Divider(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'Aún no tienes direcciones añadidas.',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _addresses.length,
                            itemBuilder: (context, index) {
                              var address = _addresses[index];
                              return ListTile(
                                title: Text(address.name),
                                subtitle: Text(address.address),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        IconlyBold.tickSquare,
                                        color: address.isDefault
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        _setDefaultAddress(address.id);
                                        // Navigator.pop(context); // Cierra el modal al seleccionar
                                        // Navigator.pop(context, true); // Enviar señal para recargar la vista
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        IconlyBold.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _deleteAddress(address.id);
                                        // Navigator.pop(context, true); // Enviar señal para recargar la vista
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
