extension StringExtension on String {

  int createNotificationIdFromUuid() {
    // Remove hyphens just to be safe
    final cleanUuid = this.replaceAll('-', '');

    // Take the first 7 characters 
    final hexSubstring = cleanUuid.substring(0, 7);

    // Parse the hex string into a standard Dart integer
    return int.parse(hexSubstring, radix: 16);
  }
}