import 'package:flutter/material.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class ChefWaiter extends StatefulWidget {
  const ChefWaiter({super.key});

  @override
  State<ChefWaiter> createState() => _ChefWaiterState();
}

class _ChefWaiterState extends State<ChefWaiter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selecciona tu rol")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen para CHEF
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PrincipalChef(currentIndex: 0)),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 2, 2, 2), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'lib/assets/chef.png', // Asegúrate que la imagen esté en ese path
                  width: 220,
                  height: 220,
                ),
              ),
            ),

            // Imagen para MESERO
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Principalwaiter()),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromARGB(255, 2, 2, 2), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'lib/assets/waiter.png',
                  width: 220,
                  height: 220
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}