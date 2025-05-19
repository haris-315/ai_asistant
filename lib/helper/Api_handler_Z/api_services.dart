import 'package:ai_asistant/core/services/snackbar_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String baseUrl =
      "https://ai-assistant-backend-dk0q.onrender.com";
  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future<dynamic> apiRequest(
    String endpoint,
    String method, {
    Object? data,
    Map<String, dynamic>? queryParams,
    String? token,
    Options? options,
    Map<String, dynamic>? extraHeaders,
    FormData? formData,
  }) async {
    try {
      Map<String, dynamic> headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(extraHeaders ?? {}),
      };

      Options requestOptions = Options(headers: headers);

      // print(" Sending Request: $method $endpoint");
      // print(" Headers: $headers");
      // print(" Data: ${data ?? formData}");

      dynamic requestData = formData ?? data;

      Response response;
      switch (method.toUpperCase()) {
        case "GET":
          response = await _dio.get(
            endpoint,
            options: requestOptions,
            queryParameters: queryParams,
          );
          break;

        case "POST":
          response = await _dio.post(
            endpoint,
            data: requestData,
            options: requestOptions,
          );
          break;

        case "PUT":
          response = await _dio.put(
            endpoint,
            data: requestData,
            options: requestOptions,
          );
          break;

        case "PATCH":
          response = await _dio.patch(
            endpoint,
            data: requestData,
            options: requestOptions,
            queryParameters: queryParams,
          );
          break;

        case "DELETE":
          response = await _dio.delete(
            endpoint,
            data: requestData,
            options: requestOptions,
            queryParameters: queryParams,
          );
          break;

        default:
          throw Exception("Invalid HTTP method: $method");
      }

      // print("Response Status: ${response.statusCode}");
      // print("Response Body: ${response.data}");

      switch (response.statusCode) {
        case 200:
        case 201:
        case 202:
          return response.data;
        case 204:
          return {"message": "No Content"};
        case 400:
        case 401:
        case 403:
        case 404:
        case 405:
        case 429:
        case 500:
          throw response.data;
        default:
          throw {"message": "Unexpected Error", "status": response.statusCode};
      }
    } on DioException catch (de) {
      if (de.type == DioExceptionType.connectionError) {
        throw "We are facing network issue. Please check you internet connection.";
      } else {
        
        return de.response!.data;
      }
    } catch (e) {
      return {"message": "Request failed", "error": e.toString()};
    }
  }

  void showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Loading...", style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showError(BuildContext context, String message) {
    SnackbarService.messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(BuildContext context, String message) {
    SnackbarService.messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
