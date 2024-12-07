// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:restmap/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  _CustomerProfilePageState createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _nroCelularController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  String? _photoUrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await _firestoreService.getUserById(user!.uid);
      var userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _nombreController.text = userData['nombre'] ?? '';
        _apellidoController.text = userData['apellido'] ?? '';
        _nroCelularController.text = userData['nro_celular'] ?? '';
        _photoUrl = userData['photoUrl'];
        _edadController.text = userData['edad']?.toString() ?? '';
      });
    }
  }

  Future<void> _updateUserData() async {
    if (user != null && _formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'nro_celular': _nroCelularController.text,
        'photoUrl': _photoUrl,
        'edad': int.tryParse(_edadController.text) ?? 0,
      };
      await _firestoreService.updateUser(user!.uid, updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos Actualizados')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Cliente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              _buildTextField('Nombre', _nombreController),
              _buildTextField('Apellido', _apellidoController),
              _buildTextField('Número de Celular', _nroCelularController),
              _buildTextField('Edad', _edadController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateUserData,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}

// import 'dart:io';

// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/services/upload_storage.dart';
// import 'package:restmap/views/customer/user_location_page.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';

// class CustomerProfilePage extends StatefulWidget {
//   @override
//   _CustomerProfilePageState createState() => _CustomerProfilePageState();
// }

// class _CustomerProfilePageState extends State<CustomerProfilePage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final User? user = FirebaseAuth.instance.currentUser;

//   final TextEditingController _nombreController = TextEditingController();
//   final TextEditingController _apellidoController = TextEditingController();
//   final TextEditingController _nroCelularController = TextEditingController();
//   final TextEditingController _direccionController = TextEditingController();
//   final TextEditingController _edadController = TextEditingController();
//   final TextEditingController _restriccionesController = TextEditingController();
//   String? _photoUrl;
//   File? _image;

//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     if (user != null) {
//       DocumentSnapshot userDoc = await _firestoreService.getUserById(user!.uid);
//       var userData = userDoc.data() as Map<String, dynamic>;

//       QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
//           .collection('usuarios')
//           .doc(user!.uid)
//           .collection('direcciones')
//           .where('predeterminada', isEqualTo: true)
//           .limit(1)
//           .get();
//       String defaultAddress = addressSnapshot.docs.isNotEmpty
//           ? addressSnapshot.docs.first['direccion']
//           : '----------';

//       setState(() {
//         _nombreController.text = userData['nombre'] ?? '';
//         _apellidoController.text = userData['apellido'] ?? '';
//         _nroCelularController.text = userData['nro_celular'] ?? '';
//         _direccionController.text = defaultAddress;
//         _photoUrl = userData['photoUrl'];
//         _edadController.text = userData['edad']?.toString() ?? '';
//         _restriccionesController.text = userData['restricciones_nutricionales'] ?? '';
//       });
//     }
//   }

//   Future<void> _updateUserData() async {
//     if (user != null && _formKey.currentState!.validate()) {
//       Map<String, dynamic> updatedData = {
//         'nombre': _nombreController.text,
//         'apellido': _apellidoController.text,
//         'nro_celular': _nroCelularController.text,
//         'direccion': _direccionController.text,
//         'photoUrl': _photoUrl,
//         'edad': int.tryParse(_edadController.text) ?? 0,
//         'restricciones_nutricionales': _restriccionesController.text,
//       };
//       await _firestoreService.updateUser(user!.uid, updatedData);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Datos Actualizados')),
//       );
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _pickImage() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//       );

//       if (result != null) {
//         setState(() {
//           _image = File(result.files.single.path!);
//         });
//         await _uploadImage();
//       } else {

//         print('No image selected.');
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }

//   Future<void> _takePicture() async {
//     // falta implementar fotos por camara
//     print('Take picture not implemented.');
//   }

//   Future<void> _uploadImage() async {
//     if (_image != null && user != null) {
//       try {
//         String? downloadUrl = await uploadProfileImage(_image!);
//         if (downloadUrl != null) {
//           setState(() {
//             _photoUrl = downloadUrl;
//           });
//           await _updateUserData();
//         }
//       } catch (e) {
//         print('Error uploading image: $e');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Perfil del Cliente'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               GestureDetector(
//                 onTap: () => _showImageSourceActionSheet(context),
//                 child: CircleAvatar(
//                   radius: 50,
//                   backgroundImage: _photoUrl != null
//                       ? NetworkImage(_photoUrl!)
//                       : AssetImage('assets/placeholder.png') as ImageProvider,
//                   child: _photoUrl == null ? Icon(Icons.camera_alt, size: 50) : null,
//                 ),
//               ),
//               SizedBox(height: 20),
//               _buildTextField('Nombre', _nombreController),
//               _buildTextField('Apellido', _apellidoController),
//               _buildTextField('Número de Celular', _nroCelularController),
//               _buildTextFieldWithButton(
//                 'Dirección',
//                 _direccionController,
//                 'Editar Dirección',
//                 () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       // builder: (context) => UserLocationPage(userId: user!.uid),
//                       builder: (context) => UserLocationPage(),
//                     ),
//                   ).then((_) {
//                     _loadUserData();
//                   });
//                 },
//               ),
//               _buildAgeField('Edad', _edadController, keyboardType: TextInputType.number),
//               _buildTextField('Restricciones Nutricionales', _restriccionesController, maxLines: 5, maxLength: 500),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (user != null && user!.email != null) {
//                     await FirebaseAuth.instance
//                         .sendPasswordResetEmail(email: user!.email!);
//                     _showInfoDialog('Correo para restablecer contraseña enviado.');
//                   }
//                 },
//                 child: Text('Cambiar Contraseña'),
//               ),
//               SizedBox(height: 20),
//               Align(
//                 alignment: Alignment.bottomRight,
//                 child: ElevatedButton.icon(
//                   onPressed: _updateUserData,
//                   icon: Icon(IconlyBold.edit),
//                   label: Text('Guardar'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, int? maxLength}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//           counterText: maxLength != null ? '' : null,
//         ),
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         maxLength: maxLength,
//       ),
//     );
//   }

//   Widget _buildTextFieldWithButton(String label, TextEditingController controller, String buttonText, VoidCallback onPressed) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextFormField(
//               controller: controller,
//               readOnly: true,
//               decoration: InputDecoration(
//                 labelText: label,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.0),
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(width: 8.0),
//           ElevatedButton(
//             onPressed: onPressed,
//             child: Text(buttonText),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAgeField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.number}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//         ),
//         keyboardType: keyboardType,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Por favor ingrese su edad';
//           }
//           final age = int.tryParse(value);
//           if (age == null || age < 18 || age > 100) {
//             return 'Ingrese una edad válida entre 18 y 100';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   void _showImageSourceActionSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: Icon(Icons.photo_library),
//                 title: Text('Elegir desde galería'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage();
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.photo_camera),
//                 title: Text('Tomar una foto'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _takePicture();
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showInfoDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text('Información'),
//         content: Text(message),
//         actions: <Widget>[
//           TextButton(
//             child: Text('Okay'),
//             onPressed: () {
//               Navigator.of(ctx).pop();
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
