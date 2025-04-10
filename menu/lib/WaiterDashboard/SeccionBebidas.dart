import 'package:flutter/material.dart';

class SeccionBebidas extends StatefulWidget {
  const SeccionBebidas({super.key});

  @override
  State<SeccionBebidas> createState() => _SeccionBebidasState();
}

class _SeccionBebidasState extends State<SeccionBebidas> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sección Bebidas'),
    );
  }
}