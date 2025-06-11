// ignore_for_file: library_private_types_in_public_api

import 'package:ai_asistant/core/services/db_helper.dart';
import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:flutter/material.dart';

class EmailReportsPage extends StatefulWidget {
  const EmailReportsPage({super.key});

  @override
  _EmailReportsPageState createState() => _EmailReportsPageState();
}

class _EmailReportsPageState extends State<EmailReportsPage> {
  List<Map<String, String>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      print(await NativeBridge.getDbPath());
      final reports = await MeetingDatabaseHelper.getAllEmailReportsWithDay();
      setState(() {
        _reports = reports;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Email Reports',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87.withValues(alpha: .8),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadReports,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _reports.isEmpty
              ? const Center(
                child: Text(
                  'No email reports found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  final report = _reports[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        'Date: ${report['day']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          report['summary'] ?? 'No summary available',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      onTap: () {
                        // Optional: Add tap functionality to view report details
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Report for ${report['day']}'),
                                content: SingleChildScrollView(
                                  child: Text(
                                    report['summary'] ?? 'No summary',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
