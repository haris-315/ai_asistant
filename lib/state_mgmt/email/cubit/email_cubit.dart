import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/data/repos/email_repo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'email_state.dart';

class EmailCubit extends Cubit<EmailState> {
  final EmailRepo _emailRepo = EmailRepo();
  int numOfGotMails = 0;
  bool hasReachedEnd = false;

  List<EmailThread> _allEmails = [];

  EmailCubit() : super(EmailInitial());

  getEmails({bool loadAgain = true}) async {
    try {
      emit(EmailLoading());

      final res = await _emailRepo.getAllEmails(
        toSkip: loadAgain ? 0 : numOfGotMails,
      );

      if (loadAgain) {
        _allEmails = res;
        numOfGotMails = res.length;
      } else {
        _allEmails.addAll(res);
        numOfGotMails += res.length;
      }

      hasReachedEnd = res.length < 6;

      emit(EmailSuccess(emails: _allEmails, hasReachedEnd: hasReachedEnd));
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

  filterEmails(String filter, List<EmailThread> unfilteredEmails) async {
    try {
      if (filter == "all") {
        return emit(EmailSuccess(emails: unfilteredEmails, hasReachedEnd: false));
      }

      emit(EmailLoading());
      await Future.delayed(Duration(seconds: 1));
      emit(EmailSuccess(
        emails: unfilteredEmails.where((x) => (x.category ?? "normal") == filter).toList(),
        hasReachedEnd: false,
      ));
    } catch (e) {
      emit(EmailError(message: e.toString()));
    }
  }

  getEmailsBySearch({required String query}) async {
    try {
      emit(EmailLoading());
      numOfGotMails = 0;

      final res = await _emailRepo.getEmailsBySearch(
        toSkip: numOfGotMails,
        limit: 15,
        query: query,
      );

      _allEmails = res;
      numOfGotMails = res.length;
      hasReachedEnd = res.length < 15;

      emit(EmailSuccess(emails: _allEmails, hasReachedEnd: hasReachedEnd));
    } catch (e) {
      emit(EmailError(message: e.toString()));
    }
  }
}
