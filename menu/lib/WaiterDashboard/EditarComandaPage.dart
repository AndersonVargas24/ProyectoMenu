import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class EditarComandaPage extends StatefulWidget {
  final String comandaId;

  const EditarComandaPage({super.key, required this.comandaId});

  @override
  State<EditarComandaPage> createState() => _EditarComandaPageState();
}

class _EditarComandaPageState extends State<EditarComandaPage> {
  final PanelController _panelController = PanelController();
  List<Map<String, dynamic>> _comandaActual = []; // Lista para los items de la comanda actual

  @override
  void initState() {
    super.initState();
    _cargarDetallesComanda();
  }

  Future<void> _cargarDetallesComanda() async {
    try {
      DocumentSnapshot comandaSnapshot = await FirebaseFirestore.instance.collection('comandas').doc(widget.comandaId).get();
      if (comandaSnapshot.exists) {
        final data = comandaSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('items')) {
          setState(() {
            _comandaActual = List<Map<String, dynamic>>.from(data['items']);
          });
        }
      } else {
        // Manejar el caso en que la comanda no existe
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La comanda no existe')),
        );
        Navigator.pop(context); // Volver a la lista de comandas
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la comanda: $error')),
      );
      Navigator.pop(context);
    }
  }

  void _agregarProducto(DocumentSnapshot productoSnapshot) {
    final existingItemIndex = _comandaActual.indexWhere((item) => item['producto_id'] == productoSnapshot.id);
    setState(() {
      if (existingItemIndex != -1) {
        _comandaActual[existingItemIndex]['cantidad']++;
      } else {
        _comandaActual.add({
          'producto_id': productoSnapshot.id,
          'nombre': productoSnapshot['nombre'],
          'precio': productoSnapshot['precio'],
          'cantidad': 1,
        });
      }
    });
    _panelController.open();
  }

  void _aumentarCantidad(Map<String, dynamic> item) {
    setState(() {
      item['cantidad']++;
    });
  }

  void _disminuirCantidad(Map<String, dynamic> item) {
    setState(() {
      if (item['cantidad'] > 1) {
        item['cantidad']--;
      }
    });
  }

  void _eliminarProductoComanda(Map<String, dynamic> item) {
    setState(() {
      _comandaActual.remove(item);
    });
  }

  Future<void> _guardarCambiosComanda() async {
    try {
      await FirebaseFirestore.instance.collection('comandas').doc(widget.comandaId).update({
        'items': _comandaActual,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda actualizada')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la comanda: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Comanda'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('menu').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay platos disponibles"));
              }
              final List<DocumentSnapshot> menuItems = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final menuItem = menuItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(menuItem['nombre']),
                      subtitle: Text('\$${menuItem['precio'].toStringAsFixed(2)}'),
                      trailing: const Icon(Icons.add),
                      onTap: () => _agregarProducto(menuItem),
                    ),
                  );
                },
              );
            },
          ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 50,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panel: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comanda Actual',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _comandaActual.length,
                    itemBuilder: (context, index) {
                      final item = _comandaActual[index];
                      return ListTile(
                        title: Text(item['nombre']),
                        subtitle: Text('\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _disminuirCantidad(item),
                            ),
                            Text('${item['cantidad']}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _aumentarCantidad(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _eliminarProductoComanda(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _guardarCambiosComanda,
                    child: const Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
            body: Container(), // El StreamBuilder del menú está en la parte superior
          ),
        ],
      ),
    );
  }
}