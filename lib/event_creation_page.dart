import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventCreationPage extends StatefulWidget {
  const EventCreationPage({Key? key}) : super(key: key);

  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _untilWhen = DateTime.now().add(const Duration(hours: 2));
  bool _isFormValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  Future<void> _publishEvent() async {
    if (!_isFormValid) return;

    try {
      await Supabase.instance.client.from('events').insert({
        'name': _nameController.text,
        'location': _locationController.text,
        'details': _detailsController.text,
        'start_time': DateTime.now().toIso8601String(),
        'end_time': _untilWhen.toIso8601String(),
        'host_id': Supabase.instance.client.auth.currentUser?.id,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host an Event')),
      body: Form(
        key: _formKey,
        onChanged: _validateForm,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a location' : null,
            ),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Details'),
              maxLines: 3,
            ),
            ListTile(
              title: const Text('Until when'),
              subtitle: Text(_untilWhen.toString()),
              onTap: () async {
                final picked = await showDateTimePicker(context);
                if (picked != null) {
                  setState(() => _untilWhen = picked);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isFormValid ? _publishEvent : null,
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _untilWhen,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_untilWhen),
    );
    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
