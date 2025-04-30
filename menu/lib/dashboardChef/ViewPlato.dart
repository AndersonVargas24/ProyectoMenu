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
      color: Color.fromARGB(255, 145, 117, 115),
      fallbackHeight: 200,
      fallbackWidth: 200,
      strokeWidth: 2,
      child: Text("View Plato"),
    );
  }
}