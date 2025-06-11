import 'dart:async';
import 'dart:convert';

import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:ai_asistant/data/models/service_models/assistant_service_model.dart';
import 'package:ai_asistant/data/repos/email_repo.dart';
import 'package:ai_asistant/ui/screen/assistant/assistant_settings.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class AssistantControlPage extends StatefulWidget {
  const AssistantControlPage({super.key});

  @override
  State<AssistantControlPage> createState() => _AssistantControlPageState();
}

class _AssistantControlPageState extends State<AssistantControlPage> {
  bool _isLoading = true;
  AssistantServiceModel assistantServiceModel = AssistantServiceModel.empty();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadFirstTime();
    await _loadKey();
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
      var mails = await stringifiedEmails();
      String hash = computeListHash(mails);
      if (hash != newData.mailsSyncHash) {
        await NativeBridge.dumpMails(mails);
        print("Sending mails...");
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<List<String>> stringifiedEmails() async {
    List<EmailMessage> mails = await EmailRepo.getEmailsReceivedToday();
    return mails.map((eml) => eml.toString()).toList();
  }

  String computeListHash(List<String> list) {
    final sortedList = [...list]..sort();
    final joined = sortedList.join(',');
    return md5.convert(utf8.encode(joined)).toString();
  }

  Future<void> _loadKey() async {
    // await SettingsService.removeSetting("akey");

    String? key = await SettingsService.getSetting("akey");
    if (key != null) {
      await NativeBridge.setPorcupineKey(key);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((c) {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.leftToRight,
            child: SettingsPage(),
          ),
        );
      });
    }
  }

  Future<void> _toggleListening() async {
    if (!assistantServiceModel.isStoped) {
      await NativeBridge.stopListening();
      if (!_mounted) return;
    } else {
      await NativeBridge.startListening();
      if (!_mounted) return;
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !assistantServiceModel.isStoped;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 24),
                  // Tech-inspired status circle
                  _AssistantStatusCircle(
                    isActive: isActive,
                    isStandBy: assistantServiceModel.isStandBy,
                    isWarmingTts: assistantServiceModel.isWarmingTts,
                  ),
                  const SizedBox(height: 32),
                  // Speech recognition display
                  _SpeechDisplay(
                    text: assistantServiceModel.recognizedText,
                    isActive: isActive,
                  ),
                  const Spacer(),
                  // Control button
                  _TechControlButton(
                    isActive: isActive,
                    isWarmingTts: assistantServiceModel.isWarmingTts,
                    onPressed: _toggleListening,
                  ),
                ],
              ),
    );
  }
}

class _AssistantStatusCircle extends StatelessWidget {
  final bool isActive;
  final bool isStandBy;
  final bool isWarmingTts;

  const _AssistantStatusCircle({
    required this.isActive,
    required this.isStandBy,
    required this.isWarmingTts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive
                      ? colors.primary.withValues(alpha: 0.3)
                      : colors.outline.withValues(alpha: 0.2),
              width: 8,
            ),
          ),
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isActive
                      ? colors.primary.withValues(alpha: 0.5)
                      : colors.outline.withValues(alpha: 0.3),
              width: 6,
            ),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive
                    ? colors.primary.withValues(alpha: 0.1)
                    : colors.surfaceContainerHighest,
            border: Border.all(
              color:
                  isActive
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWarmingTts)
                SizedBox(height: 36, child: Image.asset("assets/fire.gif"))
              else
                Icon(
                  isActive ? Icons.assistant : Icons.assistant_outlined,
                  size: 48,
                  color: isActive ? colors.primary : colors.outline,
                ),
              const SizedBox(height: 8),
              Text(
                isWarmingTts
                    ? "INITIALIZING"
                    : !isActive
                    ? "INACTIVE"
                    : isStandBy
                    ? "STANDBY"
                    : "LISTENING",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isActive ? colors.primary : colors.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                !isActive
                    ? "Inactive"
                    : isStandBy
                    ? "Standby"
                    : "Listening",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpeechDisplay extends StatelessWidget {
  final String text;
  final bool isActive;

  const _SpeechDisplay({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive
                  ? colors.primary.withValues(alpha: 0.3)
                  : colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard_voice,
                size: 20,
                color: isActive ? colors.primary : colors.outline,
              ),
              const SizedBox(width: 8),
              Text(
                "VOICE INPUT",
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: colors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text.isEmpty ? 'Waiting for voice input...' : text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
                color: text.isEmpty ? colors.outline : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechControlButton extends StatelessWidget {
  final bool isActive;
  final bool isWarmingTts;
  final VoidCallback onPressed;

  const _TechControlButton({
    required this.isActive,
    required this.isWarmingTts,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(24),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: isActive ? colors.errorContainer : colors.primaryContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isWarmingTts ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWarmingTts)
                  SizedBox(height: 24, child: Image.asset("assets/fire.gif"))
                else
                  Icon(
                    isActive ? Icons.power_settings_new : Icons.mic,
                    size: 28,
                    color:
                        isActive
                            ? colors.onErrorContainer
                            : colors.onPrimaryContainer,
                  ),
                const SizedBox(width: 12),
                Text(
                  isWarmingTts
                      ? "SYSTEM WARMING"
                      : isActive
                      ? 'DEACTIVATE'
                      : 'ACTIVATE',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isActive
                            ? colors.onErrorContainer
                            : colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
