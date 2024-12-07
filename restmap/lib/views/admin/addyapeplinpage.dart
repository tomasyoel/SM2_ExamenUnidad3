// import 'dart:io';
// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/services/upload_storage.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';

// class AddYapePlinPage extends StatefulWidget {
//   @override
//   _AddYapePlinPageState createState() => _AddYapePlinPageState();
// }

// class _AddYapePlinPageState extends State<AddYapePlinPage> {
//   final FirestoreService firestoreService = FirestoreService();
//   File? _image;
//   bool _isActive = true;

//   Future<void> _pickImage() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null) {
//       setState(() {
//         _image = File(result.files.single.path!);
//       });
//     }
//   }

//   Future<void> _uploadImage() async {
//     if (_image != null) {
//       String? imageUrl = await uploadMiyapeImage(_image!);
//       if (imageUrl != null) {
//         await firestoreService.addYapePlinImage({
//           'imageUrl': imageUrl,
//           'isActive': _isActive,
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Imagen subida exitosamente')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error al subir la imagen')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Seleccione una imagen primero')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Agregar Imagen Yape/Plin'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _image != null
//                 ? Image.file(_image!, height: 200)
//                 : Placeholder(fallbackHeight: 200),
//             SizedBox(height: 16),
//             SwitchListTile(
//               title: Text('Activo'),
//               value: _isActive,
//               onChanged: (bool value) {
//                 setState(() {
//                   _isActive = value;
//                 });
//               },
//             ),
//             ElevatedButton.icon(
//               onPressed: _pickImage,
//               icon: Icon(Icons.image),
//               label: Text('Seleccionar Imagen'),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _uploadImage,
//               child: Text('Subir Imagen'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
