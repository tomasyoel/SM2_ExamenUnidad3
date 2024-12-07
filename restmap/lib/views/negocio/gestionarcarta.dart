import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GestionarCartaPage extends StatefulWidget {
  final String negocioId;

  const GestionarCartaPage({super.key, required this.negocioId});

  @override
  _GestionarCartaPageState createState() => _GestionarCartaPageState();
}

class _GestionarCartaPageState extends State<GestionarCartaPage> {
  List<Map<String, dynamic>> productos = [];
  Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};
  String? selectedCategory;
  String? selectedProduct;
  List<Map<String, dynamic>> selectedProductsInCarta = [];
  Color _colorFondo = Colors.black;
  Color _colorTexto = Colors.orange;
  File? _imagenFondo;

  @override
  void initState() {
    super.initState();
    _loadProductos();
    _loadCarta();
  }

  Future<void> _loadProductos() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    if (cartaSnapshot.exists) {
      setState(() {
        productos =
            List<Map<String, dynamic>>.from(cartaSnapshot['productos'] ?? []);
        _agruparProductosPorCategoria();
      });
    }
  }

  Future<Map<String, String>> _getCategoryNames() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    List categorias = cartaSnapshot['categoriasprod'] ?? [];
    Map<String, String> categoryMap = {};
    for (var cat in categorias) {
      categoryMap[cat['id']] = cat['nombre'];
    }
    return categoryMap;
  }

  Future<void> _loadCarta() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    if (cartaSnapshot.exists) {
      setState(() {
        selectedProductsInCarta =
            List<Map<String, dynamic>>.from(cartaSnapshot['carta'] ?? []);
      });
    }

    Map<String, String> categoryNames = await _getCategoryNames();
    setState(() {
      for (var product in selectedProductsInCarta) {
        product['categoryName'] =
            categoryNames[product['catprod']] ?? 'Sin categoría';
      }
    });
  }

  Future<void> _agruparProductosPorCategoria() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    List categorias = cartaSnapshot['categoriasprod'] ?? [];

    Map<String, String> categoryIdToNameMap = {};

    for (var cat in categorias) {
      categoryIdToNameMap[cat['id']] = cat['nombre'];
    }

    Map<String, List<Map<String, dynamic>>> agrupados = {};
    for (var producto in productos) {
      String categoriaId = producto['catprod'] ?? 'Sin Categoría';
      String categoriaNombre =
          categoryIdToNameMap[categoriaId] ?? 'Sin Categoría';

      if (!agrupados.containsKey(categoriaNombre)) {
        agrupados[categoriaNombre] = [];
      }
      agrupados[categoriaNombre]!.add(producto);
    }

    setState(() {
      productosPorCategoria = agrupados;
    });
  }

  Future<void> _saveCarta() async {
    await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .update({
      'carta': selectedProductsInCarta,
    });
  }

  Widget _buildMenuSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _colorFondo.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildEditableMenuItem(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableMenuItem(Map<String, dynamic> product) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(product['urlImagen'] ?? ''),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product['nombre'] ?? 'Sin nombre',
                style: TextStyle(fontSize: 18, color: _colorTexto),
              ),
              const SizedBox(height: 5),
              Text(
                'Precio: S/.${product['precio']?.toString() ?? '0'}',
                style: TextStyle(
                    fontSize: 16, color: _colorTexto.withOpacity(0.7)),
              ),
              if (product['stock'] != null && product['stock'] > 0)
                Text(
                  'Stock: ${product['stock']}',
                  style: TextStyle(
                      fontSize: 16, color: _colorTexto.withOpacity(0.7)),
                ),
              Text(
                'Estado: ${product['estado'] ?? 'Sin estado'}',
                style: TextStyle(
                    fontSize: 16, color: _colorTexto.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_red_eye, color: Colors.white),
          onPressed: () {
            _showProductPreviewDialog(product);
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.red),
          onPressed: () {
            setState(() {
              selectedProductsInCarta.remove(product);
              _saveCarta();
            });
          },
        ),
      ],
    );
  }

  void _showProductPreviewDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            product['nombre'] ?? 'Sin nombre',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['urlImagen'] != null)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(product['urlImagen']),
                        fit: BoxFit.contain,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                const SizedBox(height: 10),
                if (product['descripcion'] != null)
                  Text(
                    product['descripcion'],
                    style: const TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Precio: S/.${product['precio']?.toString() ?? '0'}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                if (product['stock'] != null && product['stock'] > 0)
                  Text(
                    'Stock: ${product['stock']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 5),
                Text(
                  'Estado: ${product['estado'] ?? 'Sin estado'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartaPreview() {
    return Stack(
      children: [
        if (_imagenFondo != null)
          Positioned.fill(
            child: Image.file(
              _imagenFondo!,
              fit: BoxFit.cover,
            ),
          ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Previsualización de la Carta',
                style: TextStyle(fontSize: 24, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              if (productosPorCategoria.isNotEmpty)
                ...productosPorCategoria.entries.map((entry) {
                  String categoria = entry.key;
                  List<Map<String, dynamic>> productosDeCategoria = entry.value;
                  return _buildMenuSection(categoria, productosDeCategoria);
                }),
              if (productosPorCategoria.isEmpty)
                const Center(
                    child: Text('No hay productos añadidos a la carta',
                        style: TextStyle(color: Colors.orange))),
            ],
          ),
        ),
      ],
    );
  }

  void _addProductToCarta(String? productName) {
    final product = productos.firstWhere(
        (element) => element['nombre'] == productName,
        orElse: () => {});
    final existsInCarta =
        selectedProductsInCarta.any((p) => p['nombre'] == productName);

    if (product.isNotEmpty && !existsInCarta) {
      setState(() {
        selectedProductsInCarta.add(product);
        _saveCarta();
      });
    } else if (existsInCarta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El producto ya existe en la carta.')),
      );
    }
  }

  void _pickBackgroundImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _imagenFondo = File(result.files.single.path!);
      });
    }
  }

  void _pickColorFondo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color de fondo'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _colorFondo,
              onColorChanged: (color) {
                setState(() {
                  _colorFondo = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _pickColorTexto() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un color de texto'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _colorTexto,
              onColorChanged: (color) {
                setState(() {
                  _colorTexto = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
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
        title: const Text('Gestionar Carta'),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar Productos a la Carta',
              style: TextStyle(fontSize: 20, color: Colors.orange),
            ),
            DropdownButton<String>(
              value: selectedProduct,
              hint: const Text('Selecciona un producto',
                  style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.black,
              onChanged: (String? value) {
                setState(() {
                  selectedProduct = value;
                  _addProductToCarta(value);
                });
              },
              items: productos.map<DropdownMenuItem<String>>((product) {
                return DropdownMenuItem<String>(
                  value: product['nombre'],
                  child: Text(product['nombre'],
                      style: const TextStyle(color: Colors.orange)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickBackgroundImage,
              child: const Text('Seleccionar Imagen de Fondo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickColorFondo,
              child: const Text('Seleccionar Color de Fondo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickColorTexto,
              child: const Text('Seleccionar Color de Texto'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Previsualización de la Carta',
              style: TextStyle(fontSize: 20, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            _buildCartaPreview(),
          ],
        ),
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';

// class GestionarCartaPage extends StatefulWidget {
//   final String negocioId;

//   const GestionarCartaPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _GestionarCartaPageState createState() => _GestionarCartaPageState();
// }

// class _GestionarCartaPageState extends State<GestionarCartaPage> {
//   List<Map<String, dynamic>> productos = [];
//   Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};
//   String? selectedCategory;
//   String? selectedProduct;
//   List<Map<String, dynamic>> selectedProductsInCarta = [];
//   Color _colorFondo = Colors.black;
//   Color _colorTexto = Colors.orange;
//   File? _imagenFondo;

//   @override
//   void initState() {
//     super.initState();
//     _loadProductos();
//     _loadCarta();
//   }

//   Future<void> _loadProductos() async {
//     final cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (cartaSnapshot.exists) {
//       setState(() {
//         productos = List<Map<String, dynamic>>.from(cartaSnapshot['productos'] ?? []);
//         _agruparProductosPorCategoria();
//       });
//     }
//   }

//   void _agruparProductosPorCategoria() {
//     Map<String, List<Map<String, dynamic>>> agrupados = {};
//     for (var producto in productos) {
//       String categoria = producto['catprod'] ?? 'Sin Categoría';
//       if (!agrupados.containsKey(categoria)) {
//         agrupados[categoria] = [];
//       }
//       agrupados[categoria]!.add(producto);
//     }
//     setState(() {
//       productosPorCategoria = agrupados;
//     });
//   }

//   Future<void> _loadCarta() async {
//     final cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (cartaSnapshot.exists) {
//       setState(() {
//         selectedProductsInCarta = List<Map<String, dynamic>>.from(cartaSnapshot['carta'] ?? []);
//       });
//     }
//   }

//   Future<void> _saveCarta() async {
//     await FirebaseFirestore.instance.collection('cartasnegocio').doc(widget.negocioId).update({
//       'carta': selectedProductsInCarta,
//     });
//   }

//   Widget _buildMenuSection(String title, List<Map<String, dynamic>> items) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: _colorTexto,
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: _colorFondo.withOpacity(0.8),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: items.map((item) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: _buildEditableMenuItem(item),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEditableMenuItem(Map<String, dynamic> product) {
//     return Row(
//       children: [
//         Container(
//           width: 80,
//           height: 80,
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: NetworkImage(product['urlImagen'] ?? ''),
//               fit: BoxFit.cover,
//             ),
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 product['nombre'] ?? 'Sin nombre',
//                 style: TextStyle(fontSize: 18, color: _colorTexto),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Precio: S/.${product['precio']?.toString() ?? '0'}',
//                 style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//               ),
//               if (product['stock'] != null && product['stock'] > 0)
//                 Text(
//                   'Stock: ${product['stock']}',
//                   style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//                 ),
//               Text(
//                 'Estado: ${product['estado'] ?? 'Sin estado'}',
//                 style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//               ),
//             ],
//           ),
//         ),
//         IconButton(
//           icon: const Icon(Icons.remove_red_eye, color: Colors.white),
//           onPressed: () {
//             _showProductPreviewDialog(product);
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.clear, color: Colors.red),
//           onPressed: () {
//             setState(() {
//               selectedProductsInCarta.remove(product);
//               _saveCarta();
//             });
//           },
//         ),
//       ],
//     );
//   }

//   void _showProductPreviewDialog(Map<String, dynamic> product) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             product['nombre'] ?? 'Sin nombre',
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (product['urlImagen'] != null)
//                   Container(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     height: 200,
//                     decoration: BoxDecoration(
//                       image: DecorationImage(
//                         image: NetworkImage(product['urlImagen']),
//                         fit: BoxFit.contain,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 const SizedBox(height: 10),
//                 if (product['descripcion'] != null)
//                   Text(
//                     product['descripcion'],
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'Precio: S/.${product['precio']?.toString() ?? '0'}',
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 5),
//                 if (product['stock'] != null && product['stock'] > 0)
//                   Text(
//                     'Stock: ${product['stock']}',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 const SizedBox(height: 5),
//                 Text(
//                   'Estado: ${product['estado'] ?? 'Sin estado'}',
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cerrar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildCartaPreview() {
//     return Stack(
//       children: [
//         if (_imagenFondo != null)
//           Positioned.fill(
//             child: Image.file(
//               _imagenFondo!,
//               fit: BoxFit.cover,
//             ),
//           ),
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Previsualización de la Carta',
//                 style: TextStyle(fontSize: 24, color: Colors.orange),
//               ),
//               const SizedBox(height: 20),
//               if (productosPorCategoria.isNotEmpty)
//                 ...productosPorCategoria.entries.map((entry) {
//                   String categoria = entry.key;
//                   List<Map<String, dynamic>> productosDeCategoria = entry.value;
//                   return _buildMenuSection(categoria, productosDeCategoria);
//                 }).toList(),
//               if (productosPorCategoria.isEmpty)
//                 const Center(
//                     child: Text('No hay productos añadidos a la carta',
//                         style: TextStyle(color: Colors.orange))),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _addProductToCarta(String? productName) {
//     final product = productos.firstWhere((element) => element['nombre'] == productName, orElse: () => {});
//     if (product.isNotEmpty) {
//       setState(() {
//         selectedProductsInCarta.add(product);
//         _saveCarta(); // Guardar la carta en Firebase cuando se agrega un producto
//       });
//     }
//   }

//   void _pickBackgroundImage() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null) {
//       setState(() {
//         _imagenFondo = File(result.files.single.path!);
//       });
//     }
//   }

//   void _pickColorFondo() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Selecciona un color de fondo'),
//           content: SingleChildScrollView(
//             child: BlockPicker(
//               pickerColor: _colorFondo,
//               onColorChanged: (color) {
//                 setState(() {
//                   _colorFondo = color;
//                 });
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cerrar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _pickColorTexto() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Selecciona un color de texto'),
//           content: SingleChildScrollView(
//             child: BlockPicker(
//               pickerColor: _colorTexto,
//               onColorChanged: (color) {
//                 setState(() {
//                   _colorTexto = color;
//                 });
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cerrar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestionar Carta'),
//         backgroundColor: Colors.green,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Agregar Productos a la Carta',
//               style: TextStyle(fontSize: 20, color: Colors.orange),
//             ),
//             DropdownButton<String>(
//               value: selectedProduct,
//               hint: const Text('Selecciona un producto', style: TextStyle(color: Colors.white)),
//               dropdownColor: Colors.black,
//               onChanged: (String? value) {
//                 setState(() {
//                   selectedProduct = value;
//                   _addProductToCarta(value);
//                 });
//               },
//               items: productos.map<DropdownMenuItem<String>>((product) {
//                 return DropdownMenuItem<String>(
//                   value: product['nombre'],
//                   child: Text(product['nombre'], style: const TextStyle(color: Colors.orange)),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickBackgroundImage,
//               child: const Text('Seleccionar Imagen de Fondo'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _pickColorFondo,
//               child: const Text('Seleccionar Color de Fondo'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _pickColorTexto,
//               child: const Text('Seleccionar Color de Texto'),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Previsualización de la Carta',
//               style: TextStyle(fontSize: 20, color: Colors.orange),
//             ),
//             const SizedBox(height: 20),
//             _buildCartaPreview(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';

// class GestionarCartaPage extends StatefulWidget {
//   final String negocioId;

//   const GestionarCartaPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _GestionarCartaPageState createState() => _GestionarCartaPageState();
// }

// class _GestionarCartaPageState extends State<GestionarCartaPage> {
//   List<Map<String, dynamic>> productos = [];
//   String? selectedCategory;
//   String? selectedProduct;
//   List<Map<String, dynamic>> selectedProductsInCarta = [];
//   Color _colorFondo = Colors.black;
//   Color _colorTexto = Colors.orange;
//   File? _imagenFondo;

//   @override
//   void initState() {
//     super.initState();
//     _loadProductos();
//     _loadCarta();
//   }

//   Future<void> _loadProductos() async {
//     final cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (cartaSnapshot.exists) {
//       setState(() {
//         productos = List<Map<String, dynamic>>.from(cartaSnapshot['productos'] ?? []);
//       });
//     }
//   }

//   Future<void> _loadCarta() async {
//     final cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (cartaSnapshot.exists) {
//       setState(() {
//         selectedProductsInCarta = List<Map<String, dynamic>>.from(cartaSnapshot['carta'] ?? []);
//       });
//     }
//   }

//   Future<void> _saveCarta() async {
//     await FirebaseFirestore.instance.collection('cartasnegocio').doc(widget.negocioId).update({
//       'carta': selectedProductsInCarta,
//     });
//   }

//   Widget _buildMenuSection(String title, List<Map<String, dynamic>> items) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: _colorTexto,
//           ),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           decoration: BoxDecoration(
//             color: _colorFondo.withOpacity(0.8),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: items.map((item) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: _buildEditableMenuItem(item),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildEditableMenuItem(Map<String, dynamic> product) {
//   return Row(
//     children: [
//       Container(
//         width: 80,
//         height: 80,
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: NetworkImage(product['urlImagen'] ?? ''),
//             fit: BoxFit.cover,
//           ),
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       const SizedBox(width: 10),
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               product['nombre'] ?? 'Sin nombre',
//               style: TextStyle(fontSize: 18, color: _colorTexto),
//             ),
//             const SizedBox(height: 5),
//             Text(
//               'Precio: S/.${product['precio']?.toString() ?? '0'}',
//               style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//             ),
//             // Mostrar stock solo si es mayor a 0
//             if (product['stock'] != null && product['stock'] > 0)
//               Text(
//                 'Stock: ${product['stock']}',
//                 style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//               ),
//             // Mostrar el estado siempre
//             Text(
//               'Estado: ${product['estado'] ?? 'Sin estado'}',
//               style: TextStyle(fontSize: 16, color: _colorTexto.withOpacity(0.7)),
//             ),
//           ],
//         ),
//       ),
//       // Ícono de previsualización (ojo)
//       IconButton(
//         icon: const Icon(Icons.remove_red_eye, color: Colors.white),
//         onPressed: () {
//           _showProductPreviewDialog(product);
//         },
//       ),
//       // Ícono de quitar producto (X)
//       IconButton(
//         icon: const Icon(Icons.clear, color: Colors.red),
//         onPressed: () {
//           setState(() {
//             selectedProductsInCarta.remove(product);
//             _saveCarta(); // Actualizar Firebase después de quitar un producto de la carta
//           });
//         },
//       ),
//     ],
//   );
// }

// void _showProductPreviewDialog(Map<String, dynamic> product) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text(
//           product['nombre'] ?? 'Sin nombre',
//           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Mostrar imagen del producto con un tamaño específico y sin recorte
//               if (product['urlImagen'] != null)
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.8, // Un ancho proporcional a la pantalla
//                   height: 200, // Alto fijo para evitar errores de tamaño
//                   decoration: BoxDecoration(
//                     image: DecorationImage(
//                       image: NetworkImage(product['urlImagen']),
//                       fit: BoxFit.contain, // Ajustar la imagen para que se muestre completamente
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               const SizedBox(height: 10),
//               // Mostrar descripción del producto
//               if (product['descripcion'] != null)
//                 Text(
//                   product['descripcion'],
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               const SizedBox(height: 10),
//               // Mostrar precio
//               Text(
//                 'Precio: S/.${product['precio']?.toString() ?? '0'}',
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 5),
//               // Mostrar stock solo si es mayor a 0
//               if (product['stock'] != null && product['stock'] > 0)
//                 Text(
//                   'Stock: ${product['stock']}',
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               const SizedBox(height: 5),
//               // Mostrar estado del producto
//               Text(
//                 'Estado: ${product['estado'] ?? 'Sin estado'}',
//                 style: const TextStyle(fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Cerrar'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

//   void _editProduct(Map<String, dynamic> product) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         TextEditingController _nameController = TextEditingController(text: product['nombre']);
//         TextEditingController _priceController =
//             TextEditingController(text: product['precio']?.toString());
//         return AlertDialog(
//           title: const Text('Editar Producto'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(labelText: 'Nombre'),
//               ),
//               TextField(
//                 controller: _priceController,
//                 decoration: const InputDecoration(labelText: 'Precio'),
//                 keyboardType: TextInputType.number,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cancelar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Guardar'),
//               onPressed: () {
//                 setState(() {
//                   product['nombre'] = _nameController.text;
//                   product['precio'] = double.parse(_priceController.text);
//                 });
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _addProductToCarta(String? productName) {
//     final product = productos.firstWhere((element) => element['nombre'] == productName, orElse: () => {});
//     if (product.isNotEmpty) {
//       setState(() {
//         selectedProductsInCarta.add(product);
//         _saveCarta(); // Guardar la carta en Firebase cuando se agrega un producto
//       });
//     }
//   }

//   void _pickBackgroundImage() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null) {
//       setState(() {
//         _imagenFondo = File(result.files.single.path!);
//       });
//     }
//   }

//   void _pickColorFondo() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Selecciona un color de fondo'),
//           content: SingleChildScrollView(
//             child: BlockPicker(
//               pickerColor: _colorFondo,
//               onColorChanged: (color) {
//                 setState(() {
//                   _colorFondo = color;
//                 });
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cerrar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _pickColorTexto() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Selecciona un color de texto'),
//           content: SingleChildScrollView(
//             child: BlockPicker(
//               pickerColor: _colorTexto,
//               onColorChanged: (color) {
//                 setState(() {
//                   _colorTexto = color;
//                 });
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cerrar'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildCartaPreview() {
//     return Stack(
//       children: [
//         if (_imagenFondo != null)
//           Positioned.fill(
//             child: Image.file(
//               _imagenFondo!,
//               fit: BoxFit.cover,
//             ),
//           ),
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Previsualización de la Carta',
//                 style: TextStyle(fontSize: 24, color: Colors.orange),
//               ),
//               const SizedBox(height: 20),
//               if (selectedProductsInCarta.isNotEmpty)
//                 _buildMenuSection('Carta Actual', selectedProductsInCarta),
//               if (selectedProductsInCarta.isEmpty)
//                 const Center(
//                     child: Text('No hay productos añadidos a la carta',
//                         style: TextStyle(color: Colors.orange))),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestionar Carta'),
//         backgroundColor: Colors.green,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Agregar Productos a la Carta',
//               style: TextStyle(fontSize: 20, color: Colors.orange),
//             ),
//             DropdownButton<String>(
//               value: selectedProduct,
//               hint: const Text('Selecciona un producto', style: TextStyle(color: Colors.white)),
//               dropdownColor: Colors.black,
//               onChanged: (String? value) {
//                 setState(() {
//                   selectedProduct = value;
//                   _addProductToCarta(value);
//                 });
//               },
//               items: productos.map<DropdownMenuItem<String>>((product) {
//                 return DropdownMenuItem<String>(
//                   value: product['nombre'],
//                   child: Text(product['nombre'], style: const TextStyle(color: Colors.orange)),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickBackgroundImage,
//               child: const Text('Seleccionar Imagen de Fondo'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _pickColorFondo,
//               child: const Text('Seleccionar Color de Fondo'),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _pickColorTexto,
//               child: const Text('Seleccionar Color de Texto'),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Previsualización de la Carta',
//               style: TextStyle(fontSize: 20, color: Colors.orange),
//             ),
//             const SizedBox(height: 20),
//             _buildCartaPreview(),
//           ],
//         ),
//       ),
//     );
//   }
// }
