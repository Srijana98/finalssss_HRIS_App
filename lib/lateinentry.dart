import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config.dart'; 
import 'lateinhistory.dart';


class LateEarlyRequestApp extends StatelessWidget {
  final Map<String, dynamic>? existingData; // Add this

  const LateEarlyRequestApp({super.key, this.existingData}); // Accept it


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Late In / Early Out Request',
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
     // home: const LateEarlyRequestPage(),
     home: LateEarlyRequestPage(existingData: existingData),

    );
  }
}



class LateEarlyRequestPage extends StatefulWidget {
  final Map<String, dynamic>? existingData; // Add this

  const LateEarlyRequestPage({super.key, this.existingData});


  @override
  State<LateEarlyRequestPage> createState() => _LateEarlyRequestPageState();
}

class _LateEarlyRequestPageState extends State<LateEarlyRequestPage> {
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _remarksController;

  final List<String> _postingTypes = ['Late In', 'Early Out'];
  final List<String> _types = ['Personal Work', 'Official Work'];

  String? _selectedPostingType;
  String? _selectedType;
  int? recordId; // ✅ Store the id here

  bool _isBS = true;
  final Color _customBlue = const Color(0xFF346CB0);

  Map<String, String> headers = {};

  


@override
void initState() {
  super.initState();
  _dateController = TextEditingController();
  _timeController = TextEditingController();
  _remarksController = TextEditingController();
  _loadHeaders();

  // ✅ Pre-fill form if existingData is passed
  if (widget.existingData != null) {
    final data = widget.existingData!;
    // recordId = data['id']; // <-- correct way to store id
    recordId = data['id'] != null ? int.tryParse(data['id'].toString()) : null;
    _dateController.text = data['post_date'] ?? '';
    _timeController.text = data['le_time'] ?? '';
    _remarksController.text = data['remarks'] ?? '';
    _selectedPostingType = data['posting_type'] == 'LI' ? 'Late In' : 'Early Out';
    _selectedType = data['type'] == 'PERSONAL_WORK' ? 'Personal Work' : 'Official Work';
  }
}

  Future<void> _loadHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    setState(() {
      headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'employee_id': empId,
        'org_id': orgId,
        'location_id': locationId,
       'date_type': _isBS ? 'NP' : 'EN', 
      };
    });
    print('🗓 Date Type: ${_isBS ? 'NP' : 'EN'}');

    print('✅ Headers loaded: $headers');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (_isBS) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        setState(() {
          _dateController.text =
        '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
        });
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2023),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        setState(() {
          _dateController.text = DateFormat('yyyy/MM/dd').format(picked);
        });
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final formattedTime = DateFormat('HH:mm').format(dt);

      setState(() {
        _timeController.text = formattedTime;
      });
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

  Widget _buildDateField() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: _dateController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                _isBS = !_isBS;
              });
              _selectDate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _customBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isBS ? 'NP' : 'EN',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return GestureDetector(
      onTap: _selectTime,
      child: AbsorbPointer(
        child: TextField(
          controller: _timeController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.access_time,
                  size: 18, color: Color(0xFF346CB0)),
            ),
            suffixIconConstraints:
                BoxConstraints(minHeight: 20, minWidth: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      List<String> items, String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
      items: items
          .map((type) => DropdownMenuItem(
                value: type,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(type, style: TextStyle(fontSize: 13)),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRemarksField() {
    return TextField(
      controller: _remarksController,
      maxLines: 4,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_dateController.text.isEmpty ||
        _selectedPostingType == null ||
        _selectedType == null ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    String postingType = _selectedPostingType == 'Late In' ? 'LI' : 'EO';
    String type = _selectedType == 'Personal Work' ? 'PERSONAL_WORK' : 'OFFICIAL_WORK';
    

  final Map<String, dynamic> bodyMap = {
  "posting_type": postingType,
  "type": type,
  "post_date": _dateController.text,
  "le_time": _timeController.text,
  "remarks": _remarksController.text,
};

// ✅ Include id for update
if (recordId != null) {
  bodyMap['id'] = recordId;
}

final body = jsonEncode(bodyMap);


    final url = Uri.parse('$baseUrl/api/v1/save_late');
    print('📡 API URL: $url');
    print('📤 Body: $body');


    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'empid': empId,
          'orgId': orgId,
          'locationId': locationId
        },
        body: body,
      );

      print('📥 Response: ${response.statusCode}');
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Request submitted successfully'),
            backgroundColor: const Color(0xFF346CB0),
          ),
        );

        // Create LateEarlyRequest object for the new record
          final newRequest = LateEarlyRequest(
          posting_type: postingType,
          type: type,
          post_date: _dateController.text,
          le_time: _timeController.text,
          remarks: _remarksController.text,
        );



  Future.delayed(const Duration(milliseconds: 800), () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LateInHistoryPage()),
  );
});



      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Late In / Early Out Entry',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildRow('Date:', _buildDateField()),
            _buildRow(
                'Posting Type:',
                _buildDropdown(_postingTypes, _selectedPostingType,
                    (val) => setState(() => _selectedPostingType = val))),
            _buildRow(
                'Type:',
                _buildDropdown(
                    _types, _selectedType, (val) => setState(() => _selectedType = val))),
            _buildRow('Time:', _buildTimeField()),
            _buildRow('Remarks:', _buildRemarksField()),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _customBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on LateEarlyRequest {
  Map<String, dynamic> toJson() {
    return {
      "posting_type": posting_type,
      "type": type,
      "post_date": post_date,
      "le_time": le_time,
      "remarks": remarks,
    };
  }
}



