import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class AgregarProductoPage extends StatefulWidget {
  final String negocioId;

  const AgregarProductoPage({Key? key, required this.negocioId}) : super(key: key);

  @override
  _AgregarProductoPageState createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _estadoSeleccionado = 'disponible';
  String? _categoriaSeleccionadaId;
  final TextEditingController _idProdController = TextEditingController();
  File? _imagen;
  String? _urlImagen;
  bool _isImageUploaded = false;

  final List<String> _opcionesEstado = ['disponible', 'agotado', 'promocion'];

  void _generarCodigo() {
    if (_nombreController.text.isNotEmpty) {
      var uuid = Uuid();
      _idProdController.text = uuid.v4();
    }
  }

  Future<void> seleccionarImagen() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        File imagenArchivo = File(result.files.single.path!);
        String? nombreImagen = await _subirImagen(imagenArchivo);
        if (nombreImagen != null) {
          setState(() {
            _imagen = imagenArchivo;
            _urlImagen = nombreImagen;
            _isImageUploaded = true;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imagen subida exitosamente')));
          });
        }
      } else {
        print('No se seleccionó ninguna imagen.');
      }
    } catch (e) {
      print('Error al seleccionar la imagen: $e');
    }
  }

  Future<String?> _subirImagen(File imagen) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('productos/${_nombreController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
      UploadTask uploadTask = storageRef.putFile(imagen);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  Future<void> agregarProducto() async {
    if (_nombreController.text.isEmpty ||
        _descripcionController.text.isEmpty ||
        _precioController.text.isEmpty ||
        _categoriaSeleccionadaId == null ||
        _urlImagen == null ||
        !_isImageUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Por favor, completa todos los campos, selecciona una imagen y asegúrate de que esté cargada.')));
      return;
    }

    if (_idProdController.text.isEmpty) {
      _generarCodigo();
    }

    
    int stock = int.tryParse(_stockController.text) ?? 0;
    if (stock < 0) {
      stock = 0;
    }

    final nuevoProducto = {
      'codigo': _idProdController.text,
      'nombre': _nombreController.text,
      'descripcion': _descripcionController.text,
      'precio': double.parse(_precioController.text),
      'stock': stock,
      'estado': _estadoSeleccionado,
      'urlImagen': _urlImagen,
      'catprod': _categoriaSeleccionadaId,
    };

    await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .update({
      'productos': FieldValue.arrayUnion([nuevoProducto])
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Producto agregado exitosamente')));

    _limpiarFormulario();
  }

  Future<void> _cargarCategorias() async {
    DocumentSnapshot negocio = await FirebaseFirestore.instance.collection('cartasnegocio').doc(widget.negocioId).get();
    List categorias = negocio['categoriasprod'] ?? [];
    setState(() {
      _categorias = categorias.map((cat) => {
        'nombre': cat['nombre'],
        'id': cat['id'] 
      }).toList();
    });
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _precioController.clear();
    _stockController.clear();
    _estadoSeleccionado = 'disponible';
    _idProdController.clear();
    setState(() {
      _imagen = null;
      _isImageUploaded = false;
    });
  }


  List<Map<String, dynamic>> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Producto'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _idProdController,
              decoration: InputDecoration(labelText: 'Código del Producto'),
              enabled: false,
            ),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre del Producto'),
              onEditingComplete: _generarCodigo,
            ),
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(labelText: 'Descripción breve'),
            ),
            TextField(
              controller: _precioController,
              decoration: InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionadaId,
              onChanged: (String? newValue) {
                setState(() {
                  _categoriaSeleccionadaId = newValue ?? '';
                });
              },
              items: _categorias.map<DropdownMenuItem<String>>((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria['id'],
                  child: Text(categoria['nombre']),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Categoría'),
            ),
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado,
              onChanged: (String? newValue) {
                setState(() {
                  _estadoSeleccionado = newValue!;
                });
              },
              items: _opcionesEstado.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Estado'),
            ),
            SizedBox(height: 20),
            _imagen == null
                ? Icon(Icons.image_not_supported, size: 150)
                : Image.file(_imagen!, height: 150, width: 150),
            ElevatedButton(onPressed: seleccionarImagen, child: Text('Seleccionar Imagen')),
            ElevatedButton(onPressed: agregarProducto, child: Text('Agregar Producto')),
          ],
        ),
      ),
    );
  }
}







// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:uuid/uuid.dart';

// class AgregarProductoPage extends StatefulWidget {
//   final String negocioId; // Recibe el ID del negocio al que se agregará el producto

//   const AgregarProductoPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _AgregarProductoPageState createState() => _AgregarProductoPageState();
// }

