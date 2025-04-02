
import 'package:flutter/material.dart';

class LoginMenu extends StatefulWidget {
  const LoginMenu({super.key});

  @override
  State<LoginMenu> createState() => _LoginMenuState();
}

class _LoginMenuState extends State<LoginMenu> {

  final username = TextEditingController();
  final password = TextEditingController();
  bool isvisible = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [

                //Username
                SizedBox(
                  width: 400,
                  height: 290,
                  child:               
                Image.asset(
                  'lib/assets/LogoLogin.png',
                  fit: BoxFit.cover,  // Ajusta la imagen al tamaño del contenedor                                       
                )
            ),
                const SizedBox(height: 1),
                Container(
                  margin: EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person),
                      border: InputBorder.none,
                      hintText: "Username",
                    ),
                  ),
                ),

                //Password
                 Container(
                   margin: EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // ignore: deprecated_member_use
                    color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                  child: TextFormField(
                    obscureText: !isvisible,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.lock),
                      border: InputBorder.none,
                      hintText: "Password",
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isvisible = !isvisible; //boton de visibilidad contraseña
                          });
                        }, icon: Icon(isvisible? Icons.visibility: Icons.visibility_off))),
                  ),
                ),
                const SizedBox(height: 10),
                //Login Button
                Container(
                  height: 55,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(255, 16, 60, 134) 
                  ),
                  child: TextButton(
                    onPressed: () {}, 
                  child: Text("LOGIN", style: TextStyle(color: Colors.white ),
                  )),
                  ),

                  //sing up bottom

              ],
            ),
          ),
        ),
      ),
    );
  }
}