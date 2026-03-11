
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'attendancerequestpage.dart';
import 'config.dart';

void main() {
  runApp(const AttendanceRequestApp());
}

class AttendanceRequestApp extends StatelessWidget {
final Map<String, dynamic>? existingData; 
 const AttendanceRequestApp({super.key, this.existingData}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Request',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
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
     home: AttendanceRequestPage(existingData: existingData),
    );
  }
}

class AttendanceRequestPage extends StatefulWidget {

  final Map<String, dynamic>? existingData; 

  const AttendanceRequestPage({Key? key, this.existingData}) : super(key: key);
  

  @override
  State<AttendanceRequestPage> createState() => _AttendanceRequestPageState();
}

class _AttendanceRequestPageState extends State<AttendanceRequestPage> {
  late TextEditingController _DateController;
  late TextEditingController _checkInTimeController;
  late TextEditingController _checkOutTimeController;
  late TextEditingController _remarksController;

  String? _selectedType;
  final List<String> _typeOptions = ['Check In', 'Check Out', 'Both'];
  final Color _customBlue = const Color(0xFF346CB0);

  bool _fromIsBS = true;
  bool _toIsBS = true;
  bool _isSubmitting = false;

  String _empId = '';
  String _orgId = '';
  String _locationId = '';
  String? _recordId;


  @override
void initState() {
  super.initState();
  _DateController = TextEditingController();
  _checkInTimeController = TextEditingController();
  _checkOutTimeController = TextEditingController();
  _remarksController = TextEditingController();
  _selectedType = 'Check In';
  _loadUserData();

 
  if (widget.existingData != null) {
    final data = widget.existingData!;
    _recordId = data['id']?.toString(); 
    _DateController.text = data['att_datebs'] ?? ''; 
    _remarksController.text = data['remarks'] ?? '';
    _selectedType = (data['att_type'] == 'CHECKIN')
        ? 'Check In'
        : (data['att_type'] == 'CHECKOUT')
            ? 'Check Out'
            : 'Both';
    if (_selectedType == 'Check In' || _selectedType == 'Both') {
      _checkInTimeController.text = data['att_time'] ?? '';
    }
    if (_selectedType == 'Check Out' || _selectedType == 'Both') {
      _checkOutTimeController.text = data['att_time'] ?? '';
    }
  }
}


  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _empId = prefs.getString('employee_id') ?? '';
      _orgId = prefs.getString('org_id') ?? '';
      _locationId = prefs.getString('location_id') ?? '';
    });

    print("====== DEBUG ATTENDANCE PAGE ======");
    print("employee_id: $_empId");
    print("org_id: $_orgId");
    print("location_id: $_locationId");
   
  }

  @override
  void dispose() {
    _DateController.dispose();
    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller, bool isFromDate) async {
    final isBS = isFromDate ? _fromIsBS : _toIsBS;

    if (isBS) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        controller.text =
            '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2023),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = DateFormat('yyyy/MM/dd').format(picked);
      }
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {

      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      controller.text = '$hour:$minute';
    }
  }

  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, height: 0.6)),
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
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            isDense: true,
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.access_time, size: 18, color: Color(0xFF346CB0)),
            ),
            suffixIconConstraints: BoxConstraints(minHeight: 20, minWidth: 20),
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, bool isFromDate) {
    final isBS = isFromDate ? _fromIsBS : _toIsBS;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _selectDate(controller, isFromDate),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                border: OutlineInputBorder(),
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
                if (isFromDate) {
                  _fromIsBS = !_fromIsBS;
                } else {
                  _toIsBS = !_toIsBS;
                }
              });
              _selectDate(controller, isFromDate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF346CB0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isBS ? 'BS' : 'AD',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: OutlineInputBorder(),
      ),
      items: _typeOptions
          .map((type) => DropdownMenuItem<String>(
                value: type,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(type, style: const TextStyle(fontSize: 13)),
                ),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedType = value!),
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      maxLines: 4,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }


Future<void> _submitForm() async {
  if (_DateController.text.isEmpty ||
      ((_selectedType == 'Check In' || _selectedType == 'Both') &&
          _checkInTimeController.text.isEmpty) ||
      ((_selectedType == 'Check Out' || _selectedType == 'Both') &&
          _checkOutTimeController.text.isEmpty) ||
      _remarksController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all required fields.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {

    String attType = _selectedType == 'Check In'
        ? 'CHECKIN'
        : _selectedType == 'Check Out'
            ? 'CHECKOUT'
            : 'BOTH';

  
    String dateType = _fromIsBS ? 'NP' : 'EN';

  
    final headers = {
      'Content-Type': 'application/json',
      'empid': _empId,
      'orgid': _orgId,
      'locationid': _locationId,
      'date_type': dateType,
    };

   
    final Map<String, dynamic> body = {
      'att_type': attType,
      'cur_date': [_DateController.text.trim()],
      'overall_remarks': _remarksController.text.trim(),
    };


   
    if (attType == 'CHECKIN' || attType == 'BOTH') {
      body['cur_checkin_time'] = [_checkInTimeController.text.trim()];
    }
    if (attType == 'CHECKOUT' || attType == 'BOTH') {
      body['cur_checkout_time'] = [_checkOutTimeController.text.trim()];
    }
     
     if (_recordId != null && _recordId!.isNotEmpty) {
  body['id'] = _recordId;
}

    print('--- Request Headers ---');
    headers.forEach((key, value) => print('$key: $value'));
    print('--- Request Body ---');
    print(jsonEncode(body));

  
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/save_manual_attendance'),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Attendance saved'),
          backgroundColor: _customBlue,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AttendanceHistoryPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Failed to save attendance'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isSubmitting = false);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _customBlue,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => AttendanceHistoryPage())),
        ),
        title: const Text("Attendance Entry",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildRow('Date:', _buildDateField(_DateController, true)),
                _buildRow('Attendance Type:', _buildDropdownField()),
                if (_selectedType == 'Check In' || _selectedType == 'Both')
                  _buildRow('Check In Time:', _buildTimeField(_checkInTimeController)),
                if (_selectedType == 'Check Out' || _selectedType == 'Both')
                  _buildRow('Check Out Time:', _buildTimeField(_checkOutTimeController)),
                _buildRow('Remarks:', _buildRemarksField()),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _customBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledBackgroundColor: _customBlue.withOpacity(0.6),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}