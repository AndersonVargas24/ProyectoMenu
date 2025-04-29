import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class SeccionCreateComanda extends StatefulWidget {
  const SeccionCreateComanda({super.key});

  @override
  State<SeccionCreateComanda> createState() => _SeccionCreateComandaState();
}

class _SeccionCreateComandaState extends State<SeccionCreateComanda> {
  final PanelController _panelController = PanelController();
  final List<String> _comanda = [];

  void _agregarProducto(String producto) {
    setState(() {
      _comanda.add(producto);
    });
    _panelController.open();
  }

  void _enviarComanda() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comanda enviada')),
    );
    setState(() {
      _comanda.clear();
    });
    _panelController.close();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Crear Comanda"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Principalwaiter()),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text("Platos disponibles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                for (var i = 1; i <= 5; i++)
                  Card(
                    child: ListTile(
                      title: Text("Producto $i"),
                      trailing: Icon(Icons.add),
                      onTap: () => _agregarProducto("Producto $i"),
                    ),
                  ),
              ],
            ),
            SlidingUpPanel(
              controller: _panelController,
              minHeight: 0,
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              panel: Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Comanda Actual',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _comanda.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_comanda[index]),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _enviarComanda,
                      child: Text('Enviar Pedido'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
