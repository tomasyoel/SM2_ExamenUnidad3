import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:restmap/views/admin/mapadmin.dart';

class AgregarNegocioPage extends StatefulWidget {
  const AgregarNegocioPage({super.key});

  @override
  _AgregarNegocioPageState createState() => _AgregarNegocioPageState();
}

class _AgregarNegocioPageState extends State<AgregarNegocioPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _propietarioController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nroCelularController = TextEditingController();
  String? _encargadoSeleccionado;
  String? _tipoCocinaSeleccionado;
  LatLng? _ubicacionSeleccionada;
  File? _logoImage;
  String? _logoUrl;
  bool _isAdding = false;

  Future<void> _addNegocio() async {
  if (_nombreController.text.isEmpty ||
      _direccionController.text.isEmpty ||
      _ubicacionSeleccionada == null ||
      _logoImage == null ||
      _tipoCocinaSeleccionado == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor, completa todos los campos y sube el logo.')),
    );
    return;
  }

  setState(() {
      _isAdding = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agregando negocio...')),
    );

  try {
    _logoUrl = await _uploadLogo();

    final Map<String, dynamic> negocioData = {
      'nombre': _nombreController.text,
      'propietario': _propietarioController.text,
      'logo': _logoUrl,
      'direccion': _direccionController.text,
      'ubicacion': GeoPoint(_ubicacionSeleccionada!.latitude, _ubicacionSeleccionada!.longitude),
      'tipo_cocina': _tipoCocinaSeleccionado,
      'calificacionnegocio': [],
      'recomendaciones': [],
      'nroCelular': _nroCelularController.text.isNotEmpty ? _nroCelularController.text : '',
    };


    if (_encargadoSeleccionado != null) {
      negocioData['encargado'] = _encargadoSeleccionado;
    }


    final negocioDoc = await FirebaseFirestore.instance.collection('negocios').add(negocioData);


    await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioDoc.id).set({
      'negocioId': negocioDoc.id,
      // 'carta': [],
    });


    _nombreController.clear();
    _propietarioController.clear();
    _direccionController.clear();
    _nroCelularController.clear();
    _ubicacionSeleccionada = null;
    _encargadoSeleccionado = null;
    _tipoCocinaSeleccionado = null;
    _logoImage = null;
    // setState(() {});

    setState(() {
        _isAdding = false;
      });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Negocio agregado exitosamente y carta creada.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al agregar el negocio: $e')),
    );
  }
}



  Future<void> _seleccionarUbicacion() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaAdminPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _ubicacionSeleccionada = result;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        setState(() {
          _logoImage = File(result.files.single.path!);
        });
      } else {
        print('No se seleccionó ninguna imagen.');
      }
    } catch (e) {
      print('Error al seleccionar la imagen: $e');
    }
  }

  Future<String?> _uploadLogo() async {
    if (_logoImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('logonegocios/${_nombreController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
      UploadTask uploadTask = storageRef.putFile(_logoImage!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir el logo: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Negocio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
              ),
              TextField(
                controller: _propietarioController,
                decoration: const InputDecoration(labelText: 'Nombre del Propietario'),
              ),
              TextField(
                controller: _nroCelularController,
                decoration: const InputDecoration(labelText: 'Número de Celular'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _seleccionarUbicacion,
                child: Text(
                  _ubicacionSeleccionada == null
                      ? 'Seleccionar Ubicación en Mapa'
                      : 'Ubicación Seleccionada (${_ubicacionSeleccionada!.latitude}, ${_ubicacionSeleccionada!.longitude})',
                ),
              ),
              const SizedBox(height: 20),

              if (_ubicacionSeleccionada != null)
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _ubicacionSeleccionada!,
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('business-location'),
                        position: _ubicacionSeleccionada!,
                      ),
                    },
                  ),
                ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _logoImage != null ? FileImage(_logoImage!) : null,
                  child: _logoImage == null
                      ? const Icon(Icons.camera_alt, size: 50, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

            FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('negocios').get(),
            builder: (context, negocioSnapshot) {
              if (!negocioSnapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final negocios = negocioSnapshot.data!.docs;

          
              final Set<dynamic> usuariosAsignados = negocios
                  .where((doc) => (doc.data() as Map<String, dynamic>).containsKey('encargado'))
                  .map<dynamic>((doc) => doc['encargado'])
                  .toSet();

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'negocio')
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final usuariosNegocio = snapshot.data!.docs;

                  
                  final encargadosDisponibles = usuariosNegocio.where((usuario) {
                    return !usuariosAsignados.contains(usuario.id);
                  }).toList();

                  return DropdownButton<String>(
                    hint: const Text('Seleccionar Encargado'),
                    value: _encargadoSeleccionado,
                    onChanged: (String? newValue) {
                      setState(() {
                        _encargadoSeleccionado = newValue;
                      });
                    },
                    items: encargadosDisponibles.map((encargado) {
                      var data = encargado.data() as Map<String, dynamic>?;

                      String nombre = (data != null && data.containsKey('nombre'))
                          ? data['nombre']
                          : data?['correo'] ?? 'Sin nombre';

                      return DropdownMenuItem<String>(
                        value: encargado.id,
                        child: Text(nombre),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),


              const SizedBox(height: 20),
           
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('tipococina').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final tiposCocina = snapshot.data!.docs;

                  return DropdownButton<String>(
                    hint: const Text('Seleccionar Tipo de Cocina'),
                    value: _tipoCocinaSeleccionado,
                    onChanged: (String? newValue) {
                      setState(() {
                        _tipoCocinaSeleccionado = newValue;
                      });
                    },
                    items: tiposCocina.map((tipo) {
                      var data = tipo.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: tipo.id,
                        child: Text(data['nombre']),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                // onPressed: _addNegocio,
                onPressed: _isAdding ? null : _addNegocio,
                child: const Text('Agregar Negocio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  // Future<void> _addNegocio() async {
  //   if (_nombreController.text.isEmpty ||
  //       _direccionController.text.isEmpty ||
  //       _ubicacionSeleccionada == null ||
  //       _encargadoSeleccionado == null ||
  //       _logoImage == null ||
  //       _tipoCocinaSeleccionado == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Por favor, completa todos los campos y sube el logo.')),
  //     );
  //     return;
  //   }

  //   try {
  //     // Sube la imagen del logo al storage
  //     _logoUrl = await _uploadLogo();

  //     // Guarda el negocio en Firestore
  //     final negocioDoc = await FirebaseFirestore.instance.collection('negocios').add({
  //       'nombre': _nombreController.text,
  //       'propietario': _propietarioController.text,
  //       'logo': _logoUrl,
  //       'direccion': _direccionController.text,
  //       'ubicacion': GeoPoint(_ubicacionSeleccionada!.latitude, _ubicacionSeleccionada!.longitude),
  //       'encargado': _encargadoSeleccionado,
  //       'tipo_cocina': _tipoCocinaSeleccionado, // Tipo de cocina seleccionado
  //     });

  //     // Crear una plantilla vacía de carta vinculada al negocio
  //     await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioDoc.id).set({
  //       'negocioId': negocioDoc.id,
  //       // 'carta': [], // Inicializamos la carta vacía
  //     });

  //     // Limpia los controladores y variables
  //     _nombreController.clear();
  //     _propietarioController.clear();
  //     _direccionController.clear();
  //     _ubicacionSeleccionada = null;
  //     _encargadoSeleccionado = null;
  //     _tipoCocinaSeleccionado = null;
  //     _logoImage = null;
  //     setState(() {});

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Negocio agregado exitosamente y carta creada.')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error al agregar el negocio: $e')),
  //     );
  //   }
  // }

              // FutureBuilder<QuerySnapshot>(
              //   future: FirebaseFirestore.instance
              //       .collection('usuarios')
              //       .where('rol', isEqualTo: 'negocio')
              //       .get(),
              //   builder: (context, snapshot) {
              //     if (!snapshot.hasData) {
              //       return const CircularProgressIndicator();
              //     }

              //     final encargados = snapshot.data!.docs;

              //     return DropdownButton<String>(
              //       hint: const Text('Seleccionar Encargado'),
              //       value: _encargadoSeleccionado,
              //       onChanged: (String? newValue) {
              //         setState(() {
              //           _encargadoSeleccionado = newValue;
              //         });
              //       },
              //       items: encargados.map((encargado) {
              //         var data = encargado.data() as Map<String, dynamic>?;
              //         String nombre = (data != null && data.containsKey('nombre'))
              //             ? data['nombre']
              //             : data?['correo'] ?? 'Sin nombre';

              //         return DropdownMenuItem<String>(
              //           value: encargado.id,
              //           child: Text(nombre),
              //         );
              //       }).toList(),
              //     );
              //   },
              // ),