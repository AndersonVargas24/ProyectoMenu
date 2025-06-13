import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';
import 'package:menu/dashboardChef/inventario.dart';
import 'package:menu/dashboardChef/HistorialInventario.dart';

class VistaDiaScreen extends StatefulWidget {
  const VistaDiaScreen({super.key});

  @override
  _VistaDiaScreenState createState() => _VistaDiaScreenState();
}

class _VistaDiaScreenState extends State<VistaDiaScreen> {
  List<ProductoInventario> productos = [];
  bool inventarioGuardado = false;
  DateTime fechaSeleccionada = DateTime.now();

  // NUEVAS VARIABLES PARA INVENTARIO DEL DÍA
  bool esEditable = false;
  bool productosCargados = false;
  List<Map<String, dynamic>> productosInventario = [];

  @override
  void initState() {
    super.initState();
    verificarInventarioDelDia();
    cargarProductos();
  }

  Future<void> verificarInventarioDelDia() async {
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
    final doc =
        await FirebaseFirestore.instance
            .collection('inventario_dia')
            .doc(fechaStr)
            .get();

    if (doc.exists) {
      productosInventario = List<Map<String, dynamic>>.from(doc['productos']);
      productosCargados = true;
      esEditable = doc['estado'] == 'abierto';
    } else {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();

      productosInventario =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'nombre': data['nombre'] ?? '',
              'categoria': data['categoria'] ?? '',
              'unidad': data['unidad'] ?? '',
              'cantidad': data['cantidad'] ?? 0,
              'horaIngreso': null,
              'salida': 0,
              'horaSalida': null,
            };
          }).toList();

      await FirebaseFirestore.instance
          .collection('inventario_dia')
          .doc(fechaStr)
          .set({
            'fecha': Timestamp.fromDate(fechaSeleccionada),
            'estado': 'abierto',
            'productos': productosInventario,
          });

      productosCargados = true;
      esEditable = true;
    }
    setState(() {});
  }

  Future<void> guardarCambiosInventario() async {
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
    // Calcular y guardar saldo final para cada producto
    for (var producto in productosInventario) {
      final productoId =
          productos
              .firstWhere(
                (p) => p.nombre == producto['nombre'],
                orElse:
                    () => ProductoInventario(
                      id: '',
                      nombre: '',
                      categoria: '',
                      cantidad: 0,
                      unidad: '',
                    ),
              )
              .id;
      final stock = await calcularStock(productoId);
      producto['saldoFinal'] = stock;
    }

    await FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(fechaStr)
        .update({'productos': productosInventario});
  }

  Future<void> cerrarInventarioDelDia() async {
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
    await FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(fechaStr)
        .update({'estado': 'cerrado'});
    esEditable = false;
    setState(() {});
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
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
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
                              trailing:
                                  esEditable
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_downward,
                                              color: Colors.green,
                                            ),
                                            tooltip: 'Registrar entrada',
                                            onPressed:
                                                () => registrarMovimiento(
                                                  p.id,
                                                  'entrada',
                                                ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_upward,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Registrar salida',
                                            onPressed:
                                                () => registrarMovimiento(
                                                  p.id,
                                                  'salida',
                                                ),
                                          ),
                                        ],
                                      )
                                      : null,
                            );
                          },
                        );
                      },
                    ),
          ),
          if (esEditable)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('¿Cerrar El Inventario del día?'),
                          content: const Text(
                            'Después de guardar y cerrar, no podrás editar más los productos ni las salidas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await guardarCambiosInventario();
                    await cerrarInventarioDelDia();
                  }
                },
                child: const Text('Guardar y Cerrar Día'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Día'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Historial'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Inventario del Dia',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Ya estás en Día, no hacer nada
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Inventario()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HistorialInventarioScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}
