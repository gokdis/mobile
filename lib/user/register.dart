import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:gokdis/settings.dart';
import 'package:http/http.dart' as http;
import 'package:gokdis/user/login.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? surname;
  String? email;
  int? age;
  String? confirmEmail;
  String? password;
  DateTime? birthDate;
  String? gender;
  List<String> genders = ['Male', 'Female', 'Other'];

  int calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
        age = calculateAge(picked);
      });
      print(age);
    }
  }

  void register() async {
    String url = Settings.getUrl('person');
    String emailHelen = 'helen@ieu.edu.tr';
    String passwordHelen = 'helen';

    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$emailHelen:$passwordHelen'));

    final Map<String, dynamic> data = {
      'email': '$email',
      'password': '$password',
      'role': 'ROLE_USER',
      'name': '$name',
      'age': age
    };

    final Map<String, String> requestHeaders = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basicAuth,
    };
    var encodedData = jsonEncode(data);
    print("name before : $name");
    print("encoded data : $encodedData");

    try {
      print(
          'Sending request to $url with headers: $requestHeaders and data: $data');
      final response = await http.post(
        Uri.parse(url),
        body: encodedData,
        headers: requestHeaders,
      );
      // print("jsonencode data : {$jsonEncode${(data)}");
      // print("data : $data");
      // print('Response status: ${response.statusCode}');
      print("body : ${response.body}");
      print("*********************");

      print("name after : $name");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print("Success but no content returned.");
        } else {
          print("success");
          navigateToLogin();
        }
      } else {
        print("fail with status code: ${response.statusCode}");
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registration Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registration"),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Surname'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your surname';
                  }
                  return null;
                },
                onSaved: (value) => surname = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => email = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
                onSaved: (value) => password = value,
              ),
              ListTile(
                title: Text(birthDate == null
                    ? 'Select your birth date'
                    : 'Birth Date: ${birthDate!.toIso8601String().substring(0, 10)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: gender,
                hint: Text('Select Gender'),
                onChanged: (String? newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a gender' : null,
                items: genders.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      register();
                    }
                  },
                  child: Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
