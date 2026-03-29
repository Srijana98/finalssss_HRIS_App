import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'attendanceentrypage.dart';
import 'dashboardpage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'dart:convert';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class AttendanceHistoryModel {
  final String id;
  final String attendanceDateAd;
  final String attendanceDateBs;
  final String attendanceType;
  final String attendanceTime;
  final String remarks;
  final String requestDate;
  

  AttendanceHistoryModel({
    required this.id,
    required this.attendanceDateAd,
    required this.attendanceDateBs,
    required this.attendanceType,
    required this.attendanceTime,
    required this.remarks,
    required this.requestDate,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryModel(
      id: json['id']?.toString() ?? '',
      attendanceDateAd: json['att_datead'] ?? '',
      attendanceDateBs: json['att_datebs'] ?? '',
      attendanceType: json['att_type'] ?? '',
      attendanceTime: json['att_time'] ?? '',
      remarks: json['remarks'] ?? '',
      requestDate: json['created_at'] ?? '', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'att_datead': attendanceDateAd,
      'att_datebs': attendanceDateBs,
      'att_type': attendanceType,
      'att_time': attendanceTime,
      'remarks': remarks,
      'created_at': requestDate,

    };
  }
}

class AttendanceHistoryPage extends StatefulWidget {
  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final List<String> tabs = ['Pending', 'Approved', 'Cancel'];

  DateTime? _fromDate;
  DateTime? _toDate;

  bool isLoading = false;
  String? error;

Map<String, List<AttendanceHistoryModel>> historyData = {
  'Pending': [],
  'Approved': [],
   'Cancel': [],
};


  @override
  void initState() {
    super.initState();
    fetchAttendanceHistory();
  }



String formatRequestDateBS(String dateTime) {
  if (dateTime.isEmpty) return '';

  try {
    final dt = DateTime.parse(dateTime); // AD datetime
    final nepaliDate = NepaliDateTime.fromDateTime(dt);
    // Format: yyyy/MM/dd hh:mm a
    final formattedDate = 
        '${nepaliDate.year}/${nepaliDate.month.toString().padLeft(2,'0')}/${nepaliDate.day.toString().padLeft(2,'0')} '
        '${DateFormat('hh:mm a').format(dt)}';
    return formattedDate;
  } catch (e) {
    return dateTime;
  }
}




Future<void> fetchAttendanceHistory() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final prefs = await SharedPreferences.getInstance();

    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    String fromDateStr = _fromDate != null
        ? DateFormat('yyyy/MM/dd').format(_fromDate!)
        : '';
    String toDateStr = _toDate != null
        ? DateFormat('yyyy/MM/dd').format(_toDate!)
        : '';

    final uri = Uri.parse(
      '$baseUrl/api/v1/get_manual_attendance',
    ).replace(queryParameters: {
      if (fromDateStr.isNotEmpty) 'from_date': fromDateStr,
      if (toDateStr.isNotEmpty) 'to_date': toDateStr,
    });

    final response = await http.get(
      uri,
      headers: {
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
    );

    final jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'success') {
      final statusWiseHistory = jsonData['data']['statusWiseHistory'];

      Map<String, List<AttendanceHistoryModel>> parsed = {
        'Pending': [],
        'Approved': [],
         'Cancel':[],
      };

      if (statusWiseHistory is Map) {
        statusWiseHistory.forEach((key, value) {
          if (value is List && parsed.containsKey(key)) {
            parsed[key] = value
                .map((e) =>
                    AttendanceHistoryModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        });
      }

      setState(() {
        historyData = parsed;
      });
    } else {
      setState(() {
        error = jsonData['message'];
      });
    }
  } catch (e) {
    setState(() {
      error = e.toString();
    });
  } finally {
    setState(() => isLoading = false);
  }
}




Future<void> cancelAttendanceRequest(String id, int index) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    final url = Uri.parse(
      '$baseUrl/api/v1/cancelRecord_manual',
    );

    final response = await http.post(
      url,
      headers: {
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id': id}),
    );

  debugPrint('🔹 Cancel Attendance URL: $url');
debugPrint( '🔹 Headers: {empid: $empId, orgid: $orgId, locationid: $locationId}',
);
debugPrint('🔹 Body: {"id": "$id"}');


    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Just refresh the list
      fetchAttendanceHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(jsonData['message'] ?? 'Failed to cancel'),
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

   

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy/MM/dd').format(date) : '';
  }


Widget _buildList(String tab) {
  final List<AttendanceHistoryModel> records = historyData[tab] ?? [];

  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (error != null) {
    return Center(
      child: Text(
        error!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  if (records.isEmpty) {
    return Center(
      child: Text(
        'No $tab records',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  return ListView.builder(
   // padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
    itemCount: records.length,
    itemBuilder: (context, index) {
      final item = records[index];

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF346CB0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Top Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Date: ${item.attendanceDateBs}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                  ),

                  Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: item.attendanceType == 'CHECKIN'
        ? Colors.blue.shade100    
        : Colors.green.shade100,  
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    item.attendanceType,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
  ),
),

                ],
              ),

              const SizedBox(height: 4),

              Text(
                'Attendance Time: ${item.attendanceTime}',
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 4),

              Text(
                'Remarks: ${item.remarks.isNotEmpty ? item.remarks : 'No remarks'}',
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 6),

              Text(
                'Request Date: ${formatRequestDateBS(item.requestDate)}',
                style: const TextStyle(fontSize: 14),
              ),

              /// 🔹 Buttons ONLY for Pending
              if (tab == 'Pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Update',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceRequestApp(
                                existingData: item.toJson(),
                              ),
                            ),
                          );
                          fetchAttendanceHistory();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete, size: 14),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text(
                                  "HRMS says,",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                content: const Text(
                                    "Are you sure you want to cancel the record?"),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text(
                                      "Cancel",
                                      style:
                                          TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF346CB0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await cancelAttendanceRequest(
                                          item.id, index);
                                      fetchAttendanceHistory();
                                    },
                                    child: const Text(
                                      "OK",
                                      style:
                                          TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}





  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF346CB0),
          elevation: 0,
          title: const Text(
            "Attendance History",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DashboardPage()),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 130,
              color: const Color(0xFF346CB0),
            ),
            Column(
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                       // const Icon(Icons.calendar_today,
                                         const Icon(Icons.date_range,             
                                            color: Color(0xFF346CB0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fromDate != null
                                              ? _formatDate(_fromDate)
                                              : 'From',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Color(0xFF346CB0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _toDate != null
                                              ? _formatDate(_toDate)
                                              : 'To',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF346CB0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: fetchAttendanceHistory,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
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
                const SizedBox(height: 16),
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFF346CB0),
                  labelColor: const Color(0xFF346CB0),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                  tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                ),

               

Expanded(
  child: TabBarView(
    children: tabs.map((tab) => _buildList(tab)).toList(),
  ),
),

              ],
            ),
            Positioned(
              bottom: 20,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AttendanceRequestApp()),
                  );
                  fetchAttendanceHistory();
                },

               

                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Attendance",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF346CB0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}