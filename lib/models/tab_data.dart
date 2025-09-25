import 'package:flutter/material.dart';

class TabData {
  final String id;
  final String title;
  final IconData icon;
  final Widget screen;
  final Map<String, dynamic>? sessionData;

  TabData({
    required this.id,
    required this.title,
    required this.icon,
    required this.screen,
    this.sessionData,
  });
}