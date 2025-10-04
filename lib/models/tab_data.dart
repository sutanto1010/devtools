import 'package:flutter/material.dart';

class TabData {
  final String id;
  final String title;
  final IconData icon;
  final Map<String, dynamic>? sessionData;

  TabData({
    required this.id,
    required this.title,
    required this.icon,
    this.sessionData,
  });
}