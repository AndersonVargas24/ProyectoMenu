import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';

class HistorialInventarioScreen extends StatefulWidget {
  @override
  _HistorialInventarioScreenState createState() =>
      _HistorialInventarioScreenState();
}

class _HistorialInventarioScreenState extends State<HistorialInventarioScreen> {
  DateTime? _fechaSeleccionada;
  List<Map<String, dynamic>> _productos = [];
  bool _cargando = false;
  bool _hayDatos = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _seleccionarFecha,
          ),
        ],
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _fechaSeleccionada == null
              ? const Center(child: Text('Selecciona una fecha'))
              : !_hayDatos
              ? const Center(child: Text('No hay nada para mostrar'))
              : ListView.builder(
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  final producto = _productos[index];
                  return ListTile(
                    leading:
                        producto['imagenUrl'] != null
                            ? Image.network(
                              producto['imagenUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.fastfood),
                    title: Text(producto['nombre']),
                    subtitle: Text(
                      'Cantidad: ${producto['cantidad']} ${producto['unidad']}\n'
                      'Categoría: ${producto['categoria']}\n'
                      'Entrada: ${producto['horaEntrada'] ?? 'N/A'}\n'
                      'Salida: ${producto['cantidadSalida'] ?? 0} a las ${producto['horaSalida'] ?? 'N/A'}\n'
                      'Saldo final: ${producto['saldoFinal'] ?? producto['cantidad']}',
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
        _cargando = true;
        _productos.clear();
      });

      final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      try {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('inventario_dia')
                .where('fecha', isGreaterThanOrEqualTo: inicioDelDia)
                .where('fecha', isLessThan: finDelDia)
                .get();

        if (snapshot.docs.isEmpty) {
          setState(() {
            _hayDatos = false;
            _cargando = false;
          });
        } else {
          final productos =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'nombre': data['nombre'] ?? '',
                  'categoria': data['categoria'] ?? '',
                  'cantidad': data['cantidad'] ?? 0,
                  'unidad': data['unidad'] ?? '',
                  'imagenUrl': data['imagenUrl'],
                  'horaEntrada': data['horaEntrada'],
                  'cantidadSalida': data['cantidadSalida'],
                  'horaSalida': data['horaSalida'],
                  'saldoFinal': data['saldoFinal'],
                };
              }).toList();

          setState(() {
            _productos = productos;
            _hayDatos = true;
            _cargando = false;
          });
        }
      } catch (e) {
        setState(() {
          _hayDatos = false;
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar los datos')),
        );
      }
    }
  }
}
