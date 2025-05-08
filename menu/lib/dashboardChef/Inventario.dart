import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/dashboardChef/EditarProducto.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class ProductoInventario {
  String id;
  String nombre;
  String categoria;
  int cantidad;
  String unidad;
  String? imagenUrl;

  ProductoInventario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.cantidad,
    required this.unidad,
    this.imagenUrl,
  });

  factory ProductoInventario.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductoInventario(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      cantidad: data['cantidad'] ?? 0,
      unidad: data['unidad'] ?? '',
      imagenUrl: data['imagenUrl'],
    );
  }
}

class Inventario extends StatefulWidget {
  @override
  _InventarioState createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  List<ProductoInventario> productos = [];
  String filtroCategoria = 'Todos';
  String busqueda = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final snapshot = await FirebaseFirestore.instance.collection('productos').get();
    setState(() {
      productos = snapshot.docs.map((doc) => ProductoInventario.fromDocument(doc)).toList();
    });
  }

  Future<void> agregarProducto() async {
    String nombre = '';
    String categoria = '';
    int cantidad = 0;
    String unidad = '';
    File? imagen;
    String? imagenUrl;

    final nombreController = TextEditingController();
    final categoriaController = TextEditingController();
    final cantidadController = TextEditingController();
    final unidadController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Agregar producto'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nombreController, decoration: InputDecoration(labelText: 'Nombre')),
              TextField(controller: categoriaController, decoration: InputDecoration(labelText: 'Categoría')),
              TextField(controller: cantidadController, decoration: InputDecoration(labelText: 'Cantidad'), keyboardType: TextInputType.number),
              TextField(controller: unidadController, decoration: InputDecoration(labelText: 'Unidad')),
              ElevatedButton(
                onPressed: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => imagen = File(picked.path));
                  }
                },
                child: Text('Seleccionar imagen'),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              nombre = nombreController.text;
              categoria = categoriaController.text;
              cantidad = int.tryParse(cantidadController.text) ?? 0;
              unidad = unidadController.text;

              if (imagen != null) {
                final ref = FirebaseStorage.instance.ref().child('productos/${DateTime.now().millisecondsSinceEpoch}.jpg');
                await ref.putFile(imagen!);
                imagenUrl = await ref.getDownloadURL();
              }

              final doc = await FirebaseFirestore.instance.collection('productos').add({
                'nombre': nombre,
                'categoria': categoria,
                'cantidad': cantidad,
                'unidad': unidad,
                'imagenUrl': imagenUrl,
              });

              setState(() {
                productos.add(ProductoInventario(
                  id: doc.id,
                  nombre: nombre,
                  categoria: categoria,
                  cantidad: cantidad,
                  unidad: unidad,
                  imagenUrl: imagenUrl,
                ));
              });

              Navigator.pop(context);
            },
            child: Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> categorias = ['Todos', ...productos.map((e) => e.categoria).toSet()];
    List<ProductoInventario> productosFiltrados = productos.where((p) {
      final coincideBusqueda = p.nombre.toLowerCase().contains(busqueda.toLowerCase());
      final coincideCategoria = filtroCategoria == 'Todos' || p.categoria == filtroCategoria;
      return coincideBusqueda && coincideCategoria;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PrincipalChef()),
            );
          },
        ),
        title: TextField(
          decoration: InputDecoration(hintText: 'Buscar producto...'),
          onChanged: (value) => setState(() => busqueda = value),
        ),
        actions: [
          DropdownButton<String>(
            value: filtroCategoria,
            onChanged: (value) => setState(() => filtroCategoria = value ?? 'Todos'),
            items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: productosFiltrados.length,
        itemBuilder: (context, index) {
          final p = productosFiltrados[index];
          return ListTile(
            leading: p.imagenUrl != null
                ? Image.network(p.imagenUrl!, width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.fastfood),
            title: Text(p.nombre),
            subtitle: Text('${p.cantidad} ${p.unidad} - ${p.categoria}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarProductoScreen(
                      productoId: p.id,
                      productoData: {
                        'nombre': p.nombre,
                        'categoria': p.categoria,
                        'unidad': p.unidad,
                        'imagenUrl': p.imagenUrl,
                      },
                    ),
                  ),
                );
                cargarProductos(); // actualiza la lista al volver
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarProducto,
        child: Icon(Icons.add),
      ),
    );
  }
}