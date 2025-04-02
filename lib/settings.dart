import 'package:flutter/material.dart';
import 'account_settings_page.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          Divider(),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Account'),
            subtitle: Text('Manage your account settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountSettingsPage()),
              );
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.info),
          //   title: Text('About'),
          //   subtitle: Text('App version and details'),
          //   onTap: () {
          //     _showCustomAboutDialog(context);
          //   },
          // ),
        ],
      ),
    );
  }
}
