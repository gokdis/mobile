import 'package:flutter/material.dart';
import 'package:gokdis/user/shopping_list.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('email');
    String? savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = savedEmail;
        _passwordController.text = savedPassword;
      });
    }
  }

  void _login() async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('email', _usernameController.text);
      prefs.setString('password', _passwordController.text);
    }

    navigateToShoppingList();
  }

  void navigateToShoppingList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListWidget(),
      ),
    );
  }

  void _navigateToRegister() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Login'),
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFFFFA500),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  if (_isError)
                    Text(
                      'Wrong email or password',
                      style: TextStyle(color: Colors.red),
                    ),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      Text('Remember me'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.orange),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Not registered?',
                        style: TextStyle(color: Colors.black),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: const Text(
                          ' Register',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ]),
          ),
        ));
  }
}
