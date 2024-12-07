import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:restmap/views/customer/map_page.dart';
import 'package:restmap/views/customer/user_location_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class DetallePedidoPage extends StatefulWidget {
  final String negocioId;
  final List<Map<String, dynamic>> productosSeleccionados;
  final double total;

  DetallePedidoPage({
    required this.negocioId,
    required this.productosSeleccionados,
    required this.total,
  });

  @override
  _DetallePedidoPageState createState() => _DetallePedidoPageState();
}

class _DetallePedidoPageState extends State<DetallePedidoPage> {
  String? _modalidadSeleccionada = 'delivery';
  String _nroCelular = '';
  String _direccion = '---------'; // Dirección predeterminada
  String _notas = '';
  LatLng? _ubicacion;
  String? _metodoPagoSeleccionado = 'yape_plin';
  GoogleMapController? _mapController;
  double? _costoDelivery;
  String? _mensajeDelivery;

  bool _isSubmitting = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _escucharCambiosEnStock();
    _calcularCostoDelivery(); // Calcular el costo al iniciar
  }

  Future<void> _loadDefaultAddress() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('direcciones')) {
        var direcciones = userData['direcciones'] as List<dynamic>;
        var direccionPredeterminada = direcciones.firstWhere(
          (direccion) => direccion['predeterminada'] == true,
          orElse: () => null,
        );

        if (direccionPredeterminada != null) {
          setState(() {
            _direccion = direccionPredeterminada['direccion'] ?? 'Sin dirección';
            _ubicacion = LatLng(
              direccionPredeterminada['latitud'] ?? 0.0,
              direccionPredeterminada['longitud'] ?? 0.0,
              
            );
          }); _moveToLocation();
           _calcularCostoDelivery(); // Recalcular costo al cargar la dirección
          print('Ubicación cargada: $_ubicacion');
        } else {
          print('No se encontró una dirección predeterminada.');
        }
      } else {
        print('No hay direcciones asociadas al usuario.');
      }
    } catch (e) {
      print('Error al cargar la dirección: $e');
    }
  }
}

Future<void> _calcularCostoDelivery() async {
    if (_modalidadSeleccionada != 'delivery' || _ubicacion == null) return;

    // Obtener ubicación del negocio
    DocumentSnapshot negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .get();
    var negocioData = negocioDoc.data() as Map<String, dynamic>?;
    if (negocioData == null || negocioData['ubicacion'] == null) {
      setState(() {
        _mensajeDelivery = "No se pudo obtener la ubicación del negocio.";
      });
      return;
    }

    GeoPoint ubicacionNegocio = negocioData['ubicacion'];
    
    // Cálculo de distancia usando fórmula de Haversine
    double distancia = _calcularDistanciaHaversine(
      ubicacionNegocio.latitude,
      ubicacionNegocio.longitude,
      _ubicacion!.latitude,
      _ubicacion!.longitude,
    );

    // Aplicar factor de ajuste para aproximar distancia real por carretera
    distancia = distancia * 1.3; // Factor de ajuste del 30%

    double? costo;
    if (distancia <= 2.5) {
      costo = 5;
    } else if (distancia <= 3.5) {
      costo = 6;
    } else if (distancia <= 4.5) {
      costo = 7;
    } else if (distancia <= 5.5) {
      costo = 8;
    } else if (distancia <= 6.5) {
      costo = 9;
    } else if (distancia <= 7.5) {
      costo = 11;
    } else if (distancia <= 8.5) {
      costo = 12;
    } else if (distancia <= 9.5) {
      costo = 13;
    } else if (distancia <= 10.5) {
      costo = 14;
    } else if (distancia <= 12.5) {
      costo = 16;
    } else {
      setState(() {
        _mensajeDelivery = "Consultar con el negocio.";
        _costoDelivery = null;
      });
      return;
    }

    setState(() {
      _costoDelivery = costo;
      
      // _mensajeDelivery = "Distancia: ${distancia.toStringAsFixed(1)} km";
    });
}

