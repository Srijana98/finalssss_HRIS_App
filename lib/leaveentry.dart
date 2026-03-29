import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'leavehistory.dart';



void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave Request',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      home: const LeaveRequestPage(),
    );
  }
}

class LeaveRequestPage extends StatefulWidget {
   final Map<String, dynamic>? existingData; // ✅ add this line
  const LeaveRequestPage({super.key, this.existingData});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: '1');
  final TextEditingController _remainingController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController(); 

   bool _startIsBS = true;
   bool _endIsBS = true;
   String _currentDateType = 'NP';
   int? recordId; 

  List<PlatformFile> _attachments = [];

  bool _halfLeave = false;
  bool _sameDate = false;
  String? _selectedSubstitute;
  String? _pickedFileName;
  String? _halfLeaveType;
  bool _isProgrammaticUpdate = false;

  final Color _customBlue = const Color(0xFF346CB0);


  List<Map<String, dynamic>> leaveQuota = [];
  List<Map<String, dynamic>> substitutes = [];
  bool isLoading = true;
  Map<String, String> headers = {};


  Set<String> _selectedLeaveIds = {};
  Map<String, TextEditingController> _daysControllers = {};

 
  @override
  void dispose() {
    _daysControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  double _totalSelectedLeaveDays() {
  double total = 0;
  for (var id in _selectedLeaveIds) {
    total += double.tryParse(_daysControllers[id]?.text ?? '0') ?? 0;
  }
  return total;


}

 Map<String, dynamic>? _getSubstituteById(String? id) {
  if (id == null || id.isEmpty || id == 'null') return null;
  
  try {
    return substitutes.firstWhere(
      (e) => e['id'].toString() == id,
      orElse: () => throw Exception('Not found'),
    );
  } catch (e) {
    print("⚠️ Substitute with ID $id not found in list");
    return null;
  }
}

@override
void initState() {
  super.initState();
  _loadHeadersAndFetch(); 
}


void _prefillFormData() {
  final data = widget.existingData!;

   print("🔍 API Data: ${data['substitute_employee_id']}");
   print("🔍 Substitutes List Length: ${substitutes.length}");
   print("🔍 Available IDs: ${substitutes.map((s) => s['id']).toList()}");


  setState(() {
    // Store record ID for update
    recordId = int.tryParse(data['id']?.toString() ?? '');

    // Fill dates
    _startDateController.text = data['start_datebs'] ?? '';
    _endDateController.text = data['end_datebs'] ?? '';

    // Calculate days
    if (_startDateController.text.isNotEmpty && _endDateController.text.isNotEmpty) {
      try {
        DateTime start = DateFormat('yyyy/MM/dd').parse(_startDateController.text);
        DateTime end = DateFormat('yyyy/MM/dd').parse(_endDateController.text);
        int difference = end.difference(start).inDays + 1;
        _daysController.text = difference.toString();
      } catch (_) {}
    }

    // Check if same date
    if (_startDateController.text == _endDateController.text) {
      _sameDate = true;
    }

    // Half leave
    if (data['halfleave_type'] != null && data['halfleave_type'].toString().isNotEmpty) {
      _halfLeave = true;
      _halfLeaveType = data['halfleave_type'];
      _daysController.text = '0.5';
    }


    
    
if (data['substitute_employee_id'] != null) {
  final rawId = data['substitute_employee_id'].toString();
  
  
  if (rawId != 'null' && rawId.isNotEmpty && rawId != '0') {
    _selectedSubstitute = rawId;
    
    
    final exists = substitutes.any((s) => s['id'].toString() == rawId);
    
    if (!exists) {
      print("⚠️ Substitute ID $rawId not found in substitutes list");
      _selectedSubstitute = null;
    } else {
      print("✅ Substitute ID $rawId found and selected");
    }
  } else {
    _selectedSubstitute = null;
  }
}
  
 // Reason
    _reasonController.text = data['reason'] ?? '';

    // Attachment filename (if exists)
    if (data['attachment'] != null && data['attachment'].toString().isNotEmpty) {
      _pickedFileName = data['attachment'].toString().split('/').last;
    }

   
    if (data['leave_categories'] != null && data['leave_categories'] is List) {
      final categories = data['leave_categories'] as List;
      
      print("🔍 Categories from API: $categories");
      print("🔍 Available leaveQuota: ${leaveQuota.map((q) => q['leavecategory']).toList()}");
      
        for (var cat in categories) {
        String categoryName = cat['name'] ?? '';
        String days = cat['days'] ?? '';
        
        print("🔹 Looking for category: $categoryName with days: $days");
        
    
        for (var quota in leaveQuota) {
          final rawId = quota['leave_catid'];
          final id = (rawId is List) ? rawId.first.toString() : rawId.toString();
          
          // Match by category name (handle "Category Name-days" format)
          String quotaCategoryName = quota['leavecategory'] ?? '';
          String cleanCategoryName = categoryName.split('-')[0].trim();
          
          print("  🔸 Comparing '$cleanCategoryName' with '$quotaCategoryName'");
          
          if (quotaCategoryName == cleanCategoryName) {
            print("  ✅ MATCH FOUND! Selecting ID: $id with days: $days");
            
            _selectedLeaveIds.add(id);
            
            // ✅ FIX: Make sure controller exists before setting text
            if (_daysControllers.containsKey(id)) {
              _daysControllers[id]?.text = days.contains('.') 
                  ? days.split('.')[0] // Remove decimal
                  : days;
            } else {
              print("  ⚠️ Controller not found for ID: $id");
            }
            break;
          }
        }
      }
      
     
    }

    // Update remaining leave
    _updateRemainingLeave();
  });
}
  Future<void> _loadHeadersAndFetch() async {
  final prefs = await SharedPreferences.getInstance();
  final empId = prefs.getString('employee_id') ?? '';
  final orgId = prefs.getString('org_id') ?? '';
  final locationId = prefs.getString('location_id') ?? '';
_currentDateType = _startIsBS ? 'NP' : 'EN';
  await prefs.setString('current_date_type', _currentDateType);
 setState(() {
    headers = {
      'Content-Type': 'application/json',
      'empid': empId,
      'orgid': orgId,
      'locationid': locationId,
      'date_type': _currentDateType, 
    };
  });

  debugPrint('📅 Date Type set to: $_currentDateType');
  fetchLeaveData();
}
  
  Future<void> fetchLeaveData() async {
  final url = Uri.parse('$baseUrl/api/v1/default_leave_form');

  try {
    final response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        leaveQuota = List.from(json['data']['leaveQuotaRecord']);
        substitutes = List.from(json['data']['substitute_employee']);
        isLoading = false;
        _initDaysControllers();
      });

      // ✅ ADD THIS: Prefill AFTER data is loaded
      if (widget.existingData != null) {
        print("🔥 API loaded successfully. Now prefilling form...");
       Future.delayed(Duration(milliseconds: 100), () {
     
          _prefillFormData();
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    setState(() => isLoading = false);
  }
}
void _initDaysControllers() {
  _daysControllers.clear();

  for (var item in leaveQuota) {
    
    final rawId = item['leave_catid'];

    final id = (rawId is List)
        ? rawId.first.toString()
        : rawId.toString();

    _daysControllers[id] = TextEditingController(text: '');
  }
}


Future<void> saveLeaveRequest() async {
  final prefs = await SharedPreferences.getInstance();
  final empId = prefs.getString('employee_id') ?? '';
  final orgId = prefs.getString('org_id') ?? '';
  final locationId = prefs.getString('location_id') ?? '';
  final token = prefs.getString('token') ?? '';

  // 🔥 ADD THIS: Update current date type before saving
  _currentDateType = _startIsBS ? 'NP' : 'EN';
  await prefs.setString('current_date_type', _currentDateType);
  
  debugPrint('📅 Saving with Date Type: $_currentDateType');

  final url = Uri.parse('$baseUrl/api/v1/save_leave_request');
  
  var request = http.MultipartRequest('POST', url);
  
  request.headers.addAll({
    "Authorization": "Bearer $token",
    "empid": empId,
    "orgid": orgId,
    "locationid": locationId,
    "date_type": _currentDateType,  
  });

 
  
  request.fields['empid'] = empId;
  request.fields['start_date'] = _startDateController.text;
  request.fields['end_date'] = _endDateController.text;
  request.fields['total_leave_days'] = _daysController.text;
  request.fields['leave_end_type'] = "F";
  request.fields['fyear'] = "082/83";
  request.fields['halfleave_type'] = _halfLeaveType ?? "";
  request.fields['substitute_employee_id'] = _selectedSubstitute ?? "";
  request.fields['reason'] = "to collect";
  request.fields['weekend_count'] = "";
  request.fields['holiday_count'] = "";
  request.fields['reason'] = _reasonController.text.isEmpty ? "" : _reasonController.text;

  if (recordId != null) {
    request.fields['record_id'] = recordId.toString();
  }

  // Add multiple leave categories with indexed keys
  int index = 0;
  for (var catId in _selectedLeaveIds) {
    final days = _daysControllers[catId]?.text.trim();
    if (days != null && days.isNotEmpty) {
      request.fields['leave_categoryid[$index]'] = catId;
      request.fields['m_days[$catId]'] = days;
      index++;
    }
  }

  print("📦 Total categories selected: ${_selectedLeaveIds.length}");
  print("📦 Request fields => ${request.fields}");
  print("📅 Date Type: $_currentDateType");

  try {
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print("STATUS: ${response.statusCode}");
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ?? "Leave request submitted successfully",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF346CB0),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error: ${response.statusCode}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Network error: $e")),
    );
  }
}
// Date Picker
  Future<void> _selectDate(TextEditingController controller, bool isStartDate) async {
    final isBS = isStartDate ? _startIsBS : _endIsBS;
    if (isBS) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        controller.text = NepaliDateFormat('yyyy/MM/dd').format(picked);
        if (_sameDate && isStartDate) _endDateController.text = controller.text;
        _updateDays();
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        controller.text = DateFormat('yyyy/MM/dd').format(picked);
        if (_sameDate && isStartDate) _endDateController.text = controller.text;
        _updateDays();
      }
    }
  }

  void _updateDays() {
    if (_halfLeave) return;
    if (_startDateController.text.isNotEmpty && _endDateController.text.isNotEmpty) {
      try {
        DateTime start = DateFormat('yyyy/MM/dd').parse(_startDateController.text);
        DateTime end = DateFormat('yyyy/MM/dd').parse(_endDateController.text);
        int difference = end.difference(start).inDays + 1;
        if (difference < 0) difference = 0;
        setState(() {
          _daysController.text = difference.toString();
        });
        _updateRemainingLeave(); 
      } catch (_) {}
    }
  }


