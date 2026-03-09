import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'fieldvisithistory.dart';
import 'config.dart';
import 'dart:convert'; 
class FieldVisitEntryPage extends StatefulWidget {
  final Map<String, dynamic>? existingData; 
  const FieldVisitEntryPage({super.key, this.existingData});

  @override
  State<FieldVisitEntryPage> createState() => _FieldVisitEntryPageState();
}

class _FieldVisitEntryPageState extends State<FieldVisitEntryPage> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _visitPlaceController = TextEditingController();
  final TextEditingController _departureFromController = TextEditingController();
  final TextEditingController _departureToController = TextEditingController();
  final TextEditingController _travelVehicleController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _advanceAmountController = TextEditingController();





 
  bool _hotelBookingChecked = false;
  bool _advanceChecked = false;
  bool _addSummarizedChecked = false;
  File? _selectedFile;
  final Color _customBlue = const Color(0xFF346CB0);

  Map<String, String> _travelTypes = {};
  List<Map<String, String>> _transportationModes = [];
  List<Map<String, String>> _budgetHeads = [];
  bool _isLoadingDropdowns = true;

  String? _selectedTravelType;
  String? _selectedTransportation;
  String? _selectedBudget;
  int? recordId;
  

  bool _fromIsBS = true;
  bool _toIsBS = true;
  

  String _convertBsToAd(String bsDate) {
  if (bsDate.isEmpty) return '';
  try {
    final parts = bsDate.split('/');
    final nepali = NepaliDateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final ad = nepali.toDateTime();
    return DateFormat('yyyy/MM/dd').format(ad);
  } catch (e) {
    print("Date conversion error: $e");
    return bsDate; 
  }
}

