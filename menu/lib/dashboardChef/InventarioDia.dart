import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/ProductoPredeterminado.dart';

class InventarioDiaScreen extends StatefulWidget {
  const InventarioDiaScreen({super.key});

  @override
  _InventarioDiaScreenState createState() => _InventarioDiaScreenState();
}

class _InventarioDiaScreenState extends State<InventarioDiaScreen> {
  final DateTime hoy = DateTime.now();
  bool esEditable = false;
  bool productosCargados = false;
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    verificarInventarioDelDia();
  }

  Future<void> verificarInventarioDelDia() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('inventario_dia')
            .doc(_formatearFecha(hoy))
            .get();

    if (doc.exists) {
      productos = List<Map<String, dynamic>>.from(doc['productos']);
      productosCargados = true;
      esEditable = doc['estado'] == 'abierto';

      // Si el día está abierto, sincroniza con los productos nuevos de la colección 'productos'
      if (esEditable) {
        final snapshot =
            await FirebaseFirestore.instance.collection('productos').get();
        final productosFirestore =
            snapshot.docs.map((doc) => doc.data()).toList();

        // Agrega productos nuevos que no estén en el inventario del día
        for (final prod in productosFirestore) {
          final existe = productos.any((p) => p['nombre'] == prod['nombre']);
          if (!existe) {
            productos.add({
              'nombre': prod['nombre'],
              'categoria': prod['categoria'],
              'unidad': prod['unidad'],
              'cantidad': prod['cantidad'] ?? 0,
              'horaIngreso': Timestamp.now(),
              'salida': 0,
              'horaSalida': null,
            });
          }
        }

        // Guarda la lista actualizada si hubo cambios
        await FirebaseFirestore.instance
            .collection('inventario_dia')
            .doc(_formatearFecha(hoy))
            .update({'productos': productos});
      }
    }

    setState(() {});
  }

  Future<void> cargarProductosPredeterminados() async {
    if (productosCargados) return;
    final snapshot =
        await FirebaseFirestore.instance.collection('productos').get();

    productos =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'nombre': data['nombre'],
            'categoria': data['categoria'],
            'unidad': data['unidad'],
            'cantidad': data['cantidad'] ?? 0, // <-- usa la cantidad original
            'horaIngreso': Timestamp.now(),
            'salida': 0,
            'horaSalida': null,
          };
        }).toList();

    await FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(_formatearFecha(hoy))
        .set({
          'fecha': Timestamp.now(),
          'estado': 'abierto',
          'productos': productos,
        });

    productosCargados = true;
    esEditable = true;
    setState(() {});
  }

  Future<void> guardarCambiosInventario() async {
    await FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(_formatearFecha(hoy))
        .update({'productos': productos});
  }

  Future<void> cerrarInventarioDelDia() async {
    await FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(_formatearFecha(hoy))
        .update({'estado': 'cerrado'});
    esEditable = false;
    setState(() {});
  }

  void actualizarCantidad(int index, int nuevaCantidad) {
    productos[index]['cantidad'] = nuevaCantidad;
    productos[index]['horaIngreso'] =
        Timestamp.now(); // <-- guarda la hora de edición
    setState(() {});
  }

  void registrarSalida(int index, int salida) {
    productos[index]['salida'] = salida;
    productos[index]['horaSalida'] = Timestamp.now();
    setState(() {});
  }

  String _formatearFecha(DateTime fecha) =>
      "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario del Día')),
      body: Column(
        children: [
          if (!productosCargados)
            ElevatedButton(
              onPressed: cargarProductosPredeterminados,
              child: const Text('Cargar Productos Predeterminados'),
            ),
          Expanded(
            child:
                productos.isEmpty
                    ? const Center(
                      child: Text('No hay productos cargados hoy.'),
                    )
                    : ListView.builder(
                      itemCount: productos.length,
                      itemBuilder: (context, index) {
                        final p = productos[index];
                        return ListTile(
                          title: Text(p['nombre']),
                          subtitle: Text('${p['categoria']} - ${p['unidad']}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Cant: ${p['cantidad']}'),
                              Text('Salida: ${p['salida']}'),
                              if (esEditable)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _editarCantidad(index);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle),
                                      onPressed: () {
                                        _registrarSalida(index);
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          if (esEditable)
            ElevatedButton(
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
        ],
      ),
    );
  }

  void _editarCantidad(int index) {
    final controller = TextEditingController(
      text: productos[index]['cantidad'].toString(),
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar cantidad'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final nuevaCantidad = int.tryParse(controller.text);
                  if (nuevaCantidad != null) {
                    actualizarCantidad(index, nuevaCantidad);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _registrarSalida(int index) {
    final controller = TextEditingController(
      text: productos[index]['salida'].toString(),
    );
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Registrar salida'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final salida = int.tryParse(controller.text);
                  if (salida != null &&
                      salida <= productos[index]['cantidad']) {
                    registrarSalida(index, salida);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }
}
