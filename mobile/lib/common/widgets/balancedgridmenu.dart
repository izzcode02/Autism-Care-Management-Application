import 'package:flutter/material.dart';


class BalancedGridView extends StatelessWidget {
  const BalancedGridView(
      {super.key, required this.children, required this.columnCount});

  final List<Widget> children;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length ~/ columnCount + 1; i++)
          Row(
            children: [
              for (int j = 0; j < columnCount; j++)
                Expanded(
                  child: () {
                    final index = i * columnCount + j;
                    if (index >= children.length) {
                      return const SizedBox();
                    } else {
                      return children[index];
                    }
                  }(),
                )
            ],
          )
      ],
    );
  }
}

class MenuCardSmallTile extends StatelessWidget {
  const MenuCardSmallTile({
    Key? key,
    required this.imageLink,
    required this.label,
    required this.onTap,
    this.backgroundColor = Colors.transparent,
  }) : super(key: key);

  final String imageLink;
  final String label;
  final Function() onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: AssetImage(imageLink),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.labelMedium!.copyWith(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}