@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  await _fetchDropdownData();

  if (widget.existingData != null) {
    final data = widget.existingData!;
    recordId = data['id'] != null ? int.tryParse(data['id'].toString()) : null;

    setState(() {
      _fromDateController.text = data['from_datead'] ?? data['from_date'] ?? '';
      _toDateController.text = data['to_datead'] ?? data['to_date'] ?? '';
      _visitPlaceController.text = data['visitplace'] ?? '';
      _departureFromController.text = data['departure_from'] ?? '';
      _departureToController.text = data['departure_to'] ?? '';
      _purposeController.text = data['purpose'] ?? '';
      _remarksController.text = data['remarks'] ?? '';

      // Dropdowns
      _selectedTravelType = data['travel_type']?.toString();
      _selectedTransportation = data['mode_of_transportation']?.toString();
      _selectedBudget = data['budget']?.toString();

      _hotelBookingChecked = data['hotel_booking_required'] == 'Y';
      _advanceChecked = data['advance_for_travel'] == 'Y';
      _advanceAmountController.text = _advanceChecked ? (data['advance_amount']?.toString() ?? '') : '';

      // Summarized Remarks - Use mapped key
      final remarksList = data['summarized_remarks'];
      if (remarksList is List && remarksList.isNotEmpty) {
        _summarizedRemarks = remarksList.map((e) {
          final item = e as Map<String, dynamic>;
          return {
            'date': item['departure_date_ad']?.toString() ?? '',
            'departure_time': item['departure_time']?.toString() ?? '',
            'departure_from': item['departure_from']?.toString() ?? '',
            'transportation_mode': item['mode_of_transportation']?.toString() ?? '',
            'arrival_date': item['arrival_date_ad']?.toString() ?? '',
            'arrival_time': item['arrival_time']?.toString() ?? '',
            'departure_to': item['departure_to']?.toString() ?? '',
            'visit_purpose': item['visit_purpose']?.toString() ?? '',
          };
        }).toList();
        _addSummarizedChecked = true;
      } else {
        _summarizedRemarks = [];
        _addSummarizedChecked = false;
      }
    });
  }
}


  //FETCH DROPDOWN DATA FUNCTION
  Future<void> _fetchDropdownData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString('employee_id') ?? '';
      final orgId = prefs.getString('org_id') ?? '';
      final locationId = prefs.getString('location_id') ?? '';

      final url = Uri.parse('$baseUrl/api/v1/field_visit_default_load');
      print("🔵 Fetching dropdowns from $url");

      final response = await http.post(
        url,
        headers: {
          "empid": empId,
          "orgid": orgId,
          "locationid": locationId,
        },
      );

      print("🟢 Response Status: ${response.statusCode}");
      print("🟣 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          setState(() {
            _travelTypes = Map<String, String>.from(data["travel_type"]);
            _transportationModes = List<Map<String, String>>.from(
                data["transportation_modes"].map((e) => {
                      "id": e["id"].toString(),
                      "name": e["title"].toString(),
                    }));
            _budgetHeads = List<Map<String, String>>.from(
                data["budget_heads"].map((e) => {
                      "id": e["id"].toString(),
                      "name": e["title"].toString(),
                    }));
            _isLoadingDropdowns = false;
          });
        } else {
          throw Exception("Failed to load dropdowns");
        }
      } else {
        throw Exception("Failed with ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching dropdowns: $e");
      setState(() {
        _isLoadingDropdowns = false;
      });
    }
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _visitPlaceController.dispose();
    _departureFromController.dispose();
    _departureToController.dispose();
    _travelVehicleController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    _budgetController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller, bool isFromDate) async {
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

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }
String _getDateType() {
  // If ANY date is in Nepali (BS), send "NP"
  if (_fromIsBS || _toIsBS) {
    return "NP";
  }
  return "EN";
}

    Future<void> _submitForm() async {
    if (_selectedTravelType == null ||
        _selectedTransportation == null ||
        _selectedBudget == null ||
        _fromDateController.text.isEmpty ||
        _toDateController.text.isEmpty ||
        _visitPlaceController.text.isEmpty ||
        _departureFromController.text.isEmpty ||
        _departureToController.text.isEmpty ||
        _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      
      return;
    }
    

  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/storefield_visit');

  final Map<String, dynamic> body = {
  "travel_type": _selectedTravelType ?? "",
  "from_date": _fromDateController.text,
  "to_date": _toDateController.text,
  "visitplace": _visitPlaceController.text,
  "mode_of_transportation": _selectedTransportation ?? "",
  "departure_from": _departureFromController.text,
  "departure_to": _departureToController.text,
  "remarks": _remarksController.text,
  "hotel_booking_required": _hotelBookingChecked ? "Y" : "N",
  "advance_for_travel": _advanceChecked ? "Y" : "N",
  "advance_amount": _advanceChecked ? _advanceAmountController.text : "0",
  "budget": _selectedBudget ?? "",
  "purpose": _purposeController.text,
};

// Add summarized remarks with correct keys
if (_addSummarizedChecked) {
  body["summarized_remarks"] = _summarizedRemarks.map((row) {
    return {
      "departure_date_ad": row['date'] ?? "",
      "departure_time": row['departure_time'] ?? "",
      "departure_from": row['departure_from'] ?? "",
      "mode_of_transportation": row['transportation_mode'] ?? "",
      "arrival_date_ad": row['arrival_date'] ?? "",
      "arrival_time": row['arrival_time'] ?? "",
      "departure_to": row['departure_to'] ?? "",
      "visit_purpose": row['visit_purpose'] ?? "",
    };
  }).toList();
}

if (recordId != null) {
  body['id'] = recordId;
}
    
  print('🔵 API URL: $url');
  print('🟩 Request Headers:');
  print({
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
  'empid': empId,
  'orgid': orgId,
  'locationid': locationId,
});
print('🟨 Request Body: $body');
print('🟧 Date Type Header: ${_getDateType()}');



final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'empid': empId,
    'orgid': orgId,
    'locationid': locationId,
    'date-type': _getDateType(),
  },
  body: jsonEncode(body), 
);

print('🟦 Status Code: ${response.statusCode}');
print('🟣 Response Body: ${response.body}');


    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Field visit request submitted successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF346CB0),
        ),
      );

      Navigator.pop(context, true);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit. Status code: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error response: ${response.body}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error submitting request: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 0.6)),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  InputDecoration _underlineDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      contentPadding: const
      EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      isDense: true,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC))),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC))),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: _underlineDecoration(),
    );
  }

  Widget _buildDateField(TextEditingController controller, bool isFromDate) {
    final isBS = isFromDate ? _fromIsBS : _toIsBS;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickDate(controller, isFromDate),
          child: AbsorbPointer(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13),
              decoration: _underlineDecoration(),
            ),
          ),
        ),
        Positioned(
          right: 8,
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
              _pickDate(controller, isFromDate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF346CB0),
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
 Widget _buildAttachmentField() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _customBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Choose File',
              style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _selectedFile != null
                ? _selectedFile!.path.split('/').last
                : 'No file selected',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
// field for the table
bool _arrivalIsBS = true;
  List<Map<String, String>> _summarizedRemarks = [];

void _addDailyRow() {
  setState(() {
    _summarizedRemarks.add({
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'departure_time': '',
      'departure_from': '',
      'transportation_mode': '',
      'arrival_date': '',
      'arrival_time': '',
      'departure_to': '',
      'visit_purpose': '',
    });
  });
}

void _deleteDailyRow(int index) {
  setState(() {
    _summarizedRemarks.removeAt(index);
  });
}

Future<void> _pickTime(BuildContext context, Map<String, String> row, String fieldKey) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      final formattedTime =
          "${picked.hourOfPeriod.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.period == DayPeriod.am ? "AM" : "PM"}";
      row[fieldKey] = formattedTime;
    });
  }
}


