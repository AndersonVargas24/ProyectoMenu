import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeccionMenu extends StatelessWidget {
  const SeccionMenu({super.key});

  void _anadirAComanda(BuildContext context, String nombrePlato) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plato "$nombrePlato" añadido a la comanda')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección del Menú"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('menu')
            .where('tipo', isEqualTo: 'Plato')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay platos disponibles"));
          }

          var platos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              var plato = platos[index];

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
                      child: plato['imagen'] != ''
                          ? (plato['imagen'].toString().startsWith('http')
                              ? Image.network(
                                  plato['imagen'],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  plato['imagen'],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ))
                          : const Icon(Icons.image, size: 100),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plato['nombre'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Precio: \$${plato['precio']}'),
                            const SizedBox(height: 6),
                            Text(
                              plato['descripcion'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _anadirAComanda(context, plato['nombre']);
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
          );
        },
      ),
    );
  }
}