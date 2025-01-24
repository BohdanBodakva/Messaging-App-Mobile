import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoginForm = true;

  void toggleForm() {
    setState(() {
      isLoginForm = !isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  LoginForm({required this.toggleForm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Login',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {},
          child: Text(
            'Login',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))
            ),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0072FF)),
        ),
        SizedBox(height: 10),
        TextButton(
          onPressed: toggleForm,
          child: Text("Don't have an account? Sign Up", style: TextStyle(color: Color(0xFF0072FF))),
        ),
      ],
    );
  }
}

class SignUpForm extends StatelessWidget {
  final VoidCallback toggleForm;

  SignUpForm({required this.toggleForm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sign Up',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 15),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Repeat Password',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {},
          child: Text(
            'Sign Up',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))
            ),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0072FF)),
        ),
        SizedBox(height: 10),
        TextButton(
          onPressed: toggleForm,
          child: Text("Already have an account? Login", style: TextStyle(color: Color(0xFF0072FF))),
        ),
      ],
    );
  }
}
