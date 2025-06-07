import 'package:flutter/material.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/Usuario/PrincipalUsuario.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';



class ChefWaiter extends StatefulWidget {
  const ChefWaiter({super.key});

  @override
  State<ChefWaiter> createState() => _ChefWaiterState();
}

class _ChefWaiterState extends State<ChefWaiter> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  final List<Map<String, dynamic>> roles = [
    {
      'nombre': 'Chef',
      'imagen': 'lib/assets/chef.png',
      'onTap': () => {},
    },
    {
      'nombre': 'Mesero',
      'imagen': 'lib/assets/waiter.png',
      'onTap': () => {},
    },
    {
      'nombre': 'Usuario',
      'imagen': 'lib/assets/user.png',
      'onTap': () => {},
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asigna las funciones reales aquí para que usen context
    roles[0]['onTap'] = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PrincipalChef(currentIndex: 0)),
        );

    roles[1]['onTap'] = () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Principalwaiter()),
        );
    roles[2]['onTap'] = () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Principalusuario()),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginMenu()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Desliza para elegir tu rol ",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: roles.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final rol = roles[index];
                return GestureDetector(
                  onTap: rol['onTap'] as VoidCallback,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            rol['imagen'] as String,
                            width: 200,
                            height: 200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            rol['nombre'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: roles.length,
            effect: const WormEffect(
              dotHeight: 12,
              dotWidth: 12,
              activeDotColor: Colors.black,
              dotColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}