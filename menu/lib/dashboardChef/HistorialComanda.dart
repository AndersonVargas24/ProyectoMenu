import 'package:flutter/material.dart';

class HistorialComanda extends StatefulWidget {
  const HistorialComanda({super.key});

  @override
  State<HistorialComanda> createState() => _HistorialComandaState();
}

class _HistorialComandaState extends State<HistorialComanda> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder(
      color: Colors.red,
      fallbackHeight: 200,
      fallbackWidth: 200,
      strokeWidth: 2,
      child: Text("Historial Comanda"),
    );
  }
}