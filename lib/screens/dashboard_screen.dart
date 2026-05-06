import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';
import 'event_setup_screen.dart';
import 'checkin_screen.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final participantProvider = Provider.of<ParticipantProvider>(context);
    
    final event = eventProvider.currentEvent;
    
    if (event == null) {
      return const Scaffold(body: Center(child: Text('No event configured.')));
    }

    final int maxCapacity = event.maxCapacity;
    final int checkedIn = participantProvider.checkedInCount;
    final int remaining = maxCapacity - checkedIn;
    final double fillPercentage = maxCapacity > 0 ? (checkedIn / maxCapacity) : 0;

    // Determine Status Level and Color
    String statusText;
    Color statusColor;
    if (fillPercentage < 0.7) {
      statusText = 'Safe';
      statusColor = Colors.green;
    } else if (fillPercentage < 0.95) {
      statusText = 'Moderate';
      statusColor = Colors.orange;
    } else {
      statusText = 'Full';
      statusColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'End Event & Reset',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('End Event?'),
                  content: const Text('This will delete the current event and all check-in data. Are you sure?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('End Event')),
                  ],
                ),
              );
              if (confirm == true) {
                await participantProvider.clearParticipants();
                await eventProvider.clearEvent();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const EventSetupScreen()),
                  );
                }
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Info Header
            Text(
              event.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${event.dateTime.month}/${event.dateTime.day}/${event.dateTime.year} at ${TimeOfDay.fromDateTime(event.dateTime).format(context)}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Crowd Level Indicator
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Crowd Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: fillPercentage,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: statusColor,
                          ),
                        ),
                        Column(
                          children: [
                            Icon(
                              fillPercentage >= 0.95 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                              color: statusColor,
                              size: 40,
                            ),
                            Text(
                              statusText,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Row
            Row(
              children: [
                Expanded(child: _buildStatCard('Checked In', checkedIn.toString(), Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Remaining', remaining.toString(), statusColor)),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard('Maximum Capacity', maxCapacity.toString(), Colors.grey.shade700),
            
            const SizedBox(height: 40),
            
            // Phase 3 Navigation Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Open Check-in Scanner', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckinScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Phase 4 Navigation Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              icon: const Icon(Icons.list_alt),
              label: const Text('View Check-in Logs', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
