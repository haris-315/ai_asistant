// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/core/shared/functions/show_snackbar.dart';
import 'package:ai_asistant/data/models/chats/session_model.dart';
import 'package:ai_asistant/data/models/chats/session_model_placeholder.dart';
import 'package:ai_asistant/state_mgmt/chats/cubit/chat_cubit.dart';
import 'package:ai_asistant/state_mgmt/sessions/cubit/sessions_cubit.dart';
import 'package:ai_asistant/ui/widget/animted_typing_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widget/drawer.dart';

class ChatScreen extends StatefulWidget {
  final SessionModelHolder? session;
  const ChatScreen({super.key, this.session});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SessionModel currentSession;
  String activeModel = AppConstants.availableModels.first;
  bool disableSend = true;
  int? lastAnimatedIndex;
  bool showAnimatedResponse = false;
  bool _showScrollDownFab = false;

  final Set<String> _animatedMessages = {};

  void sendMessage(SessionModel session) {
    if (_controller.text.isNotEmpty) {
      showAnimatedResponse = true;
      context.read<ChatCubit>().sendMessage(
        message: _controller.text.trim(),
        session: session,
        isNewSession: currentSession.id.isEmpty || currentSession.id == "",
        model: activeModel,
        onDone: (session) {
          if (session.messages.length == 2) {
            context.read<SessionsCubit>().loadSessions(force: true);
          }
          _scrollToBottom();
        },
        refreshSessions: () {
          context.read<SessionsCubit>().loadSessions();
        },
      );
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (currentScroll < maxScroll - 100) {
        if (!_showScrollDownFab) {
          setState(() {
            _showScrollDownFab = true;
          });
        }
      } else {
        if (_showScrollDownFab) {
          setState(() {
            _showScrollDownFab = false;
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      currentSession = SessionModel.empty(id: widget.session!.id);
    } else {
      currentSession = SessionModel.empty();
    }

    _scrollController.addListener(_handleScroll);

    _controller.addListener(() {
      if (_controller.text.isNotEmpty && disableSend) {
        setState(() {
          disableSend = false;
        });
      } else if (_controller.text.isEmpty && !disableSend) {
        setState(() {
          disableSend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          showSnackBar(context: context, message: state.message);
        }
        if (state is ChatLoaded) {
          setState(() {
            currentSession = state.currentActiveSession;
            if (currentSession.messages.isNotEmpty) {
              lastAnimatedIndex = currentSession.messages.length - 1;
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            backgroundColor: Colors.white,
            title: buildModelSelector(),
            actions: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.blue),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/home");
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: const SideMenu(),
          floatingActionButton:
              _showScrollDownFab
                  ? FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.blue,
                    onPressed: _scrollToBottom,
                    child: const Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  )
                  : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              Expanded(
                child:
                    currentSession.messages.isEmpty
                        ? buildEmptyPrompt(textTheme)
                        : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5.w,
                            vertical: 1.h,
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                currentSession.messages.length +
                                (state is ChatLoading && !state.isLoadingSession
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == currentSession.messages.length &&
                                  state is ChatLoading &&
                                  !state.isLoadingSession) {
                                return buildLoadingDots();
                              }

                              if (index >= currentSession.messages.length) {
                                return const SizedBox(height: 100);
                              }

                              final message = currentSession.messages[index];
                              final isAI = message.role == "assistant";
                              final isLatestAI =
                                  isAI && index == lastAnimatedIndex;

                              final messageId = message.id;
                              final shouldAnimate =
                                  isLatestAI &&
                                  showAnimatedResponse &&
                                  !_animatedMessages.contains(messageId);

                              if (shouldAnimate) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _animatedMessages.add(messageId);
                                });
                              }

                              return AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment:
                                    isAI
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                child: Padding(
                                  padding:
                                      isAI
                                          ? const EdgeInsets.only(right: 40.0)
                                          : const EdgeInsets.only(left: 40.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isAI
                                              ? Colors.blue.shade100
                                              : Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        buildSenderTag(isAI),
                                        const SizedBox(height: 6),
                                        shouldAnimate
                                            ? AnimatedTypingText(
                                              text: message.content,
                                              textStyle: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                            )
                                            : isAI
                                            ? MarkdownBody(
                                              data: message.content,
                                              selectable: true,
                                              styleSheet: MarkdownStyleSheet(
                                                p: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                code: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      fontFamily: 'monospace',
                                                      fontSize: 14,
                                                    ),

                                                h1: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                                h2: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                h3: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                h4: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                h5: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                                listBullet: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                codeblockPadding:
                                                    const EdgeInsets.all(8),
                                                codeblockDecoration:
                                                    BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                              ),
                                            )
                                            : Text(
                                              message.content,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
              buildInputArea(textTheme),
            ],
          ),
        );
      },
    );
  }

  Widget buildModelSelector() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.model_training, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeModel,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items:
                    AppConstants.availableModels
                        .map(
                          (model) => DropdownMenuItem<String>(
                            value: model,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(model.toUpperCase()),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? newVal) {
                  setState(() {
                    activeModel = newVal ?? activeModel;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyPrompt(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 32, color: Colors.blue),
          const SizedBox(height: 10),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            style:
                textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black,
                ) ??
                const TextStyle(),
            child: const Text("How Can I Help You Today?"),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingDots() {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: JumpingDots(
          color: Colors.blue,
          radius: 6,
          animationDuration: const Duration(milliseconds: 200),
          innerPadding: 2,
          numberOfDots: 4,
        ),
      ),
    );
  }

  Widget buildSenderTag(bool isAI) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Align(
        alignment: Alignment.topLeft,
        child: CircleAvatar(
          radius: 12,
          backgroundColor: isAI ? Colors.blue : Colors.amber,
          child: Text(
            isAI ? "AI" : "You",
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget buildInputArea(TextTheme textTheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.blue.shade300, width: 2)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  maxLines: null,
                  scrollPhysics: const AlwaysScrollableScrollPhysics(),
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "I need an AI assistant",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: InkWell(
                  key: ValueKey<bool>(disableSend),
                  onTap:
                      disableSend
                          ? null
                          : () {
                            sendMessage(currentSession);
                          },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: disableSend ? Colors.blueGrey : Colors.blue,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
