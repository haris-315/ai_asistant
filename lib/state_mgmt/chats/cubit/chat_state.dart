part of 'chat_cubit.dart';

@immutable
sealed class ChatState {}

final class ChatInitial extends ChatState {}

final class ChatLoading extends ChatState {
  final bool isLoadingSession;

  ChatLoading({this.isLoadingSession = false});
}

final class ChatLoaded extends ChatState {
  final SessionModel currentActiveSession;

  ChatLoaded({required this.currentActiveSession});
}

final class ChatError extends ChatState {
  final String message;

  ChatError({required this.message});
}
