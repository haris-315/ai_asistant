import 'package:ai_asistant/data/models/chats/session_model_placeholder.dart';
import 'package:ai_asistant/data/repos/chat_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sessions_states.dart';

class SessionsCubit extends Cubit<SessionsState> {
  final _chatRepo = ChatRepo();
  List<SessionModelHolder> currentSessions = [];
  bool someThingChanged = false;
  SessionsCubit() : super(SessionsInitial());
  loadSessions({bool force = false}) async {
    try {
      if (currentSessions.isNotEmpty && !force && !someThingChanged) {
        someThingChanged = false;
        return emit(SessionsLoaded(sessions: currentSessions));
      }
      emit(SessionsLoading());
      final sessions = await _chatRepo.getChatSessions();
      currentSessions =
          sessions.map((x) => SessionModelHolder.fromMap(x)).toList();
      return emit(SessionsLoaded(sessions: currentSessions));
    } catch (e) {
      print(e);
      return emit(SessionsError(message: e.toString()));
    }
  }

  void setChanges() {
    someThingChanged = true;
  }

  deleteSession(String id) async {
    try {
      emit(SessionsLoading());
      final sessions = await _chatRepo.deleteSession(id);
      currentSessions =
          sessions.map((x) => SessionModelHolder.fromMap(x)).toList();

      return emit(
        SessionsLoaded(
          sessions: currentSessions,
          hasMessage: true,
          message: "Session id: '$id' deleted successfully.",
        ),
      );
    } catch (e) {
      print(e);
      return emit(SessionsError(message: e.toString()));
    }
  }

  // createNewSession({
  //   String? title,
  //   String? model,
  //   String? category,
  //   Function(SessionModel session)? completeEvent,
  //   Function(String? message)? mustCallEvent,
  // }) async {
  //   String? error;
  //   try {
  //     emit(SessionsLoading());
  //     final sessions = await _chatRepo.startNewSession(title: title);
  //     currentSessions = sessions.map((x) => SessionModel.fromMap(x)).toList();

  //     emit(
  //       SessionsLoaded(
  //         shouldGoToChatScreen: true,
  //         sessions: currentSessions,
  //         hasMessage: true,
  //         message: "Created New Session Titled: ${currentSessions.first.title}",
  //       ),
  //     );
  //     if (completeEvent != null) {
  //       Future.microtask(() {
  //         // completeEvent.call(currentSessions.first);
  //       });
  //     }
  //   } on DioException catch (de) {
  //     if (de.type == DioExceptionType.connectionError) {
  //       error =
  //           "We are facing network issue. Please check you internet connection.";
  //     } else {
  //       error = de.message ?? "There was an error";
  //     }
  //   } catch (e) {
  //     print(e);
  //     error = e.toString();
  //     emit(SessionsError(message: e.toString()));
  //   }
  //   if (mustCallEvent != null) {
  //     Future.microtask(() {
  //       mustCallEvent.call(error);
  //     });
  //   }
  // }
}
