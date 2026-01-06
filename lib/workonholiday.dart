import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'workonholidayhistory.dart';

class WorkonHolidayEntryPage extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  const WorkonHolidayEntryPage({super.key, this.existingData});

  @override
  State<WorkonHolidayEntryPage> createState() => _WorkonHolidayEntryPageState();
}

class _WorkonHolidayEntryPageState extends State<WorkonHolidayEntryPage> {
  final Color _customBlue = const Color(0xFF346CB0);
  final String _entryType = 'WORKFROMHOLI';

  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late TextEditingController _purposeController;

  bool _fromIsBS = true;
  bool _toIsBS = true;
  int? recordId;

  List<PlatformFile> _attachments = [];

  // Holiday API Data
  List<Holiday> _holidays = [];
  Holiday? _selectedHoliday;
  
  // Store holiday_id from existing data
  String? _prefilledHolidayId;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fromDateController = TextEditingController();
    _toDateController = TextEditingController();
    _purposeController = TextEditingController();

    // Check if we're in edit mode
    if (widget.existingData != null) {
      _isEditMode = true;
      
      print('🔍 ====== EXISTING DATA CHECK ======');
      print('📋 Full existingData: ${widget.existingData}');
      print('📋 Keys in existingData: ${widget.existingData!.keys.toList()}');
      
      // Try multiple possible key names
      _prefilledHolidayId = widget.existingData!['holiday_id']?.toString() ?? 
                           widget.existingData!['holidayId']?.toString() ??
                           widget.existingData!['holidayid']?.toString();
      
      print('🆔 holiday_id extracted: $_prefilledHolidayId');
      print('===================================');
      
      _loadExistingData();
    }

    // Fetch holidays from API
    _fetchHolidays();
  }

  void _loadExistingData() {
    final data = widget.existingData!;

    _purposeController.text = data['purpose'] ?? '';

    recordId = data['id'] != null ? int.tryParse(data['id'].toString()) : null;

    final dateType = data['date_type'] ?? 'NP';

    if (dateType == 'EN') {
      _fromDateController.text = data['from_datead'] ?? '';
      _toDateController.text = data['to_datead'] ?? '';
      _fromIsBS = false;
      _toIsBS = false;
    } else {
      _fromDateController.text = data['from_datebs'] ?? '';
      _toDateController.text = data['to_datebs'] ?? '';
      _fromIsBS = true;
      _toIsBS = true;
    }

    print('✅ Loaded existing data:');
    print('   Purpose: ${_purposeController.text}');
    print('   From Date: ${_fromDateController.text}');
    print('   To Date: ${_toDateController.text}');
    print('   Record ID: $recordId');
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _fetchHolidays() async {
    const url = '${baseUrl}/api/v1/employee/holidays';

    try {
      final prefs = await SharedPreferences.getInstance();
      final empid = prefs.getString('employee_id') ?? '';
      final orgid = prefs.getString('org_id') ?? '';
      final locationid = prefs.getString('location_id') ?? '';

      final headers = {
        'empid': empid,
        'orgid': orgid,
        'locationid': locationid,
      };

      print('🌐 ====== FETCHING HOLIDAYS ======');
      print('📡 URL: $url');
      print('🔑 Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);
      
      print('📥 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List holidaysJson = data['holidays'];
          
          print('✅ Holidays fetched: ${holidaysJson.length} items');
          
          setState(() {
            _holidays = holidaysJson.map((e) => Holiday.fromJson(e)).toList();
            
            // Debug: Print all holiday IDs
            print('🔍 Available Holiday IDs:');
            for (var h in _holidays) {
              print('   ID: ${h.id}, Name: ${h.eventname}, Dates: ${h.startDateBS} to ${h.endDateBS}');
            }
            
            // ✅ SOLUTION: Since API doesn't return holiday_id, match by dates!
            if (_isEditMode && _holidays.isNotEmpty) {
              final fromDate = _fromDateController.text.trim();
              final toDate = _toDateController.text.trim();
              
              print('🔍 ====== MATCHING HOLIDAY BY DATES ======');
              print('📅 Looking for holiday with dates: $fromDate to $toDate');
              
              if (fromDate.isNotEmpty && toDate.isNotEmpty) {
                try {
                  // Try to find holiday that matches the date range
                  _selectedHoliday = _holidays.firstWhere(
                    (h) => h.startDateBS == fromDate && h.endDateBS == toDate,
                  );
                  print('✅ Holiday matched by dates: ${_selectedHoliday?.eventname}');
                  print('   Holiday ID: ${_selectedHoliday?.id}');
                } catch (e) {
                  print('❌ No holiday found matching dates: $fromDate to $toDate');
                  print('   Available holidays:');
                  for (var h in _holidays) {
                    print('      ${h.eventname}: ${h.startDateBS} to ${h.endDateBS}');
                  }
                }
              }
              print('=========================================');
            }
          });
        } else {
          print('❌ API returned failure status');
        }
      } else {
        print('❌ Failed to load holidays: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching holidays: $e');
    }
  }

  // Date Picker (BS/AD)
  Future<void> _selectDate(TextEditingController controller, bool isFrom) async {
    final isBS = isFrom ? _fromIsBS : _toIsBS;
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

  Future<void> _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _attachments.addAll(result.files));
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

  Widget _buildDateField(TextEditingController controller, bool isFrom) {
    final isBS = isFrom ? _fromIsBS : _toIsBS;
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _selectDate(controller, isFrom),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCCCCCC)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF346CB0), width: 2),
                ),
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
                if (isFrom) _fromIsBS = !_fromIsBS;
                else _toIsBS = !_toIsBS;
              });
              _selectDate(controller, isFrom);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _customBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(isBS ? 'BS' : 'AD',
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeField() {
    return TextField(
      controller: _purposeController,
      maxLines: 4,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        isDense: true,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
      ),
    );
  }

  Widget _buildHolidayDropdown() {
    // Debug widget state
    print('🎨 Building dropdown - _selectedHoliday: ${_selectedHoliday?.eventname ?? "NULL"}');
    print('🎨 Holidays count: ${_holidays.length}');
    
    return DropdownButtonFormField<Holiday>(
      value: _selectedHoliday,
      hint: const Text('--Select--'),
      isExpanded: true,
      items: _holidays
          .map((h) => DropdownMenuItem(
                value: h,
                child: Text(
                  '${h.eventname} (${h.startDateBS} to ${h.endDateBS})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ))
          .toList(),
      onChanged: (Holiday? value) {
        print('✅ Dropdown changed to: ${value?.eventname}');
        setState(() {
          _selectedHoliday = value;
          _fromDateController.text = value?.startDateBS ?? '';
          _toDateController.text = value?.endDateBS ?? '';
        });
      },
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
      ),
    );
  }

  Widget _buildAttachmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickFiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: _customBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Choose File', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _attachments.isEmpty
                    ? 'No file selected'
                    : '${_attachments.length} file(s) selected',
                style: const TextStyle(fontSize: 13, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._attachments.map(
            (file) => ListTile(
              dense: true,
              leading:
                  const Icon(Icons.description, size: 20, color: Color(0xFF346CB0)),
              title: Text(file.name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () => setState(() => _attachments.remove(file)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submitWorkonHoliday() async {
    final String url = '$baseUrl/api/v1/work_from_home/store';

    if (_fromDateController.text.isEmpty ||
        _toDateController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _selectedHoliday == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required fields'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final empid = prefs.getString('employee_id') ?? '1';
      final orgid = prefs.getString('org_id') ?? '1';
      final locationid = prefs.getString('location_id') ?? '1';

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'empid': empid,
        'orgid': orgid,
        'locationid': locationid,
        'date_type': _fromIsBS ? 'NP' : 'EN',
      });

      request.fields['empid'] = empid;
      request.fields['orgid'] = orgid;
      request.fields['locationid'] = locationid;
      request.fields['holiday_id'] = _selectedHoliday?.id ?? '';

      request.fields['entry_type'] = _entryType;
      request.fields['from_date'] = _fromDateController.text.trim();
      request.fields['to_date'] = _toDateController.text.trim();
      request.fields['purpose'] = _purposeController.text.trim();

      if (recordId != null) {
        request.fields['id'] = recordId.toString();
      }

      if (_attachments.isNotEmpty && _attachments.first.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          _attachments.first.path!,
        ));
      }

      print('📡 ====== API REQUEST ======');
      print('➡️ URL: $url');
      print('🧩 Headers: ${request.headers}');
      print('📦 Fields: ${request.fields}');
      print('📎 Files: ${_attachments.map((f) => f.name).toList()}');
      print('===========================');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final result = json.decode(responseBody);

      print('✅ ====== API RESPONSE ======');
      print('🔢 Status Code: ${response.statusCode}');
      print('💬 Response Body: $responseBody');
      print('=============================');

      if (response.statusCode == 200 && result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Work on Holiday request submitted successfully!'),
          backgroundColor: _customBlue,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Failed: ${result['message'] ?? 'Something went wrong'}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('❌ ERROR during request: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _customBlue,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? "Update Work On Holiday" : "Work On Holiday Entry",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildRow('Holiday:', _buildHolidayDropdown()),
            _buildRow('From Date:', _buildDateField(_fromDateController, true)),
            _buildRow('To Date:', _buildDateField(_toDateController, false)),
            _buildRow('Purpose:', _buildPurposeField()),
            const SizedBox(height: 16),
            _buildRow('Attachment:', _buildAttachmentField()),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitWorkonHoliday,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _customBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isEditMode ? 'Update' : 'Save',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model for Holiday
class Holiday {
  final String id;
  final String eventname;
  final String startDateBS;
  final String endDateBS;

  Holiday({
    required this.id,
    required this.eventname,
    required this.startDateBS,
    required this.endDateBS,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'].toString(), // ✅ Convert to string to handle both int and string
      eventname: json['eventname'],
      startDateBS: json['start_datebs'],
      endDateBS: json['end_datebs'],
    );
  }
}