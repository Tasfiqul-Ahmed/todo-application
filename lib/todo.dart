import 'dart:ui';

import 'package:flutter/material.dart';

class Todo {
  String id;
  String title;
  String description;
  int createdAt;
  String status;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt,
      'status': status,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      createdAt: int.parse(json['created_at'].toString()),
      status: json['status'],
    );
  }

  String toCsv() {
    return '$id,$title,$description,$createdAt,$status';
  }

  // Get the color associated with each status for simplicity
  Color get statusColor {
    switch (status) {
      case 'completed':
        return Colors.green.shade50;
      case 'pending':
        return Colors.orange.shade50;
      case 'ready':
      default:
        return Colors.blue.shade50;
    }
  }
}