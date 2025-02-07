import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:messaging_app/pages/login.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  File? _image;
  final _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _logout(languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.localizedStrings['confirmLogout'] ?? "Confirm Logout"),
        content: Text(languageProvider.localizedStrings['logoutConfirmMessage'] ?? "Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
          ElevatedButton(onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(-1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                )
              );
            }, 
            child: Text(languageProvider.localizedStrings['logout'] ?? "Logout")
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(languageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController currentPasswordController = TextEditingController();
        final TextEditingController newPasswordController = TextEditingController();
        final TextEditingController repeatNewPasswordController = TextEditingController();

        return AlertDialog(
          title: Text(languageProvider.localizedStrings['changePassword'] ?? "Change Password"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(currentPasswordController, languageProvider.localizedStrings['currentPassword'] ?? "Current Password", obscureText: true),
                _buildTextField(newPasswordController, languageProvider.localizedStrings['newPassword'] ?? "New Password", obscureText: true),
                _buildTextField(repeatNewPasswordController, languageProvider.localizedStrings['repeatNewPassword'] ?? "Repeat New Password", obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(languageProvider) {
    bool _notifications = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(languageProvider.localizedStrings['settings'] ?? "Settings"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                _buildDropdown(
                  "Language",
                  Provider.of<LanguageProvider>(context).locale.languageCode,
                  [
                    const DropdownMenuItem(value: 'en', child: Text("English")),
                    const DropdownMenuItem(value: 'uk', child: Text("Українська")),
                  ],
                  (value) {
                    Provider.of<LanguageProvider>(context, listen: false).setLocale(value!);
                  } 
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(languageProvider.localizedStrings['notifications'] ?? "Notifications"),
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.localizedStrings['profile'] ?? 'Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () {_logout(languageProvider);}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!) as ImageProvider
                      : const AssetImage('assets/letter_images/a.png'),
                ),
              ),
              _buildTextField(_nameController, languageProvider.localizedStrings['name'] ?? "Name"),
              _buildTextField(_surnameController, languageProvider.localizedStrings['surname'] ?? "Surname"),
              _buildTextField(_usernameController, languageProvider.localizedStrings['username'] ?? "Username"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(languageProvider.localizedStrings['settings'] ?? "Settings"),
                onTap: () {_showSettingsDialog(languageProvider);},
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(languageProvider.localizedStrings['changePassword'] ?? "Change Password"),
                onTap: () {_showChangePasswordDialog(languageProvider);},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
