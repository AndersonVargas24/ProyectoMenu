import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BebidaChef extends StatelessWidget {
  const BebidaChef({super.key});

  // Función para eliminar un plato
  void _eliminarPlato(BuildContext context, String platoId) async {
    bool confirmacion = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta bebida?'),
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

    if (confirmacion) {
      try {
        await FirebaseFirestore.instance.collection('menu').doc(platoId).delete();
        // Verificar si el widget sigue montado antes de mostrar el SnackBar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('bebida eliminada correctamente')),
          );
        }
      } catch (e) {
        // En caso de error, muestra el mensaje correspondiente
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hubo un error al eliminar la bebida')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Chef"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menu')
            .where('tipo', isEqualTo: 'Bebida')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay Bebidas disponibles"));
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // Navegar a página de edición
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditarPlatoPage(platoId: plato.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _eliminarPlato(context, plato.id);
                      },
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

class EditarPlatoPage extends StatelessWidget {
  final String platoId;

  const EditarPlatoPage({super.key, required this.platoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Plato"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('menu').doc(platoId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No se pudo cargar la bebida"));
          }

          var plato = snapshot.data!;
          var nombreController = TextEditingController(text: plato['nombre']);
          var precioController = TextEditingController(text: plato['precio'].toString());
          var descripcionController = TextEditingController(text: plato['descripcion']);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('menu').doc(platoId).update({
                      'nombre': nombreController.text,
                      'precio': double.tryParse(precioController.text) ?? 0,
                      'descripcion': descripcionController.text,
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Guardar cambios"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}