Widget _buildDateField(TextEditingController controller, bool isStartDate) {
  return SizedBox(
    width: 130,
    child: TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        suffixIcon: TextButton(
          onPressed: () async {  
            setState(() {
              if (isStartDate) {
                _startIsBS = !_startIsBS;
              } else {
                _endIsBS = !_endIsBS;
              }
            });
            
           
            await _loadHeadersAndFetch();
             _selectDate(controller, isStartDate);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(20, 20),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isStartDate ? (_startIsBS ? "NP" : "EN") : (_endIsBS ? "NP" : "EN"),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
      onTap: () => _selectDate(controller, isStartDate),
    ),
  );
}
// Row Widget
Widget _buildRow(String label, Widget field, {double spacing = 4.0}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: spacing),
    child: Row(
      crossAxisAlignment:CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        
        Flexible(child: field),
      ],
    ),
  );
}

  /// File Picker
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _pickedFileName = result.files.single.name;
      });
    }
  }

  void _showNoDaysDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("smarthajiri.com says"),
        content: const Text("No leave days remaining"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
void _updateRemainingLeave() {
  double maxAllowed = double.tryParse(_daysController.text) ?? 0;
  double used = _totalSelectedLeaveDays();
  double remaining = maxAllowed - used;

  if (remaining < 0) remaining = 0;

  setState(() {
    _remainingController.text = remaining % 1 == 0
        ? remaining.toInt().toString()
        : remaining.toString();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Leave Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: _customBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
          Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
          children: [
          SizedBox(
         width: 150,
              child: Text("Start Date:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
     

      SizedBox(
 
   width: 150,

  child: _buildDateField(_startDateController, true),
),

    ],
  ),
),

          

  Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      const SizedBox(
        width: 60,
        child: Text(
          "End Date:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),

      Checkbox(
        value: _sameDate,
        activeColor: _customBlue,
        onChanged: (val) {
          setState(() {
            _sameDate = val!;
            if (_sameDate) {
              _endDateController.text = _startDateController.text;
              _endIsBS = _startIsBS;
              _updateDays();
            }
          });
        },
      ),

      const Text("Same Date", style: TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
Expanded(
  child: _buildDateField(_endDateController, false),
),

    ],
  ),
),
const SizedBox(height: 6),

          Row(
  children: [
    const Text('Half Leave:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    const SizedBox(width: 10),
    

    Switch(
  value: _halfLeave,
  activeColor: _customBlue,
  onChanged: (value) {
    setState(() {
      _halfLeave = value;

      if (value) {
        _daysController.text = '0.5';
        _remainingController.text = '0.5';  
      } else {
        _updateDays();
        _halfLeaveType = null;
        _remainingController.text = '';    
      }
    });
  },
),

    const SizedBox(width: 10),

    // Make dropdown flexible instead of fixed width
    if (_halfLeave)
      Flexible(
        child: DropdownButtonFormField<String>(
          value: _halfLeaveType,
          hint: const Text('--Select Leave--'),
          items: const [
            DropdownMenuItem(value: 'First Half', child: Text('First Half')),
            DropdownMenuItem(value: 'Second Half', child: Text('Second Half')),
          ],
          onChanged: (value) => setState(() => _halfLeaveType = value),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          ),
        ),
      ),
      ],
),
   // Days
            _buildRow(
              'Days:',
              SizedBox(

    width: 50,
  child: TextFormField(
    controller: _daysController,
    readOnly: true,
    style: TextStyle(fontSize: 12), 
    decoration: const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), 
      border: OutlineInputBorder(),
    ),
  ),
),
spacing: 2,
            ),

            const SizedBox(height: 10),
            const Text('Select Leave Category:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),

// Dynamic Table with Checkbox + Editable Days + Highlight
isLoading
    ? const Center(child: CircularProgressIndicator())
    : Table(
        border: TableBorder.all(
          color: Colors.grey.shade700, // darker grey border
          width: 1.0,
        ),
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(1),
        },
        children: [
           TableRow(decoration: const BoxDecoration(color: Color(0xFF346CB0)), // blue

            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Balance',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Days',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),


...leaveQuota.asMap().entries.map((entry) {
  final index = entry.key;
  final item = entry.value;
  final rawId = item['leave_catid'];
  final id = (rawId is List) ? rawId.first.toString() : rawId.toString();

  final bool isSelected = _selectedLeaveIds.contains(id);

  return TableRow(
    children: [
    Container(
        color: isSelected ? _customBlue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: _customBlue,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

onChanged: (bool? val) {
  double maxAllowed = double.tryParse(_daysController.text) ?? 0;

  if (val == true) {
    double currentTotal = _totalSelectedLeaveDays();

    if (currentTotal >= maxAllowed) {
      _showNoDaysDialog();
      return; // block selection
    }

    _selectedLeaveIds.add(id);
    _daysControllers[id]?.text = ""; 
  } else {
    _selectedLeaveIds.remove(id);
    _daysControllers[id]?.text = "";
  }
  _updateRemainingLeave(); 
  setState(() {});
},

 ),


            Expanded(
              child: Text(
                item['leavecategory'] ?? '',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),

      // BALANCE COLUMN
      Container(
        color: isSelected ? _customBlue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          item['BL'] ?? '0.00',
          style: const TextStyle(fontSize: 13),
        ),
      ),

      // DAYS COLUMN
      Container(
        color: isSelected ? _customBlue.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: isSelected
            ? SizedBox(
                width: 50,
                child: TextFormField(
                  controller: _daysControllers[id],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

onChanged: (value) {
  if (_isProgrammaticUpdate) return;

  double entered = double.tryParse(value) ?? 0;
  double totalOther = 0;

  for (var otherId in _selectedLeaveIds) {
    if (otherId != id) {
      totalOther += double.tryParse(_daysControllers[otherId]?.text ?? "0") ?? 0;
    }
  }

  double maxAllowed = double.tryParse(_daysController.text) ?? 0;

  if (entered + totalOther > maxAllowed) {
    _showNoDaysDialog();

    _isProgrammaticUpdate = true;
    _daysControllers[id]?.text = "";
    Future.delayed(Duration(milliseconds: 50), () {
      _isProgrammaticUpdate = false;
    });

    _updateRemainingLeave();  
    return;
  }

  _updateRemainingLeave();  
},



  ),
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}).toList(),

        ],
      ),
const SizedBox(height: 10),

            // Remaining Leave
            _buildRow(
              'Remaining Leave:',
                 SizedBox(

  width: 50,
  child: TextFormField(
    controller: _remainingController,
    style: TextStyle(fontSize: 12),
    decoration: const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), // smaller height
      border: OutlineInputBorder(),
    ),
  ),
),
 spacing: 2,
            ),
            const SizedBox(height: 10),
           _buildRow(
  'Attachments:',
  Row(
    children: [
     ElevatedButton(
     onPressed: _pickFile,
     style: ElevatedButton.styleFrom(
     backgroundColor: const Color(0xFF346CB0), 
     foregroundColor: Colors.white,            
     shape: RoundedRectangleBorder(
     borderRadius: BorderRadius.circular(4), 
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  ),
  child: const Text('Choose File', style: TextStyle(fontSize: 12)),
),


      const SizedBox(width: 8),
      if (_pickedFileName != null)
        Expanded(
          child: Text(
            _pickedFileName!,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
  ),
  spacing: 2,
),
 const SizedBox(height: 10),


     _buildRow(
  'Substitute Employee:',
  DropdownSearch<Map<String, dynamic>>(
    popupProps: PopupProps.menu(
      showSearchBox: true,
      searchFieldProps: TextFieldProps(
        decoration: InputDecoration(
          hintText: "Search by name or ID",
          isDense: true,
          border: OutlineInputBorder(),
        ),
      ),
      itemBuilder: (context, item, isSelected) {
        return ListTile(
          title: Text("${item['empcode']} - ${item['full_name']}"),
        );
      },
    ),
    items: substitutes,
    itemAsString: (item) => "${item!['empcode']} - ${item['full_name']}",
  
    selectedItem: _selectedSubstitute != null && substitutes.isNotEmpty
    ? substitutes.firstWhere(
        (e) => e['id'].toString() == _selectedSubstitute,
        orElse: () => <String, dynamic>{},  
      ).isNotEmpty 
        ? substitutes.firstWhere((e) => e['id'].toString() == _selectedSubstitute)
        : null
    : null,
    onChanged: (value) {
      setState(() {
        _selectedSubstitute = value?['id']?.toString();
      });
    },
    dropdownDecoratorProps: DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
        isDense: true,
       
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      ),
    ),
  ),
  spacing: 2,
),

 const SizedBox(height: 10),
          
            _buildRow(
        'Leave Reason:',
       TextFormField(
       controller: _reasonController, 
        maxLines: 2,
       decoration: const InputDecoration(
      isDense: true,
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    ),
  ),
  spacing: 2,
),

            const SizedBox(height: 12),
            
            Center(
      child: ElevatedButton.icon(
    
    onPressed: () async {
  await saveLeaveRequest();
},

    
    label: const Text(
      'Save',
      style: TextStyle(color: Colors.white, fontSize: 13),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF346CB0),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

    ),
  ),
),

          ],
        ),
      ),
    );
  }
}
