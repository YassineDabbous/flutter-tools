import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> pickTime({
  required BuildContext context,
  required Function(TimeOfDay?) onPick,
  String? initialDate,
  DateTime? firstDate,
  // DateTime? lastDate,
  String? helpText,
  String format = 'HH:mm',
}) async {
  TimeOfDay? pickedTime = await showTimePicker(
    helpText: helpText,
    initialEntryMode: TimePickerEntryMode.dial,
    context: context,
    initialTime: initialDate == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(DateFormat(format).parse(initialDate)),
    // // currentDate: initialDate ?? DateTime.now(),
    // firstDate: firstDate ?? DateTime(2000), //DateTime.now() ,
    // lastDate: lastDate ?? DateTime(2100),
  );

  if (pickedTime != null) {
    onPick(pickedTime);
  } else {
    onPick(null);
  }
}

Future<void> pickFormatedDate({
  required BuildContext context,
  required Function(String?) onPick,
  String? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
  String format = 'yyyy-MM-dd',
}) async {
  DateTime? pickedDate = await showDatePicker(
    helpText: helpText,
    initialEntryMode: DatePickerEntryMode.calendar,
    context: context,
    initialDate: initialDate == null
        ? DateTime.now()
        : DateFormat(format).parse(initialDate),
    // currentDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2000), //DateTime.now() ,
    lastDate: lastDate ?? DateTime(2100),
  );

  if (pickedDate != null) {
    onPick(DateFormat(format).format(pickedDate));
  } else {
    onPick(null);
  }
}

Future<void> pickFormatedDateRange({
  required BuildContext context,
  required Function(String?, String?) onPick,
  String? initialDateStart,
  String? initialDateEnd,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  DateTimeRange? pickedRange = await showDateRangePicker(
    initialEntryMode: DatePickerEntryMode.input,
    context: context,
    // initialDate: DateTime.now(),
    initialDateRange: (initialDateStart == null || initialDateEnd == null)
        ? null
        : DateTimeRange(
            start: DateFormat('yyyy-MM-dd').parse(initialDateStart),
            end: DateFormat('yyyy-MM-dd').parse(initialDateEnd),
          ),
    firstDate: firstDate ?? DateTime(2000), //DateTime.now(),
    lastDate: lastDate ?? DateTime(2100),
  );

  if (pickedRange != null) {
    onPick(
      DateFormat('yyyy-MM-dd').format(pickedRange.start),
      DateFormat('yyyy-MM-dd').format(pickedRange.end),
    );
    // onPick(DateFormat('yyyy-MM-dd').format(pickedDate), addDays == null ? null : DateFormat('yyyy-MM-dd').format(pickedDate.add(Duration(days: addDays))));
  } else {
    onPick(null, null);
  }
}

Future<void> pickFormatedDateRangeOld({
  required BuildContext context,
  required Function(String?, String?) onPick,
  int? addDays,
}) async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialEntryMode: DatePickerEntryMode.input,
    initialDate: DateTime.now(),
    firstDate:
        DateTime.now(), //DateTime(1950), //DateTime.now() - not to allow to choose before today.
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    onPick(
      DateFormat('yyyy-MM-dd').format(pickedDate),
      addDays == null
          ? null
          : DateFormat(
              'yyyy-MM-dd',
            ).format(pickedDate.add(Duration(days: addDays))),
    );
  } else {
    onPick(null, null);
  }
}
