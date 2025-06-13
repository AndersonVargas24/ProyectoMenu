import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:menu/dashboardChef/ComandaChef.dart';
import 'package:menu/dashboardChef/CreacionMenu.dart';
import 'package:menu/dashboardChef/HistorialComanda.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/MenuChef.dart';
// import 'package:menu/dashboardChef/ComandaChef.dart'; // Ensure this import is correct

class PrincipalChef extends StatefulWidget {
  final int currentIndex;
  const PrincipalChef({super.key, this.currentIndex = 0});

  @override
  State<PrincipalChef> createState() => _PrincipalChefState();
}

class _PrincipalChefState extends State<PrincipalChef> {
  late int _selectedIndex;
  String _rolUsuario = "Cargando rol..."; // More informative initial state

  final List<Widget> _pages = <Widget>[
    const MenuChef(),
    const CreacionMenu(),
    const Comandachef(),
    const HistorialComanda(),
    Inventario(), // Inventario is a StatefulWidget, consider making it const if possible
  ];

  final List<DrawerItem> _drawerItems = [
    DrawerItem(
      icon: Icons.restaurant_menu,
      title: "Menú",
      subtitle: "Ver platos disponibles",
    ),
    DrawerItem(

      icon: Icons.add_circle_outline,
      title: "Crear Plato",
      subtitle: "Añadir nuevo elemento",
    ),
    DrawerItem(
      icon: Icons.receipt_long,
      title: "Comandas",
      subtitle: "Pedidos activos",
    ),
    DrawerItem(
      icon: Icons.history,
      title: "Historial",
      subtitle: "Comandas anteriores",
    ),
    DrawerItem(
      icon: Icons.inventory_2,
      title: "Inventario",
      subtitle: "Gestionar productos",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _fetchUserRole(); // Renamed for clarity
  }

  // Renamed the function for better semantics and added debugPrint
  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        if (data != null && data.containsKey('rol')) {
          setState(() {
            // Capitalize the first letter of the role for better display
            String fetchedRol = data['rol'];
            _rolUsuario = "Hola, ${fetchedRol[0].toUpperCase()}${fetchedRol.substring(1)}";
          });
        } else {
          setState(() {
            _rolUsuario = "Hola, Usuario"; // Default if role not found
          });
        }
      } catch (e) {
        debugPrint("⚠️ Error al obtener rol del usuario: $e");
        setState(() {
          _rolUsuario = "Error al cargar rol"; // Informative message on error
        });
      }
    } else {
      setState(() {
        _rolUsuario = "No autenticado"; // For unauthenticated state
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Close the drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Chef"), // More specific title
        backgroundColor: const Color.fromARGB(255, 67, 126, 236),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 117, 182, 219),
                    Color.fromARGB(255, 74, 84, 143),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _rolUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Panel de Control",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _drawerItems.length,
                itemBuilder: (context, index) {
                  final item = _drawerItems[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.orange.shade50 : Colors.transparent,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color.fromARGB(255, 117, 182, 219),
                            )
                          : null,
                      onTap: () => _onItemTapped(index),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () => _logoutAndRedirect(context), // Call the new internal method
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Cerrar Sesión",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final String subtitle;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// Global function for logout and redirection (now named _logoutAndRedirect for clarity)
// This function needs to be outside the _PrincipalChefState class, or be a static method.
// I've moved it to be a global function here as it was previously.
Future<void> _logoutAndRedirect(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final rol = data != null ? data['rol'] : null;

      await FirebaseAuth.instance.signOut();

      // Ensure navigation correctly clears the stack
      if (rol == 'Chef') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginMenu()),
          (Route<dynamic> route) => false, // Clears all previous routes
        );
      } else if (rol == 'Admin') {
        // Assuming ChefWaiter is the main login/role selection screen for Admin
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChefWaiter()),
          (Route<dynamic> route) => false, // Clears all previous routes
        );
      } else {
        // Default fallback if role is not recognized or null
        debugPrint("⚠️ Rol no reconocido o nulo al cerrar sesión. Redirigiendo a ChefWaiter.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesión cerrada. Rol no reconocido.")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChefWaiter()),
          (Route<dynamic> route) => false, // Clears all previous routes
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error cerrando sesión o obteniendo rol: $e");
      // Fallback in case of any error during logout process
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cerrar sesión. Intente de nuevo.")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChefWaiter()),
        (Route<dynamic> route) => false, // Clears all previous routes
      );
    }
  } else {
    // If somehow user is null, still redirect to the main login/role selection
    debugPrint("⚠️ Usuario nulo al intentar cerrar sesión. Redirigiendo a ChefWaiter.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChefWaiter()),
      (Route<dynamic> route) => false, // Clears all previous routes
    );
  }
}