
import 'package:flutter/material.dart';

class LoginMenu extends StatefulWidget {
  const LoginMenu({super.key});

  @override
  State<LoginMenu> createState() => _LoginMenuState();
}

class _LoginMenuState extends State<LoginMenu> {
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
                Container(
                  margin: EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.3)),
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
                    color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.3)),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person),
                      border: InputBorder.none,
                      hintText: "Password",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}