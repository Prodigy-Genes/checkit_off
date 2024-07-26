import 'package:flutter/material.dart';

class MenuIcon extends StatelessWidget {
  final Function() onPressed;

  const MenuIcon({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: Color.fromARGB(255, 172, 16, 16)),
      onPressed: onPressed,
    );
  }
}
