import 'package:flutter/material.dart';

Widget buildHeroVideo(String url) {
  // On non-web platforms, just render a black box.
  // The parent (home_page.dart) uses the poster image instead on non-web,
  // so this function is rarely called.
  return Container(color: Colors.black);
}
