import 'dart:async';

import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/data/models/service_models/assistant_service_model.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AssistantControlPage extends StatefulWidget {
  const AssistantControlPage({super.key});

  @override
  State<AssistantControlPage> createState() => _AssistantControlPageState();
}

class _AssistantControlPageState extends State<AssistantControlPage> {
  String _recognizedText = 'Waiting for speech...';
  bool _isListening = false;
  bool _isLoading = true;
  bool? _hasPermission;
  AssistantServiceModel assistantServiceModel = AssistantServiceModel.empty();
  StreamSubscription<String>? _speechSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _startSpeechSubscription();
    loadFirstTime();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!_mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (!_mounted) return;
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  void _startSpeechSubscription() {
    _speechSubscription = NativeBridge.getSpeechResults().listen(
      (text) {
        if (!_mounted) return;
        if (text.trim().isNotEmpty) {
          setState(() {
            _recognizedText = text;
          });
        }
      },
      onError: (error) {
        if (!_mounted) return;
        setState(() {
          _recognizedText = 'Error: $error';
        });
      },
    );
  }

  Future<void> loadFirstTime() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);
    assistantServiceModel = await NativeBridge.getInfo();
    if (!_mounted) return;
    setState(() => _isLoading = false);
    _loadServiceInfo();
  }

  Future<void> _loadServiceInfo() async {
    while (_mounted) {
      final newData = await NativeBridge.getInfo();
      if (!_mounted) break;
      if (newData != assistantServiceModel) {
        setState(() {
          assistantServiceModel = newData;
        });
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _speechSubscription?.cancel();
    NativeBridge.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      final success = await NativeBridge.stopListening();
      if (!_mounted) return;
      if (success) {
        setState(() {
          _isListening = false;
          _recognizedText = 'Stopped listening';
        });
      }
    } else {
      final success = await NativeBridge.startListening();
      if (!_mounted) return;
      if (success) {
        setState(() {
          _isListening = true;
          _recognizedText = 'Listening...';
        });
      } else {
        setState(() {
          _recognizedText = 'Failed to start listening';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant Control'), elevation: 2),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Service Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatusRow(
                              'Is Bound',
                              assistantServiceModel.isBound,
                            ),
                            _buildStatusRow(
                              'Is StandBy',
                              assistantServiceModel.isStandBy,
                            ),
                            _buildStatusRow(
                              'Is Stopped',
                              assistantServiceModel.isStoped,
                            ),
                            _buildInfoCol(
                              'Channel',
                              assistantServiceModel.channel,
                            ),
                            _buildInfoCol(
                              'Result Channel',
                              assistantServiceModel.resultChannel,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _hasPermission == true
                                      ? Icons.mic
                                      : Icons.mic_off,
                                  color:
                                      _hasPermission == true
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hasPermission == true
                                      ? 'Microphone Permission Granted'
                                      : 'Microphone Permission Required',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (_hasPermission != true)
                              ElevatedButton(
                                onPressed: _requestPermission,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Grant Permission'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recognized Speech',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _recognizedText,
                              maxLines: null,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed:
                          _hasPermission == true ? _toggleListening : null,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(
                        _isListening ? 'Stop Assistant' : 'Wake Assistant',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor:
                            _isListening ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: value ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                color: value ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            value.isEmpty ? 'N/A' : value,
            maxLines: null,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
