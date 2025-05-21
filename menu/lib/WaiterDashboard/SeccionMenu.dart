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
  int _siguienteNumeroComanda = 1;
  String _comentario = '';

  @override
  void initState() {
    super.initState();
    _cargarMenuItems();
    _cargarUltimoNumeroComanda();
  }

  Future<void> _cargarUltimoNumeroComanda() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comandas')
        .orderBy('numeroComanda', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final last = snapshot.docs.first.data();
      if (last.containsKey('numeroComanda') && last['numeroComanda'] is int) {
        setState(() => _siguienteNumeroComanda = last['numeroComanda'] + 1);
      }
    }
  }

  void _cargarMenuItems() {
    FirebaseFirestore.instance.collection('menu').snapshots().listen((snapshot) {
      setState(() => _menuItems = snapshot.docs);
    });
  }

  List<DocumentSnapshot> get filteredMenuItems {
    return _filtro == 'TODO'
        ? _menuItems
        : _menuItems.where((item) => item['tipo'] == _filtro).toList();
  }

  void _anadirItem(Map<String, dynamic> menuItem) async {
    setState(() {
      final index = _itemsComanda.indexWhere((item) => item['nombre'] == menuItem['nombre']);
      if (index != -1) {
        _itemsComanda[index]['cantidad']++;
      } else {
        _itemsComanda.add({...menuItem, 'cantidad': 1});
      }
    });
    if (!_panelController.isPanelOpen) await _panelController.open();
  }

  void _incrementarCantidad(int index) {
    setState(() => _itemsComanda[index]['cantidad']++);
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

  void _eliminarItem(int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar item?'),
        content: const Text('¿Estás seguro de eliminar este item de la comanda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _itemsComanda.removeAt(index);
        if (_itemsComanda.isEmpty && _panelController.isPanelOpen) {
          _panelController.close();
        }
      });
    }
  }

  double _calcularTotalComanda() => _itemsComanda.fold(0, (total, item) => total + item['precio'] * item['cantidad']);

  Future<String> _getUsername(String? uid) async {
    if (uid == null) return 'Usuario Desconocido';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists && doc.data()?.containsKey('username') == true
          ? doc['username'] ?? 'Usuario Desconocido'
          : 'Usuario Desconocido';
    } catch (e) {
      debugPrint('Error al obtener el username: $e');
      return 'Usuario Desconocido';
    }
  }

  Future<void> _guardarComanda() async {
    if (_itemsComanda.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La comanda está vacía')));
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      final username = await _getUsername(user?.uid);

      await FirebaseFirestore.instance.collection('comandas').add({
        'numeroComanda': _siguienteNumeroComanda,
        'items': _itemsComanda.map((item) => {
          'nombre': item['nombre'],
          'precio': item['precio'],
          'cantidad': item['cantidad'],
          'producto_id': item['id'] ?? null,
        }).toList(),
        'fecha_creacion': DateTime.now(),
        'estado': 'pendiente',
        'usuario_creador_uid': user?.uid,
        'usuario_creador_nombre': username,
        'comentario': _comentario,
        'total': _calcularTotalComanda(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comanda creada exitosamente')));
      setState(() {
        _itemsComanda.clear();
        _comentario = '';
        _siguienteNumeroComanda++;
      });
      _panelController.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear la comanda: $e')));
    }
  }

  void _cerrarSesion() async {
    final user = FirebaseAuth.instance.currentUser;
    Widget destino = const LoginMenu();
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['rol'] == 'Admin') {
        destino = const ChefWaiter();
      }
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección del Menú", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['TODO', 'Plato', 'Bebida'].map((tipo) {
                return ElevatedButton(
                  onPressed: () => setState(() => _filtro = tipo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _filtro == tipo ? Colors.blue : Colors.grey[300],
                    foregroundColor: _filtro == tipo ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(tipo == 'TODO' ? 'TODO' : '${tipo.toUpperCase()}S'),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _menuItems.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filteredMenuItems.isEmpty
                  ? const Center(child: Text("No hay items en esta categoría"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final itemData = filteredMenuItems[index].data() as Map<String, dynamic>;
                        final itemId = filteredMenuItems[index].id;
                        final nombre = itemData['nombre'] ?? 'Sin nombre';
                        final precio = itemData['precio'] ?? 0;
                        final descripcion = itemData['descripcion'] ?? '';
                        final imagen = itemData['imagen'] ?? '';
                        final tipo = itemData['tipo'] ?? '';

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                child: imagen != ''
                                    ? (imagen.startsWith('http')
                                        ? Image.network(imagen, width: 100, height: 100, fit: BoxFit.cover)
                                        : Image.asset(imagen, width: 100, height: 100, fit: BoxFit.cover))
                                    : Icon(tipo == 'Plato' ? Icons.restaurant : Icons.local_drink, size: 100),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text('Precio: \$${precio.toString()}'),
                                      const SizedBox(height: 6),
                                      Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _anadirItem({...itemData, 'id': itemId}),
                                          icon: const Icon(Icons.add),
                                          label: const Text("Añadir a comanda"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(255, 183, 208, 246),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                Text('Comanda #${_siguienteNumeroComanda}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Items en Comanda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                                  IconButton(icon: const Icon(Icons.remove), onPressed: () => _decrementarCantidad(index)),
                                  Text('${item['cantidad']}'),
                                  IconButton(icon: const Icon(Icons.add), onPressed: () => _incrementarCantidad(index)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarItem(index)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Total: \$${_calcularTotalComanda().toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Comentario (opcional)'),
                    onChanged: (value) => _comentario = value,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _guardarComanda,
                          child: const Text('Guardar Comanda'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        ),
                      ),
                    ],
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
