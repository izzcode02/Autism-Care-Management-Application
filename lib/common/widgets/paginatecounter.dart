import 'package:flutter/material.dart';
import 'package:im_stepper/stepper.dart';

class PaginateCounter extends StatefulWidget {
  const PaginateCounter(
      {super.key, required this.counter, required this.currentPage});

  final int counter;
  final int currentPage;

  @override
  State<PaginateCounter> createState() => _PaginateCounterState();
}

class _PaginateCounterState extends State<PaginateCounter> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: DotStepper(
        dotCount: widget.counter,
        activeStep: widget.currentPage,
        dotRadius: 20.0,
        shape: Shape.pipe,
        spacing: 10.0,
        tappingEnabled: false,
      ),
    );
  }
}
