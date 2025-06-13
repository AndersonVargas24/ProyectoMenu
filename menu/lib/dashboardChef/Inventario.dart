import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu/dashboardChef/EditarProducto.dart';
import 'package:menu/dashboardChef/InventarioDia.dart';
import 'package:menu/dashboardChef/VistaDia.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  List<String> unidadesDisponibles = [];
  String unidadSeleccionada = 'Unidad';
  String busqueda = '';
  final ImagePicker _picker = ImagePicker();
  DateTime? filtroFecha;
  int _currentIndex = 0;
  bool isLoading = true;
  bool estaConectado = true;
  bool esInventarioDia = false;

  // NUEVO: Inicializar inventario del día
  Future<void> inicializarInventarioDelDia() async {
    final hoy = DateTime.now();
    final fechaDoc =
        "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
    final inventarioDiaRef = FirebaseFirestore.instance
        .collection('inventario_dia')
        .doc(fechaDoc);

    final doc = await inventarioDiaRef.get();

    // Obtener productos base
    final productosSnapshot =
        await FirebaseFirestore.instance.collection('productos').get();
    List<Map<String, dynamic>> productosHoy = [];

    if (doc.exists) {
      // Si ya existe el documento del día, solo agrega productos nuevos si no existen
      final data = doc.data() as Map<String, dynamic>;
      final productosExistentes = List<Map<String, dynamic>>.from(
        data['productos'] ?? [],
      );
      productosHoy = List<Map<String, dynamic>>.from(productosExistentes);

      for (final productoDoc in productosSnapshot.docs) {
        final dataProd = productoDoc.data();
        final yaExiste = productosExistentes.any(
          (p) => p['nombre'] == dataProd['nombre'],
        );
        if (!yaExiste) {
          productosHoy.add({
            'nombre': dataProd['nombre'] ?? '',
            'categoria': dataProd['categoria'] ?? '',
            'unidad': dataProd['unidad'] ?? '',
            'cantidad': 0,
            'horaIngreso': Timestamp.now(),
            'salida': 0,
            'horaSalida': null,
          });
        }
      }
      await inventarioDiaRef.update({'productos': productosHoy});
    } else {
      // Si no existe el documento, crea uno nuevo con todos los productos en 0
      productosHoy =
          productosSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'nombre': data['nombre'] ?? '',
              'categoria': data['categoria'] ?? '',
              'unidad': data['unidad'] ?? '',
              'cantidad': 0,
              'horaIngreso': Timestamp.now(),
              'salida': 0,
              'horaSalida': null,
            };
          }).toList();

      await inventarioDiaRef.set({
        'fecha': Timestamp.now(),
        'productos': productosHoy,
        'estado': 'abierto',
      });
    }
    esInventarioDia = true;
    setState(() {});
  }

  cargarProductos() async {
    setState(() {
      isLoading = true;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();
      productos =
          snapshot.docs
              .map((doc) => ProductoInventario.fromDocument(doc))
              .toList();
    } catch (e) {
      print('Error al cargar productos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar productos')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
    inicializarInventarioDelDia(); // <-- Llama aquí
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
    cargarUnidades();
  }

  Future<void> verificarConexion() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      estaConectado = result != ConnectivityResult.none;
    });
  }

  Future<void> cargarCategorias() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categorias').get();
    final nuevasCategorias =
        snapshot.docs
            .map((doc) => doc['nombre'] as String)
            .where((nombre) => nombre.isNotEmpty)
            .toSet()
            .toList();

    setState(() {
      categoriasDisponibles = nuevasCategorias; // Solo categorías reales
      // Si quieres, puedes mantener la lógica del filtro aparte
      if (!categoriasDisponibles.contains(categoriaSeleccionada)) {
        categoriaSeleccionada =
            categoriasDisponibles.isNotEmpty ? categoriasDisponibles.first : '';
      }
    });
  }

  Future<void> cargarUnidades() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('U_medida').get();
    setState(() {
      unidadesDisponibles =
          snapshot.docs
              .map((doc) => doc['unidad'] as String)
              .where((u) => u.isNotEmpty)
              .toList();
      if (unidadesDisponibles.isNotEmpty) {
        unidadSeleccionada = unidadesDisponibles.first;
      }
    });
  }

  Future<void> agregarProducto() async {
    String nombre = '';
    String categoria = '';
    String unidad = '';
    File? imagen;
    String? imagenUrl;

    final nombreController = TextEditingController();

    // Inicializa la unidad seleccionada correctamente
    if (unidadesDisponibles.isNotEmpty &&
        (unidadSeleccionada.isEmpty ||
            !unidadesDisponibles.contains(unidadSeleccionada))) {
      unidadSeleccionada = unidadesDisponibles.first;
    } else if (unidadesDisponibles.isEmpty) {
      unidadSeleccionada = '';
    }

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
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          categoria = value;
                        });
                      }
                    },
                    items:
                        categoriasDisponibles
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                  ),
                  DropdownButtonFormField<String>(
                    value:
                        unidadesDisponibles.contains(unidadSeleccionada)
                            ? unidadSeleccionada
                            : null,
                    hint: const Text('Selecciona una unidad'),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          unidadSeleccionada = value;
                          unidad = value;
                        });
                      }
                    },
                    items:
                        unidadesDisponibles
                            .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)),
                            )
                            .toList(),
                  ),
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
                  //categoria = categoriaController.text;
                  //cantidad = 0;

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
                        'cantidad': 0,
                        'unidad': unidadSeleccionada,
                        'imagenUrl': imagenUrl,
                        'fecha': FieldValue.serverTimestamp(),
                      });

                  setState(() {
                    productos.add(
                      ProductoInventario(
                        id: doc.id,
                        nombre: nombre,
                        categoria: categoria,
                        cantidad: 0,
                        unidad: unidadSeleccionada,
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
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
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
    final theme = Theme.of(context);
    if (isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kBackgroundColor,
          title: const Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

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
            hintStyle: const TextStyle(color: Colors.white70),
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: productosFiltrados.length,
        itemBuilder: (context, index) {
          final p = productosFiltrados[index];

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
                '${p.cantidad} ${p.unidad} - ${p.categoria}',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: kErrorColor),
                onPressed: () => _eliminarProducto(p),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: agregarProducto,
        child: const Icon(Icons.add),
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
        currentIndex: 1,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VistaDiaScreen()),
            );
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
    );
  }
}
