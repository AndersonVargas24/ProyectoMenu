import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class EditarComandaView extends StatefulWidget {
  final String comandaId;

  const EditarComandaView({super.key, required this.comandaId});

  @override
  State<EditarComandaView> createState() => _EditarComandaViewState();
}

class _EditarComandaViewState extends State<EditarComandaView> with TickerProviderStateMixin {
  Map<String, dynamic>? comandaData;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> editingItems = [];
  double totalComanda = 0.0;
  List<DocumentSnapshot> _menuItems = [];
  final PanelController _panelController = PanelController();
  late TabController _tabController;
  List<DocumentSnapshot> _platos = [];
  List<DocumentSnapshot> _bebidas = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComandaData();
    _cargarMenuItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarMenuItems() async {
    FirebaseFirestore.instance.collection('menu').snapshots().listen((snapshot) {
      setState(() {
        _menuItems = snapshot.docs;
        _platos = _menuItems.where((item) => item['tipo'] == 'Plato').toList();
        _bebidas = _menuItems.where((item) => item['tipo'] == 'Bebida').toList();
      });
    });
  }

  Future<void> _loadComandaData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('comandas')
          .doc(widget.comandaId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          comandaData = snapshot.data()!;
          editingItems = (comandaData!['items'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .toList();
          _calculateTotal();
          isLoading = false;
        });
        print('Datos de la comanda cargados: $comandaData');
      } else {
        setState(() {
          errorMessage = 'No se encontró la comanda con ID: ${widget.comandaId}';
          isLoading = false;
        });
        print(errorMessage);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar la comanda: $e';
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  void _calculateTotal() {
    totalComanda = editingItems.fold(0.0, (sum, item) => sum + (item['precio'] * item['cantidad']));
  }

  void _updateItemQuantity(int index, int newQuantity) {
    if (newQuantity >= 0) {
      setState(() {
        editingItems[index]['cantidad'] = newQuantity;
        _calculateTotal();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      editingItems.removeAt(index);
      _calculateTotal();
    });
  }

  void _anadirItem(Map<String, dynamic> menuItem) {
    setState(() {
      final existingItemIndex = editingItems.indexWhere((item) => item['nombre'] == menuItem['nombre']);
      if (existingItemIndex != -1) {
        editingItems[existingItemIndex]['cantidad'] = (editingItems[existingItemIndex]['cantidad'] as int) + 1;
      } else {
        editingItems.add({...menuItem, 'cantidad': 1});
      }
      _calculateTotal();
    });
    if (!_panelController.isPanelOpen) {
      _panelController.open();
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('comandas')
          .doc(widget.comandaId)
          .update({'items': editingItems, 'total': totalComanda});
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comanda actualizada con éxito.')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al guardar los cambios: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la comanda: $errorMessage')),
      );
    }
  }

  Widget _buildMenuItemCard(DocumentSnapshot itemSnap) {
    final item = itemSnap.data() as Map<String, dynamic>;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _anadirItem({...item, 'id': itemSnap.id}),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: item['imagen'] != null && item['imagen'].isNotEmpty
                    ? (item['imagen'].toString().startsWith('http')
                        ? Image.network(item['imagen'], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported))
                        : Image.asset(item['imagen'], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported)))
                    : Icon(item['tipo'] == 'Plato' ? Icons.restaurant : Icons.local_drink, size: 60),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nombre'] ?? 'Nombre no disponible', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('\$${item['precio']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item['descripcion'] ?? '', overflow: TextOverflow.ellipsis, maxLines: 2),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, color: Colors.green, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(int index) {
    final item = editingItems[index];
    return ListTile(
      title: Text(item['nombre'] ?? 'Nombre no disponible'),
      subtitle: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => _updateItemQuantity(index, (item['cantidad'] as int) - 1),
          ),
          Text('${item['cantidad'] ?? 0}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _updateItemQuantity(index, (item['cantidad'] as int) + 1),
          ),
          const Spacer(),
          Text('\$${(item['precio'] * (item['cantidad'] as int)).toStringAsFixed(2)}'),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoading
            ? 'Cargando Comanda...'
            : comandaData?['numeroComanda'] != null
                ? 'Editar Comanda #${comandaData!['numeroComanda']}'
                : 'Editar Comanda'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          else if (comandaData != null)
            SlidingUpPanel(
              controller: _panelController,
              minHeight: editingItems.isEmpty ? 0 : 100,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              panel: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ítems en la Comanda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: editingItems.isEmpty
                          ? const Center(child: Text('No hay ítems en la comanda.'))
                          : ListView.builder(
                              itemCount: editingItems.length,
                              itemBuilder: (context, index) => _buildOrderItem(index),
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('\$${totalComanda.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Guardar Cambios', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Platos'),
                      Tab(text: 'Bebidas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _platos.isEmpty
                            ? const Center(child: Text('No hay platos disponibles.'))
                            : ListView.builder(
                                itemCount: _platos.length,
                                itemBuilder: (context, index) => _buildMenuItemCard(_platos[index]),
                              ),
                        _bebidas.isEmpty
                            ? const Center(child: Text('No hay bebidas disponibles.'))
                            : ListView.builder(
                                itemCount: _bebidas.length,
                                itemBuilder: (context, index) => _buildMenuItemCard(_bebidas[index]),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}