// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restmap/views/customer/detallepedido.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener esta importación

class CartaPage extends StatefulWidget {
  final String negocioId;
  final String userId;

  const CartaPage({super.key, required this.negocioId, required this.userId});

  @override
  _CartaPageState createState() => _CartaPageState();
}

class _CartaPageState extends State<CartaPage> {
  Map<String, int> selectedQuantities = {};
  Map<String, bool> showFullDescription = {};
  Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};
  double total = 0.0;
  int totalProducts = 0;

  @override
  void initState() {
    super.initState();
    _loadProductosAgrupados();
  }

  Future<void> _loadProductosAgrupados() async {
    final cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    if (cartaSnapshot.exists) {
      var cartaData = cartaSnapshot.data();
      if (cartaData != null) {
        var productos =
            List<Map<String, dynamic>>.from(cartaData['carta'] ?? []);
        var categorias =
            List<Map<String, dynamic>>.from(cartaData['categoriasprod'] ?? []);
        _agruparProductosPorCategoria(productos, categorias);
      }
    }
  }

  Future<void> _agruparProductosPorCategoria(
      List<Map<String, dynamic>> productos,
      List<Map<String, dynamic>> categorias) async {
    Map<String, String> categoriaIdToNombre = {};

    for (var cat in categorias) {
      categoriaIdToNombre[cat['id']] = cat['nombre'];
    }

    Map<String, List<Map<String, dynamic>>> agrupados = {};

    for (var producto in productos) {
      String categoriaId = producto['catprod'] ?? 'Sin Categoría';
      String categoriaNombre =
          categoriaIdToNombre[categoriaId] ?? 'Sin Categoría';

      if (!agrupados.containsKey(categoriaNombre)) {
        agrupados[categoriaNombre] = [];
      }
      agrupados[categoriaNombre]!.add(producto);
    }

    setState(() {
      productosPorCategoria = agrupados;
    });
  }

  Future<void> _iniciarRuta(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir la ruta en Google Maps';
    }
  }

  void _updateTotal() {
    total = 0.0;
    totalProducts = 0;
    selectedQuantities.forEach((key, value) {
      var producto = productosPorCategoria.values
          .expand((prod) => prod)
          .firstWhere((p) => p['codigo'] == key);
      total += (producto['precio'] * value);
      totalProducts += value;
    });
    setState(() {});
  }

  // void agregarProductoaCarrito() async {
  //   final carrito = selectedQuantities.entries.map((entry) {
  //     var producto = productosPorCategoria.values.expand((prod) => prod).firstWhere((p) => p['codigo'] == entry.key);
  //     return {
  //       'nombre': producto['nombre'],
  //       'cantidad': entry.value,
  //       'precio': producto['precio'],
  //     };
  //   }).toList();

  //   await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).update({
  //     'carrito': FieldValue.arrayUnion(carrito)
  //   });

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => DetallePedidoPage(
  //         negocioId: widget.negocioId,
  //         productosSeleccionados: carrito,
  //         total: total,
  //       ),
  //     ),
  //   );
  // }

//   void agregarProductoaCarrito() async {
//   final userDoc = FirebaseFirestore.instance.collection('usuarios').doc(widget.userId);

//   try {
//     final productosActualizados = <Map<String, dynamic>>[];

//     for (var entry in selectedQuantities.entries) {
//       // Buscar el producto en la carta local
//       var productoLocal = productosPorCategoria.values
//           .expand((prod) => prod)
//           .firstWhere((p) => p['codigo'] == entry.key);

//       // Obtener la carta del negocio desde Firestore
//       final cartaDoc = await FirebaseFirestore.instance
//           .collection('cartasnegocio')
//           .doc(widget.negocioId)
//           .get();

//       if (!cartaDoc.exists) {
//         throw Exception("No se encontró la carta del negocio.");
//       }

//       final cartaData = cartaDoc.data();
//       var productosFirestore = List<Map<String, dynamic>>.from(cartaData?['carta'] ?? []);
//       var productoFirestore = productosFirestore.firstWhere(
//         (p) => p['codigo'] == productoLocal['codigo'],
//         orElse: () => {},
//       );

//       if (productoFirestore.isEmpty) {
//         throw Exception("Producto no encontrado en Firestore.");
//       }

//       int stockDisponible = productoFirestore['stock'] ?? 0;
//       String estadoProducto = productoFirestore['estado'] ?? 'agotado';

//       // Obtener el carrito actual del usuario o inicializarlo vacío si no existe
//       final userSnapshot = await userDoc.get();
//       List<dynamic> carritoActual = userSnapshot.data()?['carrito']?.cast<Map<String, dynamic>>() ?? [];

//       // Validar stock infinito (estado "promocion" o "disponible" con stock 0)
//       if ((estadoProducto == "promocion" || estadoProducto == "disponible") && stockDisponible == 0) {
//         // Stock infinito: reemplazar directamente
//         productosActualizados.add({
//           'nombre': productoLocal['nombre'],
//           'cantidad': entry.value,
//           'precio': productoLocal['precio'],
//           'codigo': productoLocal['codigo'],
//         });
//         continue;
//       }

//       // Calcular stock restante para productos con stock limitado
//       int cantidadEnCarrito = carritoActual
//           .where((item) => item['codigo'] == entry.key)
//           .fold(0, (int sum, item) => sum + ((item['cantidad'] ?? 0) as int));

//       int stockRestante = stockDisponible - cantidadEnCarrito;

//       if (stockRestante <= 0) {
//         // Mostrar mensaje de stock insuficiente
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text("Stock insuficiente"),
//             content: Text("Lo sentimos, este producto ya no tiene stock disponible."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   Navigator.pop(context); // Regresa a la carta del negocio
//                 },
//                 child: Text("Aceptar"),
//               ),
//             ],
//           ),
//         );
//         return;
//       }

//       // Reemplazar la cantidad con el valor ajustado al stock disponible
//       int cantidadFinal = entry.value > stockRestante ? stockRestante : entry.value;

//       productosActualizados.add({
//         'nombre': productoLocal['nombre'],
//         'cantidad': cantidadFinal,
//         'precio': productoLocal['precio'],
//         'codigo': productoLocal['codigo'],
//       });
//     }

//     // Actualizar el carrito en Firestore
//     await userDoc.update({
//       'carrito': productosActualizados,
//       'negocioId': widget.negocioId,
//     });

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DetallePedidoPage(
//           negocioId: widget.negocioId,
//           productosSeleccionados: productosActualizados,
//           total: total,
//         ),
//       ),
//     );
//   } catch (e) {
//     print("Error al agregar productos al carrito: $e");
//   }
// }

  void agregarProductoaCarrito() async {
    final userDoc =
        FirebaseFirestore.instance.collection('usuarios').doc(widget.userId);

    try {
      final List<Map<String, dynamic>> carritoActual = [];

      // Obtener el carrito actual del usuario o inicializarlo vacío
      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        carritoActual.addAll(List<Map<String, dynamic>>.from(
            userSnapshot.data()?['carrito'] ?? []));
      }

      for (var entry in selectedQuantities.entries) {
        // Buscar el producto en la carta local
        var productoLocal = productosPorCategoria.values
            .expand((prod) => prod)
            .firstWhere((p) => p['codigo'] == entry.key);

        // Verificar si el producto ya está en el carrito
        bool productoExiste = false;
        for (var productoCarrito in carritoActual) {
          if (productoCarrito['codigo'] == entry.key) {
            // Reemplazar la cantidad con la nueva cantidad
            productoCarrito['cantidad'] = entry.value;
            productoExiste = true;
            break;
          }
        }

        // Si no existe en el carrito, agregarlo como nuevo
        if (!productoExiste) {
          carritoActual.add({
            'nombre': productoLocal['nombre'],
            'cantidad': entry.value,
            'precio': productoLocal['precio'],
            'codigo': productoLocal['codigo'],
          });
        }
      }

      // Actualizar el carrito en Firestore
      await userDoc.update({
        'carrito': carritoActual,
        'negocioId': widget.negocioId,
      });

      // Navegar al detalle del pedido con el carrito actualizado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallePedidoPage(
            negocioId: widget.negocioId,
            productosSeleccionados: carritoActual,
            total: carritoActual.fold(
              0.0,
              (sum, item) => sum + (item['cantidad'] * item['precio']),
            ),
          ),
        ),
      );
    } catch (e) {
      //print("Error al agregar productos al carrito: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carta del Negocio'),
      ),
      body: Stack(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('negocios')
                .doc(widget.negocioId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: Image.asset('assets/loadingbeli.gif',
                        width: 100, height: 100));
              }

              var negocio = snapshot.data!.data() as Map<String, dynamic>;
              var ubicacion = negocio['ubicacion']
                  as GeoPoint?; // Asegúrate de que los datos de ubicación estén en Firestore

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    productosPorCategoria.isNotEmpty &&
                            productosPorCategoria.entries.first.value.isNotEmpty
                        ? Image.network(
                            productosPorCategoria.entries.first.value[0]
                                ['urlImagen'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover)
                        : const SizedBox(
                            height: 200, child: Icon(Icons.store, size: 100)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          negocio['logo'] != null
                              ? Image.network(negocio['logo'],
                                  width: 50, height: 50)
                              : const Icon(Icons.store, size: 50),
                          const SizedBox(width: 10),
                          Text(
                            negocio['nombre'],
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Dirección: ${negocio['direccion']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (ubicacion != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _iniciarRuta(
                              ubicacion.latitude, ubicacion.longitude),
                          icon: const Icon(Icons.directions),
                          label: const Text('Iniciar Ruta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade500,
                          ),
                        ),
                      ),
                    const Divider(),
                    productosPorCategoria.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                productosPorCategoria.entries.map((entry) {
                              String categoria = entry.key;
                              List<Map<String, dynamic>> productos =
                                  entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      categoria,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: productos.length,
                                    itemBuilder: (context, index) {
                                      var producto = productos[index];
                                      String codigoProducto =
                                          producto['codigo'];
                                      bool mostrarDescripcionCompleta =
                                          showFullDescription[codigoProducto] ??
                                              false;

                                      int stock = producto['stock'];
                                      String estado = producto['estado'];
                                      int selectedQuantity = selectedQuantities[
                                              producto['codigo']] ??
                                          0;

                                      bool isAvailable =
                                          estado == 'disponible' ||
                                              estado == 'promocion';
                                      bool isStockLimited = stock > 0;
                                      bool canAddMore = isStockLimited
                                          ? selectedQuantity < stock
                                          : true;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: ListTile(
                                          leading: producto['urlImagen'] != null
                                              ? Image.network(
                                                  producto['urlImagen'],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover)
                                              : const Icon(Icons.fastfood,
                                                  size: 50),
                                          title: Text(producto['nombre']),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto['descripcion'],
                                                maxLines:
                                                    mostrarDescripcionCompleta
                                                        ? null
                                                        : 2,
                                                overflow:
                                                    mostrarDescripcionCompleta
                                                        ? TextOverflow.visible
                                                        : TextOverflow.ellipsis,
                                                textAlign: TextAlign.justify,
                                              ),
                                              if (producto['descripcion']
                                                      .length >
                                                  50)
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      showFullDescription[
                                                              codigoProducto] =
                                                          !mostrarDescripcionCompleta;
                                                    });
                                                  },
                                                  child: Text(
                                                    mostrarDescripcionCompleta
                                                        ? 'Leer menos'
                                                        : 'Leer más',
                                                    style: const TextStyle(
                                                        color: Colors.blue),
                                                  ),
                                                ),
                                              Text('S/${producto['precio']}'),
                                              if (isStockLimited)
                                                Text('Stock: $stock',
                                                    style: const TextStyle(
                                                        color: Colors.green)),
                                              if (estado == 'agotado')
                                                const Text('Agotado',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                            ],
                                          ),
                                          trailing: isAvailable
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (selectedQuantity > 0)
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.remove),
                                                        onPressed: () {
                                                          setState(() {
                                                            selectedQuantities[
                                                                    producto[
                                                                        'codigo']] =
                                                                selectedQuantity -
                                                                    1;
                                                            _updateTotal();
                                                          });
                                                        },
                                                      ),
                                                    Text('$selectedQuantity'),
                                                    IconButton(
                                                      icon:
                                                          const Icon(Icons.add),
                                                      onPressed: canAddMore
                                                          ? () {
                                                              setState(() {
                                                                selectedQuantities[
                                                                        producto[
                                                                            'codigo']] =
                                                                    selectedQuantity +
                                                                        1;
                                                                _updateTotal();
                                                              });
                                                            }
                                                          : null,
                                                    ),
                                                  ],
                                                )
                                              : const ElevatedButton(
                                                  onPressed: null,
                                                  child: Text(
                                                    'Agotado',
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }).toList(),
                          )
                        : const Center(
                            child: Text('No hay productos disponibles'),
                          ),
                  ],
                ),
              );
            },
          ),
          if (total > 0)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalProducts producto(s)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'S/${total.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onPressed: agregarProductoaCarrito,
                      child: const Text(
                        'Ordenar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:restmap/views/customer/detallepedido.dart';

// class CartaPage extends StatefulWidget {
//   final String negocioId;
//   final String userId;

//   CartaPage({required this.negocioId, required this.userId});

//   @override
//   _CartaPageState createState() => _CartaPageState();
// }

// class _CartaPageState extends State<CartaPage> {
//   Map<String, int> selectedQuantities = {};
//   Map<String, bool> showFullDescription = {};
//   Map<String, List<Map<String, dynamic>>> productosPorCategoria = {};
//   double total = 0.0;
//   int totalProducts = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadProductosAgrupados();
//   }

//   Future<void> _loadProductosAgrupados() async {
//     final cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (cartaSnapshot.exists) {
//       var cartaData = cartaSnapshot.data();
//       if (cartaData != null) {
//         var productos = List<Map<String, dynamic>>.from(cartaData['carta'] ?? []);
//         var categorias = List<Map<String, dynamic>>.from(cartaData['categoriasprod'] ?? []);
//         _agruparProductosPorCategoria(productos, categorias);
//       }
//     }
//   }

//   Future<void> _agruparProductosPorCategoria(
//       List<Map<String, dynamic>> productos, List<Map<String, dynamic>> categorias) async {
//     Map<String, String> categoriaIdToNombre = {};

//     for (var cat in categorias) {
//       categoriaIdToNombre[cat['id']] = cat['nombre'];
//     }

//     Map<String, List<Map<String, dynamic>>> agrupados = {};

//     for (var producto in productos) {
//       String categoriaId = producto['catprod'] ?? 'Sin Categoría';
//       String categoriaNombre = categoriaIdToNombre[categoriaId] ?? 'Sin Categoría';

//       if (!agrupados.containsKey(categoriaNombre)) {
//         agrupados[categoriaNombre] = [];
//       }
//       agrupados[categoriaNombre]!.add(producto);
//     }

//     setState(() {
//       productosPorCategoria = agrupados;
//     });
//   }

//   void _updateTotal() {
//     total = 0.0;
//     totalProducts = 0;
//     selectedQuantities.forEach((key, value) {
//       var producto = productosPorCategoria.values.expand((prod) => prod).firstWhere((p) => p['codigo'] == key);
//       total += (producto['precio'] * value);
//       totalProducts += value;
//     });
//     setState(() {});
//   }

//   void agregarProductoaCarrito() async {
//     final carrito = selectedQuantities.entries.map((entry) {
//       var producto = productosPorCategoria.values.expand((prod) => prod).firstWhere((p) => p['codigo'] == entry.key);
//       return {
//         'nombre': producto['nombre'],
//         'cantidad': entry.value,
//         'precio': producto['precio'],
//       };
//     }).toList();

//     await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).update({
//       'carrito': FieldValue.arrayUnion(carrito)
//     });

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => DetallePedidoPage(
//           negocioId: widget.negocioId,
//           productosSeleccionados: carrito,
//           total: total,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Carta del Negocio'),
//       ),
//       body: Stack(
//         children: [
//           FutureBuilder<DocumentSnapshot>(
//             future: FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId).get(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return Center(child: Image.asset('assets/loadingbeli.gif', width: 100, height: 100));
//               }

//               var negocio = snapshot.data!.data() as Map<String, dynamic>;

//               return SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     productosPorCategoria.isNotEmpty && productosPorCategoria.entries.first.value.isNotEmpty
//                         ? Image.network(productosPorCategoria.entries.first.value[0]['urlImagen'],
//                             width: double.infinity, height: 200, fit: BoxFit.cover)
//                         : SizedBox(height: 200, child: Icon(Icons.store, size: 100)),

//                     Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Row(
//                         children: [
//                           negocio['logo'] != null
//                               ? Image.network(negocio['logo'], width: 50, height: 50)
//                               : Icon(Icons.store, size: 50),
//                           SizedBox(width: 10),
//                           Text(
//                             negocio['nombre'],
//                             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Text(
//                         'Dirección: ${negocio['direccion']}',
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     ),
//                     Divider(),

//                     productosPorCategoria.isNotEmpty
//                         ? Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: productosPorCategoria.entries.map((entry) {
//                               String categoria = entry.key;
//                               List<Map<String, dynamic>> productos = entry.value;

//                               return Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Text(
//                                       categoria,
//                                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                                     ),
//                                   ),
//                                   ListView.builder(
//                                     shrinkWrap: true,
//                                     physics: NeverScrollableScrollPhysics(),
//                                     itemCount: productos.length,
//                                     itemBuilder: (context, index) {
//                                       var producto = productos[index];
//                                       String codigoProducto = producto['codigo'];
//                                       bool mostrarDescripcionCompleta = showFullDescription[codigoProducto] ?? false;

//                                       int stock = producto['stock'];
//                                       String estado = producto['estado'];
//                                       int selectedQuantity = selectedQuantities[producto['codigo']] ?? 0;

//                                       bool isAvailable = estado == 'disponible' || estado == 'promocion';
//                                       bool isStockLimited = stock > 0;
//                                       bool canAddMore = isStockLimited ? selectedQuantity < stock : true;

//                                       return Card(
//                                         margin: EdgeInsets.symmetric(vertical: 8),
//                                         child: ListTile(
//                                           leading: producto['urlImagen'] != null
//                                               ? Image.network(producto['urlImagen'], width: 80, height: 80, fit: BoxFit.cover)
//                                               : Icon(Icons.fastfood, size: 50),
//                                           title: Text(producto['nombre']),
//                                           subtitle: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 producto['descripcion'],
//                                                 maxLines: mostrarDescripcionCompleta ? null : 2,
//                                                 overflow: mostrarDescripcionCompleta ? TextOverflow.visible : TextOverflow.ellipsis,
//                                                 textAlign: TextAlign.justify,
//                                               ),
//                                               if (producto['descripcion'].length > 50)
//                                                 GestureDetector(
//                                                   onTap: () {
//                                                     setState(() {
//                                                       showFullDescription[codigoProducto] = !mostrarDescripcionCompleta;
//                                                     });
//                                                   },
//                                                   child: Text(
//                                                     mostrarDescripcionCompleta ? 'Leer menos' : 'Leer más',
//                                                     style: TextStyle(color: Colors.blue),
//                                                   ),
//                                                 ),
//                                               Text('S/${producto['precio']}'),
//                                               if (isStockLimited)
//                                                 Text('Stock: $stock', style: TextStyle(color: Colors.green)),
//                                               if (estado == 'agotado')
//                                                 Text('Agotado', style: TextStyle(color: Colors.red)),
//                                             ],
//                                           ),
//                                           trailing: isAvailable
//                                               ? Row(
//                                                   mainAxisSize: MainAxisSize.min,
//                                                   children: [
//                                                     if (selectedQuantity > 0)
//                                                       IconButton(
//                                                         icon: Icon(Icons.remove),
//                                                         onPressed: () {
//                                                           setState(() {
//                                                             selectedQuantities[producto['codigo']] =
//                                                                 selectedQuantity - 1;
//                                                             _updateTotal();
//                                                           });
//                                                         },
//                                                       ),
//                                                     Text('$selectedQuantity'),
//                                                     IconButton(
//                                                       icon: Icon(Icons.add),
//                                                       onPressed: canAddMore
//                                                           ? () {
//                                                               setState(() {
//                                                                 selectedQuantities[producto['codigo']] =
//                                                                     selectedQuantity + 1;
//                                                                 _updateTotal();
//                                                               });
//                                                             }
//                                                           : null,
//                                                     ),
//                                                   ],
//                                                 )
//                                               : ElevatedButton(
//                                                   onPressed: null,
//                                                   child: Text(
//                                                     'Agotado',
//                                                     style: TextStyle(fontSize: 12),
//                                                   ),
//                                                 ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ],
//                               );
//                             }).toList(),
//                           )
//                         : Center(
//                             child: Text('No hay productos disponibles'),
//                           ),
//                   ],
//                 ),
//               );
//             },
//           ),

//           if (total > 0)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 color: Colors.white,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       '$totalProducts producto(s)',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'S/${total.toStringAsFixed(1)}',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                       ),
//                       onPressed: agregarProductoaCarrito,
//                       child: Text(
//                         'Ordenar',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
