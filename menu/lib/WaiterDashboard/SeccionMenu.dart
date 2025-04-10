import 'package:flutter/material.dart';

class SeccionMenu extends StatefulWidget {
  const SeccionMenu({super.key});

  @override
  State<SeccionMenu> createState() => _SeccionMenuState();
}

class _SeccionMenuState extends State<SeccionMenu> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text ('Sección Menú'));
  }
}