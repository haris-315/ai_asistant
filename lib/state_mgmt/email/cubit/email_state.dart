part of 'email_cubit.dart';

abstract class EmailState {}

class EmailInitial extends EmailState {}

class EmailLoading extends EmailState {}

class EmailSuccess extends EmailState {
  final List<EmailThread> emails;
  final List<EmailMessage> searchEmails;
  final bool hasReachedEnd;
  final bool isSearching;

  EmailSuccess({
    required this.emails,
    required this.searchEmails,
    required this.hasReachedEnd,
    this.isSearching = false,
  });
}

class EmailError extends EmailState {
  final String message;

  EmailError({required this.message});
}