
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'substituteleavehistory.dart';

class SubstituteLeavePage extends StatefulWidget {

  final Map<String, dynamic>? existingLeaveData;
  const SubstituteLeavePage({Key? key, this.existingLeaveData}) : super(key: key);
  @override
  _SubstituteLeavePageState createState() => _SubstituteLeavePageState();
}

class _SubstituteLeavePageState extends State<SubstituteLeavePage> {
  List<LeaveEntry> leaveEntries = [LeaveEntry()];
  TextEditingController remarksController = TextEditingController();
  

  
  String? empId;
  String? orgId;
  String? locationId;
  bool _isLoading = false;
  String? leaveId;


  int get totalDays => leaveEntries.length;


  @override
  void initState() {
  super.initState();
  _loadUserData();
  _prefillDataIfExists(); 
}



void _prefillDataIfExists() {
  if (widget.existingLeaveData != null) {
    final data = widget.existingLeaveData!;

    print("====== PREFILL DATA DEBUG ======");
    print("Full data: ${jsonEncode(data)}");

   
   leaveId = data['leave_assign_masterid']?.toString();

    print("Leave ID for update: $leaveId");
    
    
    if (data['remarks'] != null && data['remarks'].toString().isNotEmpty) {
      remarksController.text = data['remarks'];
    }
    
    leaveEntries.clear();
    
    final List<dynamic> substitutes = data['substitutes'] as List<dynamic>? ?? [];
    print("Number of substitutes: ${substitutes.length}");
    
    
    for (var substitute in substitutes) {
      LeaveEntry entry = LeaveEntry();

      print("====== PROCESSING SUBSTITUTE ======");
      print("Full substitute data: ${jsonEncode(substitute)}");
      
      
      // Parse duty date (substitute_datebs)
      if (substitute['substitute_datebs'] != null) {
        try {
          String dateStr = substitute['substitute_datebs'].toString();
          print("Parsing duty date: $dateStr"); 
          List<String> parts = dateStr.split('/');
          if (parts.length == 3) {
            entry.dutyDate = NepaliDateTime(
              int.parse(parts[0]), 
              int.parse(parts[1]), 
              int.parse(parts[2])
            );
            entry.dutyIsBS = true;
            print("✅ Duty date set: ${entry.dutyDate}");
          }
        } catch (e) {
          print("❌ Error parsing duty date: $e");
        }
      }
      
      
      if (substitute['is_half'] != null) {
        entry.isHalfDuty = substitute['is_half'].toString().toUpperCase() == 'Y';
        print("Half duty status: ${entry.isHalfDuty}");
      }
      
      
      if (substitute['substitute_remarks'] != null && 
          substitute['substitute_remarks'].toString().isNotEmpty) {
        entry.remarksController.text = substitute['substitute_remarks'];
        print("Remarks set: ${entry.remarksController.text}");
      }
      
      
      String? leaveDateStr;
      
      
      if (substitute['taken'] != null && 
          substitute['taken'].toString().trim().toUpperCase() == 'Y') {
        leaveDateStr = substitute['taken_datebs']?.toString();
        print("Using taken_datebs (taken=Y): $leaveDateStr");
      }
      
      
      if (leaveDateStr == null || leaveDateStr.isEmpty || leaveDateStr == 'null') {
        leaveDateStr = substitute['leave_datebs']?.toString();
        print("Using leave_datebs: $leaveDateStr");
      }
      
      
      if (leaveDateStr == null || leaveDateStr.isEmpty || leaveDateStr == 'null') {
        leaveDateStr = substitute['leave_date']?.toString();
        print("Using leave_date: $leaveDateStr");
      }
      
      
      if (leaveDateStr != null && 
          leaveDateStr.isNotEmpty && 
          leaveDateStr != 'null') {
        try {
          String dateStr = leaveDateStr.trim();
          print("Attempting to parse leave date: '$dateStr'");
          
          List<String> parts = dateStr.split('/');
          print("Date parts: $parts (length: ${parts.length})");
          
          if (parts.length == 3) {
            int year = int.parse(parts[0].trim());
            int month = int.parse(parts[1].trim());
            int day = int.parse(parts[2].trim());
            
            print("Parsed values - Year: $year, Month: $month, Day: $day");
            
            entry.leaveDate = NepaliDateTime(year, month, day);
            entry.leaveIsBS = true;
            entry.isApplyLeave = true; 
            
            print("✅✅✅ Leave date SET SUCCESSFULLY: ${entry.leaveDate}");
            print("Leave date formatted: ${NepaliDateFormat('yyyy/MM/dd').format(entry.leaveDate)}");
          } else {
            print("❌ Invalid date format - expected 3 parts, got ${parts.length}");
          }
        } catch (e) {
          print("❌❌❌ Error parsing leave date: $e");
        }
      } else {
        print("No leave date found in any field");
        entry.isApplyLeave = false;
      }
      
      print("====== FINAL ENTRY STATE ======");
      print("Duty Date: ${entry.dutyDate}");
      print("Leave Date: ${entry.leaveDate}");
      print("isApplyLeave: ${entry.isApplyLeave}");
      print("isHalfDuty: ${entry.isHalfDuty}");
     
      
      leaveEntries.add(entry);
    }
    
    
    if (leaveEntries.isEmpty) {
      leaveEntries.add(LeaveEntry());
    }
    
    setState(() {});
  }
}
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      empId = prefs.getString('employee_id');
      orgId = prefs.getString('org_id');
      locationId = prefs.getString('location_id'); 
    });
    
    print("====== LOADED USER DATA ======");
    print("employee_id: $empId");
    print("org_id: $orgId");
    print("location_id: $locationId");
   
  }

  void _addNewEntry() {
    setState(() {
      leaveEntries.add(LeaveEntry());
    });
  }

  void _removeEntry(int index) {
    setState(() {
      leaveEntries.removeAt(index);
    });
  }

  Future<void> _selectDate(int index, bool isDutyDate) async {
    final entry = leaveEntries[index];
    final isBS = isDutyDate ? entry.dutyIsBS : entry.leaveIsBS;

    if (isBS) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        setState(() {
          if (isDutyDate) {
            entry.dutyDate = picked;
            _checkDutyDateAPIs(entry, picked, isBS);
          } else {
            entry.leaveDate = picked;
          }
        });
      }
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setState(() {
          if (isDutyDate) {
            entry.dutyDate = picked;
            _checkDutyDateAPIs(entry, picked, isBS);
          } else {
            entry.leaveDate = picked;
          }
        });
      }
    }
  }

  Future<void> _checkDutyDateAPIs(LeaveEntry entry, dynamic date, bool isBS) async {
    if (empId == null || orgId == null) {
      setState(() {
        entry.apiResponseMessage = "Employee ID or Organization ID not found. Please login again.";
        entry.hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      entry.apiResponseMessage = null;
      entry.hasError = false;
    });

    try {
      String dateVal;
      String dateType = isBS ? 'NP' : 'EN';
      
      if (isBS) {
        NepaliDateTime nepaliDate = date is NepaliDateTime ? date : NepaliDateTime.fromDateTime(date);
        dateVal = NepaliDateFormat('yyyy/MM/dd').format(nepaliDate);
      } else {
        DateTime englishDate = date is DateTime ? date : date.toDateTime();
        dateVal = DateFormat('yyyy/MM/dd').format(englishDate);
      }

     
      print("empid: $empId");
      print("orgid: $orgId");
      print("date_type: $dateType");
      print("date_val: $dateVal");
     

 
      List<String> responses = [];
      
     
      String attendanceMsg = await _checkAttendance(dateVal, dateType);
      responses.add(attendanceMsg);
      

      String rejectionMsg = await _checkRejection(dateVal, dateType);
      responses.add(rejectionMsg);
 
      String overtimeMsg = await _checkOvertime(dateVal, dateType);
      responses.add(overtimeMsg);

      setState(() {
        entry.apiResponseMessage = responses.join('\n');
        entry.hasError = false;
      });

    } catch (e) {
      print("Error calling APIs: $e");
      setState(() {
        entry.apiResponseMessage = "Error checking duty date: $e";
        entry.hasError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _checkAttendance(String dateVal, String dateType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/substitute_Leave_check_attendance'),
        headers: {
          'Content-Type': 'application/json',
          'empid': empId!,
          'orgid': orgId!,
          'date_type': dateType,
        },
        body: jsonEncode({'date_val': dateVal}),
      );

      print("====== ATTENDANCE API RESPONSE ======");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
     

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return "✓ Attendance: ${data['message'] ?? 'Checked successfully'}";
        } else {
          return "✗ Attendance: ${data['message'] ?? 'Check failed'}";
        }
      } else {
        return "✗ Attendance: Check failed";
      }
    } catch (e) {
      print("Attendance API Error: $e");
      return "✗ Attendance: Error - $e";
    }
  }


  

  Future<String> _checkRejection(String dateVal, String dateType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/substitute_leave_check_rejection'),
        headers: {
          'Content-Type': 'application/json',
          'empid': empId!,
          'orgid': orgId!,
          'date_type': dateType,
        },
        body: jsonEncode({'date_val': dateVal}),
      );

      print("====== REJECTION API RESPONSE ======");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
    

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return "✓ Rejection: ${data['message'] ?? 'No rejections'}";
        } else {
          return "✗ Rejection: ${data['message'] ?? 'Check failed'}";
        }
      } else {
        return "✗ Rejection: Check failed";
      }
    } catch (e) {
      print("Rejection API Error: $e");
      return "✗ Rejection: Error - $e";
    }
  }

  Future<String> _checkOvertime(String dateVal, String dateType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/substitute_leave_check_overtime'),
        headers: {
          'Content-Type': 'application/json',
          'empid': empId!,
          'orgid': orgId!,
          'date_type': dateType,
        },
        body: jsonEncode({'date_val': dateVal}),
      );

      print("====== OVERTIME API RESPONSE ======");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
     

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return "✓ Overtime: ${data['message'] ?? 'Checked successfully'}";
        } else {
          return "✗ Overtime: ${data['message'] ?? 'Check failed'}";
        }
      } else {
        return "✗ Overtime: Check failed";
      }
    } catch (e) {
      print("Overtime API Error: $e");
      return "✗ Overtime: Error - $e";
    }
  }