// Función para calcular distancia usando fórmula de Haversine
double _calcularDistanciaHaversine(
    double lat1, double lon1, double lat2, double lon2) {
  const double radioTierra = 6371; // Radio de la Tierra en kilómetros
  
  // Convertir grados a radianes
  var dLat = _toRadianes(lat2 - lat1);
  var dLon = _toRadianes(lon2 - lon1);
  
  // Fórmula de Haversine
  var a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_toRadianes(lat1)) * cos(_toRadianes(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
          
  var c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return radioTierra * c; // Distancia en kilómetros
}

// Función auxiliar para convertir grados a radianes
double _toRadianes(double grados) {
  return grados * pi / 180;
}


  void _confirmarEliminarProducto(Map<String, dynamic> producto) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('¿Quitar producto?'),
      content: Text('¿Estás seguro(a) de que deseas quitar "${producto['nombre']}" del carrito?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cerrar sin acción
          child: Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Cerrar el diálogo
            _eliminarProductoDelCarrito(producto);
          },
          child: Text('Sí'),
        ),
      ],
    ),
  );
}



void _eliminarProductoDelCarrito(Map<String, dynamic> producto) async {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Remover el producto del carrito en Firestore
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
      'carrito': FieldValue.arrayRemove([producto]),
    });

    // Obtener el carrito actualizado desde Firestore
    final carritoSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final carritoActualizado =
        List<Map<String, dynamic>>.from(carritoSnapshot.data()?['carrito'] ?? []);

    // Si el carrito está vacío, mostrar mensaje y regresar a la carta del negocio
    if (carritoActualizado.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Carrito vacío 🛒"),
          content: Text("Ups, tu carrito está vacío. ¡Agrega productos para continuar! 😊"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el mensaje
                Navigator.pop(context); // Regresar a la carta del negocio
              },
              child: Text("Aceptar"),
            ),
          ],
        ),
      );
      return; // Detener ejecución para no recargar la página
    }

    // Recalcular el total basado en el carrito actualizado
    double nuevoTotal = 0.0;
    for (var item in carritoActualizado) {
      nuevoTotal += (item['cantidad'] ?? 0) * (item['precio'] ?? 0.0);
    }

    // Recargar la página de detalle del pedido con el total y carrito actualizados
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePedidoPage(
          negocioId: widget.negocioId,
          productosSeleccionados: carritoActualizado,
          total: nuevoTotal,
        ),
      ),
    );
  }
}

void _moveToLocation() {
  if (_mapController != null && _ubicacion != null) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
          zoom: 15,
        ),
      ),
    );
  }
}

  void _escucharCambiosEnStock() {
  FirebaseFirestore.instance
      .collection('cartasnegocio')
      .doc(widget.negocioId)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      final cartaData = snapshot.data();
      var productosFirestore = List<Map<String, dynamic>>.from(cartaData?['carta'] ?? []);

      bool stockInsuficiente = false;

      for (var productoCarrito in widget.productosSeleccionados) {
        var productoFirestore = productosFirestore.firstWhere(
          (p) => p['codigo'] == productoCarrito['codigo'],
          orElse: () => {},
        );

        if (productoFirestore.isEmpty) continue;

        int stockDisponible = productoFirestore['stock'] ?? 0;
        String estadoProducto = productoFirestore['estado'] ?? 'agotado';

        // Validar stock infinito (estado "promocion" o "disponible" con stock 0)
        if ((estadoProducto == "promocion" || estadoProducto == "disponible") && stockDisponible == 0) {
          // Producto con stock infinito, no considerar como insuficiente
          continue;
        }

        // Validar si la cantidad en el carrito supera el stock disponible
        if (productoCarrito['cantidad'] > stockDisponible) {
          stockInsuficiente = true;
          break;
        }
      }

      if (stockInsuficiente) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Stock insuficiente"),
            content: Text(
                "Lo sentimos, uno o más productos en tu carrito ya no están disponibles o su stock ha cambiado. Por favor, vuelve a seleccionar."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Regresa a la carta del negocio
                },
                child: Text("Aceptar"),
              ),
            ],
          ),
        );

        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          'carrito': [],
          'negocioId': FieldValue.delete(),
        });
      }
    }
  });
}