// class _AgregarProductoPageState extends State<AgregarProductoPage> {
//   final TextEditingController _nombreController = TextEditingController();
//   final TextEditingController _descripcionController = TextEditingController();
//   final TextEditingController _precioController = TextEditingController();
//   final TextEditingController _stockController = TextEditingController();
//   String _estadoSeleccionado = 'disponible';
//   final TextEditingController _idProdController = TextEditingController();
//   File? _imagen;
//   String? _urlImagen;
//   bool _isImageUploaded = false;

//   final List<String> _opcionesEstado = ['disponible', 'agotado', 'promocion'];

//   void _generarCodigo() {
//     if (_nombreController.text.isNotEmpty) {
//       var uuid = Uuid();
//       _idProdController.text = uuid.v4();
//     }
//   }

//   Future<void> seleccionarImagen() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//       if (result != null) {
//         File imagenArchivo = File(result.files.single.path!);
//         String? nombreImagen = await _subirImagen(imagenArchivo);
//         if (nombreImagen != null) {
//           setState(() {
//             _imagen = imagenArchivo;
//             _urlImagen = nombreImagen;
//             _isImageUploaded = true;
//             ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Imagen subida exitosamente')));
//           });
//         }
//       } else {
//         print('No se seleccionó ninguna imagen.');
//       }
//     } catch (e) {
//       print('Error al seleccionar la imagen: $e');
//     }
//   }

//   Future<String?> _subirImagen(File imagen) async {
//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('productos/${_nombreController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
//       UploadTask uploadTask = storageRef.putFile(imagen);
//       TaskSnapshot snapshot = await uploadTask;
//       return await snapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error al subir la imagen: $e');
//       return null;
//     }
//   }

//   Future<void> agregarProducto() async {
//     if (_nombreController.text.isEmpty ||
//         _descripcionController.text.isEmpty ||
//         _precioController.text.isEmpty ||
//         _stockController.text.isEmpty ||
//         _urlImagen == null ||
//         !_isImageUploaded) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(
//               'Por favor, completa todos los campos, selecciona una imagen y asegúrate de que esté cargada.')));
//       return;
//     }

//     if (_idProdController.text.isEmpty) {
//       _generarCodigo();
//     }

//     // Validar y asignar el stock
//     int stock = int.tryParse(_stockController.text) ?? 0; // Si está vacío, será 0
//     if (stock < 0) {
//       stock = 0; // No permitir valores negativos
//     }


//     final nuevoProducto = {
//       'codigo': _idProdController.text,
//       'nombre': _nombreController.text,
//       'descripcion': _descripcionController.text,
//       'precio': double.parse(_precioController.text),
//       // 'stock': int.parse(_stockController.text),
//       'stock': stock, // Guardar el stock como 0 si está vacío o es 0
//       'estado': _estadoSeleccionado,
//       'urlImagen': _urlImagen,
//     };

//     await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .update({
//       'productos': FieldValue.arrayUnion([nuevoProducto])
//     });

//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text('Producto agregado exitosamente')));

//     _limpiarFormulario();
//   }

//   void _limpiarFormulario() {
//     _nombreController.clear();
//     _descripcionController.clear();
//     _precioController.clear();
//     _stockController.clear();
//     _estadoSeleccionado = 'disponible';
//     _idProdController.clear();
//     setState(() {
//       _imagen = null;
//       _isImageUploaded = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Agregar Producto'),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               controller: _idProdController,
//               decoration: InputDecoration(labelText: 'Código del Producto'),
//               enabled: false,
//             ),
//             TextField(
//               controller: _nombreController,
//               decoration: InputDecoration(labelText: 'Nombre del Producto'),
//               onEditingComplete: _generarCodigo,
//             ),
//             TextField(
//               controller: _descripcionController,
//               decoration: InputDecoration(labelText: 'Descripción breve'),
//             ),
//             TextField(
//               controller: _precioController,
//               decoration: InputDecoration(labelText: 'Precio'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: _stockController,
//               decoration: InputDecoration(labelText: 'Stock'),
//               keyboardType: TextInputType.number,
//             ),
//             DropdownButtonFormField<String>(
//               value: _estadoSeleccionado,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _estadoSeleccionado = newValue!;
//                 });
//               },
//               items: _opcionesEstado.map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               decoration: InputDecoration(labelText: 'Estado'),
//             ),
//             SizedBox(height: 20),
//             _imagen == null
//                 ? Icon(Icons.image_not_supported, size: 150)
//                 : Image.file(_imagen!, height: 150, width: 150),
//             ElevatedButton(onPressed: seleccionarImagen, child: Text('Seleccionar Imagen')),
//             ElevatedButton(onPressed: agregarProducto, child: Text('Agregar Producto')),
//           ],
//         ),
//       ),
//     );
//   }
// }
