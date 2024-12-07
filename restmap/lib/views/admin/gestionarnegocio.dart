import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionarNegociosPage extends StatefulWidget {
  const GestionarNegociosPage({super.key});

  @override
  _GestionarNegociosPageState createState() => _GestionarNegociosPageState();
}

class _GestionarNegociosPageState extends State<GestionarNegociosPage> {
  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Gestionar Negocios"),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('negocios').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final negocios = snapshot.data!.docs;

            if (negocios.isEmpty) {
              return const Center(child: Text("No hay negocios registrados."));
            }

            return ListView.builder(
              itemCount: negocios.length,
              itemBuilder: (context, index) {
                var negocio = negocios[index];
                var negocioData = negocio.data() as Map<String, dynamic>?;

              
                var logo = (negocioData != null && negocioData['logo'] != null)
                    ? negocioData['logo']
                    : null;

                return ListTile(
                  leading: logo != null
                      ? Image.network(logo, width: 50, height: 50)
                      : const Icon(Icons.store),
                  title: Text(negocioData?['nombre'] ?? 'Sin nombre'),
                  subtitle: Text('Propietario: ${negocioData?['propietario'] ?? 'Sin propietario'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _viewNegocio(context, negocioData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editNegocio(context, negocio.id, negocioData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteNegocio(context, negocio.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    }

  
    void _viewNegocio(BuildContext context, Map<String, dynamic>? negocioData) async {
      
      String encargadoInfo = "Sin encargado";
      if (negocioData?['encargado'] != null) {
        var encargadoSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(negocioData!['encargado'])
            .get();
        if (encargadoSnapshot.exists) {
          var encargadoData = encargadoSnapshot.data();
          encargadoInfo = (encargadoData != null && encargadoData.containsKey('nombre'))
              ? encargadoData['nombre']
              : encargadoData?['correo'] ?? 'Sin encargado';
        }
      }

    
      String tipoCocinaNombre = "Sin tipo de cocina";
      if (negocioData?['tipo_cocina'] != null) {
        var tipoCocinaSnapshot = await FirebaseFirestore.instance
            .collection('tipococina')
            .doc(negocioData!['tipo_cocina'])
            .get();
        if (tipoCocinaSnapshot.exists) {
          var tipoCocinaData = tipoCocinaSnapshot.data();
          tipoCocinaNombre = tipoCocinaData?['nombre'] ?? "Sin tipo de cocina";
        }
      }

      
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Información del Negocio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                negocioData?['logo'] != null
                    ? Image.network(negocioData!['logo'], height: 100)
                    : const Icon(Icons.store, size: 100),
                const SizedBox(height: 20),
                Text('Nombre: ${negocioData?['nombre'] ?? 'Sin nombre'}'),
                Text('Propietario: ${negocioData?['propietario'] ?? 'Sin propietario'}'),
                Text('Encargado: $encargadoInfo'),
                Text('Tipo de Cocina: $tipoCocinaNombre'),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }


    void _editNegocio(BuildContext context, String negocioId, Map<String, dynamic>? negocioData) {
    final TextEditingController nombreController = TextEditingController(text: negocioData?['nombre']);
    final TextEditingController propietarioController = TextEditingController(text: negocioData?['propietario']);
    String? encargadoSeleccionado = negocioData?['encargado'];
    String? tipoCocinaSeleccionado = negocioData?['tipo_cocina'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Negocio'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
                    ),
                    TextField(
                      controller: propietarioController,
                      decoration: const InputDecoration(labelText: 'Nombre del Propietario'),
                    ),
                    const SizedBox(height: 20),
                  
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .where('rol', isEqualTo: 'negocio')
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final encargados = snapshot.data!.docs;

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('Seleccionar Encargado'),
                                value: encargadoSeleccionado,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    encargadoSeleccionado = newValue;
                                  });
                                },
                                items: encargados.map((encargado) {
                                  var data = encargado.data() as Map<String, dynamic>?;
                                  String nombre = (data != null && data.containsKey('nombre'))
                                      ? data['nombre']
                                      : data?['correo'] ?? 'Sin nombre';

                                  return DropdownMenuItem<String>(
                                    value: encargado.id,
                                    child: Text(nombre),
                                  );
                                }).toList(),
                              ),
                            ),
                            if (encargadoSeleccionado != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () async {
                                  
                                  await FirebaseFirestore.instance
                                      .collection('negocios')
                                      .doc(negocioId)
                                      .update({'encargado': FieldValue.delete()});

                                  setState(() {
                                    encargadoSeleccionado = null;
                                  });

                                
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Encargado eliminado')),
                                  );
                                },
                              ),
                          ],
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
                          value: tipoCocinaSeleccionado,
                          onChanged: (String? newValue) {
                            setState(() {
                              tipoCocinaSeleccionado = newValue;
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                
                    Map<String, dynamic> updateData = {
                      'nombre': nombreController.text,
                      'propietario': propietarioController.text,
                      'tipo_cocina': tipoCocinaSeleccionado,
                    };

                    if (encargadoSeleccionado != null) {
                      updateData['encargado'] = encargadoSeleccionado;
                    }

                    await FirebaseFirestore.instance.collection('negocios').doc(negocioId).update(updateData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos actualizados correctamente')),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


    void _confirmDeleteNegocio(BuildContext context, String negocioId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Está seguro de que desea eliminar este negocio?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        
        DocumentSnapshot negocioSnapshot =
            await FirebaseFirestore.instance.collection('negocios').doc(negocioId).get();
        var negocioData = negocioSnapshot.data() as Map<String, dynamic>?;

      
        if (negocioData != null && negocioData['logo'] != null) {
          String logoUrl = negocioData['logo'];
          
          Reference storageRef = FirebaseStorage.instance.refFromURL(logoUrl);
          await storageRef.delete();
        }
        
        
        await FirebaseFirestore.instance.collection('negocios').doc(negocioId).delete();

        
        var cartasSnapshot = await FirebaseFirestore.instance
            .collection('cartasnegocio')
            .where('negocioId', isEqualTo: negocioId)
            .get();
        for (var carta in cartasSnapshot.docs) {
          await FirebaseFirestore.instance.collection('cartasnegocio').doc(carta.id).delete();
        }

      
        var cuponesSnapshot = await FirebaseFirestore.instance
            .collection('cuponesnegocios')
            .where('negocioId', isEqualTo: negocioId)
            .get();
        for (var cupon in cuponesSnapshot.docs) {
          await FirebaseFirestore.instance.collection('cuponesnegocios').doc(cupon.id).delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Negocio y registros relacionados eliminados exitosamente.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el negocio: $e')),
        );
      }
    }
  }
}
