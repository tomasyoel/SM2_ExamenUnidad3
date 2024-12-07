// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';

// class GestionarTipoCocinaPage extends StatelessWidget {
//   final CollectionReference tiposCocina =
//       FirebaseFirestore.instance.collection('tipococina');
//   final CollectionReference negocios =
//       FirebaseFirestore.instance.collection('negocios');

//   const GestionarTipoCocinaPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Gestionar Tipos de Cocina"),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: tiposCocina.snapshots(),
//         builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final tipos = snapshot.data!.docs;

//           if (tipos.isEmpty) {
//             return const Center(
//               child: Text(
//                 "No hay tipos de cocina registrados.",
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: tipos.length,
//             itemBuilder: (context, index) {
//               var tipoCocina = tipos[index];
//               var tipoData = tipoCocina.data() as Map<String, dynamic>?;

//               return ListTile(
//                 leading: tipoData?['imagen'] != null
//                     ? Image.network(
//                         tipoData!['imagen'],
//                         width: 50,
//                         height: 50,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Icon(Icons.image_not_supported);
//                         },
//                       )
//                     : const Icon(Icons.image_not_supported),
//                 title: Text(tipoCocina['nombre'] ?? 'Sin nombre'),
//                 trailing: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     IconButton(
//                       icon: const Icon(Icons.edit),
//                       onPressed: () =>
//                           _editTipoCocina(context, tipoCocina, tipoData),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete),
//                       onPressed: () =>
//                           _showDeleteConfirmationDialog(context, tipoCocina.id, tipoData?['imagen']),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _editTipoCocina(BuildContext context, DocumentSnapshot document, Map<String, dynamic>? tipoData) {
//     final TextEditingController nameController = TextEditingController();
//     File? newImage;
//     String? imageUrl = tipoData?['imagen'];
//     bool isSaving = false;

//     nameController.text = document['nombre'] ?? 'Sin nombre';

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('Editar Tipo de Cocina'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: nameController,
//                     decoration: const InputDecoration(hintText: "Nombre"),
//                   ),
//                   const SizedBox(height: 20),
//                   GestureDetector(
//                     onTap: () async {
//                       FilePickerResult? result =
//                           await FilePicker.platform.pickFiles(type: FileType.image);

//                       if (result != null) {
//                         setState(() {
//                           newImage = File(result.files.single.path!);
//                         });
//                       }
//                     },
//                     child: CircleAvatar(
//                       radius: 50,
//                       backgroundImage: newImage != null
//                           ? FileImage(newImage!)
//                           : imageUrl != null
//                               ? NetworkImage(imageUrl!)
//                               : null as ImageProvider?,
//                       child: newImage == null && imageUrl == null
//                           ? const Icon(Icons.camera_alt, size: 50)
//                           : null,
//                     ),
//                   ),
//                 ],
//               ),
//               actions: <Widget>[
//                 TextButton(
//                   child: const Text('Cancelar'),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                 ),
//                 ElevatedButton(
//                   onPressed: isSaving
//                       ? null
//                       : () async {
//                           setState(() {
//                             isSaving = true;
//                           });

//                           try {

//                             if (newImage != null) {

//                               if (imageUrl != null) {
//                                 await FirebaseStorage.instance
//                                     .refFromURL(imageUrl!)
//                                     .delete();
//                               }

//                               final storageRef = FirebaseStorage.instance
//                                   .ref()
//                                   .child('tipococinaimagen/${document.id}_${DateTime.now().millisecondsSinceEpoch}.png');
//                               UploadTask uploadTask = storageRef.putFile(newImage!);
//                               TaskSnapshot snapshot = await uploadTask;
//                               imageUrl = await snapshot.ref.getDownloadURL();
//                             }

//                             await tiposCocina.doc(document.id).update({
//                               'nombre': nameController.text,
//                               'imagen': imageUrl,
//                             });

//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Tipo de cocina actualizado correctamente.'),
//                               ),
//                             );

//                             Navigator.of(context).pop();
//                           } catch (e) {

//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('Error al actualizar: $e'),
//                               ),
//                             );
//                           } finally {
//                             setState(() {
//                               isSaving = false;
//                             });
//                           }
//                         },
//                   child: isSaving
//                       ? const CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         )
//                       : const Text('Guardar'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   void _showDeleteConfirmationDialog(BuildContext context, String documentId, String? imageUrl) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Confirmación'),
//           content: const Text('¿Estás seguro de que deseas eliminar este tipo de cocina?'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('No'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Sí'),
//               onPressed: () async {

//                 await _checkAndDeleteTipoCocina(dialogContext, documentId, imageUrl);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _checkAndDeleteTipoCocina(
//       BuildContext context, String documentId, String? imageUrl) async {
//     try {

//       QuerySnapshot negociosAsignados = await FirebaseFirestore.instance
//           .collection('negocios')
//           .where('tipo_cocina', isEqualTo: documentId)
//           .get();

//       if (negociosAsignados.docs.isNotEmpty) {

//         Navigator.of(context).pop();

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No se puede eliminar, está asignado a un negocio.'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else {

//         Navigator.of(context).pop();

//         await _deleteTipoCocina(context, documentId, imageUrl);

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Tipo de cocina eliminado exitosamente.'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {

//       Navigator.of(context).pop();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _deleteTipoCocina(
//       BuildContext context, String documentId, String? imageUrl) async {
//     try {

//       await FirebaseFirestore.instance
//           .collection('tipococina')
//           .doc(documentId)
//           .delete();

//       if (imageUrl != null && imageUrl.isNotEmpty) {
//         try {
//           await FirebaseStorage.instance.refFromURL(imageUrl).delete();
//         } catch (e) {
//           print('Error al eliminar la imagen: $e');
//         }
//       }
//     } catch (e) {
//       throw Exception('Error al eliminar el tipo de cocina: $e');
//     }
//   }
// }
