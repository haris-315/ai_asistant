part of 'email_cubit.dart';

@immutable
sealed class EmailState {}

final class EmailInitial extends EmailState {}

final class EmailSuccess extends EmailState {
  final List<EmailThread> emails;
  final bool hasReachedEnd;
  EmailSuccess({required this.emails,this.hasReachedEnd = false});
}

final class EmailLoading extends EmailState {}

final class EmailError extends EmailState {
  final String message;

  EmailError({required this.message});
}
