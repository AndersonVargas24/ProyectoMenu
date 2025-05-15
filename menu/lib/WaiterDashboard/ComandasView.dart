import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'EditarComanda.dart'; // Importa la pantalla EditarComandaView

class ComandasView extends StatelessWidget {
  const ComandasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Un fondo más suave
      appBar: AppBar(
        title: const Text(
          'Comandas Pendientes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.deepPurple, // Un color más vibrante para el AppBar
        elevation: 0, // Sin sombra en el AppBar para un look más plano
        iconTheme: const IconThemeData(color: Colors.white), // Color de los íconos del AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comandas')
            .where('estado', isEqualTo: 'pendiente')
            .orderBy('numeroComanda', descending: true) // Intentando ordenar por numeroComanda
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Error al cargar las comandas: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Error al cargar las comandas.',
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.assignment_turned_in_outlined, color: Colors.grey, size: 50),
                  SizedBox(height: 10),
                  Text(
                    '¡No hay comandas pendientes en este momento!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Relájate y espera nuevas órdenes.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          print('Se recibieron ${snapshot.data!.docs.length} documentos.');

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

              print('Datos del documento ${document.id}: $data'); // Imprimir todos los datos del documento

              List<dynamic> items = data['items'];
              DateTime fechaCreacion = (data['fecha_creacion'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion);
              final String nombreMesero = data['usuario_creador_nombre'] ?? 'Usuario Desconocido';
              final int numeroComanda = data['numeroComanda'] is int ? data['numeroComanda'] : 0; // Seguridad al acceder a numeroComanda

              double totalComanda = items.fold(0.0, (sum, item) => sum + (item['precio'] * item['cantidad']));

              return _ComandaCard(
                documentId: document.id,
                formattedDate: formattedDate,
                items: items,
                estado: data['estado'],
                totalComanda: totalComanda,
                nombreMesero: nombreMesero,
                numeroComanda: numeroComanda, // Usando el número de comanda
              );
            },
          );
        },
      ),
    );
  }
}

class _ComandaCard extends StatelessWidget {
  final String documentId;
  final String formattedDate;
  final List<dynamic> items;
  final String estado;
  final double totalComanda;
  final String nombreMesero;
  final int numeroComanda;

  const _ComandaCard({
    required this.documentId,
    required this.formattedDate,
    required this.items,
    required this.estado,
    required this.totalComanda,
    required this.nombreMesero,
    required this.numeroComanda,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: () {
          print('Tarjeta de comanda con ID: $documentId tocada.');
        },
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comanda # $numeroComanda', // Mostrar el número de comanda
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  Chip(
                    label: Text(
                      estado.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    backgroundColor: _getEstadoColor(estado),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Fecha: $formattedDate',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Creada por: $nombreMesero',
                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12.0),
              const Text(
                'Detalles de la Orden:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8.0),
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['nombre']} (x${item['cantidad']})',
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      Text(
                        '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const Divider(height: 25, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                  ),
                  Text(
                    '\$${totalComanda.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple),
                  ),
                ],
              ),
              const SizedBox(height: 15.0),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Editar Comanda', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditarComandaView(comandaId: documentId),
                      ),
                    );
                    print('Navegar a la edición de comanda con ID: $documentId');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orangeAccent;
      case 'preparando':
        return Colors.blueAccent;
      case 'listo':
        return Colors.green;
      case 'entregado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

//mesero@gmail.com