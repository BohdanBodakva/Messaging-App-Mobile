import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {}, child: const Text("Logout")),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController currentPasswordController = TextEditingController();
        final TextEditingController newPasswordController = TextEditingController();
        final TextEditingController repeatNewPasswordController = TextEditingController();

        return AlertDialog(
          title: const Text("Change Password"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(currentPasswordController, "Current Password", obscureText: true),
                _buildTextField(newPasswordController, "New Password", obscureText: true),
                _buildTextField(repeatNewPasswordController, "Repeat New Password", obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Save")),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    bool _isDarkMode = false;
    String _language = 'en';
    bool _notifications = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Settings"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: _isDarkMode,
                  onChanged: (value) => setState(() => _isDarkMode = value),
                ),
                const SizedBox(height: 10),
                _buildDropdown(
                  "Language",
                  _language,
                  [
                    const DropdownMenuItem(value: 'en', child: Text("English")),
                    const DropdownMenuItem(value: 'uk', child: Text("Ukrainian")),
                  ],
                  (value) => setState(() => _language = value!),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Notifications"),
                  value: _notifications,
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Save")),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout),
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
                      : const NetworkImage("https://example.com/default_profile.jpg"),
                ),
              ),
              _buildTextField(_nameController, "Name"),
              _buildTextField(_surnameController, "Surname"),
              _buildTextField(_usernameController, "Username"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () {}, child: const Text("Save")),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: _showSettingsDialog,
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Change Password"),
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
