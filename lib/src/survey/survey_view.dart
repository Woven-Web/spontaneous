import 'package:flutter/material.dart';

class SurveyView extends StatefulWidget {
  const SurveyView({super.key});

  @override
  State<SurveyView> createState() => _SurveyViewState();

  static const routeName = '/survey';
}

class _SurveyViewState extends State<SurveyView> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? workingOn;
  String? enjoying;
  String? curiousAbout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Survey'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onSaved: (value) => name = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'What you are working on'),
                onSaved: (value) => workingOn = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter what you are working on';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'What you are enjoying'),
                onSaved: (value) => enjoying = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter what you are enjoying';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'What you are curious about'),
                onSaved: (value) => curiousAbout = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter what you are curious about';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Handle the form submission here
                    print('Name: $name');
                    print('Working on: $workingOn');
                    print('Enjoying: $enjoying');
                    print('Curious about: $curiousAbout');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Survey submitted successfully!')),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
