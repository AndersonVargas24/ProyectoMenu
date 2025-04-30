import 'package:flutter/material.dart';
import 'package:menu/dashboardChef/CreacionMenu.dart';
import 'package:menu/dashboardChef/HistorialComanda.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/ViewPlato.dart';
import 'package:menu/dashboardChef/MenuChef.dart';
import 'package:menu/dashboardChef/ComandaChef.dart';
import 'Package:menu/dashboardChef/BebidaChef.dart';

class PrincipalChef extends StatefulWidget {
  const PrincipalChef({super.key});

  @override
  State<PrincipalChef> createState() => _PrincipalChefState();
}

class _PrincipalChefState extends State<PrincipalChef> {
  int _selectedIndex = 0;
  final List<Widget> _pages = <Widget>[
    const MenuChef(),
    const BebidaChef(),
    const CreacionMenu(),
    const ComandaChef(),
    const HistorialComanda(),
    Inventario(),
    const ViewPlato(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer después de seleccionar una opción
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chef")),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("Menú de Opciones"),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text("Menú"),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              title: Text("Bebidas"),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              title: Text("Crear Plato o Bebida"),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              title: Text("Comandas"),
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              title: Text("Historial de Comandas"),
              onTap: () => _onItemTapped(4),
            ),
            ListTile(
              title: Text("Inventario"),
              onTap: () => _onItemTapped(5),
            ),  
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}