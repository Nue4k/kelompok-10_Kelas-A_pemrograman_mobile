import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a Firestore field ([Timestamp], [DateTime], or null) to [DateTime?].
DateTime? dateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// Converts a nullable [DateTime] to a Firestore [Timestamp?].
Timestamp? dateToFirestore(DateTime? date) {
  if (date == null) return null;
  return Timestamp.fromDate(date);
}

/// Returns the local calendar date (midnight) for [dt].
DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
