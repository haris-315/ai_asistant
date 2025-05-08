part of 'sessions_cubit.dart';

@immutable
sealed class SessionsState {}

final class SessionsInitial extends SessionsState {}

final class SessionsLoading extends SessionsState {}

final class SessionsLoaded extends SessionsState {
  final List<SessionModelHolder> sessions;
  final bool shouldGoToChatScreen;
  // final SessionModel currentActiveSession;
  final bool hasMessage;
  final String? message;
  SessionsLoaded({
    required this.sessions,
    // required this.currentActiveSession,
    this.shouldGoToChatScreen = false,
    this.hasMessage = false,
    this.message,
  });
}

final class SessionsError extends SessionsState {
  final String message;

  SessionsError({required this.message});
}
