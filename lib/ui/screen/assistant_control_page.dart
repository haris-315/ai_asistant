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
  bool _isLoading = true;
  bool? _hasPermission;
  AssistantServiceModel assistantServiceModel = AssistantServiceModel.empty();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkPermission();
    await loadFirstTime();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!_mounted) return;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (!_mounted) return;
    setState(() => _hasPermission = status.isGranted);
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
        setState(() => assistantServiceModel = newData);
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _toggleListening() async {
    if (!assistantServiceModel.isStoped) {
      final success = await NativeBridge.stopListening();
      if (!_mounted || !success) return;
    } else {
      await NativeBridge.startListening();
      if (!_mounted) return;
    }
  }

  @override
  void dispose() {
    _mounted = false;
    // NativeBridge.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !assistantServiceModel.isStoped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant Control'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadFirstTime,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _AssistantStatusCard(
                      isStandBy: assistantServiceModel.isStandBy,
                      isActive: isActive,
                    ),
                    const SizedBox(height: 16),
                    _MicrophonePermissionCard(
                      hasPermission: _hasPermission,
                      onRequestPermission: _requestPermission,
                    ),
                    const SizedBox(height: 16),
                    _SpeechInputCard(
                      text: assistantServiceModel.recognizedText,
                      isActive: isActive,
                    ),
                    const Spacer(),
                    _ControlButton(
                      isActive: isActive,
                      hasPermission: _hasPermission == true,
                      onPressed: _toggleListening,
                    ),
                  ],
                ),
              ),
    );
  }
}

class _AssistantStatusCard extends StatelessWidget {
  final bool isStandBy;
  final bool isActive;

  const _AssistantStatusCard({required this.isStandBy, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.assistant : Icons.assistant_outlined,
                  color:
                      isActive
                          ? colors.primary
                          : colors.onSurface.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assistant Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatusIndicator(
              label: 'Current State',
              value: isActive ? 'Active' : 'Inactive',
              color: isActive ? colors.primary : colors.error,
              icon: isActive ? Icons.check_circle : Icons.pause_circle,
            ),
            const SizedBox(height: 8),
            _StatusIndicator(
              label: 'Listening Mode',
              value: isStandBy ? 'Standby' : 'Ready',
              color: isStandBy ? colors.secondary : colors.tertiary,
              icon: isStandBy ? Icons.nights_stay : Icons.light_mode,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatusIndicator({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechInputCard extends StatelessWidget {
  final String text;
  final bool isActive;

  const _SpeechInputCard({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.keyboard_voice,
                  color:
                      isActive
                          ? colors.primary
                          : colors.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Speech Recognition',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                text.isEmpty ? 'Waiting for voice input...' : text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color:
                      text.isEmpty
                          ? colors.onSurface.withOpacity(0.6)
                          : colors.onSurface,
                ),
              ),
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MicrophonePermissionCard extends StatelessWidget {
  final bool? hasPermission;
  final VoidCallback onRequestPermission;

  const _MicrophonePermissionCard({
    required this.hasPermission,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isGranted = hasPermission == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isGranted
                        ? colors.primary.withOpacity(0.1)
                        : colors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGranted ? Icons.mic : Icons.mic_off,
                color: isGranted ? colors.primary : colors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Microphone Access',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isGranted
                        ? 'Permission granted'
                        : 'Required for voice commands',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              FilledButton.tonal(
                onPressed: onRequestPermission,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.errorContainer,
                  foregroundColor: colors.onErrorContainer,
                ),
                child: const Text('Enable'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final bool isActive;
  final bool hasPermission;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.isActive,
    required this.hasPermission,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: hasPermission ? onPressed : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor:
              isActive ? colors.errorContainer : colors.primaryContainer,
          foregroundColor:
              isActive ? colors.onErrorContainer : colors.onPrimaryContainer,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? Icons.stop_circle : Icons.mic_none, size: 24),
            const SizedBox(width: 12),
            Text(
              isActive ? 'Deactivate Assistant' : 'Activate Assistant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
