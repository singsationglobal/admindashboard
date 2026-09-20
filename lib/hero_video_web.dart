// Web-only implementation. Never imported on non-web platforms.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildHeroVideo(String url) {
  // Register a unique view factory for this video once.
  const String viewType = 'hero-video-view';

  // Create the underlying HTML video element.
  final html.VideoElement video = html.VideoElement()
    ..src = url
    ..autoplay = true
    ..muted = true
    ..loop = true
    ..setAttribute('playsinline', 'true')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover';

  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => video,
  );

  return HtmlElementView(viewType: viewType);
}
