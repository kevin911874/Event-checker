import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/participant_provider.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({Key? key}) : super(key: key);

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _manualIdController = TextEditingController();
  final _manualNameController = TextEditingController();
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualIdController.dispose();
    _manualNameController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processCheckIn(String id, String name) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final participantProvider = Provider.of<ParticipantProvider>(context, listen: false);
    
    final event = eventProvider.currentEvent;
    
    if (event == null) {
      _showError('No event configured.');
      setState(() => _isProcessing = false);
      return;
    }

    if (participantProvider.checkedInCount >= event.maxCapacity) {
      _showError('Event is at maximum capacity!');
      setState(() => _isProcessing = false);
      return;
    }

    final success = await participantProvider.checkInParticipant(id, name);
    
    if (success) {
      _showSuccess('Participant $name checked in successfully!');
      _manualIdController.clear();
      _manualNameController.clear();
    } else {
      _showError('Duplicate entry! Participant ID $id has already checked in.');
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participant Check-in'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR Scan'),
            Tab(icon: Icon(Icons.keyboard), text: 'Manual Entry'),
          ],
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRScanner(),
          _buildManualEntry(),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  // For demo, we assume the QR code is just the Participant ID
                  // We'll give a default name for QR scans since it might not be encoded
                  _processCheckIn(barcode.rawValue!, 'QR Guest ${barcode.rawValue!.substring(0, 4)}');
                  break; 
                }
              }
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Align the QR code within the frame to check in.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildManualEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.assignment_ind, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 24),
          TextField(
            controller: _manualIdController,
            decoration: const InputDecoration(
              labelText: 'Participant ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manualNameController,
            decoration: const InputDecoration(
              labelText: 'Participant Name (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isProcessing
                ? null
                : () {
                    final id = _manualIdController.text.trim();
                    if (id.isEmpty) {
                      _showError('Participant ID is required.');
                      return;
                    }
                    final name = _manualNameController.text.trim().isEmpty 
                        ? 'Guest $id' 
                        : _manualNameController.text.trim();
                    _processCheckIn(id, name);
                  },
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Check In', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
