import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';


class MoreAttendancePage extends StatefulWidget {
  @override
  State<MoreAttendancePage> createState() => _MoreAttendancePageState();
}

class _MoreAttendancePageState extends State<MoreAttendancePage> {
  final Color _customBlue = const Color(0xFF346CB0);

  String? _fromDate;
  String? _toDate;
  bool _isFromBS = true;
  bool _isToBS = true;

  
  List<Map<String, String>> _attendanceData = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLog(); // 👈 This automatically loads data when page opens
  }


  // Date selection logic
  Future<void> _selectDate(bool isFrom) async {
    if ((isFrom ? _isFromBS : _isToBS)) {
      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: NepaliDateTime.now(),
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2090),
      );
      if (picked != null) {
        setState(() {
          final formatted =
              '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
          if (isFrom) {
            _fromDate = formatted;
          } else {
            _toDate = formatted;
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
          final formatted = DateFormat('yyyy/MM/dd').format(picked);
          if (isFrom) {
            _fromDate = formatted;
          } else {
            _toDate = formatted;
          }
        });
      }
    }
  }

  // Date input with BS/AD toggle
  Widget _buildDateBox({
    required String? date,
    required String hint,
    required bool isFrom,
  }) {
    bool isBS = isFrom ? _isFromBS : _isToBS;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _selectDate(isFrom),
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(text: date ?? ''),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 14,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isFrom) {
                  _isFromBS = !_isFromBS;
                } else {
                  _isToBS = !_isToBS;
                }
              });
              _selectDate(isFrom);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _customBlue,
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




Future<void> _fetchAttendanceLog() async {
  try {
    setState(() {
      _attendanceData = []; // clear old data
    });

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/my_attendance_log'),
      headers: {
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
    );

    debugPrint("📩 Response Code: ${response.statusCode}");
    debugPrint("📦 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final data = responseData['data'];
        final List<dynamic> dailyActivity = data['daily_activity'] ?? [];
        final Map<String, dynamic> dateArr =
            Map<String, dynamic>.from(data['date_arr'] ?? {});
        final Map<String, dynamic> shiftCategory =
            Map<String, dynamic>.from(data['shift_category'] ?? {});

        List<Map<String, String>> loadedData = [];
        int sn = 1;

        for (var activity in dailyActivity) {
          final String dateAD = activity['datead']?.toString() ?? '-';
          final String dateBS = dateArr[dateAD]?.toString() ?? '-';
          final String activityName = activity['activity']?.toString() ?? '-';
          final String shiftId = activity['attendance_typeid']?.toString() ?? '';
          final shiftInfo = shiftCategory[shiftId];

          // Extract shift details (if available)
          final String shiftName =
              shiftInfo != null ? shiftInfo['name']?.toString() ?? '-' : '-';
          final String startTime =
              shiftInfo != null ? shiftInfo['office_start_time']?.toString() ?? '-' : '-';
          final String endTime =
              shiftInfo != null ? shiftInfo['office_end_time']?.toString() ?? '-' : '-';
          final String workHrs =
              activity['working_hours']?.toString() ?? '-';

          loadedData.add({
            'sn': sn.toString(),
            'dateAD': dateAD,
            'dateBS': dateBS,
            'days': '-', // Not provided in response
            'shift': shiftName,
            'checkIn': activity['checkin']?.toString().isNotEmpty == true
                ? activity['checkin'].toString()
                : startTime,
            'checkOut': activity['checkout']?.toString().isNotEmpty == true
                ? activity['checkout'].toString()
                : endTime,
            'workHrs': workHrs,
            'activity': activityName,
          });
          sn++;
        }

        setState(() {
          _attendanceData = loadedData;
        });

        debugPrint("✅ Loaded ${loadedData.length} attendance records");
      } else {
        debugPrint("⚠️ No attendance data found in response.");
      }
    } else {
      debugPrint("❌ Failed to fetch attendance log: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load attendance data')),
      );
    }
  } catch (e) {
    debugPrint("⚠️ Error fetching attendance log: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching attendance log: $e')),
    );
  }
}



  
  // Table header + rows
Widget _buildAttendanceTable() {
  final headers = [
    'S.N',
    'Date(AD)',
    'Date(BS)',
    'Days',
    'Shift',
    'CheckIn',
    'CheckOut',
    'WorkHrs',
    'Activity'
  ];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.grey[50],
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(90),
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: _customBlue.withOpacity(0.1),
            ),
            children: headers.map((h) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Center(
                  child: Text(
                    h,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _customBlue,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Data rows
          ..._attendanceData.map((row) {
            return TableRow(
              children: [
                _buildTableCell(row['sn']),
                _buildTableCell(row['dateAD']),
                _buildTableCell(row['dateBS']),
                _buildTableCell(row['days']),
                _buildTableCell(row['shift']),
                _buildTableCell(row['checkIn']),
                _buildTableCell(row['checkOut']),
                _buildTableCell(row['workHrs']),
                _buildTableCell(
                  row['activity'],
                  color: row['activity'] == 'Leave'
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    ),
  );
}

// Helper for each cell
Widget _buildTableCell(String? text, {Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: Center(
      child: Text(
        text ?? '-',
        style: TextStyle(
          fontSize: 12.5,
          color: color ?? Colors.black87,
        ),
      ),
    ),
  );
}


  // Helper: build each table cell
  Widget _buildCell(String? text, {Color? color}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      alignment: Alignment.center,
      child: Text(
        text ?? '-',
        style: TextStyle(
          fontSize: 12.5,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _customBlue,
        elevation: 0,
        title: const Text(
          "My Attendance",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(height: 130, color: _customBlue),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Filter section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateBox(
                                    date: _fromDate,
                                    hint: 'From',
                                    isFrom: true),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDateBox(
                                    date: _toDate, hint: 'To', isFrom: false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _customBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                debugPrint(
                                    'Filtering from $_fromDate to $_toDate');
                                      _fetchAttendanceLog();
                              },
                              child: const Text(
                                'Filter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Table below filter
                _buildAttendanceTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
