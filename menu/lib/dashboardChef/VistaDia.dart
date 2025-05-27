import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:menu/dashboardChef/inventario.dart';
import 'package:menu/dashboardChef/HistorialInventario.dart';

class VistaDiaScreen extends StatefulWidget {
  @override
  _VistaDiaScreenState createState() => _VistaDiaScreenState();
}

class _VistaDiaScreenState extends State<VistaDiaScreen> {
  List<ProductoInventario> productos = [];
  bool inventarioGuardado = false;
  DateTime fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    cargarInventarioDelDia();
    cargarProductos();
  }

  Future<void> cargarInventarioDelDia() async {
    final fechaHoy = DateTime.now();
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaHoy);
    final inventarioRef = FirebaseFirestore.instance
        .collection('inventario')
        .doc(fechaStr);

    final docSnapshot = await inventarioRef.get();
    if (!docSnapshot.exists) {
      setState(() {
        productos = [];
        inventarioGuardado = false;
      });
      return;
    }

    final productosSnapshot = await inventarioRef.collection('productos').get();
    setState(() {
      productos =
          productosSnapshot.docs
              .map((doc) => ProductoInventario.fromDocument(doc))
              .toList();
      inventarioGuardado = true;
    });
  }

  Future<void> cargarProductos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();
      setState(() {
        productos =
            snapshot.docs
                .map((doc) => ProductoInventario.fromDocument(doc))
                .toList();
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar productos')));
      }
    }
  }

  Future<int> calcularStock(String productoId) async {
    try {
      final movimientos =
          await FirebaseFirestore.instance
              .collection('movimientos')
              .where('productoId', isEqualTo: productoId)
              .get();

      int entradas = 0;
      int salidas = 0;

      for (var m in movimientos.docs) {
        final data = m.data();
        if (data['fecha'] != null &&
            data['tipo'] != null &&
            data['cantidad'] != null) {
          final fecha = (data['fecha'] as Timestamp).toDate();
          if (fecha.isBefore(fechaSeleccionada.add(Duration(days: 1)))) {
            final cantidad = int.tryParse(data['cantidad'].toString()) ?? 0;
            if (data['tipo'] == 'entrada') entradas += cantidad;
            if (data['tipo'] == 'salida') salidas += cantidad;
          }
        }
      }

      return entradas - salidas;
    } catch (e) {
      print('Error al calcular stock: $e');
      return 0;
    }
  }

  Future<void> registrarMovimiento(String productoId, String tipo) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Registrar $tipo'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Cantidad'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final cantidad = int.tryParse(controller.text) ?? 0;
                  if (cantidad <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor, ingresa una cantidad válida'),
                      ),
                    );
                    return;
                  }

                  if (tipo == 'salida') {
                    final stockActual = await calcularStock(productoId);
                    if (cantidad > stockActual) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No hay suficiente stock')),
                      );
                      return;
                    }
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('movimientos')
                        .add({
                          'productoId': productoId,
                          'tipo': tipo,
                          'cantidad': cantidad,
                          'fecha': Timestamp.fromDate(fechaSeleccionada),
                        });

                    Navigator.pop(context);
                    setState(() {}); // Refrescar la pantalla
                  } catch (e) {
                    print('Error al registrar movimiento: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al registrar movimiento')),
                    );
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Movimientos del Día - ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada)}',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialInventarioScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final seleccion = await showDatePicker(
                context: context,
                initialDate: fechaSeleccionada,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
              );
              if (seleccion != null) {
                setState(() => fechaSeleccionada = seleccion);
              }
            },
          ),
        ],
      ),
      body:
          productos.isEmpty
              ? Center(child: Text('No hay productos disponibles'))
              : ListView.builder(
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final p = productos[index];
                  return FutureBuilder<int>(
                    future: calcularStock(p.id),
                    builder: (context, snapshot) {
                      final stock = snapshot.data ?? 0;
                      return ListTile(
                        title: Text(p.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stock Actual $stock ${p.unidad}'),
                            if (p.fecha != null)
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(p.fecha!)}',
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_downward,
                                color: Colors.green,
                              ),
                              tooltip: 'Registrar entrada',
                              onPressed:
                                  () => registrarMovimiento(p.id, 'entrada'),
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_upward, color: Colors.red),
                              tooltip: 'Registrar salida',
                              onPressed:
                                  () => registrarMovimiento(p.id, 'salida'),
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
}
