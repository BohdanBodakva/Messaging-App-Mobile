String formatDateTime(DateTime dateTime) {
  DateTime now = DateTime.now();
  String formattedDate;

  if (dateTime.year == now.year) {
    if (dateTime.day == now.day && dateTime.month == now.month) {
      formattedDate = 'Today, ${_formatTime(dateTime)}';
    } else if (dateTime.day == now.day - 1 && dateTime.month == now.month) {
      formattedDate = 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      formattedDate = '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
    }
  } else {
    formattedDate = '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
  }
  return formattedDate;
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
