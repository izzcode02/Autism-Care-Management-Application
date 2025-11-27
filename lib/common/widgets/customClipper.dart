import 'package:flutter/material.dart';

class Customshape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double height = size.height;
    double width = size.width;
    double offset = 100.0;
    Path path = Path();
    path.lineTo(0, height);
    path.lineTo(width, height);
    path.lineTo(width, 0);
    path.quadraticBezierTo(width / 2, offset, height - offset, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
