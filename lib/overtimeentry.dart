import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:http/http.dart' as http;
import 'overtimehistory.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp( OvertimeEntryApp());
}

class OvertimeEntryApp extends StatelessWidget {
  final Map<String, dynamic>? existingData;

  const OvertimeEntryApp({super.key, this.existingData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overtime Entry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: OvertimeEntryPage(existingData: existingData),
      
    );
  }
}

class OvertimeEntryPage extends StatefulWidget {
  final Map<String, dynamic>? existingData; // Add this
   const OvertimeEntryPage({super.key, this.existingData});


  @override
  State<OvertimeEntryPage> createState() => _OvertimeEntryPageState();
}


class OvertimeRequest {
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String remarks;

  OvertimeRequest({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.remarks,
  });
}

extension OvertimeRequestExtension on OvertimeRequest {
  Map<String, dynamic> toJson() {
    return {
      "ot_dates": [startDate],
      "ot_enddates": [endDate],
      "ot_starttimes": [startTime],
      "ot_endtimes": [endTime],
      "operation": "insert",
      "remarks": remarks,
    };
  }
}


class _OvertimeEntryPageState extends State<OvertimeEntryPage> {
  late TextEditingController _startDateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endDateController;
  late TextEditingController _endTimeController;
  late TextEditingController _totalHoursController;
  late TextEditingController _remarksController;

  final Color _customBlue = const Color(0xFF346CB0);
  bool _isSubmitting = false;

  // Track BS / AD selection
  bool _startIsBS = true;
  bool _endIsBS = true;
  int? _masterId;


  

  @override
void initState() {
  super.initState();
  _startDateController = TextEditingController();
  _startTimeController = TextEditingController();
  _endDateController = TextEditingController();
  _endTimeController = TextEditingController();
  _totalHoursController = TextEditingController();
  _remarksController = TextEditingController();



if (widget.existingData != null) {
  final data = widget.existingData!;

  _startDateController.text = data['ot_datead'] ?? '';   // 🔁 changed
  _endDateController.text = data['ot_datebs'] ?? '';     // 🔁 changed
  _startTimeController.text = data['ot_starttime'] ?? ''; // 🔁 changed
  _endTimeController.text = data['ot_endtime'] ?? '';     // 🔁 changed
  _remarksController.text = data['remarks'] ?? '';

  _masterId = data['master_id'] != null
      ? int.tryParse(data['master_id'].toString())
      : null;

  print("DEBUG: Master ID = $_masterId");
  _calculateTotalHours();
}
}


  @override
  void dispose() {
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    _totalHoursController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ------------------ DATE PICKER (AD + BS) ------------------
  Future<void> _selectDate(TextEditingController controller, bool isStartDate) async {
    final bool isBS = isStartDate ? _startIsBS : _endIsBS;

    if (isBS) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        setState(() {
          controller.text =
              '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
          _calculateTotalHours();
        });
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.tryParse(controller.text.replaceAll('/', '-')) ?? DateTime.now(),
        firstDate: DateTime(2023),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          controller.text =
              '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
          _calculateTotalHours();
        });
      }
    }
  }

  // ------------------ TIME PICKER ------------------
  String _formatTimeForDisplay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00'; // HH:mm:ss
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (pickedTime != null) {
      setState(() {
        controller.text = _formatTimeForDisplay(pickedTime);
        _calculateTotalHours();
      });
    }
  }


 
  // ------------------ TOTAL HOURS CALCULATION ------------------
