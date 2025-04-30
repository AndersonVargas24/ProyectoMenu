import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class SeccionCreateComanda extends StatefulWidget {
  const SeccionCreateComanda({super.key});

  @override
  State<SeccionCreateComanda> createState() => _SeccionCreateComandaState();
}

class _SeccionCreateComandaState extends State<SeccionCreateComanda> {
  final PanelController _panelController = PanelController();
  final List<Map<String, dynamic>> _comanda = []; // Lista para almacenar los items de la comanda (con nombre y otros detalles si es necesario)

  void _agregarProducto(DocumentSnapshot productoSnapshot) {
    setState(() {
      _comanda.add({
        'id': productoSnapshot.id,
        'nombre': productoSnapshot['nombre'],
        'precio': productoSnapshot['precio'],
        // Puedes agregar más detalles si los necesitas
      });
    });
    _panelController.open();
  }

  void _enviarComanda() {
    if (_comanda.isNotEmpty) {
      // Aquí implementarías la lógica para enviar la comanda
      // Por ejemplo, guardar los items de _comanda en Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comanda enviada con ${_comanda.length} items')),
      );
      setState(() {
        _comanda.clear();
      });
      _panelController.close();
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
                          trailing: Text('\$${item['precio'].toStringAsFixed(2)}'),
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
