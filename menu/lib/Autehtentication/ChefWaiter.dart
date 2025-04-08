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
      appBar: AppBar(title: Text("Selecciona tu rol")),
  
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagen 1
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Principalchef()),
                );
              },
              child: Image.asset(
                'lib/assets/chef.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 40),
            // Imagen 2
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Principalwaiter()),
                );
              },
              child: Image.asset(
                'lib/assets/Waiter.png',
                width: 200,
                height: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}