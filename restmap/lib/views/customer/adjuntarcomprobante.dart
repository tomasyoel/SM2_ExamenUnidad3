// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/services/upload_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';

// class AdjuntarComprobantePage extends StatefulWidget {
//   final String orderId;
//   final double totalPrice;

//   AdjuntarComprobantePage({required this.orderId, required this.totalPrice});

//   @override
//   _AdjuntarComprobantePageState createState() => _AdjuntarComprobantePageState();
// }

// class _AdjuntarComprobantePageState extends State<AdjuntarComprobantePage> {
//   final FirestoreService firestoreService = FirestoreService();
//   File? _selectedImage;
//   bool _isLoadingImage = false;
//   TextEditingController _nombresCompletosController = TextEditingController();
//   bool _isButtonEnabled = false;

//   Future<void> _pickImage() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null) {
//       setState(() {
//         _selectedImage = File(result.files.single.path!);
//       });
//     }
//   }

//   Future<void> _uploadComprobante() async {
//     if (_selectedImage != null && _nombresCompletosController.text.isNotEmpty) {
//       setState(() {
//         _isLoadingImage = true;
//       });
//       String? url = await uploadComprobanteImage(_selectedImage!);
//       if (url != null) {
//         setState(() {
//           _isLoadingImage = false;
//         });
//         await firestoreService.updateOrder(widget.orderId, {'fotopago': url, 'nombresCompletos': _nombresCompletosController.text});
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Comprobante subido exitosamente')),
//         );
//         Navigator.of(context).pop();
//       } else {
//         setState(() {
//           _isLoadingImage = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error al subir el comprobante')),
//         );
//       }
//     }
//   }

//   void _onNameChanged() {
//     setState(() {
//       _isButtonEnabled = _nombresCompletosController.text.isNotEmpty;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     _nombresCompletosController.addListener(_onNameChanged);
//   }

//   @override
//   void dispose() {
//     _nombresCompletosController.removeListener(_onNameChanged);
//     _nombresCompletosController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Adjuntar Comprobante de Pago'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             FutureBuilder<Map<String, dynamic>?>(
//               future: firestoreService.getActiveYapePlinImage(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Container(
//                     height: 600,
//                     width: double.infinity,
//                     child: Center(
//                       child: Image.asset(
//                         'assets/loadingbeli.gif',
//                         height: 600,
//                         width: double.infinity,
//                       ),
//                     ),
//                   );
//                 }
//                 if (snapshot.hasData && snapshot.data != null) {
//                   return Container(
//                     height: 600,
//                     width: double.infinity,
//                     child: Image.network(
//                       snapshot.data!['imageUrl'],
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Center(
//                           child: Image.asset(
//                             'assets/loadingbeli.gif',
//                             height: 600,
//                             width: double.infinity,
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 } else {
//                   return Container(
//                     height: 600,
//                     width: double.infinity,
//                     child: Center(
//                       child: Text('No se encontró imagen activa de Yape/Plin'),
//                     ),
//                   );
//                 }
//               },
//             ),
//             SizedBox(height: 16),
//             Container(
//               height: 600,
//               width: double.infinity,
//               child: _selectedImage != null
//                   ? Image.file(_selectedImage!, fit: BoxFit.cover)
//                   : Center(child: Text('No se ha seleccionado ninguna imagen')),
//             ),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: _pickImage,
//                   child: Text('Seleccionar\nImagen', textAlign: TextAlign.center),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: _isButtonEnabled ? _uploadComprobante : null,
//                   child: _isLoadingImage
//                       ? CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         )
//                       : Text('Subir\nComprobante', textAlign: TextAlign.center),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Total a pagar: S/.${widget.totalPrice.toStringAsFixed(2)}',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             TextField(
//               controller: _nombresCompletosController,
//               decoration: InputDecoration(
//                 hintText: 'Ingrese nombres completos del propietario de su yape en mayúscula',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Importante: El pago correspondiente será validado por el administrador, si el comprobante es falso se rechazará el pedido y se eliminará el mismo sin opción a reclamos',
//               style: TextStyle(fontSize: 12, color: Colors.red),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }