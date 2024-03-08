import 'package:flutter/material.dart';
import 'package:gokdis/user/register.dart';
import 'package:gokdis/user/shopping_list.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gokdis/settings.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isError = false;
  bool isLoggedIn = false;
  String loggedInEmail = "";
  @override
  void initState() {
    super.initState();

    _loadAppSettings();
  }

  void _loadAppSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? rememberMe = prefs.getBool('rememberMe');

    if (rememberMe != null && rememberMe) {
      String? savedEmail = prefs.getString('email');
      String? savedPassword = prefs.getString('password');

      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _rememberMe = true;
          _usernameController.text = savedEmail;
          _passwordController.text = savedPassword;
        });
      }
    } else {
      setState(() {
        _rememberMe = rememberMe ?? false;
      });
    }
  }

  Future<void> login() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      prefs.setString('email', _usernameController.text);
      prefs.setString('password', _passwordController.text);
    } else {
      prefs.remove('email');
      prefs.remove('password');
    }
    prefs.setBool('rememberMe', _rememberMe);

    String url = Settings.instance.getUrl('beacon/c7:10:69:07:fb:51');

    String email = _usernameController.text;
    String password = _passwordController.text;
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$email:$password'));

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: requestHeaders,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 403 ||
          response.statusCode == 204) {
        navigateToShoppingList();
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      _isError = true;
      print("Error occurred while fetching data: $error");
    }
  }

  void navigateToShoppingList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingListWidget(),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationPage(),
      ),
    );
  }

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
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('rememberMe', _rememberMe);
                          });
                        },
                      ),
                      Text('Remember me'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: login,
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