Future<void> _saveSubstituteLeave() async {

  if (empId == null || orgId == null || locationId == null) {
    _showMessage("User data not found. Please login again.", isError: true);
    return;
  }

  if (leaveEntries.isEmpty) {
    _showMessage("Please add at least one leave entry.", isError: true);
    return;
  }


  for (int i = 0; i < leaveEntries.length; i++) {
    if (leaveEntries[i].dutyDate == null) {
      _showMessage("Please select duty date for Entry ${i + 1}", isError: true);
      return;
    }
  }

  setState(() => _isLoading = true);

  try {
    
    List<String> subDates = [];
    List<int> detailIds = [];
    List<String> attendStatuses = [];
    List<String> otStatuses = [];
    List<dynamic> utilized = [];  
    List<String> isHalfs = [];
    List<dynamic> leaveDates = [];  
    List<String> employeeRemarks = [];
  

    

   
    String sdate = DateFormat('yyyy/MM/dd').format(DateTime.now());

    for (var entry in leaveEntries) {
      String formattedDutyDate;
      if (entry.dutyIsBS) {
        NepaliDateTime nepaliDate = entry.dutyDate is NepaliDateTime 
            ? entry.dutyDate 
            : NepaliDateTime.fromDateTime(entry.dutyDate);
        formattedDutyDate = NepaliDateFormat('yyyy/MM/dd').format(nepaliDate);
      } else {
        DateTime englishDate = entry.dutyDate is DateTime 
            ? entry.dutyDate 
            : entry.dutyDate.toDateTime();
        formattedDutyDate = DateFormat('yyyy/MM/dd').format(englishDate);
      }
      subDates.add(formattedDutyDate);


      dynamic formattedLeaveDate; 
      if (entry.leaveDate != null) {
        if (entry.leaveIsBS) {
          NepaliDateTime nepaliDate = entry.leaveDate is NepaliDateTime 
              ? entry.leaveDate 
              : NepaliDateTime.fromDateTime(entry.leaveDate);
          formattedLeaveDate = NepaliDateFormat('yyyy/MM/dd').format(nepaliDate);
        } else {
          DateTime englishDate = entry.leaveDate is DateTime 
              ? entry.leaveDate 
              : entry.leaveDate.toDateTime();
          formattedLeaveDate = DateFormat('yyyy/MM/dd').format(englishDate);
        }
      } else {
        formattedLeaveDate = null;  
      }
      leaveDates.add(formattedLeaveDate);

      // Add other data
      detailIds.add(0);  
      attendStatuses.add("true");  
      otStatuses.add("false");     
      utilized.add(null);
      isHalfs.add(entry.isHalfDuty ? "Y" : "N");
      employeeRemarks.add(entry.remarksController.text.trim().isEmpty 
          ? "Substitute leave" 
          : entry.remarksController.text.trim());
    }

    // Prepare request body
    final requestBody = {
      "sdate": sdate,
      "tdays": totalDays,
       "id": leaveId,
      "sub_date": subDates,
      "detailid": detailIds,
      "attendStatus": attendStatuses,
      "otStatus": otStatuses,
      "utilized": utilized,
      "is_half": isHalfs,
      "leave_date": leaveDates,
      "employee_remarks": employeeRemarks,
      "is_special": "N",
      "remarks": remarksController.text.trim().isEmpty 
          ? "Substitute leave deposit" 
          : remarksController.text.trim(),
      "app_status": "1"
    };

    print("====== SAVE API REQUEST ======");
    print("Headers:");
    print("  empid: $empId");
    print("  orgid: $orgId");
    print("  locationid: $locationId");
    print("Body: ${jsonEncode(requestBody)}");

    // Make API call
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/save_substitute_leave_deposit'),
      headers: {
        'Content-Type': 'application/json',
        'empid': empId!,
        'orgid': orgId!,
        'locationid': locationId!,
      },
      body: jsonEncode(requestBody),
    );

    print("====== SAVE API RESPONSE ======");
    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

    

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  if (data['status'] == 'success') {
    String successMessage;
    if (data['message'] is List) {
      successMessage = (data['message'] as List).join('\n');
    } else {
      successMessage = data['message']?.toString() ?? "Substitute leave saved successfully!";
    }
    _showMessage(successMessage);
  
    
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SubstituteHistoryPage(),
        ),
      );
   
  } else {
    String errorMessage;
    if (data['message'] is List) {
      errorMessage = (data['message'] as List).join('\n');
    } else if (data['message'] is String) {
      errorMessage = data['message'];
    } else {
     errorMessage = "Failed to save substitute leave";
    }
    print("Error details: $data");
    _showMessage(errorMessage, isError: true);
  }
} else {
  _showMessage("Server error: ${response.statusCode}", isError: true);
}
} catch (e, stackTrace) {  
  print("Save API Error: $e");
  print("Stack trace: $stackTrace");  
  _showMessage("Error saving substitute leave: $e", isError: true);
} finally {
  setState(() => _isLoading = false);
}
}

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(dynamic date, bool isBS) {
    if (date == null) return 'Select Date';
    if (isBS) {
      NepaliDateTime nepaliDate = date is NepaliDateTime ? date : NepaliDateTime.fromDateTime(date);
      return NepaliDateFormat('yyyy/MM/dd').format(nepaliDate);
    } else {
      DateTime englishDate = date is DateTime ? date : date.toDateTime();
      return DateFormat('yyyy/MM/dd').format(englishDate);
    }
  }

  Widget _buildDatePickerField({
    required String label,
    required dynamic date,
    required bool isBS,
    required VoidCallback onTap,
    required VoidCallback toggleCalendar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(date, isBS),
                    style: TextStyle(
                      fontSize: 13,
                      color: date == null ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: toggleCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF346CB0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isBS ? 'BS' : 'AD',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF346CB0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveEntryCard(int index, LeaveEntry item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF346CB0).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF346CB0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Entry ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (leaveEntries.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => _removeEntry(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDatePickerField(
            label: 'Select Duty Date:',
            date: item.dutyDate,
            isBS: item.dutyIsBS,
            onTap: () => _selectDate(index, true),
            toggleCalendar: () {
              setState(() {
                item.dutyIsBS = !item.dutyIsBS;
                if (item.dutyDate != null) {
                  item.dutyDate = item.dutyIsBS
                      ? NepaliDateTime.fromDateTime(
                          item.dutyDate is DateTime ? item.dutyDate : item.dutyDate.toDateTime())
                      : item.dutyDate is NepaliDateTime
                          ? item.dutyDate.toDateTime()
                          : item.dutyDate;
                }
              });
            },
          ),
          
         
          if (item.apiResponseMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.hasError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.hasError ? Colors.red.shade300 : Colors.green.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.apiResponseMessage!.split('\n').map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          line.startsWith('✓') ? Icons.check_circle : Icons.info,
                          size: 14,
                          color: item.hasError ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 11,
                              color: item.hasError ? Colors.red.shade900 : Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSwitchField(
                label: 'Half Duty',
                value: item.isHalfDuty,
                onChanged: (val) => setState(() => item.isHalfDuty = val),
              ),
              const SizedBox(height: 8),
              _buildSwitchField(
                label: 'Apply Leave',
                value: item.isApplyLeave,
                onChanged: (val) => setState(() => item.isApplyLeave = val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDatePickerField(
            label: 'Select Leave Date:',
            date: item.leaveDate,
            isBS: item.leaveIsBS,
            onTap: () => _selectDate(index, false),
            toggleCalendar: () {
              setState(() {
                item.leaveIsBS = !item.leaveIsBS;
                if (item.leaveDate != null) {
                  item.leaveDate = item.leaveIsBS
                      ? NepaliDateTime.fromDateTime(
                          item.leaveDate is DateTime ? item.leaveDate : item.leaveDate.toDateTime())
                      : item.leaveDate is NepaliDateTime
                          ? item.leaveDate.toDateTime()
                          : item.leaveDate;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remarks:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: item.remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF346CB0), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF346CB0),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Substitute Leave",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                
                  Row(
  children: [
    const Text(
      "Total Days:",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Color(0xFF2C3E50),
        
      ),
    ),
    const SizedBox(width: 12),
    Container(
      width: 55,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF346CB0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:const Color(0xFF346CB0),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$totalDays',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
         color: Color(0xFF346CB0),
       
        ),
      ),
    ),
  ],
),

                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        "Leave Entries:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...leaveEntries.asMap().entries.map((entry) {
                    return _buildLeaveEntryCard(entry.key, entry.value);
                  }).toList(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addNewEntry,
                      icon: const Icon(Icons.add_circle_outline, size: 14),
                      label: const Text(
                        'Add Entry',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF346CB0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 2,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 12),
                          label: const Text(
                            "Re-verify Attendance & Overtime",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF346CB0),
                            side: const BorderSide(color: Color(0xFF346CB0), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            // Re-verify all duty dates
                            for (var entry in leaveEntries) {
                              if (entry.dutyDate != null) {
                                _checkDutyDateAPIs(entry, entry.dutyDate, entry.dutyIsBS);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.warning_amber_rounded, size: 12),
                        label: const Text(
                          "Check Rejections",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          // Check rejections for all duty dates
                          setState(() => _isLoading = true);
                          for (var entry in leaveEntries) {
                            if (entry.dutyDate != null) {
                              String dateVal;
                              String dateType = entry.dutyIsBS ? 'NP' : 'EN';
                              
                              if (entry.dutyIsBS) {
                                NepaliDateTime nepaliDate = entry.dutyDate is NepaliDateTime 
                                    ? entry.dutyDate 
                                    : NepaliDateTime.fromDateTime(entry.dutyDate);
                                dateVal = NepaliDateFormat('yyyy/MM/dd').format(nepaliDate);
                              } else {
                                DateTime englishDate = entry.dutyDate is DateTime 
                                    ? entry.dutyDate 
                                    : entry.dutyDate.toDateTime();
                                dateVal = DateFormat('yyyy/MM/dd').format(englishDate);
                              }
                              
                              String rejectionMsg = await _checkRejection(dateVal, dateType);
                              setState(() {
                                entry.apiResponseMessage = rejectionMsg;
                                entry.hasError = rejectionMsg.contains('✗');
                              });
                            }
                          }
                          setState(() => _isLoading = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Text(
                        "General Remarks:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: remarksController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF346CB0), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
Center(
  child: ElevatedButton.icon(
    label: const Text(
      "Save",
      style: TextStyle(color: Colors.white, fontSize: 13),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF346CB0),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: _saveSubstituteLeave,
  ),
),
const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF346CB0)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LeaveEntry {
  dynamic dutyDate;
  dynamic leaveDate;
  bool isHalfDuty = false;
  bool isApplyLeave = false;
  bool dutyIsBS = true;
  bool leaveIsBS = true;
  TextEditingController remarksController = TextEditingController();
  
  // Combined API response
  String? apiResponseMessage;
  bool hasError = false;
}



