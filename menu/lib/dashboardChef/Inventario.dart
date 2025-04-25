import 'package:flutter/material.dart';

class Inventario extends StatefulWidget {
  const Inventario({super.key});

  @override
  State<Inventario> createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      color: Colors.red,
      fallbackHeight: 200,
      fallbackWidth: 200,
      strokeWidth: 2,
      child: Text("Inventario"),
    );
  }
}