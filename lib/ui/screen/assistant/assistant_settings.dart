// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/data/models/service_models/voice.dart';
import 'package:ai_asistant/ui/widget/input_field.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _hasPermission;
  List<Voice> voices = [];
  String? selectedVoice;
  bool _loadingVoices = false;
  bool toSetAKey = false;
  Map<dynamic, dynamic>? keyRes;
  TextEditingController con = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initialize();
    con.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initialize() async {
    await _checkPermission();
    await _loadVoices();
    await _loadKey();
  }

  Future<void> _loadVoices() async {
    if (!mounted) return;
    setState(() => _loadingVoices = true);
    try {
      final loadedVoices = await NativeBridge.getOrSetAvailableVoices(null);
      if (!mounted) return;
      setState(() {
        voices = loadedVoices;
        _loadingVoices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingVoices = false);
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _setVoice(String? voice) async {
    if (voice == null) return;

    await NativeBridge.getOrSetAvailableVoices(voice);
    await SettingsService.storeSetting(AppConstants.cuVoiceKey, voice);
    if (!mounted) return;
    setState(() => selectedVoice = voice);
  }

  Future<void> _loadKey() async {
    String? key = await SettingsService.getSetting("akey");
    if (key != null) {
      await NativeBridge.setPorcupineKey(key);
    } else {
      setState(() {
        toSetAKey = true;
      });
    }
  }

  Future<bool> _setKey(String key) async {
    try {
      SettingsService.storeSetting("akey", key);
      Map<dynamic, dynamic> res = await NativeBridge.setPorcupineKey(key);
      setState(() {
        keyRes = res;
      });
      await Future.delayed(const Duration(milliseconds: 1600));
      if (res['success'] ?? false) {
        setState(() {
          toSetAKey = false;
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showVoiceSelectionDialog() async {
    if (voices.isEmpty) {
      await _loadVoices();
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: -12,
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'VOICE SELECTOR',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child:
                          _loadingVoices
                              ? const Center(
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                              : voices.isEmpty
                              ? _buildEmptyState(context)
                              : CustomScrollView(
                                slivers: [
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) => _buildVoiceItem(
                                        context,
                                        voices[index],
                                      ),
                                      childCount: voices.length,
                                    ),
                                  ),
                                  const SliverPadding(
                                    padding: EdgeInsets.only(bottom: 12),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'DONE',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.voice_chat_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No voices available",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check your connection",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceItem(BuildContext context, Voice voice) {
    final isSelected = selectedVoice == voice.name;
    final isOnline = voice.isOnline ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await _setVoice(voice.name);
            if (!mounted) return;
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child:
                      isSelected
                          ? Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voice.locale ?? "Voice",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        voice.name ?? "",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOnline
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline ? Icons.circle : Icons.circle_outlined,
                            size: 8,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? "LIVE" : "OFFLINE",
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${voice.latency.toString()}ms",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    con.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: true,
      ),
      body:
          toSetAKey
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomFormTextField(
                        focusNode: focusNode,
                        error: "Porcupine Key",
                        label: "Porcupine Key",
                        icon: Icons.lock,
                        controller: con,
                      ),
                      const SizedBox(height: 25),
                      MaterialButton(
                        onPressed:
                            con.text.isEmpty
                                ? null
                                : () async {
                                  focusNode.unfocus();
                                  if (con.text.isNotEmpty) {
                                    await _setKey(con.text.trim());
                                  }
                                },
                        child: const Text("Set Key"),
                      ),
                      const SizedBox(height: 24),
                      if (keyRes != null)
                        Text(
                          keyRes?['msg'] ?? "",
                          maxLines: null,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                keyRes?['success'] ?? false
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _MicrophonePermissionCard(
                    hasPermission: _hasPermission,
                    onRequestPermission: _requestPermission,
                  ),
                  const SizedBox(height: 16),
                  _VoiceSelectionCard(
                    currentVoice: selectedVoice,
                    onTap: _showVoiceSelectionDialog,
                    isLoading: _loadingVoices,
                  ),
                ],
              ),
    );
  }
}

class _VoiceSelectionCard extends StatelessWidget {
  final String? currentVoice;
  final VoidCallback onTap;
  final bool isLoading;

  const _VoiceSelectionCard({
    required this.currentVoice,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.voice_chat, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistant Voice',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: LinearProgressIndicator(),
                      )
                    else
                      Text(
                        currentVoice ?? 'No voice selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              currentVoice != null
                                  ? colors.onSurface
                                  : colors.onSurface.withValues(alpha: 0.6),
                          fontStyle:
                              currentVoice == null ? FontStyle.italic : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                color: colors.onSurface.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
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
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.error.withValues(alpha: 0.1),
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
                      color: colors.onSurface.withValues(alpha: 0.6),
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
