import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HorarioPage extends StatefulWidget {
  final String negocioId;

  HorarioPage({required this.negocioId});

  @override
  _HorarioPageState createState() => _HorarioPageState();
}

class _HorarioPageState extends State<HorarioPage> {
  Map<String, dynamic> horarios = {
    'Lunes': {'inicio': null, 'fin': null, 'cerrado': false},
    'Martes': {'inicio': null, 'fin': null, 'cerrado': false},
    'Miércoles': {'inicio': null, 'fin': null, 'cerrado': false},
    'Jueves': {'inicio': null, 'fin': null, 'cerrado': false},
    'Viernes': {'inicio': null, 'fin': null, 'cerrado': false},
    'Sábado': {'inicio': null, 'fin': null, 'cerrado': false},
    'Domingo': {'inicio': null, 'fin': null, 'cerrado': false},
  };

  final List<String> orderedDays = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _loadHorario();
  }

  Future<void> _loadHorario() async {
    DocumentSnapshot negocioDoc = await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .get();

    if (negocioDoc.exists) {
      Map<String, dynamic>? negocioData = negocioDoc.data() as Map<String, dynamic>?;

      if (negocioData != null && negocioData.containsKey('horarios') && negocioData['horarios'] != null) {
        Map<String, dynamic> loadedHorarios = Map<String, dynamic>.from(negocioData['horarios']);

        setState(() {
          loadedHorarios.forEach((dia, horario) {
            horarios[dia] = {
              'inicio': horario['inicio'] != null ? _stringToTimeOfDay(horario['inicio'].toString().trim()) : null,
              'fin': horario['fin'] != null ? _stringToTimeOfDay(horario['fin'].toString().trim()) : null,
              'cerrado': horario['cerrado'] ?? false,
            };
          });
        });
      } else {
        await _saveHorario();
      }
    }
  }

  Future<void> _saveHorario() async {
    Map<String, dynamic> horariosFormatted = {};
    horarios.forEach((dia, horario) {
      horariosFormatted[dia] = {
        'inicio': horario['inicio'] != null ? _timeOfDayToString(horario['inicio']) : null,
        'fin': horario['fin'] != null ? _timeOfDayToString(horario['fin']) : null,
        'cerrado': horario['cerrado'] ?? false,
      };
    });

    await FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .set({'horarios': horariosFormatted}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Horario actualizado')),
    );
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay? initialTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    return picked;
  }

  bool _validateTime(TimeOfDay inicio, TimeOfDay fin) {
    final inicioMinutes = inicio.hour * 60 + inicio.minute;
    final finMinutes = fin.hour * 60 + fin.minute;
    return finMinutes > inicioMinutes;
  }

  TimeOfDay? _stringToTimeOfDay(String tod) {
    tod = tod.trim();
    if (tod.isEmpty) return null;

    try {
      final DateFormat format = DateFormat.jm();
      return TimeOfDay.fromDateTime(format.parse(tod));
    } catch (e) {
      print('Error al convertir String a TimeOfDay: $e');
      // Intenta parsear manualmente
      final parts = tod.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minutePart = parts[1].split(' ');
        final minute = int.tryParse(minutePart[0]);
        if (hour != null && minute != null) {
          int finalHour = hour;
          if (minutePart.length > 1 && minutePart[1].toLowerCase() == 'pm' && hour != 12) {
            finalHour += 12;
          }
          if (minutePart.length > 1 && minutePart[1].toLowerCase() == 'am' && hour == 12) {
            finalHour = 0;
          }
          return TimeOfDay(hour: finalHour % 24, minute: minute % 60);
        }
      }
      return null;
    }
  }

  String _timeOfDayToString(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horario de Atención'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveHorario,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: orderedDays.map((dia) {
                final bool cerrado = horarios[dia]['cerrado'] ?? false;
                return ListTile(
                  title: Text(dia),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          horarios[dia]['inicio'] != null && !cerrado
                              ? _timeOfDayToString(horarios[dia]['inicio'])
                              : 'Sin horario',
                        ),
                      ),
                      Text(' - '),
                      Expanded(
                        child: Text(
                          horarios[dia]['fin'] != null && !cerrado
                              ? _timeOfDayToString(horarios[dia]['fin'])
                              : 'Sin horario',
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          if (!cerrado) {
                            TimeOfDay? inicio = await _selectTime(context, horarios[dia]['inicio']);
                            TimeOfDay? fin = await _selectTime(context, horarios[dia]['fin']);
                            if (inicio != null && fin != null) {
                              if (_validateTime(inicio, fin)) {
                                setState(() {
                                  horarios[dia] = {'inicio': inicio, 'fin': fin, 'cerrado': false};
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('La hora de salida debe ser después de la hora de entrada')),
                                );
                              }
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: Image.asset(
                          cerrado ? 'assets/cerrado.png' : 'assets/cerradodesmarc.png',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            horarios[dia]['cerrado'] = !cerrado;
                            if (cerrado) {
                              horarios[dia]['inicio'] = null;
                              horarios[dia]['fin'] = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(),
          Text(
            'Horario de Atención',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: orderedDays.map((dia) {
                final horario = horarios[dia];
                final bool cerrado = horario['cerrado'] ?? false;
                return ListTile(
                  title: Text('$dia'),
                  subtitle: cerrado
                      ? Text('Cerrado')
                      : Text(
                          'Apertura: ${horario['inicio'] != null ? _timeOfDayToString(horario['inicio']) : 'Sin apertura'}, '
                          'Cierre: ${horario['fin'] != null ? _timeOfDayToString(horario['fin']) : 'Sin cierre'}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}