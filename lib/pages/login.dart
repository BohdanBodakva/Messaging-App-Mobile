import 'package:flutter/material.dart';
import 'package:messaging_app_mobile/pages/chat_list.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isLoginForm = true;

  void toggleForm() {
    setState(() {
      isLoginForm = !isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Messaging App'),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Login',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
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
              )
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0072FF)),
          child: const Text(
            'Login',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))
            ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: toggleForm,
          child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Color(0xFF0072FF))),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sign Up',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        const TextField(
          decoration: InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        const TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Repeat Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0072FF)),
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))
            ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: toggleForm,
          child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF0072FF))),
        ),
      ],
    );
  }
}
