import 'package:flutter/material.dart';
import 'package:menu/WaiterDashboard/CrearComanda.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Importamos la librería para formatear fechas

class ViewComanda extends StatefulWidget {
  const ViewComanda({super.key});

  @override
  State<ViewComanda> createState() => _ViewComandaState();
}

class _ViewComandaState extends State<ViewComanda> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sección Comandas"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navegar a crear comanda
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CrearComanda()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('comandas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay comandas existentes.'));
          }

          final List<DocumentSnapshot> comandas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: comandas.length,
            itemBuilder: (context, index) {
              final comanda = comandas[index];
              final items = comanda['items'] as List<dynamic>;
              final Timestamp timestamp = comanda['fecha_creacion'] as Timestamp;
              final DateTime fechaCreacion = timestamp.toDate();
              final String horaMinutos = DateFormat('HH:mm').format(fechaCreacion); // Formateamos la hora y minutos
              final estado = comanda['estado'];

              return Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 3, // Añadimos un poco de sombra para más estética
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Bordes redondeados
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Comanda #${index + 1}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(estado.toUpperCase(), style: const TextStyle(color: Colors.white)),
                            backgroundColor: estado == 'pendiente' ? Colors.orange : Colors.green, // Ejemplo de color según el estado
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Hora: $horaMinutos', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) => Text('- ${item['nombre']} (${item['cantidad']})')).toList(),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {
                            // Navegar a la pantalla de edición de la comanda
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditarComandaPage(comandaId: comanda.id),
                              ),
                            );
                          },
                          child: const Text('Ver Detalles', style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditarComandaPage extends StatelessWidget {
  final String comandaId;

  const EditarComandaPage({super.key, required this.comandaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Comanda'),
      ),
      body: Center(
        child: Text('Pantalla para editar la comanda con ID: $comandaId'),
      ),
    );
  }
}