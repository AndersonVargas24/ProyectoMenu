import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class CrearComanda extends StatefulWidget {
  const CrearComanda({super.key});

  @override
  State<CrearComanda> createState() => _CrearComandaState();
}

class _CrearComandaState extends State<CrearComanda> {
  final PanelController _panelController = PanelController();
  final List<Map<String, dynamic>> _comanda = []; // Lista para almacenar los items de la comanda (con id, nombre, precio y cantidad)

  void _agregarProducto(DocumentSnapshot productoSnapshot) {
    final existingItemIndex = _comanda.indexWhere((item) => item['id'] == productoSnapshot.id);
    setState(() {
      if (existingItemIndex != -1) {
        _comanda[existingItemIndex]['cantidad']++;
      } else {
        _comanda.add({
          'id': productoSnapshot.id,
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
      } else {
        // Si la cantidad es 1, al disminuirla se elimina el item
        _eliminarProductoComanda(item);
      }
    });
  }

  void _eliminarProductoComanda(Map<String, dynamic> item) {
    setState(() {
      _comanda.remove(item);
      if (_comanda.isEmpty) {
        _panelController.close();
      }
    });
  }

  Future<void> _enviarComanda() async {
    if (_comanda.isNotEmpty) {
      try {
        // Obtener la referencia a la colección de comandas
        CollectionReference comandasCollection = FirebaseFirestore.instance.collection('comandas');

        // Crear un nuevo documento para la comanda
        await comandasCollection.add({
          'items': _comanda.map((item) => {
                'producto_id': item['id'],
                'nombre': item['nombre'],
                'precio': item['precio'],
                'cantidad': item['cantidad'],
              }).toList(),
          'fecha_creacion': DateTime.now(),
          'estado': 'pendiente', // Puedes agregar un estado inicial para la comanda
          // Puedes agregar más información relevante para la comanda, como el mesero, la mesa, etc.
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda enviada exitosamente')),
        );
        setState(() {
          _comanda.clear();
        });
        _panelController.close();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la comanda: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La comanda está vacía')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Crear Comanda"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Principalwaiter()),
              );
            },
          ),
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
                    final nombre = menuItem['nombre'];
                    final precio = menuItem['precio'];
                    final imagen = menuItem['imagen'];
                    return Card(
                      child: ListTile(
                        leading: imagen != ''
                            ? Image.asset(imagen, width: 50, height: 50)
                            : const Icon(Icons.restaurant, size: 50),
                        title: Text(nombre),
                        subtitle: Text('Precio: \$${precio.toStringAsFixed(2)}'),
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
              minHeight: 0,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
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
                      itemCount: _comanda.length,
                      itemBuilder: (context, index) {
                        final item = _comanda[index];
                        return ListTile(
                          title: Text(item['nombre']),
                          subtitle: Text('\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  _disminuirCantidad(item);
                                },
                              ),
                              Text('${item['cantidad']}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _aumentarCantidad(item);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  _eliminarProductoComanda(item);
                                },
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
                      onPressed: _enviarComanda,
                      child: Text('Enviar Pedido (${_comanda.length} items)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}