Future<void> _pickArrivalDate(Map<String, String> row) async {
  if (_arrivalIsBS) {
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: NepaliDateTime.now(),
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime(2090),
    );
    if (picked != null) {
      row['arrival_date'] = '${picked.year}/${picked.month.toString().padLeft(2,'0')}/${picked.day.toString().padLeft(2,'0')}';
    }
  } else {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      row['arrival_date'] = DateFormat('yyyy/MM/dd').format(picked);
    }
  }
  setState(() {});
}
Widget _buildSummarizedRemarksTable() {
  if (_summarizedRemarks.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "No summarized records added yet.",
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 18,
      headingRowColor:
          MaterialStateColor.resolveWith((states) => const Color(0xFFE6EEF8)),
      border: TableBorder.all(color: const Color(0xFFDDDDDD)),
      columns: const [
        DataColumn(label: Text('S.N', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Departure Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      

        DataColumn(label: Text('Departure From', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Transportation Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
       
       DataColumn(
  label: SizedBox(
    width: 130,
    child: Text('Arrival Date', 
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
  ),
),
        DataColumn(label: Text('Arrival Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Departure To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Visit Purpose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), // ✅ New column
       
      ],
      rows: List<DataRow>.generate(_summarizedRemarks.length, (index) {
        final row = _summarizedRemarks[index];
        return DataRow(cells: [
          DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 12))),
          DataCell(
            TextFormField(
              initialValue: row['date'],
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) => row['date'] = val,
            ),
          ),
          

          DataCell(
  Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: TextEditingController(text: row['departure_time']),
          readOnly: true,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.access_time, size: 18, color: Color(0xFF346CB0)),
        onPressed: () => _pickTime(context, row, 'departure_time'),
      ),
    ],
  ),
),

          DataCell(
            TextFormField(
              initialValue: row['departure_from'],
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) => row['departure_from'] = val,
            ),
          ),
         
          DataCell(
  DropdownButton<String>(
    isExpanded: true,
    value: (row['transportation_mode'] ?? '').isEmpty ? null : row['transportation_mode'],
    hint: const Text("Select", style: TextStyle(fontSize: 12)),
    items: _transportationModes.map((item) {
      return DropdownMenuItem(
        value: item["id"],
        child: Text(item["name"] ?? '', style: const TextStyle(fontSize: 12)),
      );
    }).toList(),
    onChanged: (val) {
      setState(() {
        row['transportation_mode'] = val ?? "";
      });
    },
    underline: Container(height: 1, color: Colors.grey),
  ),
),

DataCell(Stack(
            children: [
              GestureDetector(
                onTap: () => _pickArrivalDate(row),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(text: row['arrival_date'] ?? ''),
                    readOnly: true,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
              ),
              Positioned(
                right: 0, top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _arrivalIsBS = !_arrivalIsBS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: _customBlue,
                    child: Text(_arrivalIsBS ? 'NP' : 'EN', style: const TextStyle(fontSize: 9, color: Colors.white)),
                  ),
                ),
              ),
            ],
          )),
          DataCell(
  Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: TextEditingController(text: row['arrival_time']),
          readOnly: true,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.access_time, size: 18, color: Color(0xFF346CB0)),
        onPressed: () => _pickTime(context, row, 'arrival_time'),
      ),
    ],
  ),
),

          DataCell(
            TextFormField(
              initialValue: row['departure_to'],
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) => row['departure_to'] = val,
            ),
          ),
          DataCell(
            TextFormField(
              initialValue: row['visit_purpose'],
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) => row['visit_purpose'] = val,
            ),
          ),
          DataCell(
      IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF346CB0)),
        onPressed: _addDailyRow, // 🔹 Adds a new empty row
      ),
    ),
          
        ]);
      }),
    ),
  );
}



  Widget _buildTravelTypeDropdown() {
  if (_isLoadingDropdowns) return const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2));

    return DropdownButtonFormField<String>(
    value: _travelTypes.containsKey(_selectedTravelType) ? _selectedTravelType : null,
    items: _travelTypes.entries.map((e) {
    return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
    }).toList(),
    onChanged: (val) => setState(() => _selectedTravelType = val),
    decoration: _underlineDecoration(),
    hint: const Text("--Select--", style: TextStyle(fontSize: 13)),
  );
}




  Widget _buildTransportationDropdown() {
  if (_isLoadingDropdowns) return const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2));

  final validValue = _transportationModes.any((m) => m["id"] == _selectedTransportation)
      ? _selectedTransportation
      : null;

  return DropdownButtonFormField<String>(
    value: validValue,
    items: _transportationModes.map((m) {
      return DropdownMenuItem(value: m["id"], child: Text(m["name"]!, style: const TextStyle(fontSize: 13)));
    }).toList(),
    onChanged: (val) => setState(() => _selectedTransportation = val),
    decoration: _underlineDecoration(),
    hint: const Text("--Select--", style: TextStyle(fontSize: 13)),
  );
  }


