import 'package:intl/intl.dart';

String formatEmailDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return "";

  DateTime emailDate = DateTime.parse(dateString);
  DateTime now = DateTime.now();
  DateTime yesterday = now.subtract(Duration(days: 1));

  if (emailDate.year == now.year &&
      emailDate.month == now.month &&
      emailDate.day == now.day) {
   return DateFormat('hh:mm a').format(emailDate);
  } else if (emailDate.year == yesterday.year &&
      emailDate.month == yesterday.month &&
      emailDate.day == yesterday.day) {
    return "Yesterday";
  } else {
    return DateFormat('dd MMM yy').format(emailDate);
  }
}
