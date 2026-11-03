import 'package:flutter/material.dart';

class GramSakshamMark extends StatelessWidget {
  const GramSakshamMark({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.055),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF7),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFB8DCC3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF075B35).withValues(alpha: 0.12),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/village_background.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.18),
          errorBuilder: (_, __, ___) => Icon(
            Icons.eco_rounded,
            color: const Color(0xFF087A3E),
            size: size * 0.58,
          ),
        ),
      ),
    );
  }
}
