class AppConstants {
  static List<String> availableModels = [
    "gpt-4o",
    "gpt-4-turbo",
    "gpt-4",
    "gpt-3.5-turbo",
  ];
  static final baseUrl = "https://ai-assistant-backend-dk0q.onrender.com/";
  static String appStateKey = "asKey";
  static String appStateInitializing = "init";
  static String appStateInitialized = "done";
  static String cuVoiceKey = "cuVK";
  static final String firstCheckKey = "frstchk";
}
