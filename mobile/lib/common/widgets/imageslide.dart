import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageSlider extends StatefulWidget {
  final double height;
  final double width;

  const ImageSlider({Key? key, required this.height, required this.width})
      : super(key: key);

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  List<String> _imageAsset = [
    "assets/images/login.png",
    "assets/images/activityplanner1.png",
    "assets/images/attendance1.png",
    "assets/images/auticarebanner.png",
    "assets/images/childparent1.png",
  ];

  @override
  void dispose() {
    // Break any references to the State object here
    _imageAsset = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _imageAsset.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: widget.height,
            width: widget.width,
            child: CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                pauseAutoPlayOnTouch: true,
                aspectRatio: widget.width / widget.height,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                enlargeFactor: 0.5,
                viewportFraction: 0.9,
              ),
              items: _imageAsset
                  .map((imageAsset) => Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        width: widget.width,
                      ))
                  .toList(),
            ),
          );
  }
}
