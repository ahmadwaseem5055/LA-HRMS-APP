// import 'package:flutter/material.dart';
// import 'screens/profile_screen.dart';
// import 'screens/attendance_screen.dart';
// import 'screens/time_off_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = const [
//     ProfileScreen(),
//     AttendanceScreen(),
//     TimeOffScreen(),
//   ];

//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//         selectedItemColor: const Color(0xFF00AEEF),
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.access_time),
//             label: 'Attendance',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.event_busy),
//             label: 'Time Off',
//           ),
//         ],
//       ),
//     );
//   }
// }
