import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'MenuUsuario.dart';

class ComandaUsuario extends StatelessWidget {
  const ComandaUsuario({super.key});

  // Obtener el usuario actual autenticado
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Verificar si el usuario está autenticado
    if (currentUser == null) {
      return _buildNotAuthenticated(context);
    }

    // DEBUG: Imprimir información del usuario
    print('Usuario actual: ${currentUser!.uid}');
    print('Email: ${currentUser!.email}');

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          'Mis Comandas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        actions: [
          // Botón de perfil/logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(currentUser?.email ?? 'Usuario'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // La consulta de StreamBuilder ya estaba bien, apuntando a la subcolección 'comandas'
        stream: FirebaseFirestore.instance
            .collection('ComandaUsuario')
            .doc(currentUser!.uid)
            .collection('comandas') 
            .orderBy('fecha_creacion', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // DEBUG: Agregar más información de debug
          print('ConnectionState: ${snapshot.connectionState}');
          print('HasError: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
          }
          print('HasData: ${snapshot.hasData}');
          if (snapshot.hasData) {
            print('Docs count: ${snapshot.data!.docs.length}');
            // Imprimir cada documento para debug
            for (var doc in snapshot.data!.docs) {
              print('Doc ID: ${doc.id}');
              print('Doc data: ${doc.data()}');
            }
          }

          if (snapshot.hasError) {
            print('Error en stream: ${snapshot.error}');
            return _buildError(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty(context);
          }

          // Filtrar manualmente por estado si es necesario
          List<DocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
            String estado = data['estado'] ?? '';
            // Mostrar solo las comandas con estados específicos (descomentar si es necesario)
            return ['pendiente', 'preparando', 'listo'].contains(estado); 
          }).toList();

          // Ordenar manualmente por fecha (si ya se usa orderBy en el stream, esto es redundante pero no causa daño)
          filteredDocs.sort((a, b) {
            Map<String, dynamic> dataA = a.data()! as Map<String, dynamic>;
            Map<String, dynamic> dataB = b.data()! as Map<String, dynamic>;
            
            Timestamp? timestampA = dataA['fecha_creacion'] as Timestamp?;
            Timestamp? timestampB = dataB['fecha_creacion'] as Timestamp?;
            
            if (timestampA == null && timestampB == null) return 0;
            if (timestampA == null) return 1;
            if (timestampB == null) return -1;
            
            return timestampB.compareTo(timestampA); // Descendente
          });

