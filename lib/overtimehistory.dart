import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'overtimeentry.dart';
import 'dashboardpage.dart';
import 'config.dart';


class OvertimeRequest {
  final String masterId;
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final String remarks;

  OvertimeRequest({
    required this.masterId,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.remarks,
  });

  /// ✅ Safely convert API response (with possible List or String values)
  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
  return OvertimeRequest(
    masterId: json['master_id']?.toString() ?? '', // ✅ new
    startDate: json['ot_datead']?.toString() ?? '', // API field
    endDate: json['ot_datebs']?.toString() ?? '',   // API field
    startTime: json['ot_starttime']?.toString() ?? '',
    endTime: json['ot_endtime']?.toString() ?? '',
    remarks: json['remarks']?.toString().trim() ?? '',
  );
}


  /// ✅ Convert Dart object → JSON (for API submission)
  Map<String, dynamic> toJson() {
  return {
    "master_id": masterId,
    "ot_datead": startDate,
    "ot_datebs": endDate,
    "ot_starttime": startTime,
    "ot_endtime": endTime,
    "remarks": remarks,
  };
}

}


class OverTimeHistoryPage extends StatefulWidget {
  final Map<String, dynamic>? overtimeData;
  const OverTimeHistoryPage({super.key, this.overtimeData});

  @override
  State<OverTimeHistoryPage> createState() => _OverTimeHistoryPageState();
}

class _OverTimeHistoryPageState extends State<OverTimeHistoryPage> {
  final List<String> tabs = ['Pending', 'Approved', 'Review', 'Cancel'];
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _error;

  Map<String, List<OvertimeRequest>> historyData = {
    'Pending': [],
    'Approved': [],
    'Review': [],
    'Cancel': [],
  };

  @override
  void initState() {
    super.initState();
    if (widget.overtimeData != null) {
      parseHistoryData(widget.overtimeData!);
    } else {
      fetchOvertimeHistory();
    }
  }

  void parseHistoryData(Map<String, dynamic> data) {
    final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};

    Map<String, List<OvertimeRequest>> parsedData = {
      'Pending': [],
      'Approved': [],
      'Review': [],
      'Cancel': [],
    };

    if (statusWiseHistory is Map) {
      statusWiseHistory.forEach((key, value) {
        final safeKey = key.toString();
        if (value is List) {
          parsedData[safeKey] = value
              .map((item) => OvertimeRequest.fromJson(item))
              .toList();
        }
      });
    }

    setState(() {
      historyData = parsedData;
    });
  }

  Future<void> fetchOvertimeHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    
   final locationId = prefs.getString('location_id') ?? '';



    final url = Uri.parse('$baseUrl/api/v1/request_overtime');

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "empid": empId,
          "orgid": orgId,
          "locationid": locationId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          parseHistoryData(data);
          print("History API Response: ${jsonEncode(data)}");


        

          

        } else {
          setState(() {
            _error = data['message'] ?? 'No data available';
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parsed = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("h:mm a").format(parsed);
    } catch (_) {
      return time;
    }
  }

  Widget _buildList(String tab) {
    List<OvertimeRequest> records = historyData[tab] ?? [];

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (records.isEmpty) {
      return Center(
          child: Text('No $tab records',
              style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final request = records[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                // ✅ Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date: ${request.startDate}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Overtime',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text('O.T Start Time: ${_formatTime(request.startTime)}'),
                Text('O.T End Time: ${_formatTime(request.endTime)}'),
                Text(
                    'Remarks: ${request.remarks.isNotEmpty ? request.remarks : 'No remarks'}'),
                if (tab == 'Pending')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                           await Navigator.push(
                             context,
                              MaterialPageRoute(
                                builder: (_) => OvertimeEntryApp(
                                  existingData: request.toJson(),
                                ),

                         
                              ),
                            );
                            fetchOvertimeHistory();
                          },
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Update',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    "HRMS says,",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 20),
                                  ),
                                  content: const Text(
                                      "Are you sure you want to cancel this record?"),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
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
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          historyData['Pending']
                                              ?.removeAt(index);
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Record canceled successfully'),
                                          backgroundColor: Colors.red,
                                        ));
                                      },
                                      child: const Text("OK",
                                          style: TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete, size: 14),
                          label: const Text('Cancel',
                              style: TextStyle(fontSize: 12)),
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
            "Overtime History",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
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
            Container(height: 130, color: const Color(0xFF346CB0)),
            Column(
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
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
                                child: GestureDetector(
                                  onTap: () => _selectDate(true),
                                  child:
                                      _buildDateField(_fromDate, 'From'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child:
                                      _buildDateField(_toDate, 'To'),
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
                                backgroundColor:
                                    const Color(0xFF346CB0),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              onPressed: fetchOvertimeHistory,
                              child: const Text('Filter',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white)),
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
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.bold),
                  tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children:
                        tabs.map((tab) => _buildList(tab)).toList(),
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
                        builder: (context) =>
                             OvertimeEntryApp()),
                  );
                  fetchOvertimeHistory();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Overtime",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF346CB0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(DateTime? date, String hint) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today,
              color: Colors.black87, size: 18),
          const SizedBox(width: 8),
          Text(date != null ? _formatDate(date) : hint,
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
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
    return date != null
        ? DateFormat('yyyy-MM-dd').format(date)
        : '';
  }
}
