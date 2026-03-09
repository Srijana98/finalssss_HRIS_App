import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';



class WorkonWeekendEntryPage extends StatefulWidget {
  final Map<String, dynamic>? existingData; 

  const WorkonWeekendEntryPage({super.key, this.existingData});


  @override
  State<WorkonWeekendEntryPage> createState() => _WorkonWeekendEntryPageState();
}

class _WorkonWeekendEntryPageState extends State<WorkonWeekendEntryPage> {
  final Color _customBlue = const Color(0xFF346CB0);
  final String _entryType = 'WORKFROMWEEK'; 

  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  late TextEditingController _purposeController;

  bool _fromIsBS = true;
  bool _toIsBS = true;
  int? recordId;

  List<PlatformFile> _attachments = [];

  

   @override
void initState() {
  super.initState();

  _fromDateController = TextEditingController();
  _toDateController = TextEditingController();
  _purposeController = TextEditingController();

  

if (widget.existingData != null) {
  final data = widget.existingData!;

  // Prefill Purpose
  _purposeController.text = data['purpose'] ?? '';
   recordId = data['id'] != null ? int.tryParse(data['id'].toString()) : null;


  // Prefill Dates based on date_type
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
}
}


 @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _purposeController.dispose();
    super.dispose();
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
  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
  if (result != null) {
    setState(() => _attachments.addAll(result.files));
  }
}

  // Reusable Row
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            leading: const Icon(Icons.description,
                size: 20, color: Color(0xFF346CB0)),
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


  
  Future<void> _submitWorkFromWeekend() async {
  final String url = '$baseUrl/api/v1/work_from_home/store';


  if (_fromDateController.text.isEmpty ||
      _toDateController.text.isEmpty ||
      _purposeController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Please fill all required fields'),
      backgroundColor: Colors.red,
    ));
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final empid = prefs.getString('empid') ?? '1';
    final orgid = prefs.getString('orgid') ?? '1';
    final locationid = prefs.getString('locationid') ?? '1';

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
   

    request.fields['entry_type'] = _entryType;
    request.fields['from_date'] = _fromDateController.text.trim();
    request.fields['to_date'] = _toDateController.text.trim();
    request.fields['purpose'] = _purposeController.text.trim();

    if (recordId != null) {
     request.fields['id'] = recordId.toString();
    }


    if (_attachments.isNotEmpty && _attachments.first.path != null) {
  request.files.add(await http.MultipartFile.fromPath(
    'attachment', // ✅ remove the []
    _attachments.first.path!,
  ));
}


    // 🧾 Log all outgoing request details
    print('📡 ====== API REQUEST ======');
    print('➡️ URL: $url');
    print('🧩 Headers: ${request.headers}');
    print('📦 Fields: ${request.fields}');
    print('📎 Files: ${_attachments.map((f) => f.name).toList()}');
    print('===========================');

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    final result = json.decode(responseBody);

    // 🧾 Log the full response
    print('✅ ====== API RESPONSE ======');
    print('🔢 Status Code: ${response.statusCode}');
    print('💬 Response Body: $responseBody');
    print('=============================');

    if (response.statusCode == 200 && result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Work From Weekend request submitted successfully!'),
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
    print('❌ ERROR during request: $e'); // also log error in console
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
        title: const Text("Work on Weekend Entry",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildRow('From Date:', _buildDateField(_fromDateController, true)),
            _buildRow('To Date:', _buildDateField(_toDateController, false)),
            _buildRow('Purpose:', _buildPurposeField()),
            const SizedBox(height: 16),
            _buildRow('Attachment:', _buildAttachmentField()),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitWorkFromWeekend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _customBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
 
           child: const Text('Save',
                    style:
                        TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}