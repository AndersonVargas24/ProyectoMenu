import 'package:flutter/material.dart';

class Inventario extends StatelessWidget {
   Inventario({super.key});

  final List<ProductoInventario> productos = [
    ProductoInventario(
      nombre: "Tomate",
      cantidad: "15 kg",
      estado: EstadoInventario.suficiente,
      imagen: "assets/tomate...", // Corregido
    ),
    ProductoInventario(
      nombre: "Pechuga de Pollo",
      cantidad: "5 kg",
      estado: EstadoInventario.bajo,
      imagen: "assets/pollo.jpeg",
    ),
    ProductoInventario(
      nombre: "Harina",
      cantidad: "0 kg",
      estado: EstadoInventario.agotado,
      imagen: "assets/harina.jpeg",
    ),
    ProductoInventario(
      nombre: "Agotado",
      cantidad: "Agotado",
      estado: EstadoInventario.agotado,
      imagen: "assets/agotado.jpeg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0), // Corregido
        child: GridView.builder(
          itemCount: productos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];
            return InventarioCard(producto: producto);
          },
        ),
      ),
    );
  }
}

class ProductoInventario {
  final String nombre;
  final String cantidad;
  final EstadoInventario estado;
  final String imagen;

  ProductoInventario({
    required this.nombre,
    required this.cantidad,
    required this.estado,
    required this.imagen,
  });
}

enum EstadoInventario { suficiente, bajo, agotado }

class InventarioCard extends StatelessWidget {
  final ProductoInventario producto;

  const InventarioCard({required this.producto, super.key});

  Color getEstadoColor(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.suficiente:
        return Colors.green.shade200;
      case EstadoInventario.bajo:
        return Colors.yellow.shade600;
      case EstadoInventario.agotado:
        return Colors.red.shade300;
    }
  }

  String getEstadoTexto(EstadoInventario estado) {
    switch (estado) {
      case EstadoInventario.suficiente:
        return "Suficiente";
      case EstadoInventario.bajo:
        return "Bajo";
      case EstadoInventario.agotado:
        return "Agotado";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                producto.imagen,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            producto.nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text("Cantidad: ${producto.cantidad}"),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: getEstadoColor(producto.estado),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getEstadoTexto(producto.estado),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Editar"),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}