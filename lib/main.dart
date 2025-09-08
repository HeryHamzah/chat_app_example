import 'package:chat_app_example/presentation/chat/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Bungkus seluruh app dengan ProviderScope agar Riverpod dapat digunakan
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Branching Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Halaman utama diarahkan ke ChatPage
      home: const ChatPage(),
    );
  }
}

// Removed template counter page and replaced with ChatPage
