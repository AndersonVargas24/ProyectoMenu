import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:menu/dashboardChef/EditarPlato.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Autehtentication/login.dart';

class MenuChef extends StatefulWidget {
  const MenuChef({super.key});

  @override
  State<MenuChef> createState() => _SeccionMenuState();
}

class _SeccionMenuState extends State<MenuChef> {
  String _filtro = 'TODO';

  Future<void> _confirmarEliminarPlato(String itemId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar plato?'),
        content: const Text('Esta acción no se puede deshacer. ¿Estás seguro de que deseas eliminar este plato?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('menu').doc(itemId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plato eliminado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección del Menú"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // Esta línea quita la flecha
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
                    backgroundColor: _filtro == 'TODO' ? const Color.fromARGB(255, 33, 150, 243) : Colors.grey[300],
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay ítems en el menú"));
          }

          List<DocumentSnapshot> allItems = snapshot.data!.docs;
          List<DocumentSnapshot> filteredItems = _filtro == 'TODO'
              ? allItems
              : allItems.where((item) => item['tipo'] == _filtro).toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text("No hay ítems en esta categoría"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index].data() as Map<String, dynamic>;
              final itemId = filteredItems[index].id;

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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditarPlatoPage(itemId: itemId),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _confirmarEliminarPlato(itemId),
                                  ),
                                ],
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
          );
        },
      ),
    );
  }
}