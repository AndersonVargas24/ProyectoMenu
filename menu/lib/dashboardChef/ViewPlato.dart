import 'package:flutter/material.dart';

class ViewPlato extends StatefulWidget {
  const ViewPlato({super.key});

  @override
  State<ViewPlato> createState() => _ViewPlatoState();
}

class _ViewPlatoState extends State<ViewPlato> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      color: Colors.red,
      fallbackHeight: 200,
      fallbackWidth: 200,
      strokeWidth: 2,
      child: Text("View Plato"),
    );
  }
}