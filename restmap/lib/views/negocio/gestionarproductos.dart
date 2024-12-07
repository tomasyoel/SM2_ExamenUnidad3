import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class ProductManagementPage extends StatefulWidget {
  final String negocioId;

  const ProductManagementPage({super.key, required this.negocioId});

  @override
  _ProductManagementPageState createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  Future<List<Map<String, dynamic>>> _getProductos() async {
    final negocioCarta = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();
    return List<Map<String, dynamic>>.from(negocioCarta['productos'] ?? []);
  }


  Future<List<Map<String, dynamic>>> _getCategorias() async {
    final categoriasDoc = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();
    return List<Map<String, dynamic>>.from(categoriasDoc['categoriasprod'] ?? []);
  }


  Future<void> _deleteProducto(Map<String, dynamic> producto) async {
    if (producto['urlImagen'] != null && producto['urlImagen'].isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(producto['urlImagen']);
        await ref.delete();
        print('Imagen eliminada exitosamente del Storage.');
      } catch (e) {
        print('Error al eliminar la imagen del Storage: $e');
      }
    }

    await FirebaseFirestore.instance.collection('cartasnegocio').doc(widget.negocioId).update({
      'productos': FieldValue.arrayRemove([producto])
    });
    print('Producto eliminado exitosamente de Firestore.');
  }

  Future<void> _editarProducto(Map<String, dynamic> producto) async {
    final TextEditingController nombreController =
        TextEditingController(text: producto['nombre']);
    final TextEditingController descripcionController =
        TextEditingController(text: producto['descripcion']);
    final TextEditingController precioController =
        TextEditingController(text: producto['precio'].toString());
    final TextEditingController stockController =
        TextEditingController(text: producto['stock']?.toString() ?? '0');
    String estadoSeleccionado = producto['estado'] ?? 'disponible';
    String? categoriaSeleccionada = producto['catprod'];


    List<Map<String, dynamic>> categorias = await _getCategorias();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Producto: ${producto['nombre']}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock (0 - 1000)'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  items: categorias.map((categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria['id'],
                      child: Text(categoria['nombre']),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      categoriaSeleccionada = newValue;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: estadoSeleccionado,
                  items: ['disponible', 'agotado', 'promocion'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      estadoSeleccionado = newValue!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Estado'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
            
                int stock = int.tryParse(stockController.text) ?? 0;
                if (stock < 0) {
                  stock = 0;
                } else if (stock > 1000) {
                  stock = 1000; 
                }

                if (categoriaSeleccionada == null || categoriaSeleccionada!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor selecciona una categoría.')),
                  );
                  return;
                }

                final nuevoProducto = {
                  'codigo': producto['codigo'],
                  'nombre': nombreController.text,
                  'descripcion': descripcionController.text,
                  'precio': double.parse(precioController.text),
                  'stock': stock, 
                  'estado': estadoSeleccionado,
                  'urlImagen': producto['urlImagen'],
                  'catprod': categoriaSeleccionada,
                };

               
                await FirebaseFirestore.instance
                    .collection('cartasnegocio')
                    .doc(widget.negocioId)
                    .update({
                  'productos': FieldValue.arrayRemove([producto]),
                  'carta': FieldValue.arrayRemove([producto])
                });

             
                await FirebaseFirestore.instance
                    .collection('cartasnegocio')
                    .doc(widget.negocioId)
                    .update({
                  'productos': FieldValue.arrayUnion([nuevoProducto]),
                });

                if (nuevoProducto['stock'] != 0) {
                  await FirebaseFirestore.instance
                      .collection('cartasnegocio')
                      .doc(widget.negocioId)
                      .update({
                    'carta': FieldValue.arrayUnion([nuevoProducto]),
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Producto actualizado exitosamente')),
                );

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogProducto(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(producto['nombre']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(producto['urlImagen'], height: 150, width: 150),
              Text("Descripción: ${producto['descripcion']}"),
              Text("Precio: S/.${producto['precio']}"),
              Text("Stock: ${producto['stock']}"),
              Text("Estado: ${producto['estado']}"),
            ],
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

  Future<void> _confirmarEliminar(Map<String, dynamic> producto) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sí'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteProducto(producto);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado exitosamente.')));

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Productos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getProductos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar productos'));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            var productos = snapshot.data!;
            return ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                var producto = productos[index];
                return ListTile(
                  leading: producto['urlImagen'] != null
                      ? Image.network(producto['urlImagen'], width: 50, height: 50)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(producto['nombre']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio: S/.${producto['precio']}'),
                      if (producto['stock'] != 0)
                        Text('Stock: ${producto['stock']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _mostrarDialogProducto(producto),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editarProducto(producto),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmarEliminar(producto),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No hay productos disponibles'));
          }
        },
      ),
    );
  }
}






// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/services.dart';


// class ProductManagementPage extends StatefulWidget {
//   final String negocioId; // Recibe el ID del negocio

//   const ProductManagementPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _ProductManagementPageState createState() => _ProductManagementPageState();
// }

// class _ProductManagementPageState extends State<ProductManagementPage> {
//   Future<List<Map<String, dynamic>>> _getProductos() async {
//     final negocioCarta = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();
//     return List<Map<String, dynamic>>.from(negocioCarta['productos'] ?? []);
//   }

//   // Eliminar producto y su imagen del Storage
//   Future<void> _deleteProducto(Map<String, dynamic> producto) async {
//     if (producto['urlImagen'] != null && producto['urlImagen'].isNotEmpty) {
//       try {
//         final ref = FirebaseStorage.instance.refFromURL(producto['urlImagen']);
//         await ref.delete();  // Eliminar imagen del Storage
//         print('Imagen eliminada exitosamente del Storage.');
//       } catch (e) {
//         print('Error al eliminar la imagen del Storage: $e');
//       }
//     }

