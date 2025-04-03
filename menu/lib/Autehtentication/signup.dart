import 'package:flutter/material.dart';
import 'package:menu/Autehtentication/login.dart';

class RegisterMenu extends StatefulWidget {
  const RegisterMenu({super.key});

  @override
  State<RegisterMenu> createState() => _RegisterMenuState();
}

class _RegisterMenuState extends State<RegisterMenu> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmpassword = TextEditingController();

  final formkey = GlobalKey<FormState>();
  bool isvisible = false;
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formkey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              
                //Register
                children: [
                  ListTile(
                    title: Text("Registrar nueva cuenta", style: TextStyle(fontSize:50, fontWeight: FontWeight.bold ),),                 
                  ),
                  Container(
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
                              color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                            child: TextFormField(
                              controller: username,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Por favor ingrese su nombre de usuario";
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                icon: Icon(Icons.person),
                                border: InputBorder.none,
                                hintText: "Username",
                              ),
                            ),
                          ),
                      
                          //Password
                           Container(
                             margin: const EdgeInsets.all(8),
                            padding: 
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
                              color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                            child: TextFormField(
                              controller: password,
                               validator: (value) {
                                if (value!.isEmpty) {
                                  return "Por favor ingrese su contraseña";
                                }
                                return null;
                              },
                              obscureText: !isvisible,
                              decoration: InputDecoration(
                                icon: const Icon(Icons.lock),
                                border: InputBorder.none,
                                hintText: "Contraseña",
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isvisible = !isvisible; //boton de visibilidad contraseña
                                    });
                                  }, icon: Icon(isvisible? Icons.visibility: Icons.visibility_off))),
                            ),
                          ),

                          //Confirm Password
                           Container(
                             margin: const EdgeInsets.all(8),
                            padding: 
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
                              color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                            child: TextFormField(
                              controller: confirmpassword,
                               validator: (value) {
                                if (value!.isEmpty) {
                                  return "Por favor ingrese su contraseña";
                                } else if (value != password.text) {
                                  return "Las contraseñas no coinciden";
                                }
                                return null;
                              },
                              obscureText: !isvisible,
                              decoration: InputDecoration(
                                icon: const Icon(Icons.lock),
                                border: InputBorder.none,
                                hintText: " Confirmar contraseña",
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
                      onPressed: () {
                        if (formkey.currentState!.validate()) {
                          //navegar a la pantalla de inicio
                        }
                      }, 
                    child: Text("REGISTRARSE", style: TextStyle(color: Colors.white ),
                    )),
                    ),
              
                    //sing up bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Ya tienes una cuenta?"),
                      TextButton(onPressed: () {
                        //navegar a la pantalla de registro
                         Navigator.push(context,
                         MaterialPageRoute(
                          builder: (context) => const LoginMenu ())); 
                      },
                       child: const Text("LOGIN"))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
