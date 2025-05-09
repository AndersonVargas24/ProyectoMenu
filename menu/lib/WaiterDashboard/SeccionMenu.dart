import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class SeccionMenu extends StatefulWidget {
  const SeccionMenu({super.key});

  @override
  State<SeccionMenu> createState() => _SeccionMenuState();
}

class _SeccionMenuState extends State<SeccionMenu> {
  final PanelController _panelController = PanelController();
  List<Map<String, dynamic>> _itemsComanda = [];
  String _filtro = 'TODO';
  List<DocumentSnapshot> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _cargarMenuItems();
  }

  Future<void> _cargarMenuItems() async {
    FirebaseFirestore.instance.collection('menu').snapshots().listen((snapshot) {
      setState(() {
        _menuItems = snapshot.docs;
      });
    });
  }

  List<DocumentSnapshot> get _filteredMenuItems {
    if (_filtro == 'TODO') {
      return _menuItems;
    } else {
      return _menuItems.where((item) => item['tipo'] == _filtro).toList();
    }
  }

  void _anadirItem(Map<String, dynamic> menuItem) {
    setState(() {
      final existingItemIndex = _itemsComanda.indexWhere((item) => item['nombre'] == menuItem['nombre']);
      if (existingItemIndex != -1) {
        _itemsComanda[existingItemIndex]['cantidad']++;
      } else {
        _itemsComanda.add({...menuItem, 'cantidad': 1});
      }
    });
    if (!_panelController.isPanelOpen) {
      _panelController.open();
    }
  }

  void _incrementarCantidad(int index) {
    setState(() {
      _itemsComanda[index]['cantidad']++;
    });
  }

  void _decrementarCantidad(int index) {
    setState(() {
      if (_itemsComanda[index]['cantidad'] > 1) {
        _itemsComanda[index]['cantidad']--;
      } else {
        _itemsComanda.removeAt(index);
        if (_itemsComanda.isEmpty && _panelController.isPanelOpen) {
          _panelController.close();
        }
      }
    });
  }

  void _eliminarItem(int index) {
    setState(() {
      _itemsComanda.removeAt(index);
      if (_itemsComanda.isEmpty && _panelController.isPanelOpen) {
        _panelController.close();
      }
    });
  }

  double _calcularTotalComanda() {
    double total = 0;
    for (var item in _itemsComanda) {
      total += item['precio'] * item['cantidad'];
    }
    return total;
  }

  Future<void> _guardarComanda() async {
    if (_itemsComanda.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('comandas').add({
          'items': _itemsComanda.map((item) => {
                'nombre': item['nombre'],
                'precio': item['precio'],
                'cantidad': item['cantidad'],
                'producto_id': item.containsKey('id') ? item['id'] : null,
              }).toList(),
          'fecha_creacion': DateTime.now(),
          'estado': 'pendiente',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda creada exitosamente')),
        );
        setState(() {
          _itemsComanda.clear();
          _panelController.close();
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la comanda: $error')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección del Menú"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user != null) {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();

                final role = userDoc['rol'];

                if (role == 'Admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ChefWaiter()),
                  );
                } else if (role == 'Mesero') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginMenu()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginMenu()),
                  );
                }
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginMenu()),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtro = 'TODO';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filtro == 'TODO' ? Colors.blue : Colors.grey[300],
                    foregroundColor: _filtro == 'TODO' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('TODO'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtro = 'Plato';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filtro == 'Plato' ? Colors.blue : Colors.grey[300],
                    foregroundColor: _filtro == 'Plato' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('PLATILLOS'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtro = 'Bebida';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filtro == 'Bebida' ? Colors.blue : Colors.grey[300],
                    foregroundColor: _filtro == 'Bebida' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('BEBIDAS'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _menuItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _filteredMenuItems.isEmpty
                  ? const Center(child: Text("No hay items en esta categoría"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredMenuItems[index].data() as Map<String, dynamic>;
                        final itemId = _filteredMenuItems[index].id;
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                child: item['imagen'] != ''
                                    ? (item['imagen'].toString().startsWith('http')
                                        ? Image.network(
                                            item['imagen'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            item['imagen'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ))
                                    : Icon(item['tipo'] == 'Plato' ? Icons.restaurant : Icons.local_drink, size: 100),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['nombre'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Precio: \$${item['precio']}'),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['descripcion'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _anadirItem({...item, 'id': itemId});
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text("Añadir a comanda"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(255, 183, 208, 246),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: _itemsComanda.isEmpty ? 0 : 50,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            panel: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Items en Comanda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: _itemsComanda.isEmpty
                      ? const Center(child: Text('No hay items en la comanda'))
                      : ListView.builder(
                          itemCount: _itemsComanda.length,
                          itemBuilder: (context, index) {
                            final item = _itemsComanda[index];
                            return ListTile(
                              title: Text(item['nombre']),
                              subtitle: Text('Cantidad: ${item['cantidad']} - \$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _decrementarCantidad(index),
                                  ),
                                  Text('${item['cantidad']}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _incrementarCantidad(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _eliminarItem(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${_calcularTotalComanda().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _guardarComanda,
                    child: const Text('Guardar Comanda'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
            body: Container(),
          ),
        ],
      ),
    );
  }
}
