import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeccionMenu extends StatelessWidget {
  const SeccionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección del Menú"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu')
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
            itemCount: platos.length,
            itemBuilder: (context, index) {
              var plato = platos[index];
              return ListTile(
                      leading: plato['imagen'] != ''
                    ? (plato['imagen'].toString().startsWith('http')
                      ? Image.network(plato['imagen'], width: 50, height: 50, fit: BoxFit.cover)
                      : Image.asset(plato['imagen'], width: 50, height: 50, fit: BoxFit.cover))
                  : const Icon(Icons.image, size: 50),
                title: Text(plato['nombre']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio: \$${plato['precio']}'),
                    Text('Descripción: ${plato['descripcion']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // lógica para añadir el plato a la comanda
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Plato ${plato['nombre']} añadido a la comanda')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}