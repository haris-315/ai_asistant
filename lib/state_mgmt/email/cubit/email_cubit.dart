import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/data/repos/email_repo.dart';
import 'package:ai_asistant/ui/screen/home/navigationScreen/home_screen_content.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'email_state.dart';

class EmailCubit extends Cubit<EmailState> {
  final EmailRepo _emailRepo = EmailRepo();
  int numOfGotMails = 0;
  bool hasReachedEnd = false;

  List<EmailThread> allEmails = [];
  List<EmailMessage> searchEmails = [];
  BgMailsState bgMailsState = BgMailsState.L;
  bool isSearching = false;

  EmailCubit() : super(EmailInitial()) {
    getEmails();
  }

  Future<void> getEmails({bool loadAgain = true}) async {
    try {
      emit(EmailLoading());

      final res = await _emailRepo.getAllEmails(
        toSkip: loadAgain ? 0 : numOfGotMails,
        tillHowMany: 15, // Fetch 15 emails per load
      );

      if (loadAgain) {
        allEmails = res;
        numOfGotMails = res.length;
      } else {
        allEmails.addAll(res);
        numOfGotMails += res.length;
      }

      hasReachedEnd = res.length < 15; // Check for less than 15 emails

      emit(EmailSuccess(
        emails: allEmails,
        searchEmails: searchEmails,
        hasReachedEnd: hasReachedEnd,
        isSearching: isSearching,
      ));
    } on DioException catch (de) {
      if (de.type == DioExceptionType.connectionError) {
        emit(EmailError(
          message: "We are facing network issue. Please check your internet connection.",
        ));
      } else {
        emit(EmailError(message: de.toString()));
      }
    } catch (e) {
      emit(EmailError(message: e.toString()));
    }
  }

  Future<void> filterEmails(String filter, List<EmailThread> unfilteredEmails) async {
    try {
      if (filter == "all") {
        return emit(EmailSuccess(
          emails: unfilteredEmails,
          searchEmails: searchEmails,
          hasReachedEnd: hasReachedEnd,
          isSearching: isSearching,
        ));
      }

      emit(EmailLoading());
      await Future.delayed(Duration(seconds: 1));
      emit(EmailSuccess(
        emails: unfilteredEmails.where((x) => (x.category ?? "normal") == filter).toList(),
        searchEmails: searchEmails,
        hasReachedEnd: hasReachedEnd,
        isSearching: isSearching,
      ));
    } catch (e) {
      emit(EmailError(message: e.toString()));
    }
  }

  Future<void> backLoadEmails(GlobalKey<HomeContentState> key) async {
    try {
      bgMailsState = BgMailsState.L;
      setBgState(key);
      await _emailRepo.loadMailsInBackground();
      bgMailsState = BgMailsState.F;
      setBgState(key);
    } catch (e) {
      print(e.toString());
    }
  }

  void setBgState(GlobalKey<HomeContentState> key) {
    if (key.currentContext != null && key.currentContext!.mounted) {
      key.currentState!.updateExternalState();
    }
  }

  Future<void> getEmailsBySearch({required String query}) async {
    try {
      emit(EmailLoading());
      numOfGotMails = 0;
      isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        searchEmails = [];
        emit(EmailSuccess(
          emails: allEmails,
          searchEmails: searchEmails,
          hasReachedEnd: hasReachedEnd,
          isSearching: isSearching,
        ));
        return;
      }

      final res = await _emailRepo.getEmailsBySearch(query: query);

      numOfGotMails = res.length;
      searchEmails = res;
      hasReachedEnd = res.length < 15;

      emit(EmailSuccess(
        emails: allEmails,
        searchEmails: searchEmails,
        hasReachedEnd: hasReachedEnd,
        isSearching: isSearching,
      ));
    } catch (e) {
      emit(EmailError(message: e.toString()));
    }
  }
}

enum BgMailsState { L, F }