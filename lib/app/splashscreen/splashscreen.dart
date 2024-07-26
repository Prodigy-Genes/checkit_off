import 'package:flutter/material.dart';

class Splashscreen extends StatefulWidget {
  final Widget? child;
  const Splashscreen({super.key, this.child});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(seconds: 7),
      () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => widget.child!),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.red.shade700,
                  Colors.orange.shade500,
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/app-logo2.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 20),
              
            ],
          ),
          const Positioned(
            bottom: 20,
            right: 20,
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
