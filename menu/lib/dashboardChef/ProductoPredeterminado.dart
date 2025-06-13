import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosPredeterminadosScreen extends StatefulWidget {
  const ProductosPredeterminadosScreen({super.key});

  @override
  State<ProductosPredeterminadosScreen> createState() =>
      _ProductosPredeterminadosScreenState();
}

class _ProductosPredeterminadosScreenState
    extends State<ProductosPredeterminadosScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _categoriaSeleccionada;
  List<String> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final snapshot = await _firestore.collection('categorias').get();
    setState(() {
      _categorias =
          snapshot.docs.map((doc) => doc['nombre'] as String).toList();
    });
  }

  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty || _categoriaSeleccionada == null) return;

    await _firestore.collection('productos_predeterminados').add({
      'nombre': nombre,
      'categoria': _categoriaSeleccionada,
    });

    _nombreController.clear();
    setState(() {});
  }
  Future<String?> _mostrarDialogoAgregarCategoria() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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

  Future<void> _eliminarProducto(String id) async {
    await _firestore.collection('productos_predeterminados').doc(id).delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos Predeterminados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del producto',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  
                  value: _categoriaSeleccionada,
                  hint: const Text('Selecciona una categoría'),
                  items:
                      _categorias
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _categoriaSeleccionada = val;
                    });
                  },
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
                            if (!_categorias.contains(
                              nuevaCategoria,
                            )) {
                              _categorias.add(nuevaCategoria);
                            }
                            _categoriaSeleccionada = nuevaCategoria;
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
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _guardarProducto,
                  child: const Text('Agregar producto'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('productos_predeterminados')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final productos = snapshot.data!.docs;
                if (productos.isEmpty) {
                  return const Center(
                    child: Text('No hay productos predeterminados.'),
                  );
                }
                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final doc = productos[index];
                    final nombre = doc['nombre'];
                    final categoria = doc['categoria'];
                    return ListTile(
                      title: Text(nombre),
                      subtitle: Text('Categoría: $categoria'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _eliminarProducto(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
