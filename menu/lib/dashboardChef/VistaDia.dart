import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';
import 'package:menu/dashboardChef/inventario.dart';
import 'package:menu/dashboardChef/HistorialInventario.dart';

// Tema de colores elegantes e innovadores
const Color kPrimaryColor = Color.fromARGB(255, 5, 118, 211);
const Color kAccentColor = Color.fromARGB(255, 25, 118, 210);
const Color kBackgroundColor = Color.fromARGB(255, 227, 227, 227);
const Color kErrorColor = Color(0xFFE57373);
const Color kTextPrimary = Color(0xFF263238);

class ProductoInventario {
  String id;
  String nombre;
  String categoria;
  int cantidad;
  String unidad;
  String? imagenUrl;
  DateTime? fecha;

  ProductoInventario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    this.imagenUrl,
    this.fecha,
  });

  factory ProductoInventario.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductoInventario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      cantidad: data['cantidad'] ?? 0,
      unidad: data['unidad'] ?? '',
      imagenUrl: data['imagenUrl'],
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
    );
  }
}

class VistaDiaScreen extends StatefulWidget {
  @override
  _VistaDiaScreenState createState() => _VistaDiaScreenState();
}

class _VistaDiaScreenState extends State<VistaDiaScreen> {
  List<ProductoInventario> productos = [];
  bool inventarioGuardado = false;
  DateTime fechaSeleccionada = DateTime.now();

  bool esEditable = false;
  bool productosCargados = false;
  List<Map<String, dynamic>> productosInventario = [];
  String busqueda = '';
  String filtroCategoria = 'Todos';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    verificarInventarioDelDia();
    cargarProductos();
  }

  // ...existing code...

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
      // Es un nuevo día: restablece todas las unidades a 0
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();

      productosInventario =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'nombre': data['nombre'] ?? '',
              'categoria': data['categoria'] ?? '',
              'unidad': data['unidad'] ?? '',
              'cantidad': 0, // <-- Aquí se restablece a 0
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
  // ...existing code...

  Future<void> guardarCambiosInventario() async {
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);
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
                          'Cantidad': cantidad,
                          'fecha': Timestamp.fromDate(fechaSeleccionada),
                        });

                    Navigator.pop(context);
                    setState(() {});
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

  List<String> get categorias {
    final setCategorias = <String>{'Todos'};
    setCategorias.addAll(
      productos.map((e) => e.categoria).where((c) => c.isNotEmpty),
    );
    final lista = setCategorias.toList();
    lista.sort();
    return lista;
  }

  List<ProductoInventario> get productosFiltrados {
    return productos.where((p) {
      final coincideBusqueda = p.nombre.toLowerCase().contains(
        busqueda.toLowerCase(),
      );
      final coincideCategoria =
          filtroCategoria == 'Todos' || p.categoria == filtroCategoria;
      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar producto...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => setState(() => busqueda = value),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: kAccentColor,
              value:
                  categorias.contains(filtroCategoria)
                      ? filtroCategoria
                      : 'Todos',
              onChanged:
                  (value) =>
                      setState(() => filtroCategoria = value ?? 'nombre'),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              hint: const Text('Filtrar por categoría'),
              items:
                  categorias
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
            ),
          ),
        ],
      ),
      body:
          productosFiltrados.isEmpty
              ? const Center(child: Text('No hay productos disponibles'))
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final p = productosFiltrados[index];
                  return FutureBuilder<int>(
                    future: calcularStock(p.id),
                    builder: (context, snapshot) {
                      final stock = snapshot.data ?? 0;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                p.imagenUrl != null
                                    ? Image.network(
                                      p.imagenUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.fastfood,
                                      size: 40,
                                      color: kAccentColor,
                                    ),
                          ),
                          title: Text(
                            p.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Stock Actual: $stock ${p.unidad} - ${p.categoria}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing:
                              esEditable
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
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
                                        icon: const Icon(
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
                        ),
                      );
                    },
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Día'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Historial'),
        ],
        currentIndex: 0,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            // Ya estás en Día, no hacer nada
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Inventario()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistorialInventarioScreen(),
              ),
            );
          }
        },
      ),
      floatingActionButton:
          esEditable
              ? Padding(
                padding: const EdgeInsets.only(bottom: 60.0),
                child: FloatingActionButton.extended(
                  backgroundColor: kPrimaryColor,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar y Cerrar Día'),
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
                ),
              )
              : null,
    );
  }
}
