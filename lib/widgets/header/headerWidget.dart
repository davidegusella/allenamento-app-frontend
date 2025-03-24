import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String title;
  final double expandedHeight;

  const Header({
    super.key,
    required this.title,
    this.expandedHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      expandedHeight: expandedHeight,
      floating: false,
      pinned: false, // resta visibile anche quando scrolli
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}
