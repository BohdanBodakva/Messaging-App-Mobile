import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:messaging_app/handlers/messages.dart';
import 'package:messaging_app/handlers/shared_prefs.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/login.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:messaging_app/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';

class UserProfilePage extends StatefulWidget {
  final User? currentUser;
  final Function setCurrentUser;
  final Socket socket;

  const UserProfilePage({super.key, required this.socket, required this.currentUser, required this.setCurrentUser});

  @override
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  User? profileUser;

  bool isLoading = false;

  File? _image;
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _usernameController;

  bool isNameInputValid = true;
  bool isUsernameInputValid = true;
  bool isUsernameExist = false;

   @override
  void initState() {
    super.initState();

    setState(() {
      profileUser = widget.currentUser!;
    });

    _nameController = TextEditingController(text: profileUser!.name ?? "");
    _surnameController = TextEditingController(text: profileUser!.surname ?? "");
    _usernameController = TextEditingController(text: profileUser!.username ?? "");

    _setupSocketEvents();
  }

  void _setupSocketEvents() {
    (() async {
      await _defineSocketEvents();
    })();
  }

  Future<void> _defineSocketEvents() async {
    widget.socket.on("change_user_info", (data) {

      final newUser = User.fromJson(data["user"], includeChats: false);

      User user = profileUser!;

      user.name = newUser.name;
      user.surname = newUser.surname;
      user.username = newUser.username;
      user.profilePhotoLink = newUser.profilePhotoLink;

      widget.setCurrentUser(user);
      setState(() {
        profileUser = user;
      });

      showSuccessToast(
        context, 
        Provider.of<LanguageProvider>(context, listen: false).localizedStrings["userInfoChangedSuccessfully"] ?? "User info was changed successfully"
      );
    });

    widget.socket.on("change_user_info_username_exists", (data) {
      setState(() {
        isUsernameExist = true;
        isLoading = false;
        isNameInputValid = true;
        isUsernameInputValid = true;
      });
    });

    
  }

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
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
          ElevatedButton(onPressed: () async {
              await deleteDataFromStorage("accessToken");

              Navigator.of(context, rootNavigator: true).push(
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
            TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
            ElevatedButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
          ],
        );
      },
    );
  }

  

  void _showSettingsDialog(languageProvider) {

    bool _notifications = true;

    void toggleNotifications(bool value) {
      setState(() => _notifications = value); 

      (() async {
        await Provider.of<NotificationProvider>(context, listen: false).toggleNotificationStatus();
      })();
    }
    
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
                  value: Provider.of<NotificationProvider>(context, listen: false).isNotificationsEnabled,
                  onChanged: (value) => {
                    setState(() => _notifications = value), 
                    (() async {
                      await Provider.of<NotificationProvider>(context, listen: false).toggleNotificationStatus();
                    })()
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel")),
            ElevatedButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
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
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            ),
          ),
          Visibility(
            visible: controller == _nameController ? !isNameInputValid : !isUsernameInputValid,
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, left: 5.0),
              child: Text(
                languageProvider.localizedStrings['fieldCannotBeEmpty'] ?? 'The filed cannot be empty', 
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
          Visibility(
            visible: isUsernameExist && controller == _usernameController,
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, left: 5.0),
              child: Text(
                languageProvider.localizedStrings['userAlreadyExists'] ?? 'User with such username already exists', 
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ],
      )
    );
  }

  void saveUserInfo() {
    setState(() {
      isUsernameExist = false;
      isLoading = true;
      isNameInputValid = true;
      isUsernameInputValid = true;
    });

    final name = _nameController.text;
    final surname = _surnameController.text;
    final username = _usernameController.text;

    if (name == profileUser!.name && surname == profileUser!.surname && username == profileUser!.username) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (name.isEmpty) {
      setState(() {
        isNameInputValid = false;
      });
    } else if (username.isEmpty) {
      setState(() {
        isUsernameInputValid = false;
      });
    } else {
      widget.socket.emit("change_user_info", {
        "user_id": profileUser!.id,
        "new_name": name,
        "new_surname": surname,
        "new_username": username,
        "new_profile_photo_link": null
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    widget.socket.off("change_user_info");
    widget.socket.off("change_user_info_username_exists");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.localizedStrings['profile'] ?? 'Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () {_logout(languageProvider);}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(profileUser!.profilePhotoLink!),
                    ),
                  ),
                  _buildTextField(_nameController, languageProvider.localizedStrings['name'] ?? "Name"),
                  _buildTextField(_surnameController, languageProvider.localizedStrings['surname'] ?? "Surname"),
                  _buildTextField(_usernameController, languageProvider.localizedStrings['username'] ?? "Username"),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: saveUserInfo, child: Text(languageProvider.localizedStrings['save'] ?? "Save")),
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
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      )
      
    );
  }
}
