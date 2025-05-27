import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class SeccionMenu extends StatefulWidget {
  final Map<String, dynamic>? comandaParaEditar;
  
  const SeccionMenu({super.key, this.comandaParaEditar});

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
  String _nombreComanda = '';
  final TextEditingController _nombreComandaController = TextEditingController();
  
  // Variables para manejar la edición
  bool _esModoEdicion = false;
  String? _comandaIdParaEditar;

  @override
  void initState() {
    super.initState();
    _cargarMenuItems();
    _inicializarComanda();
  }

  @override
  void dispose() {
    _nombreComandaController.dispose();
    super.dispose();
  }

  Future<void> _inicializarComanda() async {
    if (widget.comandaParaEditar != null) {
      // Modo edición
      _esModoEdicion = true;
      _comandaIdParaEditar = widget.comandaParaEditar!['id'];
      
      setState(() {
        _siguienteNumeroComanda = widget.comandaParaEditar!['numeroComanda'] ?? 1;
        _nombreComanda = widget.comandaParaEditar!['nombreComanda'] ?? 'Comanda #$_siguienteNumeroComanda';
        _nombreComandaController.text = _nombreComanda;
        _comentario = widget.comandaParaEditar!['comentario'] ?? '';
        
        // Cargar los items existentes
        if (widget.comandaParaEditar!['items'] != null) {
          _itemsComanda = List<Map<String, dynamic>>.from(
            widget.comandaParaEditar!['items'].map((item) => {
              'nombre': item['nombre'],
              'precio': item['precio'],
              'cantidad': item['cantidad'],
              'id': item['producto_id'],
              'tipo': item['tipo'] ?? 'Plato', // Valor por defecto si no existe
              'descripcion': item['descripcion'] ?? '',
              'imagen': item['imagen'] ?? '',
            })
          );
        }
      });
      
      // Abrir el panel si hay items
      if (_itemsComanda.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _panelController.open();
        });
      }
    } else {
      // Modo creación
      await _cargarUltimoNumeroComanda();
    }
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
    
    setState(() {
      _nombreComanda = 'Comanda #$_siguienteNumeroComanda';
      _nombreComandaController.text = _nombreComanda;
    });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: const Text('¿Estás seguro de eliminar este item de la comanda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
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

  void _editarNombreComanda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar nombre de comanda', 
          style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: TextField(
          controller: _nombreComandaController,
          decoration: InputDecoration(
            hintText: 'Ingrese nombre de la comanda',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.blue[50],
            prefixIcon: Icon(Icons.edit_note, color: Colors.blue[700]),
          ),
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _nombreComanda = _nombreComandaController.text.isNotEmpty 
                    ? _nombreComandaController.text 
                    : 'Comanda #$_siguienteNumeroComanda';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('La comanda está vacía'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      return;
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final username = await _getUsername(user?.uid);

      final comandaData = {
        'numeroComanda': _siguienteNumeroComanda,
        'nombreComanda': _nombreComanda,
        'items': _itemsComanda.map((item) => {
          'nombre': item['nombre'],
          'precio': item['precio'],
          'cantidad': item['cantidad'],
          'producto_id': item['id'] ?? null,
          'tipo': item['tipo'] ?? 'Plato',
          'descripcion': item['descripcion'] ?? '',
          'imagen': item['imagen'] ?? '',
        }).toList(),
        'fecha_creacion': _esModoEdicion 
            ? widget.comandaParaEditar!['fecha_creacion'] 
            : DateTime.now(),
        'fecha_modificacion': _esModoEdicion ? DateTime.now() : null,
        'estado': _esModoEdicion 
            ? widget.comandaParaEditar!['estado'] 
            : 'pendiente',
        'usuario_creador_uid': _esModoEdicion 
            ? widget.comandaParaEditar!['usuario_creador_uid'] 
            : user?.uid,
        'usuario_creador_nombre': _esModoEdicion 
            ? widget.comandaParaEditar!['usuario_creador_nombre'] 
            : username,
        'usuario_modificador_uid': _esModoEdicion ? user?.uid : null,
        'usuario_modificador_nombre': _esModoEdicion ? username : null,
        'comentario': _comentario,
        'total': _calcularTotalComanda(),
      };

      if (_esModoEdicion && _comandaIdParaEditar != null) {
        // Actualizar comanda existente
        await FirebaseFirestore.instance
            .collection('comandas')
            .doc(_comandaIdParaEditar)
            .update(comandaData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comanda actualizada exitosamente'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      } else {
        // Crear nueva comanda
        await FirebaseFirestore.instance.collection('comandas').add(comandaData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comanda creada exitosamente'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }

      // Navegar hacia atrás después de guardar
      Navigator.pop(context, true); // Retorna true para indicar que se guardó exitosamente
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al ${_esModoEdicion ? "actualizar" : "crear"} la comanda: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
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
  title: Text(
    _esModoEdicion ? "Editar Comanda" : "Sección del Menú", 
    style: const TextStyle(
      color: Colors.white, 
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  backgroundColor: Colors.blue[700],
  foregroundColor: Colors.white,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(15),
    ),
  ),
  leading: null,
  automaticallyImplyLeading: false, // 👈 esto quita la flecha por completo
  actions: [],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(60.0),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['TODO', 'Plato', 'Bebida'].map((tipo) {
          return ElevatedButton(
            onPressed: () => setState(() => _filtro = tipo),
            style: ElevatedButton.styleFrom(
              backgroundColor: _filtro == tipo ? Colors.white : Colors.blue[600],
              foregroundColor: _filtro == tipo ? Colors.blue[700] : Colors.white,
              elevation: _filtro == tipo ? 3 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              tipo == 'TODO' ? 'TODO' : '${tipo.toUpperCase()}S',
              style: TextStyle(
                fontWeight: _filtro == tipo ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  ),
),
      body: Container(
        color: Colors.blue[50],
        child: Stack(
          children: [
            _menuItems.isEmpty
                ? Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    strokeWidth: 3,
                  ))
                : filteredMenuItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, color: Colors.blue[300], size: 70),
                            const SizedBox(height: 20),
                            Text(
                              "No hay items en esta categoría",
                              style: TextStyle(fontSize: 18, color: Colors.blue[700]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
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
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: imagen != ''
                                        ? (imagen.startsWith('http')
                                            ? Image.network(imagen, width: 100, height: 100, fit: BoxFit.cover)
                                            : Image.asset(imagen, width: 100, height: 100, fit: BoxFit.cover))
                                        : Icon(
                                            tipo == 'Plato' ? Icons.restaurant : Icons.local_drink, 
                                            size: 50, 
                                            color: Colors.blue[700],
                                          ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombre, 
                                          style: TextStyle(
                                            fontSize: 18, 
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800]
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[700],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '\$${precio.toString()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          descripcion, 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _anadirItem({...itemData, 'id': itemId}),
                                            icon: const Icon(Icons.add_shopping_cart),
                                            label: const Text("Añadir"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[600],
                                              foregroundColor: Colors.white,
                                              elevation: 2,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              minHeight: _itemsComanda.isEmpty ? 0 : 60,
              maxHeight: MediaQuery.of(context).size.height * 0.65,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, spreadRadius: 1)],
              panel: Container(
                color: Colors.white,
                child: Column(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: InkWell(
                        onTap: _editarNombreComanda,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue[200]!)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _nombreComanda,
                                  style: TextStyle(
                                    fontSize: 20, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Icon(Icons.edit, color: Colors.blue[700], size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _esModoEdicion ? Colors.orange[600] : Colors.blue[700],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _esModoEdicion ? 'Editando Comanda' : 'Items en Comanda',
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _itemsComanda.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.blue[200]),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No hay items en la comanda',
                                    style: TextStyle(fontSize: 16, color: Colors.blue[300]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _itemsComanda.length,
                              itemBuilder: (context, index) {
                                final item = _itemsComanda[index];
                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            item['tipo'] == 'Plato' ? Icons.restaurant_menu : Icons.local_drink,
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['nombre'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: Colors.blue[900],
                                                ),
                                              ),
                                              Text(
                                                '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove, size: 18, color: Colors.blue[700]),
                                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => _decrementarCantidad(index),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  '${item['cantidad']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.blue[800],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.add, size: 18, color: Colors.blue[700]),
                                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                                padding: EdgeInsets.zero,
                                                onPressed: () => _incrementarCantidad(index),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 24),
                                          onPressed: () => _eliminarItem(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '\$${_calcularTotalComanda().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Comentario (opcional)',
                          labelStyle: TextStyle(color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.blue[50],
                          prefixIcon: Icon(Icons.comment, color: Colors.blue[400]),
                        ),
                        onChanged: (value) => _comentario = value,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _guardarComanda,
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar Comanda', style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: Container(),
            ),
          ],
        ),
      ),
    );
  }
}