Widget _buildBudgetDropdown() {
  if (_isLoadingDropdowns) return const SizedBox(height: 20, child: CircularProgressIndicator(strokeWidth: 2));

  final validValue = _budgetHeads.any((b) => b["id"] == _selectedBudget) ? _selectedBudget : null;

  return DropdownButtonFormField<String>(
    value: validValue,
    items: _budgetHeads.map((b) {
      return DropdownMenuItem(value: b["id"], child: Text(b["name"]!, style: TextStyle(fontSize: 13)));
    }).toList(),
    onChanged: (val) => setState(() => _selectedBudget = val),
    decoration: _underlineDecoration(),
    hint: const Text("--Select--", style: TextStyle(fontSize: 13)),
  );
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _customBlue,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => FieldVisitHistoryPage()),
              );
            },
          ),
          title: const Text(
            'Field Visit Entry',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
        

  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    _buildRow('Travel Type:', _buildTravelTypeDropdown()),
    _buildRow('From Date:', _buildDateField(_fromDateController, true)),
    _buildRow('To Date:', _buildDateField(_toDateController, false)),
    _buildRow('Mode of Transportation:', _buildTransportationDropdown()),
    _buildRow('Visit Place:', _buildTextField(_visitPlaceController)),
    _buildRow('Departure From:', _buildTextField(_departureFromController)),
    _buildRow('Departure To:', _buildTextField(_departureToController)),
    _buildRow('Budget:', _buildBudgetDropdown()),
    _buildRow('Purpose:', _buildTextField(_purposeController, maxLines: 4)),

    Row(
      children: [
        const Expanded(
          child: Text(
            "Hotel Booking",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Checkbox(
          value: _hotelBookingChecked,
          activeColor: _customBlue,
          onChanged: (val) => setState(() => _hotelBookingChecked = val ?? false),
        ),
      ],
    ),

    // ✅ FIXED: Proper row for Advance for Travel
    Row(
      children: [
        const Expanded(
          child: Text(
            "Advance for Travel",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Checkbox(
          value: _advanceChecked,
          activeColor: _customBlue,
          onChanged: (val) => setState(() => _advanceChecked = val ?? false),
        ),
      ],
    ),

    // ✅ FIXED: This is where your `if` should be
    if (_advanceChecked)
      _buildRow('Advance Amount:', _buildTextField(_advanceAmountController)),

    _buildRow('Remarks:', _buildTextField(_remarksController, maxLines: 3)),
              

Row(
  children: [
    const Expanded(
      child: Text(
        "Summarized Remarks",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    Checkbox(
      value: _addSummarizedChecked,
      activeColor: _customBlue,
      onChanged: (val) {
        setState(() {
          _addSummarizedChecked = val ?? false;
          if (_addSummarizedChecked) {
            // When checked, auto add one empty row
            _summarizedRemarks = [
              {
                'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                'departure_time': '',
                'departure_from': '',
                'transportation_mode': '',
                'arrival_time': '',
                'departure_to': '',
                'visit_purpose': '',
              }
            ];
          } else {
            // When unchecked, clear the table
            _summarizedRemarks.clear();
          }
        });
      },
    ),
  ],
),

// ✅ Show the table only when checkbox is checked
if (_addSummarizedChecked) ...[
  const SizedBox(height: 10),
  _buildSummarizedRemarksTable(),
],

              _buildRow('Attachment:', _buildAttachmentField()),
              const SizedBox(height: 24),
             
              const SizedBox(height: 24),
   Center(
  child: ElevatedButton(
    onPressed: _submitForm,
    style: ElevatedButton.styleFrom(
      backgroundColor: _customBlue,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: const Text(
      'Save',
      style: TextStyle(color: Colors.white, fontSize: 13),
    ),
  ),
),

            
  ],
      ),
        
       ),
       
       ),
    );
    
  }
}

  

