import 'package:intl/intl.dart';

class Formatters {
  static String formatPrice(int amountFc) {
    final formatter = NumberFormat('#,###', 'fr_CD');
    return '${formatter.format(amountFc)} FC';
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatEventDate(DateTime date) {
    return DateFormat("EEEE dd MMMM 'à' HH:mm", 'fr_FR').format(date);
  }

  static String formatYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return dateStr.substring(0, 4);
    } catch (_) {
      return '';
    }
  }

  static String formatRating(double? rating) {
    if (rating == null) return 'N/A';
    return rating.toStringAsFixed(1);
  }

  static String formatVotes(int? votes) {
    if (votes == null) return '0';
    if (votes >= 1000) {
      return '${(votes / 1000).toStringAsFixed(1)}k';
    }
    return votes.toString();
  }
}
