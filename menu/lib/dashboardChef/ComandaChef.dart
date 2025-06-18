import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:menu/WaiterDashboard/SeccionMenu.dart'; 


class Comandachef extends StatelessWidget {
  const Comandachef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], 
      appBar: AppBar(
        title: const Text(
          'Comandas Pendientes y en Preparación',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blue[700], // Color principal azul
        elevation: 0, // Sin sombra para un look más minimalista
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comandas')
            .where('estado', whereIn: ['pendiente', 'preparando'])
            .orderBy('numeroComanda', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            print('Error al cargar las comandas: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar las comandas.',
                    style: TextStyle(fontSize: 18, color: Colors.red[400]),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.blue[300], size: 70),
                  const SizedBox(height: 20),
                  Text(
                    '¡No hay comandas pendientes o en preparación!',
                    style: TextStyle(fontSize: 20, color: Colors.blue[700], fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Relájate y espera nuevas órdenes.',
                    style: TextStyle(fontSize: 16, color: Colors.blue[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          print('Se recibieron ${snapshot.data!.docs.length} documentos.');

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

              List<dynamic> items = data['items'];
              DateTime fechaCreacion = (data['fecha_creacion'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion);
              final String nombreMesero = data['usuario_creador_nombre'] ?? 'Usuario Desconocido';
              final int numeroComanda = data['numeroComanda'] is int ? data['numeroComanda'] : 0;
              final String nombreComanda = data['nombreComanda'] ?? 'Comanda #$numeroComanda';
              final String comentario = data['comentario'] ?? '';

              double totalComanda = items.fold(0.0, (sum, item) => sum + (item['precio'] * item['cantidad']));

              return _ComandaCard(
                documentId: document.id,
                formattedDate: formattedDate,
                items: items,
                estado: data['estado'],
                totalComanda: totalComanda,
                nombreMesero: nombreMesero,
                numeroComanda: numeroComanda,
                nombreComanda: nombreComanda,
                comentario: comentario,
                comandaData: data, // Pasamos toda la data de la comanda
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
  final String nombreComanda;
  final String comentario;
  final String horaEntrega;
  
  final Map<String, dynamic> comandaData; // Agregamos toda la de la comanda

  _ComandaCard({
    required this.documentId,
    required this.formattedDate,
    required this.items,
    required this.estado,
    required this.totalComanda,
    required this.nombreMesero,
    required this.numeroComanda,
    required this.nombreComanda,
    required this.comentario,
    required this.comandaData,
  }) : horaEntrega = comandaData['horaEntrega'] ?? '';

  // Método para cambiar estado a preparando
  void _cambiarAPreparando(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Cambiar estado', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: const Text('¿Cambiar el estado de esta comanda a "Preparando"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmar'),
              onPressed: () {
                // Cambiar estado en Firestore
                FirebaseFirestore.instance
                    .collection('comandas')
                    .doc(documentId)
                    .update({'estado': 'preparando'})
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Estado cambiado a "Preparando"'),
                      backgroundColor: Colors.orange[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cambiar estado: $error'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  // Método para cambiar estado a listo
  void _cambiarAListo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Cambiar estado', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: const Text('¿Cambiar el estado de esta comanda a "Listo"?'),
          actions: [
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirmar'),
              onPressed: () {
                // Cambiar estado en Firestore
                FirebaseFirestore.instance
                    .collection('comandas')
                    .doc(documentId)
                    .update({'estado': 'listo'})
                    .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Estado cambiado a "Listo"'),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop();
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cambiar estado: $error'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(10),
                    ),
                  );
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          print('Tarjeta de comanda con ID: $documentId tocada.');
        },
        borderRadius: BorderRadius.circular(18.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_outlined, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        nombreComanda,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      estado.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    backgroundColor: _getEstadoColor(estado),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha: $formattedDate',
                          style: TextStyle(fontSize: 14, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    if (horaEntrega.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Hora de entrega: $horaEntrega',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.orange[900], 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Creada por: $nombreMesero',
                          style: TextStyle(fontSize: 14, color: Colors.blue[900], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Mostrar comentario si existe
              if (comentario.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.comment, color: Colors.amber[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Comentario:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 26.0),
                        child: Text(
                          comentario,
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              Text(
                'Detalles de la Orden:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[800]),
              ),
              const SizedBox(height: 12.0),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${item['nombre']}',
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${item['cantidad']}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                            ),
                          ),

                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 30, thickness: 1),

              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 2,
                    ),
                    onPressed: () => _cambiarAPreparando(context),
                    child: const Text('Preparación', style: TextStyle(fontSize: 15)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 2,
                    ),
                    onPressed: () => _cambiarAListo(context),
                    child: const Text('Listo', style: TextStyle(fontSize: 15)),
                  ),
                ],
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
        return Colors.blue[600]!;
      case 'listo':
        return Colors.green[600]!;
      case 'entregado':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