//     await FirebaseFirestore.instance.collection('cartasnegocio').doc(widget.negocioId).update({
//       'productos': FieldValue.arrayRemove([producto])
//     });
//     print('Producto eliminado exitosamente de Firestore.');
//   }

//   Future<void> _editarProducto(Map<String, dynamic> producto) async {
//   final TextEditingController _nombreController =
//       TextEditingController(text: producto['nombre']);
//   final TextEditingController _descripcionController =
//       TextEditingController(text: producto['descripcion']);
//   final TextEditingController _precioController =
//       TextEditingController(text: producto['precio'].toString());
//   final TextEditingController _stockController =
//       TextEditingController(text: producto['stock']?.toString() ?? '0');
//   String _estadoSeleccionado = producto['estado'] ?? 'disponible';

//   await showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text('Editar Producto: ${producto['nombre']}'),
//         content: SingleChildScrollView(
//           child: Column(
//             children: [
//               TextField(
//                 controller: _nombreController,
//                 decoration: const InputDecoration(labelText: 'Nombre del Producto'),
//               ),
//               TextField(
//                 controller: _descripcionController,
//                 decoration: const InputDecoration(labelText: 'Descripción'),
//               ),
//               TextField(
//                 controller: _precioController,
//                 decoration: const InputDecoration(labelText: 'Precio'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: _stockController,
//                 decoration: const InputDecoration(labelText: 'Stock (0 - 1000)'),
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly // Acepta solo números enteros
//                 ],
//               ),
//               DropdownButtonFormField<String>(
//                 value: _estadoSeleccionado,
//                 items: ['disponible', 'agotado', 'oferta'].map((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//                 onChanged: (newValue) {
//                   setState(() {
//                     _estadoSeleccionado = newValue!;
//                   });
//                 },
//                 decoration: const InputDecoration(labelText: 'Estado'),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             child: const Text('Cancelar'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: const Text('Guardar'),
//             onPressed: () async {
//               // Validación del stock
//               int stock = int.tryParse(_stockController.text) ?? 0;
//               if (stock < 0) {
//                 stock = 0;  // No permitir números negativos
//               } else if (stock > 1000) {
//                 stock = 1000;  // Limitar el stock máximo a 1000
//               }

//               final nuevoProducto = {
//                 'codigo': producto['codigo'],
//                 'nombre': _nombreController.text,
//                 'descripcion': _descripcionController.text,
//                 'precio': double.parse(_precioController.text),
//                 'stock': stock,  // Guardar el stock con los límites aplicados
//                 'estado': _estadoSeleccionado,
//                 'urlImagen': producto['urlImagen'],
//               };

//               // Remover el producto original de productos y carta
//               await FirebaseFirestore.instance
//                   .collection('cartasnegocio')
//                   .doc(widget.negocioId)
//                   .update({
//                 'productos': FieldValue.arrayRemove([producto]),
//                 'carta': FieldValue.arrayRemove([producto])
//               });

//               // Agregar el producto actualizado a productos y carta (si el stock no es 0)
//               await FirebaseFirestore.instance
//                   .collection('cartasnegocio')
//                   .doc(widget.negocioId)
//                   .update({
//                 'productos': FieldValue.arrayUnion([nuevoProducto]),
//               });

//               if (nuevoProducto['stock'] != 0) {
//                 await FirebaseFirestore.instance
//                     .collection('cartasnegocio')
//                     .doc(widget.negocioId)
//                     .update({
//                   'carta': FieldValue.arrayUnion([nuevoProducto]),
//                 });
//               }

//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Producto actualizado exitosamente')),
//               );

//               Navigator.of(context).pop();
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

//   void _mostrarDialogProducto(Map<String, dynamic> producto) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(producto['nombre']),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.network(producto['urlImagen'], height: 150, width: 150),
//               Text("Descripción: ${producto['descripcion']}"),
//               Text("Precio: S/.${producto['precio']}"),
//               Text("Stock: ${producto['stock']}"),
//               Text("Estado: ${producto['estado']}"),
//             ],
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

//   Future<void> _confirmarEliminar(Map<String, dynamic> producto) async {
//     bool? confirmed = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Confirmar Eliminación'),
//           content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
//           actions: [
//             TextButton(
//               child: const Text('No'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: const Text('Sí'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed == true) {
//       await _deleteProducto(producto);
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Producto eliminado exitosamente.')));

//       // Actualizar la lista de productos después de eliminar
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gestionar Productos'),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _getProductos(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error al cargar productos'));
//           }
//           if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//             var productos = snapshot.data!;
//             return ListView.builder(
//               itemCount: productos.length,
//               itemBuilder: (context, index) {
//                 var producto = productos[index];
//                 return ListTile(
//                   leading: producto['urlImagen'] != null
//                       ? Image.network(producto['urlImagen'], width: 50, height: 50)
//                       : const Icon(Icons.image_not_supported, size: 50),
//                   title: Text(producto['nombre']),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Precio: S/.${producto['precio']}'),
//                       if (producto['stock'] != 0)
//                         Text('Stock: ${producto['stock']}'), // Mostrar stock solo si no es 0
//                     ],
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.visibility),
//                         onPressed: () => _mostrarDialogProducto(producto),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.edit),
//                         onPressed: () => _editarProducto(producto),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.delete),
//                         onPressed: () => _confirmarEliminar(producto),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           } else {
//             return const Center(child: Text('No hay productos disponibles'));
//           }
//         },
//       ),
//     );
//   }
// }