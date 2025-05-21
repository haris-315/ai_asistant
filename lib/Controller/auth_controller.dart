// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/data/models/emails/attachment.dart';
import 'package:ai_asistant/data/models/emails/email_summarization_model.dart';
import 'package:ai_asistant/data/models/emails/thread_summarization_model.dart';
import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:ai_asistant/data/models/projects/project_model.dart';
import 'package:ai_asistant/data/models/projects/section_model.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:ai_asistant/helper/Api_handler_Z/api_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/emails/thread_detail.dart';
import '../data/models/threadmodel.dart';
import '../ui/widget/snackbar.dart';

class AuthController extends GetxController {
  final ApiService apiService = ApiService();
  // final _SettingsService = const FlutterSettingsService();

  var emails = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  RxList<LabelModel> labels = <LabelModel>[].obs;
  RxList<Project> projects = <Project>[].obs;
  RxList<TaskModel> task = <TaskModel>[].obs;
  RxList<TaskModel> trashedTasks = <TaskModel>[].obs;
  RxList<SectionModel> sections = <SectionModel>[].obs;

  Future<List<SectionModel>?> loadProjectSectionsid(int id) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/sections/project/$id",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch sections. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      try {
        sections.assignAll(
          (response as List).map((f) => SectionModel.fromMap(f)),
        );
        return sections;
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Invalid response format.",
          backgroundColor: Colors.red,
        );
        return null;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<List<SectionModel>?> deleteSection(SectionModel section) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      var res = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/sections/${section.id}",
        "DELETE",
        token: token,
      );
      hideLoader();

      if (res is! Map || !res.containsKey("message")) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to delete section. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      try {
        sections.remove(section);
        return sections;
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Invalid response format.",
          backgroundColor: Colors.red,
        );
        return null;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<List<SectionModel>?> updateSection(SectionModel section) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      var res = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/sections/${section.id}",
        "PUT",
        data: section.toMap(),
        token: token,
      );
      hideLoader();

      if (res == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to update section. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      try {
        int index = sections.indexWhere((s) => s.id == section.id);
        if (index != -1) {
          sections[index] = section;
        }
        return sections;
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Invalid response format.",
          backgroundColor: Colors.red,
        );
        return null;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<List<SectionModel>?> createSection(SectionModel section) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      var res = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/sections/",
        "POST",
        data: section.toMap()..remove("id"),
        token: token,
      );
      hideLoader();

      if (res == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to create section. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      try {
        sections.add(SectionModel.fromMap(res));
        return sections;
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Invalid response format.",
          backgroundColor: Colors.red,
        );
        return null;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  void showLoader({
    bool isForEmailSummary = false,
    bool toShow = true,
    bool isForInbox = false,
  }) {
    if (!(Get.isDialogOpen ?? false) && toShow) {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(Get.context!).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(Get.context!).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isForEmailSummary ? "Optimizing Your Email" : "Loading",
                  style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(Get.context!).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isForEmailSummary
                      ? "AI is crafting the perfect message..."
                      : isForInbox
                      ? "Please wait while your inbox is getting ready."
                      : "Please wait while your request is being processed",
                  textAlign: TextAlign.center,
                  style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(
                      Get.context!,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

                SizedBox(height: 10),
                MaterialButton(
                  onPressed: () {
                    Navigator.of(Get.context!).pop();
                  },
                  color: Colors.blue,
                  child: Text("Stop!"),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  void hideLoader() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  Future<bool> hasAccess(String ackey) async {
    try {
      var res = await apiService.apiRequest(
        "https://pamaas-3xiy6a0vf-haris-eldevs-projects.vercel.app/access?ackey=$ackey",
        "GET",
      );
      if (kDebugMode) {
        print(res);
      }
      if (res is Map && res[ackey] != null && res[ackey] == "true") {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }
  }

  Future<bool> isInternetAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult[0] == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup('1.1.1.1');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool?> Registration(String name, String email, String password) async {
    try {
      Map<String, dynamic> requestBody = {
        "name": name,
        "email": email,
        "password": password,
      };

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}auth/register",
        "POST",
        // token: token,
        data: requestBody,
      );

      hideLoader();

      if (response != null &&
          response is Map<String, dynamic> &&
          response.containsKey("message")) {
        showCustomSnackbar(
          title: "Successfully",
          message: "Registration successfully",
          backgroundColor: Colors.blue,
          icon: Icons.check_box_outlined,
        );
        return true;
      } else {
        String error = "Registration failed. Please try again.";
        if (response != null &&
            response is Map<String, dynamic> &&
            response.containsKey("detail")) {
          final detail = response['detail'];

          if (detail is List && detail.isNotEmpty) {
            error = detail.first.toString();
          } else if (detail is String) {
            error = detail;
          } else {
            error = detail.toString();
          }
        }
        showCustomSnackbar(
          title: "Error",
          message: error,
          backgroundColor: Colors.red,
        );

        return false;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occurred while sending the reply.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool?> LoginUser(String email, String password) async {
    try {
      Map<String, dynamic> requestBody = {"email": email, "password": password};

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}auth/login",
        "POST",
        data: requestBody,
      );

      hideLoader();

      if (response != null &&
          response is Map<String, dynamic> &&
          response.containsKey("access_token")) {
        String token = response['access_token'];
        await SettingsService.storeSetting("access_token", token);

        showCustomSnackbar(
          title: "Success",
          message: "Signed in successfully",
          backgroundColor: Colors.blue,
          icon: Icons.check_box_outlined,
        );

        return true;
      } else {
        String error = "Login failed. Please try again.";
        if (response != null &&
            response is Map<String, dynamic> &&
            response.containsKey("detail")) {
          final detail = response['detail'];

          if (detail is List && detail.isNotEmpty) {
            error = detail.first.toString();
          } else if (detail is String) {
            error = detail;
          } else {
            error = detail.toString();
          }
        }

        showCustomSnackbar(
          title: "Error",
          message: error,
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An unexpected error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<String?> outLooklogin() async {
    if (!await isInternetAvailable()) {
      hideLoader();
      showCustomSnackbar(
        title: "No Internet",
        message: "Check your Internet connection.",
        backgroundColor: Colors.red,
      );
      return null;
    }

    showLoader();

    try {
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}auth/outlook/login",
        "GET",
      );

      hideLoader();

      if (response != null && response.containsKey("redirect_url")) {
        return response["redirect_url"];
      } else {
        showCustomSnackbar(
          title: "Error",
          message: "Try Again Please",
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      hideLoader();
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }

    return null;
  }

  //email
  Future<void> fetchEmails({bool isInitialLoad = false}) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      if (!isInitialLoad) showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/inbox",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      }

      try {
        if (response is Map<String, dynamic>) {
          if (response.containsKey('emails')) {
          } else {}

          var fetchedEmails = response['emails'];
          if (fetchedEmails is List && fetchedEmails.isNotEmpty) {
            emails.assignAll(fetchedEmails.cast<Map<String, dynamic>>());
          } else {
            showCustomSnackbar(
              title: "No Emails",
              message: "Your inbox is empty.",
              backgroundColor: Colors.blue,
            );
          }
          return;
        }

        var emailData = jsonDecode(response);

        if (emailData is Map<String, dynamic> &&
            emailData.containsKey('emails')) {
          var fetchedEmails = emailData['emails'];
          if (fetchedEmails is List && fetchedEmails.isNotEmpty) {
            emails.assignAll(fetchedEmails.cast<Map<String, dynamic>>());
          } else {
            showCustomSnackbar(
              title: "No Emails",
              message: "Your inbox is empty.",
              backgroundColor: Colors.blue,
            );
          }
        } else {
          throw Exception("Unexpected API response format");
        }
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Invalid response format.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> syncMailboxbulk() async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/sync-mailbox-bulk",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      } else {}
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> syncMailboxPeriodically() async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      // showLoader();
      var response = await apiService.apiRequest(
        // ${AppConstants.baseUrl}email/sync-mailbox
        "${AppConstants.baseUrl}email/sync-mailbox",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      } else {}
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  var emailThreads = <EmailThread>[].obs;
  Future<void> GetThreads() async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/threads",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      } else {
        List<EmailThread> threads =
            (response as List).map((e) => EmailThread.fromJson(e)).toList();

        emailThreads.assignAll(threads);
        emailThreads.refresh();

        // emailThreads.value = threads;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  var emailMessages = <EmailMessage>[].obs;
  Future<Map<String, dynamic>?> GetThreadbyID(
    String emailId,

    EmailThread email, {
    bool notToShowLoader = false,
  }) async {
    try {
      String? token = await SettingsService.getToken();
      if (token == null || token.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      if (!notToShowLoader) showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/threads/$emailId",
        "GET",
        token: token,
      );
      hideLoader();
      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      // Parse email messages
      List<EmailMessage> emails =
          response.map<EmailMessage>((e) => EmailMessage.fromJson(e)).toList();

      // Process last email if needed

      return {"thread": email, "thread_mails": emails};
    } catch (e) {
      print(e);
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<EmailSummarizationModel?> emailAiProccess(
    String emailId, {
    bool shouldShowLoader = true,
  }) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      if (shouldShowLoader) showLoader(isForEmailSummary: true);
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/ai-process/$emailId",
        "GET",
        token: token,
      );
      hideLoader();
      // print(response);
      if (response == null) {
        // print(response.runtimeType);
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      } else {
        final replies = List<String>.from(
          response['quick_replies'].map((x) => x.toString()),
        );
        response['quick_replies'] = replies;
        return EmailSummarizationModel.fromMap(response);
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
    return null;
  }

  Future<SummarizationModel?> threadAiProccess(String threadId) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      showLoader(isForEmailSummary: true);
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/ai-process/thread/$threadId",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch emails. No response received.",
          backgroundColor: Colors.red,
        );
        return null;
      } else {
        return SummarizationModel.fromJson(response);
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
    return null;
  }

  Future<bool?> emailReply(
    String emailId,
    String reply, {
    List<Attachment>? attachments,
  }) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "Please log in to reply to emails.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      Map<String, dynamic> requestBody = {"reply_body": reply};

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/inbox/$emailId/reply",
        "POST",
        token: token,
        data: requestBody,
      );

      hideLoader();

      if (response != null &&
          response is Map<String, dynamic> &&
          response.containsKey("message")) {
        showCustomSnackbar(
          title: "Successfully",
          message: "Reply sent successfully",
          backgroundColor: Colors.blue,
          icon: Icons.check_box_outlined,
        );
        return true;
      } else {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to send reply. Please try again.",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occurred while sending the reply.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool?> SendNewEmail(
    String to,
    String subject,
    String body, {
    List<Attachment>? attachments,
  }) async {
    try {
      String? token = await SettingsService.getToken();
      if (token == null || token.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "Please log in to reply to emails.",
          backgroundColor: Colors.red,
        );
        return null;
      }

      Map<String, dynamic> requestBody = {
        "to": to,
        "subject": subject,
        "body": body,
      };

      if (attachments != null && attachments.isNotEmpty) {
        requestBody["attachments"] =
            attachments.map((att) => att.toMap()).toList();
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}email/send",
        "POST",
        token: token,
        data: requestBody,
      );

      hideLoader();

      if (response != null &&
          response is Map<String, dynamic> &&
          response.containsKey("message")) {
        showCustomSnackbar(
          title: "Success",
          message: "Email sent successfully",
          backgroundColor: Colors.blue,
          icon: Icons.check_box_outlined,
        );
        return true;
      } else {
        showCustomSnackbar(
          title: "Error",
          message:
              "Failed to send Mail. Either you are using account that is not outlook account or there is some other problem.",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occurred while sending the reply.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool> addNewProject(Project project, {bool isInbox = false}) async {
    try {
      String? token = await SettingsService.getToken();

      if (token == null || token.isEmpty) {
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      final response = await apiService.apiRequest(
        '${AppConstants.baseUrl}todo/projects/',
        "POST",
        data: project.toMap(),
        token: token,
      );

      if (response is Map<String, dynamic>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            title: "Success",
            message:
                isInbox
                    ? "Your inbox is ready."
                    : "Project added successfully.",
            backgroundColor: Colors.green,
          );
        });
        return true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            title: "Error",
            message: "Unexpected response format.",
            backgroundColor: Colors.red,
          );
        });
        return false;
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackbar(
          title: "Error",
          message: "An error occured please try again.",
          backgroundColor: Colors.red,
        );
      });
      return false;
    } finally {
      hideLoader();
    }
  }

  Future<bool> fetchProject({bool isInitialFetch = false}) async {
    try {
      String? token = await SettingsService.getToken();
      if (token == null || token.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      if (!isInitialFetch) showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/projects",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch projects. No response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      try {
        var projectData = response;
        if (projectData is List) {
          projects.assignAll(projectData.map((x) => Project.fromMap(x)));
          return true;
        } else {
          showCustomSnackbar(
            title: "Error",
            message: "Unexpected response format.",
            backgroundColor: Colors.red,
          );
          return false;
        }
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Unexpected response format.",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      hideLoader();
    }
  }

  Future<bool> editProject(Project project) async {
    try {
      String? token = await SettingsService.getToken();

      if (token == null || token.isEmpty) {
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/projects/${project.id}",
        "PUT",
        data: project.toMap(),
        token: token,
      );

      if (response == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            title: "Error",
            message: "Failed to update the project. No response received.",
            backgroundColor: Colors.red,
          );
        });
        return false;
      }

      if (response is Map<String, dynamic>) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            title: "Success",
            message: "Project successfully updated.",
            backgroundColor: Colors.green,
          );
        });
        return true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            title: "Error",
            message: "Unexpected response format.",
            backgroundColor: Colors.red,
          );
        });
        return false;
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCustomSnackbar(
          title: "Error",
          message: "An error occured please try again.",
          backgroundColor: Colors.red,
        );
      });
      return false;
    } finally {
      hideLoader();
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      String? token = await SettingsService.getToken();

      if (token == null || token.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/projects/$id",
        "DELETE",
        token: token,
      );

      hideLoader();

      if (response == null ||
          (response is Map && response['message'] != 'Project deleted')) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to delete project. No valid response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      final _ = await fetchProject();
      showCustomSnackbar(
        title: "Project Deleted",
        message: "The project has been successfully deleted.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      hideLoader();
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  //label
  Future<bool> addNewLabel(LabelModel label) async {
    try {
      String? token = await SettingsService.getToken();

      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/labels/",
        "POST",
        data: label.toMap(),
        token: token,
      );

      hideLoader();

      try {
        labels.add(LabelModel.fromMap(response));
        showCustomSnackbar(
          title: "Success",
          message: "Label added successfully.",
          backgroundColor: Colors.green,
        );
        return true;
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Unexpected response format.",
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      hideLoader();

      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<void> fetchLabels() async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }
      // showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/labels",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch Labels. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      }

      try {
        var labelsData = response;

        if (labelsData is List && labelsData.isNotEmpty) {
          labels.assignAll(labelsData.map((x) => LabelModel.fromMap(x)));

          hideLoader();
        } else {
          showCustomSnackbar(
            title: "No labels",
            message: "You have no Labels yet.",
            backgroundColor: Colors.blue,
          );
        }
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Unexpected response format.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> labelTask(LabelModel label, TaskModel task2Label) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/task-labels/",
        "POST",
        token: token,
        data: {"label_id": label.id, "task_id": task2Label.id},
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to label the task.",
          backgroundColor: Colors.red,
        );
        return;
      }

      try {
        var labelsData = response;

        if (labelsData is Map && labelsData.isNotEmpty) {
          int index = task.indexOf(task2Label);
          if (index != -1) {
            task[index] = task2Label.copyWith(label_id: label.id);
          }
          hideLoader();
          showCustomSnackbar(
            title: "Success",
            message: "Task has been labeled",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Error! unexpected response.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> removeTaskLabel(int? labelId, TaskModel task2Label) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }
      showLoader();
      if (labelId == null) {
        hideLoader();
        showCustomSnackbar(
          title: "Error",
          message: "There is no label associated with the task.",
          backgroundColor: Colors.red,
        );
        return;
      }
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/task-labels/",
        "DELETE",
        token: token,
        data: {"label_id": labelId, "task_id": task2Label.id},
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to unlabel the task.",
          backgroundColor: Colors.red,
        );
        return;
      }

      try {
        var labelsData = response;

        if (labelsData is Map && labelsData.isNotEmpty) {
          int index = task.indexOf(task2Label);
          if (index != -1) {
            task[index] = task2Label.copyWith(label_id: null);
          }
          hideLoader();
          showCustomSnackbar(
            title: "Success",
            message: "Task has been unlabeled",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        showCustomSnackbar(
          title: "Error",
          message: "Error! unexpected response.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<bool?> editlabel(LabelModel label) async {
    try {
      String? token = await SettingsService.getToken();

      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/labels/${label.id}",
        "PUT",
        data: label.toMap(),
        token: token,
      );

      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to update the Label. No response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      int index = labels.indexWhere((l) => l.id == label.id);
      if (index != -1) {
        labels[index] = LabelModel.fromMap(response);
        showCustomSnackbar(
          title: "Success",
          message: "Label successfully updated.",
          backgroundColor: Colors.green,
        );

        return true;
      } else {
        showCustomSnackbar(
          title: "Error",
          message: "Unexpected response format.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      hideLoader();

      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
    return false;
  }

  Future<bool?> deleteLabel(LabelModel label) async {
    try {
      String? token = await SettingsService.getToken();

      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();

      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/labels/${label.id}",
        "DELETE",
        token: token,
      );

      hideLoader();

      if (response == null || response['message'] != 'Label deleted') {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to delete label. No valid response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      labels.remove(label);
      showCustomSnackbar(
        title: "Label Deleted",
        message: "The label has been successfully deleted.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      hideLoader();

      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
    return false;
  }

  //task
  Future<void> fetchTask({bool initialLoad = false}) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }

      showLoader(toShow: !initialLoad);
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch Task. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      }

      if (response is List && response.isNotEmpty) {
        try {
          var taskData = response;
          taskData.removeWhere((t) => t['is_deleted'] != null);
          var taskList = taskData.map((x) => TaskModel.fromMap(x)).toList();

          task.assignAll(taskList);
        } catch (e) {
          showCustomSnackbar(
            title: "Error",
            message: "Unexpected response format.",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> fetchTrashedTask({bool initialLoad = false}) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return;
      }
      showLoader(toShow: !initialLoad);
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/tasks/trashed",
        "GET",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to fetch Task. No response received.",
          backgroundColor: Colors.red,
        );
        return;
      }
      if (response is List && response.isNotEmpty) {
        try {
          var projectData = response;
          trashedTasks.assignAll(projectData.map((x) => TaskModel.fromMap(x)));
        } catch (e) {
          showCustomSnackbar(
            title: "Error",
            message: "Unexpected response format.",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<bool> createTask(TaskModel task2Create) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/",
        "POST",
        extraHeaders: {"Content-Type": "application/json"},
        token: token,
        data: task2Create.toMap(),
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to create Task. No response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }

      task.add(TaskModel.fromMap(response));
      showCustomSnackbar(
        title: "Success",
        message: "New task has been created.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<TaskModel?> updateTask(TaskModel task2Update) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      showLoader();
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/${task2Update.id}",
        "PUT",
        token: token,
        data: task2Update.toMap(),
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to update Task.",
          backgroundColor: Colors.red,
        );
        return null;
      }
      int index = task.indexWhere((t) => t.id == task2Update.id);
      if (index != -1) {
        task[index] = TaskModel.fromMap(response);
      }
      showCustomSnackbar(
        title: "Success",
        message: "Task has been updated.",
        backgroundColor: Colors.green,
      );
      return TaskModel.fromMap(response);
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occurred. Failed to update Task.",
        backgroundColor: Colors.red,
      );
      return null;
    } finally {}
  }

  Future<bool> restoreTask(TaskModel task2Restore) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/tasks/${task2Restore.id ?? 0}/restore",
        "POST",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to restore Task.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      task.add(task2Restore);
      trashedTasks.remove(task2Restore);

      showCustomSnackbar(
        title: "Success",
        message: "Task has been restored.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool> moveTaskToTrash(TaskModel task2Del) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/tasks/${task2Del.id}/soft-delete",
        "DELETE",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to send task to trash.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      task.remove(task2Del);
      trashedTasks.add(task2Del);

      showCustomSnackbar(
        title: "Success",
        message: "One task has been moved to trash.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  Future<bool> deleteTask(TaskModel task2Del) async {
    try {
      String? token = await SettingsService.getToken();
      if (token!.isEmpty) {
        hideLoader();
        showCustomSnackbar(
          title: "Authentication Error",
          message: "User is not logged in.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      var response = await apiService.apiRequest(
        "${AppConstants.baseUrl}todo/tasks/tasks/${task2Del.id}/hard-delete",
        "DELETE",
        token: token,
      );
      hideLoader();

      if (response == null) {
        showCustomSnackbar(
          title: "Error",
          message: "Failed to delete Task. No response received.",
          backgroundColor: Colors.red,
        );
        return false;
      }
      trashedTasks.remove(task2Del);

      showCustomSnackbar(
        title: "Success",
        message: "One task has been permenantly deleted.",
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      showCustomSnackbar(
        title: "Error",
        message: "An error occured please try again.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
}
