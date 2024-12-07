// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:restmap/views/negocio/mapanegocio.dart';

import 'package:restmap/services/firebase_auth_service.dart';

class PerfilNegocioPage extends StatefulWidget {
  const PerfilNegocioPage({super.key});

  @override
  _PerfilNegocioPageState createState() => _PerfilNegocioPageState();
}

class _PerfilNegocioPageState extends State<PerfilNegocioPage> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _propietarioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nroCelularController = TextEditingController();

  String? _encargado;
  String? _tipoCocina;
  File? _logoImage;
  String? _logoUrl;
  LatLng? _ubicacion;
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
          setState(() {
            negocioData =
                negocioSnapshot.docs.first.data() as Map<String, dynamic>;
            negocioData!['id'] = negocioSnapshot.docs.first.id;
            _nombreController.text = negocioData!['nombre'] ?? '';
            _propietarioController.text = negocioData!['propietario'] ?? '';
            _nroCelularController.text = negocioData!['nroCelular'] ?? '';
            _direccionController.text = negocioData!['direccion'] ?? '';
            _encargado = negocioData!['encargado'];
            _tipoCocina = negocioData!['tipo_cocina'];
            _logoUrl = negocioData!['logo'];

            if (negocioData!['ubicacion'] != null &&
                negocioData!['ubicacion'] is GeoPoint) {
              GeoPoint geoPoint = negocioData!['ubicacion'];
              _ubicacion = LatLng(geoPoint.latitude, geoPoint.longitude);
            }
          });
        }
      } catch (e) {
        //print("Error al cargar la información del negocio: $e");
      }
    }
  }

  Future<void> _updateNegocio() async {
    if (negocioData == null) return;

    try {
      String? newLogoUrl = _logoUrl;

      if (_logoImage != null) {
        newLogoUrl = await _uploadLogo();
      }

      await FirebaseFirestore.instance
          .collection('negocios')
          .doc(negocioData!['id'])
          .update({
        'nombre': _nombreController.text,
        'propietario': _propietarioController.text,
        'nroCelular': _nroCelularController.text,
        'direccion': _direccionController.text,
        'logo': newLogoUrl,
        'ubicacion': _ubicacion != null
            ? GeoPoint(_ubicacion!.latitude, _ubicacion!.longitude)
            : null,
      });


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      //print("Error al actualizar el negocio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el negocio')),
      );
    }
  }

  Future<String?> _uploadLogo() async {
    if (_logoImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'logonegocios/${_nombreController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
      UploadTask uploadTask = storageRef.putFile(_logoImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      //print('Error al subir el logo: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        setState(() {
          _logoImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      //print('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _navigateToMapaNegocio() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapaNegocioPage(negocioId: negocioData!['id']),
      ),
    );

    if (result != null) {
      setState(() {
        _ubicacion = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (negocioData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Negocio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateNegocio,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _logoImage != null
                    ? FileImage(_logoImage!)
                    : (_logoUrl != null
                            ? NetworkImage(_logoUrl!)
                            : const AssetImage('assets/placeholder.png'))
                        as ImageProvider,
                child: _logoImage == null
                    ? const Icon(Icons.camera_alt,
                        size: 50, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Nombre del Negocio', _nombreController),
            _buildTextField('Propietario', _propietarioController),
            _buildTextField('Número de Celular', _nroCelularController),
            _buildTextField('Dirección', _direccionController),
            const SizedBox(height: 20),
            _buildReadOnlyField('Encargado', _encargado),
            _buildReadOnlyField('Tipo de Cocina', _tipoCocina),
            const SizedBox(height: 20),
            _ubicacion != null
                ? Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: GoogleMap(
                          key: UniqueKey(),
                          initialCameraPosition: CameraPosition(
                            target: _ubicacion!,
                            zoom: 15.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('business-location'),
                              position: _ubicacion!,
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _navigateToMapaNegocio,
                        child: const Text('Editar Ubicación'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _navigateToMapaNegocio,
                    child: const Text('Seleccionar Ubicación'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: value ?? 'No disponible',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}

// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:restmap/services/firebase_auth_service.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importa esto si usas Google Maps

// class PerfilNegocioPage extends StatefulWidget {
//   const PerfilNegocioPage({Key? key}) : super(key: key);

//   @override
//   _PerfilNegocioPageState createState() => _PerfilNegocioPageState();
// }

// class _PerfilNegocioPageState extends State<PerfilNegocioPage> {
//   final FirebaseAuthService _authService = FirebaseAuthService();
//   final TextEditingController _nombreController = TextEditingController();
//   final TextEditingController _propietarioController = TextEditingController();
//   final TextEditingController _direccionController = TextEditingController();
//   String? _encargado;
//   String? _tipoCocina;
//   File? _logoImage;
//   String? _logoUrl;
//   LatLng? _ubicacion; // Guardar la ubicación del negocio
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
//         QuerySnapshot negocioSnapshot = await FirebaseFirestore.instance
//             .collection('negocios')
//             .where('encargado', isEqualTo: currentUser.uid)
//             .limit(1)
//             .get();

//         if (negocioSnapshot.docs.isNotEmpty) {
//           setState(() {
//             negocioData = negocioSnapshot.docs.first.data() as Map<String, dynamic>;
//             _nombreController.text = negocioData!['nombre'] ?? '';
//             _propietarioController.text = negocioData!['propietario'] ?? '';
//             _direccionController.text = negocioData!['direccion'] ?? '';
//             _encargado = negocioData!['encargado'];
//             _tipoCocina = negocioData!['tipo_cocina'];
//             _logoUrl = negocioData!['logo'];

//             // Verifica si 'ubicacion' es un GeoPoint y convierte a LatLng
//             if (negocioData!['ubicacion'] != null && negocioData!['ubicacion'] is GeoPoint) {
//               GeoPoint geoPoint = negocioData!['ubicacion'];
//               _ubicacion = LatLng(geoPoint.latitude, geoPoint.longitude); // Guarda la ubicación en LatLng
//             }
//           });
//         }
//       } catch (e) {
//         print("Error al cargar la información del negocio: $e");
//       }
//     }
//   }

//   Future<void> _updateNegocio() async {
//     if (negocioData == null) return;

//     try {
//       String? newLogoUrl = _logoUrl;

//       if (_logoImage != null) {
//         newLogoUrl = await _uploadLogo();
//       }

//       // Actualiza los datos del negocio
//       await FirebaseFirestore.instance
//           .collection('negocios')
//           .doc(negocioData!['id'])
//           .update({
//         'nombre': _nombreController.text,
//         'propietario': _propietarioController.text,
//         'direccion': _direccionController.text,
//         'logo': newLogoUrl,
//         // Asegúrate de guardar la ubicación si se ha seleccionado
//         'ubicacion': _ubicacion != null
//             ? GeoPoint(_ubicacion!.latitude, _ubicacion!.longitude)
//             : null,
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Perfil actualizado correctamente')),
//       );
//     } catch (e) {
//       print("Error al actualizar el negocio: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error al actualizar el negocio')),
//       );
//     }
//   }

//   Future<String?> _uploadLogo() async {
//     if (_logoImage == null) return null;

//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('logonegocios/${_nombreController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
//       UploadTask uploadTask = storageRef.putFile(_logoImage!);
//       TaskSnapshot snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error al subir el logo: $e');
//       return null;
//     }
//   }

//   Future<void> _pickImage() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

//       if (result != null) {
//         setState(() {
//           _logoImage = File(result.files.single.path!);
//         });
//       }
//     } catch (e) {
//       print('Error al seleccionar la imagen: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (negocioData == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Perfil del Negocio'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save),
//             onPressed: _updateNegocio,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: CircleAvatar(
//                 radius: 50,
//                 backgroundImage: _logoImage != null
//                     ? FileImage(_logoImage!)
//                     : (_logoUrl != null
//                         ? NetworkImage(_logoUrl!)
//                         : const AssetImage('assets/placeholder.png')) as ImageProvider,
//                 child: _logoImage == null
//                     ? const Icon(Icons.camera_alt, size: 50, color: Colors.white70)
//                     : null,
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildTextField('Nombre del Negocio', _nombreController),
//             _buildTextField('Propietario', _propietarioController),
//             _buildTextField('Dirección', _direccionController),
//             const SizedBox(height: 20),
//             _buildReadOnlyField('Encargado', _encargado),
//             _buildReadOnlyField('Tipo de Cocina', _tipoCocina),
//             const SizedBox(height: 20),
//             _ubicacion != null
//                 ? Text('Ubicación: Lat: ${_ubicacion!.latitude}, Lng: ${_ubicacion!.longitude}')
//                 : const Text('No se ha seleccionado una ubicación'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildReadOnlyField(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextField(
//         enabled: false,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: value ?? 'No disponible',
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//         ),
//       ),
//     );
//   }
// }
