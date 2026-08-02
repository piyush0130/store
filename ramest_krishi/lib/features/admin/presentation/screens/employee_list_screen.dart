import 'package:flutter/material.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Management')),
      body: const Center(
        child: Text('RBAC (Role Based Access Control) Management\nComing soon in Admin Panel v2'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
