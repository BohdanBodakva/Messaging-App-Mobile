import 'package:flutter/material.dart';
import 'package:messaging_app/handlers/http_request.dart';
import 'package:messaging_app/handlers/shared_prefs.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_list.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:messaging_app/widgets/error_message.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, User? currentUser, setCurrentUser});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isLoginForm = true;
  bool isLoading = false;
  String error = "";

  bool isNameInputValid = true;
  bool isSurnameInputValid = true;
  bool isUsernameInputValid = true;
  bool isPasswordInputValid = true;
  bool isRepeatPasswordInputValid = true;

  void setNameInputValid(bool newValue) {
    setState(() {
      isNameInputValid = newValue;
    });
  }

  void setSurnameInputValid(bool newValue) {
    setState(() {
      isSurnameInputValid = newValue;
    });
  }

  void setUsernameInputValid(bool newValue) {
    setState(() {
      isUsernameInputValid = newValue;
    });
  }

  void setPasswordInputValid(bool newValue) {
    setState(() {
      isPasswordInputValid = newValue;
    });
  }

  void setRepeatPasswordInputValid(bool newValue) {
    setState(() {
      isRepeatPasswordInputValid = newValue;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  void toggleForm() {
    setState(() {
      isLoginForm = !isLoginForm;
    });
  }

  void toggleLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  void setError(String newError) {
    setState(() {
      error = newError;
    });
  }

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      return false;
    });

    var languageProvider = Provider.of<LanguageProvider>(context);
    String languageCode = languageProvider.locale.languageCode;

    Future<Map<String, dynamic>> fetchData() async {
      final uri = Uri.parse("http://127.0.0.1/:5000/api/a");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load data");
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        title: const Text("Messaging App"),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoginForm ? 
                    LoginForm(
                      toggleForm: toggleForm, 
                      toggleLoading: toggleLoading,
                      error: error, 
                      setError: setError,
                      isUsernameInputValid: isUsernameInputValid,
                      setUsernameInputValid: setUsernameInputValid,
                      isPasswordInputValid: isPasswordInputValid,
                      setPasswordInputValid: setPasswordInputValid,
                    ) : 
                    SignUpForm(
                      toggleForm: toggleForm, 
                      toggleLoading: toggleLoading, 
                      error: error, 
                      setError: setError,
                      isUsernameInputValid: isUsernameInputValid,
                      setUsernameInputValid: setUsernameInputValid,
                      isPasswordInputValid: isPasswordInputValid,
                      setPasswordInputValid: setPasswordInputValid,
                      isNameInputValid: isNameInputValid,
                      setNameInputValid: setNameInputValid,
                      isSurnameInputValid: isSurnameInputValid,
                      setSurnameInputValid: setSurnameInputValid,
                      isRepeatPasswordInputValid: isRepeatPasswordInputValid,
                      setRepeatPasswordInputValid: setRepeatPasswordInputValid,
                    ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      if (languageCode == 'en') {
                        languageProvider.setLocale('uk');
                      } else {
                        languageProvider.setLocale('en');
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          languageCode == 'en' ? 'en' : 'укр',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class LoginForm extends StatelessWidget {
  final VoidCallback toggleForm;
  final VoidCallback toggleLoading;
  final String error;
  final Function setError;

  final bool isUsernameInputValid;
  final Function setUsernameInputValid;
  final bool isPasswordInputValid;
  final Function setPasswordInputValid;

  final TextEditingController _usernamenameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginForm({
    super.key, 
    required this.toggleForm, 
    required this.toggleLoading, 
    required this.error,
    required this.setError,
    required this.isUsernameInputValid,
    required this.setUsernameInputValid,
    required this.isPasswordInputValid,
    required this.setPasswordInputValid,
  });

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(languageProvider.localizedStrings['login'] ?? 'Login',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (error.isNotEmpty) 
          ErrorMessageBox(errorMessage: error),
        if (error.isNotEmpty)
          const SizedBox(height: 20),
        TextField(
          controller : _usernamenameController,
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['username'] ?? 'Username',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller : _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['password'] ?? 'Password',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            String username = _usernamenameController.text;
            String password = _passwordController.text;

            if (username.isEmpty) {
              setUsernameInputValid(false);
              return;
            } else if (password.isEmpty) {
              setPasswordInputValid(false);
              return;
            } 

            var response = await makeHttpRequest(
              "POST", 
              "/auth/login", 
              {
                "username": username,
                "password": password,
              },
              {}
            );

            final errorMessage = response[1];
            setError(errorMessage ?? "");

            if (errorMessage == null) {
              await saveDataToStorage("accessToken", response[0]["access_token"]);

              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ChatListPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0072FF)),
          child: Text(
            languageProvider.localizedStrings['login'] ?? 'Login',
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setError("");
            toggleForm();
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Text(
              languageProvider.localizedStrings['loginCheckoutMessage'] ?? "Don't have an account? Sign Up", 
              style: const TextStyle(color: Color(0xFF0072FF)),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }
}

class SignUpForm extends StatelessWidget {
  final VoidCallback toggleForm;
  final VoidCallback toggleLoading;
  final String error;
  final Function setError;

  final bool isUsernameInputValid;
  final Function setUsernameInputValid;
  final bool isPasswordInputValid;
  final Function setPasswordInputValid;
  final bool isNameInputValid;
  final Function setNameInputValid;
  final bool isSurnameInputValid;
  final Function setSurnameInputValid;
  final bool isRepeatPasswordInputValid;
  final Function setRepeatPasswordInputValid;

  const SignUpForm({
    super.key, 
    required this.toggleForm, 
    required this.toggleLoading, 
    required this.error,
    required this.setError,
    required this.isUsernameInputValid,
    required this.setUsernameInputValid,
    required this.isPasswordInputValid,
    required this.setPasswordInputValid,
    required this.isNameInputValid,
    required this.setNameInputValid,
    required this.isSurnameInputValid,
    required this.setSurnameInputValid,
    required this.isRepeatPasswordInputValid,
    required this.setRepeatPasswordInputValid,
  });

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(languageProvider.localizedStrings['signup'] ?? 'Sign Up',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (error.isNotEmpty) 
          ErrorMessageBox(errorMessage: error),
        if (error.isNotEmpty)
          const SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['name'] ?? 'First Name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['surname'] ?? 'Last Name',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['username'] ?? 'Username',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['password'] ?? 'Password',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: languageProvider.localizedStrings['repeatPassword'] ?? 'Repeat Password',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const ChatListPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0072FF)),
          child: Text(
            languageProvider.localizedStrings['signup'] ?? 'Sign Up',
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setError("");
            toggleForm();
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Text(
              languageProvider.localizedStrings['signupCheckoutMessage'] ?? "Already have an account? Login", 
              style: const TextStyle(color: Color(0xFF0072FF)),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ),
      ],
    );
  }
}
