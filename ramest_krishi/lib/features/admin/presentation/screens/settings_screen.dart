import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.store), title: Text('Shop Profile'), subtitle: Text('Update GSTIN, Address, etc.')),
          ListTile(leading: Icon(Icons.print), title: Text('Printer Settings'), subtitle: Text('Configure Thermal Printer (Bluetooth/USB)')),
          ListTile(leading: Icon(Icons.backup), title: Text('Backup & Restore'), subtitle: Text('Force Sync or Download local DB dump')),
        ],
      ),
    );
  }
}