String _generarCodigoPedido() {
  final random = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  return random.toString().padLeft(5, '0'); // Asegura que sea de 5 dígitos
}




  void _guardarPedido() async {

  setState(() {
    _isSubmitting = false; // Necesitarás agregar este estado
  });

  // Mostrar snackbar de procesando
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Procesando Pedido...'),
      duration: Duration(minutes: 1), // Duración larga para evitar que se cierre rápido
    ),
  );

  try {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    // Verificar stock antes de proceder
    final cartaDoc = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .get();

    if (!cartaDoc.exists) {
      throw Exception("Carta del negocio no encontrada.");
    }

    final cartaData = cartaDoc.data();
    List<dynamic> cartaProductos = cartaData?['carta'] ?? [];
    List<dynamic> productosFirestore = cartaData?['productos'] ?? []; // Array productos

    bool stockInsuficiente = false;

    for (var productoSeleccionado in widget.productosSeleccionados) {
      var productoFirestore = cartaProductos.firstWhere(
        (p) => p['codigo'] == productoSeleccionado['codigo'],
        orElse: () => null,
      );

      if (productoFirestore != null) {
        int stockDisponible = productoFirestore['stock'] ?? 0;
        String estadoProducto = productoFirestore['estado'] ?? 'agotado';

        // Verificar stock infinito
        if ((estadoProducto == "promocion" || estadoProducto == "disponible") && stockDisponible == 0) {
          continue; // Producto con stock infinito, no hay problema
        }

        // Si la cantidad en el carrito excede el stock disponible, marcar como insuficiente
        if (productoSeleccionado['cantidad'] > stockDisponible) {
          stockInsuficiente = true;
          break;
        }
      }
    }

    // Si hay stock insuficiente, detener el proceso
    if (stockInsuficiente) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Stock insuficiente"),
          content: Text(
              "Lo sentimos, uno o más productos en tu carrito ya no tienen stock suficiente. Por favor, vuelve a seleccionar."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Regresa a la carta del negocio
              },
              child: Text("Aceptar"),
            ),
          ],
        ),
      );

      // Limpiar el carrito del usuario
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
        'carrito': [],
        'negocioId': FieldValue.delete(),
      });

      return; // Detener el proceso de guardado
    }

    // Generar un código único de 5 caracteres
    String codigoPedido = _generarCodigoPedido();

    // Obtener datos del negocio
    final negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .get();

    String nroCelularNegocio = negocioDoc.data()?['nroCelular'] ?? 'Sin número';

    // Crear datos del pedido
    final pedido = {
      'usuarioId': user.uid,
      'codigoPedido': codigoPedido,
      'negocioId': widget.negocioId,
      'productos': widget.productosSeleccionados,
      'total': widget.total,
      'modalidad': _modalidadSeleccionada,
      'costoDelivery': _costoDelivery,
      'nroCelularCliente': _nroCelular,
      'direccion': _modalidadSeleccionada == 'delivery' ? _direccion : null,
      'ubicacion': _modalidadSeleccionada == 'delivery' && _ubicacion != null
          ? GeoPoint(_ubicacion!.latitude, _ubicacion!.longitude)
          : null,
      'notas': _notas,
      'metodoPago': _metodoPagoSeleccionado,
      'fecha': DateTime.now(),
      'estadoPedido': 'pendiente',
      'pedPago': "No Pagado",
      'nroCelularNegocio': nroCelularNegocio,
    };

    // Guardar el pedido en el array de pedidos del usuario
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
      'pedidos': FieldValue.arrayUnion([pedido]),
    });

    // Guardar el pedido en el array de pedidos del negocio
    await FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId).update({
      'pedidos': FieldValue.arrayUnion([pedido]),
    });

    // Actualizar stock de los productos en la carta y el array productos
    for (var productoSeleccionado in widget.productosSeleccionados) {
      var productoCarta = cartaProductos.firstWhere(
        (p) => p['codigo'] == productoSeleccionado['codigo'],
        orElse: () => null,
      );

      var productoArray = productosFirestore.firstWhere(
        (p) => p['codigo'] == productoSeleccionado['codigo'],
        orElse: () => null,
      );

      if (productoCarta != null) {
        int stockActual = productoCarta['stock'] ?? 0;
        String estadoActual = productoCarta['estado'] ?? 'agotado';

        // Descontar el stock solo si tiene un límite
        if (stockActual > 0 &&
            (estadoActual == 'disponible' || estadoActual == 'promocion')) {
          int nuevaCantidad = (stockActual - productoSeleccionado['cantidad']).toInt();
          productoCarta['stock'] = nuevaCantidad < 0 ? 0 : nuevaCantidad;

          // Cambiar el estado a "agotado" si el stock llega a 0
          if (productoCarta['stock'] == 0) {
            productoCarta['estado'] = 'agotado';
          }
        }
      }

      if (productoArray != null) {
        productoArray['stock'] = productoCarta['stock'];
        productoArray['estado'] = productoCarta['estado'];
      }
    }

    // Guardar los cambios en Firestore
    await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .doc(widget.negocioId)
        .update({
      'carta': cartaProductos,
      'productos': productosFirestore,
    });

    // Limpiar el carrito del usuario
    await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
      'carrito': FieldValue.delete(),
      'negocioId': FieldValue.delete(),
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido guardado con éxito.')),
    );

    // Regresar al menú principal o a la carta del negocio
    Navigator.pop(context);
    Navigator.pop(context);
  } catch (e) {
    // Cerrar el snackbar de procesando
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    // Reactivar el botón de guardar pedido
    setState(() {
      _isSubmitting = true;
    });

    print('Error al guardar el pedido: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar el pedido. Intenta de nuevo.')),
    );
  }
}



  Future<void> _showLocationModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: UserLocationPage(), // Página para gestionar ubicaciones
        );
      },
    );

    // Actualizar dirección después de cerrar el modal
    if (result == true) {
      await _loadDefaultAddress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Pedido'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Productos seleccionados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.productosSeleccionados.length,
              itemBuilder: (context, index) {
                var producto = widget.productosSeleccionados[index];
                return ListTile(
                  title: Text(producto['nombre']),
                  subtitle: Text('Cantidad: ${producto['cantidad']} - Precio: S/${producto['precio']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarEliminarProducto(producto),
                  ),
                );
              },
            ),
            Divider(),
            Text('Total: S/${widget.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),

            Text('Modalidad de Pedido', style: TextStyle(fontSize: 18)),
            RadioListTile<String>(
              title: const Text('Delivery'),
              value: 'delivery',
              groupValue: _modalidadSeleccionada,
              onChanged: (String? value) {
                setState(() {
                  _modalidadSeleccionada = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Recojo en local'),
              value: 'recojo',
              groupValue: _modalidadSeleccionada,
              onChanged: (String? value) {
                setState(() {
                  _modalidadSeleccionada = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Número de celular',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  _nroCelular = value;
                });
              },
            ),
            const SizedBox(height: 16),

            if (_modalidadSeleccionada == 'delivery')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dirección', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _direccion,
                          style: TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.location_on, color: Colors.blue),
                        onPressed: _showLocationModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_ubicacion != null)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        // Abrir Google Maps con la ruta trazada
                        final String googleMapsUrl =
                            'https://www.google.com/maps/dir/?api=1&destination=${_ubicacion!.latitude},${_ubicacion!.longitude}&travelmode=driving';
                        if (await canLaunch(googleMapsUrl)) {
                          await launch(googleMapsUrl);
                        } else {
                          print('No se pudo abrir Google Maps');
                        }
                      },
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
                          zoom: 15,
                        ),
                        zoomControlsEnabled: false, // Deshabilitar controles de zoom
                        scrollGesturesEnabled: false, // Deshabilitar desplazamiento
                        rotateGesturesEnabled: false, // Deshabilitar rotación
                        tiltGesturesEnabled: false, // Deshabilitar inclinación
                        zoomGesturesEnabled: false, // Deshabilitar zoom por gestos
                        myLocationButtonEnabled: false, // Ocultar botón de ubicación
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _moveToLocation(); // Centrar el marcador al cargar el mapa
                        },
                        markers: {
                          Marker(
                            markerId: MarkerId('ubicacion'),
                            position: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
                          ),
                        },
                      ),
                    ),
                  ),
                  Text(
                "Costo Delivery:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _mensajeDelivery != null
                  ? Text(_mensajeDelivery!, style: TextStyle(color: Colors.red))
                  : Text("S/ ${_costoDelivery?.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            const SizedBox(height: 16),

            TextField(
                decoration: InputDecoration(
                  labelText: 'Notas para el pedido',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _notas = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              Text('Método de Pago', style: TextStyle(fontSize: 18)),
              RadioListTile<String>(
                title: const Text('Yape/Plin'),
                value: 'yape_plin',
                groupValue: _metodoPagoSeleccionado,
                onChanged: (String? value) {
                  setState(() {
                    _metodoPagoSeleccionado = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Efectivo'),
                value: 'efectivo',
                groupValue: _metodoPagoSeleccionado,
                onChanged: (String? value) {
                  setState(() {
                    _metodoPagoSeleccionado = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isSubmitting ? _guardarPedido : null, // Deshabilitar si está enviando
                child: Text('Guardar Pedido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(150, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



            //   Align(
            //   alignment: Alignment.centerRight,
            //   child: ElevatedButton(
            //     onPressed: _guardarPedido,
            //     child: Text('Guardar Pedido'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.orange,
            //       minimumSize: Size(150, 50),
            //     ),
            //   ),
            // ),



  // Future<void> _calcularCostoDelivery() async {
  //   if (_modalidadSeleccionada != 'delivery' || _ubicacion == null) return;

  //   // Obtener ubicación del negocio
  //   DocumentSnapshot negocioDoc = await FirebaseFirestore.instance
  //       .collection('negocios')
  //       .doc(widget.negocioId)
  //       .get();
  //   var negocioData = negocioDoc.data() as Map<String, dynamic>?;
  //   if (negocioData == null || negocioData['ubicacion'] == null) {
  //     setState(() {
  //       _mensajeDelivery = "No se pudo calcular la distancia.";
  //     });
  //     return;
  //   }

  //   GeoPoint ubicacionNegocio = negocioData['ubicacion'];
  //   double distancia = Geolocator.distanceBetween(
  //         ubicacionNegocio.latitude,
  //         ubicacionNegocio.longitude,
  //         _ubicacion!.latitude,
  //         _ubicacion!.longitude,
  //       ) /
  //       1000; // Convertir metros a kilómetros

  //   double? costo;
  //   if (distancia <= 2.5) {
  //     costo = 5.0;
  //   } else if (distancia <= 3.5) {
  //     costo = 6.0;
  //   } else if (distancia <= 4.5) {
  //     costo = 7.0;
  //   } else if (distancia <= 5.5) {
  //     costo = 8.0;
  //   } else if (distancia <= 6.5) {
  //     costo = 9.0;
  //   } else if (distancia <= 7.5) {
  //     costo = 11.0;
  //   } else if (distancia <= 8.5) {
  //     costo = 12.0;
  //   } else if (distancia <= 9.5) {
  //     costo = 13.0;
  //   } else if (distancia <= 10.5) {
  //     costo = 14.0;
  //   } else if (distancia <= 12.5) {
  //     costo = 16.0;
  //   } else {
  //     setState(() {
  //       _mensajeDelivery = "Consultar con el negocio.";
  //       _costoDelivery = null;
  //     });
  //     return;
  //   }

  //   setState(() {
  //     _costoDelivery = costo;
  //     _mensajeDelivery = null;
  //   });
  // }




//   String _generarCodigoPedido() {
//   const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//   return List.generate(5, (index) => chars[(chars.length * DateTime.now().millisecondsSinceEpoch % chars.length) % chars.length])
//       .join();
// }


//   void _guardarPedido() async {
//   try {
//     final User? user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       throw Exception("Usuario no autenticado");
//     }

//     // Verificar stock antes de proceder
//     final cartaDoc = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .get();

//     if (!cartaDoc.exists) {
//       throw Exception("Carta del negocio no encontrada.");
//     }

//     final cartaData = cartaDoc.data();
//     List<dynamic> cartaProductos = cartaData?['carta'] ?? [];

//     bool stockInsuficiente = false;

//     for (var productoSeleccionado in widget.productosSeleccionados) {
//       var productoFirestore = cartaProductos.firstWhere(
//         (p) => p['codigo'] == productoSeleccionado['codigo'],
//         orElse: () => null,
//       );

//       if (productoFirestore != null) {
//         int stockDisponible = productoFirestore['stock'] ?? 0;
//         String estadoProducto = productoFirestore['estado'] ?? 'agotado';

//         // Verificar stock infinito
//         if ((estadoProducto == "promocion" || estadoProducto == "disponible") && stockDisponible == 0) {
//           continue; // Producto con stock infinito, no hay problema
//         }

//         // Si la cantidad en el carrito excede el stock disponible, marcar como insuficiente
//         if (productoSeleccionado['cantidad'] > stockDisponible) {
//           stockInsuficiente = true;
//           break;
//         }
//       }
//     }

//     // Si hay stock insuficiente, detener el proceso
//     if (stockInsuficiente) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text("Stock insuficiente"),
//           content: Text(
//               "Lo sentimos, uno o más productos en tu carrito ya no tienen stock suficiente. Por favor, vuelve a seleccionar."),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context); // Regresa a la carta del negocio
//               },
//               child: Text("Aceptar"),
//             ),
//           ],
//         ),
//       );

//       // Limpiar el carrito del usuario
//       await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
//         'carrito': [],
//         'negocioId': FieldValue.delete(),
//       });

//       return; // Detener el proceso de guardado
//     }

//     // Generar un código único de 5 caracteres
//     String codigoPedido = _generarCodigoPedido();

//     // Obtener datos del negocio
//     final negocioDoc = await FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(widget.negocioId)
//         .get();

//     String nroCelularNegocio = negocioDoc.data()?['nroCelular'] ?? 'Sin número';

//     // Crear datos del pedido
//     final pedido = {
//       'codigoPedido': codigoPedido,
//       'negocioId': widget.negocioId,
//       'productos': widget.productosSeleccionados,
//       'total': widget.total,
//       'modalidad': _modalidadSeleccionada,
//       'nroCelularCliente': _nroCelular,
//       'direccion': _modalidadSeleccionada == 'delivery' ? _direccion : null,
//       'ubicacion': _modalidadSeleccionada == 'delivery' && _ubicacion != null
//           ? GeoPoint(_ubicacion!.latitude, _ubicacion!.longitude)
//           : null,
//       'notas': _notas,
//       'metodoPago': _metodoPagoSeleccionado,
//       'fecha': DateTime.now(),
//       'estadoPedido': 'pendiente',
//       'pedPago': false,
//       'nroCelularNegocio': nroCelularNegocio,
//     };

//     // Guardar el pedido en el array de pedidos del usuario
//     await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
//       'pedidos': FieldValue.arrayUnion([pedido]),
//     });

//     // Actualizar stock de los productos en la carta del negocio
//     for (var productoSeleccionado in widget.productosSeleccionados) {
//       var productoFirestore = cartaProductos.firstWhere(
//         (p) => p['codigo'] == productoSeleccionado['codigo'],
//         orElse: () => null,
//       );

//       if (productoFirestore != null) {
//         int stockActual = productoFirestore['stock'] ?? 0;
//         String estadoActual = productoFirestore['estado'] ?? 'agotado';

//         // Descontar el stock solo si tiene un límite
//         if (stockActual > 0 &&
//             (estadoActual == 'disponible' || estadoActual == 'promocion')) {
//           int nuevaCantidad = (stockActual - productoSeleccionado['cantidad']).toInt();
//           productoFirestore['stock'] = nuevaCantidad < 0 ? 0 : nuevaCantidad;

//           // Cambiar el estado a "agotado" si el stock llega a 0
//           if (productoFirestore['stock'] == 0) {
//             productoFirestore['estado'] = 'agotado';
//           }
//         }
//       }
//     }

//     // Guardar los cambios en Firestore
//     await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .doc(widget.negocioId)
//         .update({'carta': cartaProductos});

//     // Limpiar el carrito del usuario
//     await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
//       'carrito': FieldValue.delete(),
//       'negocioId': FieldValue.delete(),
//     });

//     // Mostrar mensaje de éxito
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Pedido guardado con éxito.')),
//     );

//     // Regresar al menú principal o a la carta del negocio
//     Navigator.pop(context);
//     Navigator.pop(context);
//   } catch (e) {
//     print('Error al guardar el pedido: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error al guardar el pedido. Intenta de nuevo.')),
//     );
//   }
// }




            // Align(
            //   alignment: Alignment.centerRight,
            //   child: ElevatedButton(
            //     onPressed: () async {
            //       try {
            //         final User? user = FirebaseAuth.instance.currentUser;

            //         if (user != null) {
            //           // Guardar los detalles del pedido en Firestore
            //           final pedido = {
            //             'negocioId': widget.negocioId,
            //             'productos': widget.productosSeleccionados,
            //             'total': widget.total,
            //             'nroCelular': _nroCelular,
            //             'direccion': _direccion,
            //             'notas': _notas,
            //             'fecha': DateTime.now(),
            //           };

            //           await FirebaseFirestore.instance.collection('pedidos').add(pedido);

            //           // Vaciar el carrito y el negocioId
            //           await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update({
            //             'carrito': FieldValue.delete(),
            //             'negocioId': FieldValue.delete(),
            //           });

            //           // Mostrar mensaje de éxito
            //           ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(content: Text('Pedido completado con éxito.')),
            //           );

            //           // Navegar a la página principal
            //           Navigator.pop(context);
            //         }
            //       } catch (e) {
            //         print('Error al completar el pedido: $e');
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(content: Text('Error al completar el pedido. Intenta de nuevo.')),
            //         );
            //       }
            //     },
            //     child: Text('Guardar Pedido'),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.orange,
            //       minimumSize: Size(150, 50),
            //     ),
            //   ),
            // ),





            // ListView.builder(
            //   shrinkWrap: true,
            //   physics: NeverScrollableScrollPhysics(),
            //   itemCount: widget.productosSeleccionados.length,
            //   itemBuilder: (context, index) {
            //     var producto = widget.productosSeleccionados[index];
            //     return ListTile(
            //       title: Text(producto['nombre']),
            //       subtitle: Text('Cantidad: ${producto['cantidad']} - Precio: S/${producto['precio']}'),
            //     );
            //   },
            // ),






  // Future<void> _loadDefaultAddress() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     DocumentSnapshot userDoc =
  //         await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
  //     var userData = userDoc.data() as Map<String, dynamic>?;

  //     if (userData != null && userData.containsKey('direcciones')) {
  //       var direcciones = userData['direcciones'] as List<dynamic>;
  //       var direccionPredeterminada = direcciones.firstWhere(
  //         (direccion) => direccion['predeterminada'] == true,
  //         orElse: () => null,
  //       );

  //       if (direccionPredeterminada != null) {
  //         setState(() {
  //           _direccion = direccionPredeterminada['direccion'];
  //           _ubicacion = direccionPredeterminada['ubicacion']; // GeoPoint
  //         });
  //       }
  //     }
  //   }
  // }

              
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text('Dirección', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            //     Row(
            //       children: [
            //         Expanded(
            //           child: Text(
            //             _direccion,
            //             style: TextStyle(fontSize: 16),
            //             overflow: TextOverflow.ellipsis,
            //             maxLines: 1,
            //           ),
            //         ),
            //         IconButton(
            //           icon: Icon(Icons.location_on, color: Colors.blue),
            //           onPressed: _showLocationModal,
            //         ),
            //       ],
            //     ),
            //     const SizedBox(height: 8),
            //     if (_ubicacion != null)
            //       GestureDetector(
            //         onTap: () {
            //           final url = 'https://www.google.com/maps/search/?api=1&query=${_ubicacion!.latitude},${_ubicacion!.longitude}';
            //           launch(url);
            //         },
            //         child: Container(
            //           height: 200,
            //           margin: const EdgeInsets.symmetric(vertical: 8.0),
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(12.0),
            //             border: Border.all(color: Colors.grey),
            //           ),
            //           child: ClipRRect(
            //             borderRadius: BorderRadius.circular(12.0),
            //             child: GoogleMap(
            //               initialCameraPosition: CameraPosition(
            //                 target: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
            //                 zoom: 15,
            //               ),
            //               markers: {
            //                 Marker(
            //                   markerId: MarkerId('ubicacion'),
            //                   position: LatLng(_ubicacion!.latitude, _ubicacion!.longitude),
            //                 ),
            //               },
            //               myLocationButtonEnabled: false,
            //               scrollGesturesEnabled: false,
            //               zoomGesturesEnabled: false,
            //               tiltGesturesEnabled: false,
            //               rotateGesturesEnabled: false,
            //             ),
            //           ),
            //         ),
            //       ),
            //   ],
            // ),






// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:restmap/views/customer/map_page.dart';

// class DetallePedidoPage extends StatefulWidget {
//   final String negocioId;
//   final List<Map<String, dynamic>> productosSeleccionados;
//   final double total;

//   DetallePedidoPage({
//     required this.negocioId,
//     required this.productosSeleccionados,
//     required this.total,
//   });

//   @override
//   _DetallePedidoPageState createState() => _DetallePedidoPageState();
// }

// class _DetallePedidoPageState extends State<DetallePedidoPage> {
//   String? _modalidadSeleccionada = 'delivery';
//   String _nroCelular = '';
//   String _direccion = '';
//   String _notas = '';
//   GeoPoint? _ubicacion;
//   String? _metodoPagoSeleccionado = 'yape_plin';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detalles del Pedido'),
//         backgroundColor: Colors.orange,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
           
//             Text('Productos seleccionados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: widget.productosSeleccionados.length,
//               itemBuilder: (context, index) {
//                 var producto = widget.productosSeleccionados[index];
//                 return ListTile(
//                   title: Text(producto['nombre']),
//                   subtitle: Text('Cantidad: ${producto['cantidad']} - Precio: S/${producto['precio']}'),
//                 );
//               },
//             ),
//             Divider(),
//             Text('Total: S/${widget.total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
//             const SizedBox(height: 16),

          
//             Text('Modalidad de Pedido', style: TextStyle(fontSize: 18)),
//             RadioListTile<String>(
//               title: const Text('Delivery'),
//               value: 'delivery',
//               groupValue: _modalidadSeleccionada,
//               onChanged: (String? value) {
//                 setState(() {
//                   _modalidadSeleccionada = value;
//                 });
//               },
//             ),
//             RadioListTile<String>(
//               title: const Text('Recojo en local'),
//               value: 'recojo',
//               groupValue: _modalidadSeleccionada,
//               onChanged: (String? value) {
//                 setState(() {
//                   _modalidadSeleccionada = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),

     
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'Número de celular',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.phone,
//               onChanged: (value) {
//                 setState(() {
//                   _nroCelular = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),

     
//             if (_modalidadSeleccionada == 'delivery')
//               TextField(
//                 decoration: InputDecoration(
//                   labelText: 'Dirección (ej. Calle Los Alamos 530)',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _direccion = value;
//                   });
//                 },
//               ),
//             const SizedBox(height: 16),

     
//             TextField(
//               decoration: InputDecoration(
//                 labelText: 'Notas para el pedido',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//               onChanged: (value) {
//                 setState(() {
//                   _notas = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),

      
//             if (_modalidadSeleccionada == 'delivery')
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Ubicación', style: TextStyle(fontSize: 18)),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final result = await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => MapPage(userId: widget.negocioId),
//                         ),
//                       );

//                       if (result != null) {
//                         setState(() {
//                           _ubicacion = result as GeoPoint;
//                         });
//                       }
//                     },
//                     child: Text('Seleccionar ubicación'),
//                   ),
//                 ],
//               ),
//             if (_ubicacion != null)
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Text('Ubicación seleccionada: (${_ubicacion!.latitude}, ${_ubicacion!.longitude})'),
//               ),
//             const SizedBox(height: 16),

      
//             Text('Método de Pago', style: TextStyle(fontSize: 18)),
//             RadioListTile<String>(
//               title: const Text('Yape/Plin'),
//               value: 'yape_plin',
//               groupValue: _metodoPagoSeleccionado,
//               onChanged: (String? value) {
//                 setState(() {
//                   _metodoPagoSeleccionado = value;
//                 });
//               },
//             ),
//             RadioListTile<String>(
//               title: const Text('Efectivo'),
//               value: 'efectivo',
//               groupValue: _metodoPagoSeleccionado,
//               onChanged: (String? value) {
//                 setState(() {
//                   _metodoPagoSeleccionado = value;
//                 });
//               },
//             ),
//             RadioListTile<String>(
//               title: const Text('Contraentrega'),
//               value: 'contraentrega',
//               groupValue: _metodoPagoSeleccionado,
//               onChanged: (String? value) {
//                 setState(() {
//                   _metodoPagoSeleccionado = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),

       
//             Align(
//               alignment: Alignment.centerRight,
//               child: ElevatedButton(
//                 onPressed: () {
//                   print('Pedido guardado');
//                 },
//                 child: Text('Guardar'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   minimumSize: Size(150, 50),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }