import 'package:flutter/material.dart';

class RestartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RestartButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.refresh,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}