import 'package:ai_asistant/data/models/chats/chat_model.dart';
import 'package:ai_asistant/data/models/chats/session_model.dart';
import 'package:ai_asistant/data/models/chats/session_model_placeholder.dart';
import 'package:ai_asistant/data/repos/chat_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepo _chatRepo = ChatRepo();
  ChatCubit() : super(ChatInitial());

  setChatSession(String session) async {
    try {
      emit(ChatLoading());
      final res = await _chatRepo.getSingleSession(session);
      emit(ChatLoaded(currentActiveSession: res));
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          return emit(
            ChatError(
              message:
                  "We are having network issues. Please check you internet connection.",
            ),
          );
        }
      }
      emit(ChatError(message: e.toString()));
    }
  }

  sendMessage({
    required String message,
    String model = "gpt-4-turbo",
    required SessionModel session,
    required bool isNewSession,
    Function(SessionModel session)? onDone,
    VoidCallback? refreshSessions,
  }) async {
    try {
      session.messages.add(ChatModel(id: "", role: "user", content: message));
      emit(ChatLoaded(currentActiveSession: session));
      if (onDone != null) {
        Future.microtask(() {
          onDone(session);
        });
      }
      emit(ChatLoading());
      final response = await _chatRepo.sendMessage(
        message: message,
        sessionId: session.id,
        model: model,
        isNewSession: isNewSession,
      );
      session.messages.add(ChatModel.fromMap(response['ai_reply']));
      final SessionModelHolder currentSessionInfo = SessionModelHolder.fromMap(
        response['session'],
      );
      if (kDebugMode) {
        print(response);
      }
      emit(
        ChatLoaded(
          currentActiveSession: session.copyWith(
            id: currentSessionInfo.id,
            title: currentSessionInfo.title,
            model: currentSessionInfo.model,
            system_prompt: currentSessionInfo.system_prompt,
            category: currentSessionInfo.category,
          ),
        ),
      );
      if (session.messages.length == 2 && refreshSessions != null) {
        refreshSessions.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return emit(ChatError(message: e.toString()));
    }
  }
}
