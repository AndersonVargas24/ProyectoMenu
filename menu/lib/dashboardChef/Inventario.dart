import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:menu/dashboardChef/EditarProducto.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';
import 'package:menu/dashboardChef/VistaDia.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:menu/dashboardChef/HistorialInventario.dart';
import 'package:menu/dashboardChef/ProductoPredeterminado.dart';

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

class Inventario extends StatefulWidget {
  const Inventario({super.key});

  @override
  _InventarioState createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  List<String> categoriasDisponibles = ['todos'];
  String categoriaSeleccionada = 'Todos';
  List<ProductoInventario> productos = [];
  String filtroCategoria = 'Todos';
  String busqueda = '';
  final ImagePicker _picker = ImagePicker();
  DateTime? filtroFecha;
  int _currentIndex = 0;
  bool isLoading = true;
  bool estaConectado = true;

  void _eliminarProducto(ProductoInventario producto) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: Text('¿Estás seguro de eliminar "${producto.nombre}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      try {
        // Eliminar imagen de Firebase Storage si existe
        if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
          final ref = FirebaseStorage.instance.refFromURL(producto.imagenUrl!);
          await ref.delete();
        }

        // Eliminar documento de Firestore
        await FirebaseFirestore.instance
            .collection('productos')
            .doc(producto.id)
            .delete();
        // Eliminar localmente de la lista
        setState(() {
          productos.removeWhere((p) => p.id == producto.id);
        });
      } catch (e) {
        print('Error al eliminar producto o imagen: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el producto')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    verificarConexion();
    Connectivity().onConnectivityChanged.listen((result) {
      final conectado = result != ConnectivityResult.none;
      if (conectado != estaConectado) {
        setState(() {
          estaConectado = conectado;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              conectado ? 'Conectado a Internet' : 'Sin conexión a Internet',
            ),
            backgroundColor: conectado ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
    cargarProductos();
    cargarCategorias();
  }

  Future<void> verificarConexion() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      estaConectado = result != ConnectivityResult.none;
    });
  }

  Future<void> cargarProductosPredeterminados() async {
    final fechaHoy = DateTime.now();
    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaHoy);
    final inventarioRef = FirebaseFirestore.instance
        .collection('inventario')
        .doc(fechaStr);

    final docSnapshot = await inventarioRef.get();
    if (docSnapshot.exists) {
      // Inventario ya existe
      return;
    }

    final productosPredRef = FirebaseFirestore.instance.collection(
      'productos_predeterminados',
    );
    final snapshot = await productosPredRef.get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      final producto = doc.data();
      final productoRef = inventarioRef.collection('productos').doc();
      batch.set(productoRef, {
        'nombre': producto['nombre'],
        'categoria': producto['categoria'],
        'unidad': producto['unidad'],
        'cantidad': 0,
        'horaIngreso': FieldValue.serverTimestamp(),
        'salida': 0,
        'horaSalida': null,
        'saldo': 0,
      });
    }

    await batch.commit();
  }

  Future<void> cargarProductos() async {
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();
      setState(() {
        productos =
            snapshot.docs
                .map((doc) => ProductoInventario.fromDocument(doc))
                .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error al cargar productos: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> cargarCategorias() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categorias').get();
    final nuevasCategorias =
        snapshot.docs
            .map((doc) => doc['nombre'] as String)
            .toSet()
            .toList(); // Elimina duplicados
    setState(() {
      categoriasDisponibles = ['Todos', ...nuevasCategorias];
      if (!categoriasDisponibles.contains(categoriaSeleccionada)) {
        categoriaSeleccionada = 'Todos';
      }
    });
  }

  Future<String?> _mostrarDialogoAgregarCategoria() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nueva categoría'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Nombre de categoría',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> agregarProducto() async {
    String nombre = '';
    String categoria = '';
    int cantidad = 0;
    String unidad = '';
    File? imagen;
    String? imagenUrl;

    final nombreController = TextEditingController();
    final categoriaController = TextEditingController();
    final cantidadController = TextEditingController();
    final unidadController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Agregar producto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField(nombreController, 'Nombre'),
                  DropdownButtonFormField<String>(
                    value: categoria.isNotEmpty ? categoria : null,
                    hint: const Text('Selecciona una categoría'),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          categoria = value;
                        });
                      }
                    },
                    items:
                        categoriasDisponibles.where((c) => c != 'Todos').map((
                          cat,
                        ) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                  ),
                  TextButton(
                    onPressed: () async {
                      final nuevaCategoria =
                          await _mostrarDialogoAgregarCategoria();
                      if (nuevaCategoria != null && nuevaCategoria.isNotEmpty) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('categorias')
                              .add({'nombre': nuevaCategoria});
                          setState(() {
                            if (!categoriasDisponibles.contains(
                              nuevaCategoria,
                            )) {
                              categoriasDisponibles.add(nuevaCategoria);
                            }
                            categoriaSeleccionada = nuevaCategoria;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al agregar categoría'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Agregar nueva categoría'),
                  ),

                  _buildTextField(
                    cantidadController,
                    'Cantidad',
                    isNumber: true,
                  ),
                  _buildTextField(unidadController, 'Unidad'),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        imagen = File(picked.path);
                      }
                    },
                    child: const Text('Seleccionar imagen'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  nombre = nombreController.text;
                  categoria = categoriaController.text;
                  cantidad = int.tryParse(cantidadController.text) ?? 0;
                  unidad = unidadController.text;

                  if (imagen != null) {
                    final ref = FirebaseStorage.instance.ref().child(
                      'productos/${DateTime.now().millisecondsSinceEpoch}.jpg',
                    );
                    await ref.putFile(imagen!);
                    imagenUrl = await ref.getDownloadURL();
                  }

                  final doc = await FirebaseFirestore.instance
                      .collection('productos')
                      .add({
                        'nombre': nombre,
                        'categoria': categoria,
                        'cantidad': cantidad,
                        'unidad': unidad,
                        'imagenUrl': imagenUrl,
                        'fecha': FieldValue.serverTimestamp(),
                      });

                  setState(() {
                    productos.add(
                      ProductoInventario(
                        id: doc.id,
                        nombre: nombre,
                        categoria: categoria,
                        cantidad: cantidad,
                        unidad: unidad,
                        imagenUrl: imagenUrl,
                      ),
                    );
                  });

                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  TextField _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  List<ProductoInventario> get productosFiltrados {
    return productos.where((p) {
      final coincideBusqueda = p.nombre.toLowerCase().contains(
        busqueda.toLowerCase(),
      );
      final coincideCategoria =
          filtroCategoria == 'Todos' || p.categoria == filtroCategoria;
      final coincideFecha =
          filtroFecha == null ||
          (p.fecha != null &&
              p.fecha!.year == filtroFecha!.year &&
              p.fecha!.month == filtroFecha!.month &&
              p.fecha!.day == filtroFecha!.day);
      return coincideBusqueda && coincideCategoria && coincideFecha;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          decoration: const InputDecoration(hintText: 'Buscar producto...'),
          onChanged: (value) => setState(() => busqueda = value),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Inventario del día',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InventarioDiaScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_home_rounded),
            tooltip: 'Productos Predeterminados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductosPredeterminadosScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final fechaSeleccionada = await showDatePicker(
                context: context,
                initialDate: filtroFecha ?? DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
              );
              if (fechaSeleccionada != null) {
                setState(() => filtroFecha = fechaSeleccionada);
              }
            },
          ),
          DropdownButton<String>(
            value: filtroCategoria,
            onChanged:
                (value) => setState(() => filtroCategoria = value ?? 'Todos'),
            items:
                categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: productosFiltrados.length,
        itemBuilder: (context, index) {
          final p = productosFiltrados[index];
          return ListTile(
            leading:
                p.imagenUrl != null
                    ? Image.network(
                      p.imagenUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                    : const Icon(Icons.fastfood),
            title: Text(p.nombre),
            subtitle: Text('${p.cantidad} ${p.unidad} - ${p.categoria}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditarProductoScreen(
                              productoId: p.id,
                              productoData: {
                                'nombre': p.nombre,
                                'categoria': p.categoria,
                                'unidad': p.unidad,
                                'imagenUrl': p.imagenUrl,
                              },
                            ),
                      ),
                    );
                    if (result == true) {
                      cargarProductos();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarProducto(p),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarProducto,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Día'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Historial'),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VistaDiaScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
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
