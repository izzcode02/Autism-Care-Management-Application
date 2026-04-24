import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.discreteCircle(
        color: Colors.white,
        secondRingColor: Colors.green,
        thirdRingColor: Colors.orangeAccent,
        size: 50,
      ),
    );
  }
}