          if (filteredDocs.isEmpty) {
            return _buildEmpty(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = filteredDocs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

              List<dynamic> items = data['items'] ?? [];
              
              DateTime fechaCreacion;
              if (data['fecha_creacion'] != null) {
                fechaCreacion = (data['fecha_creacion'] as Timestamp).toDate();
              } else {
                fechaCreacion = DateTime.now(); // Fecha por defecto
              }
              
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion);
              final numeroComanda = data['numeroComanda'] ?? 0;
              final nombreComanda = data['nombreComanda'] ?? 'Comanda #$numeroComanda';
              final comentario = data['comentario'] ?? '';
              final metodoPago = data['metodoPago'] ?? 'No especificado';
              final estadoPago = data['estadoPago'] ?? 'pendiente';
              final estado = data['estado'] ?? 'pendiente';
              
              double totalComanda = 0.0;
              for (var item in items) {
                if (item is Map<String, dynamic>) {
                  double precio = (item['precio'] ?? 0).toDouble();
                  int cantidad = (item['cantidad'] ?? 0).toInt();
                  totalComanda += precio * cantidad;
                }
              }
              
              final horaEntrega = data['horaEntrega'] ?? '';

              return _ComandaCard(
                documentId: document.id,
                formattedDate: formattedDate,
                items: items,
                estado: estado,
                totalComanda: totalComanda,
                numeroComanda: numeroComanda,
                nombreComanda: nombreComanda,
                comentario: comentario,
                metodoPago: metodoPago,
                estadoPago: estadoPago,
                comandaData: data,
                currentUserId: currentUser!.uid,
                horaEntrega: horaEntrega,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuUsuario()),
          );
        },
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Comanda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, color: Colors.blue[400], size: 80),
            const SizedBox(height: 20),
            Text(
              'Debes iniciar sesión',
              style: TextStyle(fontSize: 24, color: Colors.blue[700], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Para ver tus comandas personales',
              style: TextStyle(fontSize: 16, color: Colors.blue[400]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
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
          const SizedBox(height: 10),
          // Mostrar error específico para debug
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $error',
              style: TextStyle(fontSize: 12, color: Colors.red[300]),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar recarga
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando tus comandas...',
            style: TextStyle(fontSize: 16, color: Colors.blue[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.blue[300], size: 80),
          const SizedBox(height: 20),
          Text(
            '¡No tienes comandas activas!',
            style: TextStyle(fontSize: 22, color: Colors.blue[700], fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Haz tu primera orden desde el menú',
            style: TextStyle(fontSize: 16, color: Colors.blue[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MenuUsuario()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            ),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Ver Menú', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          // Botón de debug para verificar conexión
          ElevatedButton(
            onPressed: () {
              _testFirebaseConnection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Test Conexión Firebase'),
          ),
        ],
      ),
    );
  }

  // Método para probar la conexión
  void _testFirebaseConnection() async {
    try {
      print('Probando conexión a Firebase...');
      
      // Verificar usuario actual
      User? user = FirebaseAuth.instance.currentUser;
      print('Usuario autenticado: ${user?.uid}');
      
      // Verificar colección principal ComandaUsuario
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ComandaUsuario')
          .limit(1)
          .get();
      
      print('Colección "ComandaUsuario" accesible: ${snapshot.docs.length} documentos encontrados directamente (posiblemente documentos de UID)');
      
      // Si el usuario está autenticado, intentar acceder a su subcolección 'comandas'
      if (user?.uid != null) {
        QuerySnapshot userComandasSnapshot = await FirebaseFirestore.instance
            .collection('ComandaUsuario')
            .doc(user!.uid)
            .collection('comandas')
            .limit(5) // Limitar para no leer demasiados
            .get();
        print('Subcolección "comandas" para UID ${user.uid} accesible: ${userComandasSnapshot.docs.length} documentos encontrados.');
        for (var doc in userComandasSnapshot.docs) {
          print('  - Comanda ID: ${doc.id}, Data: ${doc.data()}');
        }
      }
      
    } catch (e) {
      print('Error en test de conexión: $e');
    }
  }
}

// La clase _ComandaCard
class _ComandaCard extends StatelessWidget {
  final String documentId;
  final String formattedDate;
  final List<dynamic> items;
  final String estado;
  final double totalComanda;
  final int numeroComanda;
  final String nombreComanda;
  final String comentario;
  final String metodoPago;
  final String estadoPago;
  final String horaEntrega;
  final Map<String, dynamic> comandaData;
  final String currentUserId; // <-- Necesitamos pasar el UID del usuario aquí

  _ComandaCard({
    required this.documentId,
    required this.formattedDate,
    required this.items,
    required this.estado,
    required this.totalComanda,
    required this.numeroComanda,
    required this.nombreComanda,
    required this.comentario,
    required this.metodoPago,
    required this.estadoPago,
    required this.comandaData,
    required this.currentUserId, // <-- Añadir currentUserId al constructor
    required this.horaEntrega,
  });

  void _cancelarComanda(BuildContext context) {
    // Solo permitir cancelar si está en estado pendiente o preparando
    if (estado != 'pendiente' && estado != 'preparando') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No puedes cancelar esta comanda en su estado actual'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Cancelar Comanda', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro que deseas cancelar esta comanda?'),
            const SizedBox(height: 10),
            if (estadoPago == 'pagado')
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nota: Esta comanda ya fue pagada. Se procesará el reembolso.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('No, mantener', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, cancelar'),
            onPressed: () {
              // CORRECCIÓN CLAVE: Usar la ruta completa para la subcolección
              FirebaseFirestore.instance
                  .collection('ComandaUsuario')
                  .doc(currentUserId) // UID del usuario
                  .collection('comandas') // Nombre de la subcolección
                  .doc(documentId) // ID del documento de la comanda
                  .update({
                'estado': 'cancelado',
                'fecha_cancelacion': FieldValue.serverTimestamp(),
                'cancelado_por_usuario': true,
              }).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Comanda cancelada exitosamente'),
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
                    content: Text('Error al cancelar: $error'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12.0),
              _buildInfoBox(),
              const SizedBox(height: 16.0),
              if (comentario.isNotEmpty) _buildComentarioBox(),
              _buildPagoInfo(),
              _buildDetalleItems(),
              const Divider(height: 30, thickness: 1),
              _buildTotalYBotones(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_outlined, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              nombreComanda,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[700]),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(
                estado.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
              backgroundColor: _getEstadoColor(estado),
            ),
            if (estadoPago == 'pagado')
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: const Text(
                    'PAGADO',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  backgroundColor: Colors.green[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.calendar_today, 'Fecha: $formattedDate', Colors.blue[700]!),
          if (horaEntrega.isNotEmpty)
            _infoRow(Icons.access_time, 'Hora de entrega: $horaEntrega', Colors.orange[700]!),
          _infoRow(Icons.tag, 'Orden #$numeroComanda', Colors.blue[700]!),
        ],
      ),
    );
  }

  Widget _buildPagoInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estadoPago == 'pagado' ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estadoPago == 'pagado' ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                estadoPago == 'pagado' ? Icons.check_circle : Icons.payment,
                color: estadoPago == 'pagado' ? Colors.green[700] : Colors.orange[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Información de Pago',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estadoPago == 'pagado' ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.credit_card,
            'Método: $metodoPago',
            estadoPago == 'pagado' ? Colors.green[700]! : Colors.orange[700]!,
          ),
          _infoRow(
            Icons.info,
            'Estado: ${estadoPago == 'pagado' ? 'Pagado' : 'Pendiente de pago'}',
            estadoPago == 'pagado' ? Colors.green[700]! : Colors.orange[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildComentarioBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text('Comentario:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800])),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Text(
              comentario,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detalles de tu Orden:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[800])),
        const SizedBox(height: 12),
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
                        item['nombre'] ?? 'Producto',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('x${item['cantidad'] ?? 1}', style: TextStyle(color: Colors.blue[700])),
                    ),
                    const SizedBox(width: 10),
                    Text('\$${((item['precio'] ?? 0) * (item['cantidad'] ?? 1)).toStringAsFixed(2)}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalYBotones(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('\$${totalComanda.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Solo mostrar cancelar si está en estado apropiado
            if (estado == 'pendiente' || estado == 'preparando')
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[400],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _cancelarComanda(context),
              )
            else
              Container(), // Espacio vacío si no se puede cancelar

            // Botón de seguimiento/detalles
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outlined),
              label: const Text('Detalles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _mostrarDetallesCompletos(context);
              },
            ),
          ],
        ),
      ],
    );
  }
  
  // Mueve esta función aquí, dentro de la clase _ComandaCard
  Widget _buildInfoSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $item'),
          )).toList(),
        ],
      ),
    );
  }

  void _mostrarDetallesCompletos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Detalles Completos - $nombreComanda',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoSection('Estado de la Orden', [
                      'Estado actual: ${estado.toUpperCase()}',
                      'Fecha de creación: $formattedDate',
                      if (horaEntrega.isNotEmpty) 'Hora estimada: $horaEntrega',
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoSection('Información de Pago', [
                      'Método de pago: $metodoPago',
                      'Estado del pago: ${estadoPago == 'pagado' ? 'Pagado' : 'Pendiente'}',
                      'Total: \$${totalComanda.toStringAsFixed(2)}',
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoSection('Productos Ordenados',
                      items.map((item) =>
                        '${item['nombre']} x${item['cantidad']} - \$${((item['precio'] ?? 0) * (item['cantidad'] ?? 1)).toStringAsFixed(2)}'
                      ).toList()
                    ),
                    if (comentario.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoSection('Comentarios', [comentario]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: color))),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange[600]!;
      case 'preparando':
        return Colors.blue[600]!;
      case 'listo':
        return Colors.green[600]!;
      case 'entregado':
        return Colors.grey[600]!;
      case 'cancelado':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}