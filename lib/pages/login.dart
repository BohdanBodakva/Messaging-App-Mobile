import 'package:flutter/material.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_list.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, User? currentUser, setCurrentUser});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isLoginForm = true;

  @override
  void initState() {
    super.initState();
    

  }

  void toggleForm() {
    setState(() {
      isLoginForm = !isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      return false;
    });

    var languageProvider = Provider.of<LanguageProvider>(context);
    String languageCode = languageProvider.locale.languageCode;

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
                  isLoginForm ? LoginForm(toggleForm: toggleForm) : SignUpForm(toggleForm: toggleForm),
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

  const LoginForm({super.key, required this.toggleForm});

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
            languageProvider.localizedStrings['login'] ?? 'Login',
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: toggleForm,
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

  const SignUpForm({super.key, required this.toggleForm});

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
          onPressed: toggleForm,
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
