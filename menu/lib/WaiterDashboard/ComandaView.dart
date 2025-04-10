import 'package:flutter/material.dart';

class ViewComanda extends StatefulWidget {
  const ViewComanda({super.key});

  @override
  State<ViewComanda> createState() => _ViewComandaState();
}

class _ViewComandaState extends State<ViewComanda> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sección Comandas'),
    );
  }
}