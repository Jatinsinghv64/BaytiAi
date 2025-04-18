
import 'package:baytiai/profileScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ChatScreen.dart';
import 'PropertyListScreen.dart';
import 'main.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PropertyChatScreen(), // Your existing chatbot screen
    const PropertyListScreen(), // Your existing property list screen
    const ProfileScreen(), // You'll need to create this
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xff1150ab),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'BaytiAi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Properties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}