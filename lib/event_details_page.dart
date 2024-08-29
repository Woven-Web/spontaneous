import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EventDetailsPage extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isHost = currentUser?.id == event['host_id'];

    return Scaffold(
      appBar: AppBar(
        title: Text(event['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDateTime(event['start_time'], event['end_time'])),
                if (isHost)
                  TextButton(
                    onPressed: () {
                      // TODO: Implement edit/cancel functionality
                    },
                    child: const Text('Edit/Cancel Event'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('RSVPs:', style: TextStyle(fontWeight: FontWeight.bold)),
            // TODO: Implement RSVP list
            const SizedBox(height: 16),
            const Text('Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(event['description'] ?? 'No description available.'),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String start, String end) {
    final startTime = DateTime.parse(start);
    final endTime = DateTime.parse(end);
    final formatter = DateFormat('MMM d, y - h:mm a');
    return '${formatter.format(startTime)} to ${DateFormat('h:mm a').format(endTime)}';
  }
}