void _calculateTotalHours() {
  if (_startDateController.text.isEmpty ||
      _startTimeController.text.isEmpty ||
      _endDateController.text.isEmpty ||
      _endTimeController.text.isEmpty) {
    _totalHoursController.text = '';
    return;
  }

  try {
    DateTime _combineDateTime(String dateStr, String timeStr) {
      final dateParts = dateStr.split('/');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      return DateTime(year, month, day, hour, minute, second);
    }

    final startDateTime =
        _combineDateTime(_startDateController.text, _startTimeController.text);
    final endDateTime =
        _combineDateTime(_endDateController.text, _endTimeController.text);

    final diffSeconds = endDateTime.difference(startDateTime).inSeconds.abs();

    final hours = (diffSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((diffSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (diffSeconds % 60).toString().padLeft(2, '0');

    _totalHoursController.text = '$hours:$minutes:$seconds';
  } catch (e) {
    _totalHoursController.text = '';
  }
}


String _getDateType() {
  // If either start or end is BS → NP
  if (_startIsBS || _endIsBS) {
    return "NP";
  } else {
    return "EN";
  }
}


  // ------------------ FORM SUBMISSION ------------------
Future<void> _submitForm() async {
  if (_startDateController.text.isEmpty ||
      _startTimeController.text.isEmpty ||
      _endDateController.text.isEmpty ||
      _endTimeController.text.isEmpty ||
      _totalHoursController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill out all the required fields.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final empId = prefs.getString('employee_id') ?? '';
  final orgId = prefs.getString('org_id') ?? '';
  final locationId = prefs.getString('location_id') ?? '';

  print("🗓 Date Type: ${_getDateType()}");


  final url = Uri.parse("${baseUrl}/api/v1/save_overtime_request");

  final operation = _masterId != null ? "update" : "insert";
  print("DEBUG: Submitting form with masterId = $_masterId, operation = $operation");

  final body = {
  "ot_dates": [_startDateController.text],
  "ot_enddates": [_endDateController.text],
  "ot_starttimes": [_startTimeController.text],
  "ot_endtimes": [_endTimeController.text],
  "operation": operation,
  "remarks": _remarksController.text,
   if (_masterId != null) "master_id": _masterId, // include master_id for update
};

// ✅ EXTRA DEBUG PRINTS
print("empId: $empId");
print("orgId: $orgId");
print("locationid: $locationId");

// ✅ EXISTING DEBUG PRINTS
print("========== OVERTIME REQUEST DEBUG ==========");
print("Request URL: $url");
print("Headers: {empid: $empId, orgid: $orgId, locationid: $locationId}");
print("Request Body: ${jsonEncode(body)}");
print("============================================");





  try {
    final response = await http.post(
      

      url,
      headers: {
        "Content-Type": "application/json",
        "empid": empId,
        "orgid": orgId,
       "locationid": locationId,
        "date-type": _getDateType(), 
        

      },
      body: jsonEncode(body),
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

  // try {
  // final headers = {
  //   "Authorization": "Bearer ${prefs.getString('token') ?? ''}",
  //   "Content-Type": "application/json",
  //   "employee_id": empId,
  //   "org_id": orgId,
  //   "location_id": locationId,
  //   "date_type": _getDateType(),
  // };

  // print("========== OVERTIME REQUEST DEBUG ==========");
  // print("Request URL: $url");
  // print("✅ Headers loaded: $headers");
  // print("📤 Request Body: ${jsonEncode(body)}");
 

  // final response = await http.post(
  //   url,
  //   headers: headers,
  //   body: jsonEncode(body),
  // );

  // print("Response Status Code: ${response.statusCode}");
  // print("Response Body: ${response.body}");


    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 && responseData["status"] == "success") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData["message"] ?? "Overtime request submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );


        // Create OvertimeRequest object for local use
final newRequest = OvertimeRequest(
  startDate: _startDateController.text,
  endDate: _endDateController.text,
  startTime: _startTimeController.text,
  endTime: _endTimeController.text,
  remarks: _remarksController.text,
);



// // ✅ Directly go back to the history page after success
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const OverTimeHistoryPage()),
);



        
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${responseData["message"] ?? 'Unknown error'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print("Exception during request: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed: $e"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}


  // ------------------ UI BUILDERS ------------------
  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller) {
    return GestureDetector(
      onTap: () => _selectTime(controller),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF346CB0)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 6),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, bool isStartDate) {
    final bool isBS = isStartDate ? _startIsBS : _endIsBS;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _selectDate(controller, isStartDate),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isStartDate) {
                  _startIsBS = !_startIsBS;
                } else {
                  _endIsBS = !_endIsBS;
                }
              });
              _selectDate(controller, isStartDate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _customBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isBS ? 'NP' : 'EN',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------ BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _customBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Overtime Entry',
            style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildRow('OT Start Date:', _buildDateField(_startDateController, true)),
            _buildRow('Start Time:', _buildTimeField(_startTimeController)),
            _buildRow('OT End Date:', _buildDateField(_endDateController, false)),
            _buildRow('End Time:', _buildTimeField(_endTimeController)),
            _buildRow(
              'Total Hours:',
              _buildTextField(_totalHoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  readOnly: true),
            ),
            _buildRow('Remarks:', _buildTextField(_remarksController, maxLines: 3)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _customBlue,
                  padding: const EdgeInsets.symmetric(horizontal:36, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit",
                      style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}