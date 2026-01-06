import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'lateinentry.dart';
import 'dashboardpage.dart';
import 'config.dart'; 

class LateEarlyRequest {
  final int? id; 
  final String posting_type;
  final String type;
  final String post_date;
  final String le_time;
  final String remarks;

  LateEarlyRequest({
    this.id,
    required this.posting_type,
    required this.type,
    required this.post_date,
    required this.le_time,
    required this.remarks,
  });

  factory LateEarlyRequest.fromJson(Map<String, dynamic> json) {
    return LateEarlyRequest(
    id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
    posting_type: json['posting_type'] ?? '',
    type: json['type'] ?? '',
    post_date: json['post_date'] ?? json['postdatead'] ?? json['postdatebs'] ?? '',
    le_time: json['le_time'] ?? '',
    remarks: json['remarks'] ?? '',
    );
  }

Map<String, dynamic> toJson() {
  return {
    'posting_type': posting_type,
    'type': type,
    'post_date': post_date,
    'le_time': le_time,
    'remarks': remarks,
    if (id != null) 'id': id, 
  };
}

}
class LateInHistoryPage extends StatefulWidget {
  final Map<String, dynamic>? lateinData;

  const LateInHistoryPage({super.key, this.lateinData});

  @override
  State<LateInHistoryPage> createState() => _LateInHistoryPageState();
}

class _LateInHistoryPageState extends State<LateInHistoryPage> {
  final List<String> tabs = ['Pending', 'Review', 'Approved', 'Cancel'];
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _error;

  Map<String, List<LateEarlyRequest>> historyData = {
    'Pending': [],
    'Review': [],
    'Approved': [],
    'Cancel': [],
  };
  

  // @override
  void initState() {
    super.initState();
    if (widget.lateinData != null) {
      parseHistoryData(widget.lateinData!);
    } else {
      fetchLateInHistory();
    }
  }

  void parseHistoryData(Map<String, dynamic> data) {
  final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};

  Map<String, List<LateEarlyRequest>> parsedData = {
    'Pending': [],
    'Review': [],
    'Approved': [],
    'Cancel': [],
  };

  if (statusWiseHistory is Map) {
    statusWiseHistory.forEach((key, value) {
      final safeKey = key.toString();
      if (value is List) {
        parsedData[safeKey] = value
            .map((item) => LateEarlyRequest.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    });
  }
 setState(() {
    historyData = parsedData;
  });
}
 Future<void> fetchLateInHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/request?tab=history');

    if (empId.isEmpty || orgId.isEmpty || locationId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '⚠️ Missing employee details. Please log in again.';
      });
      return;
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'empid': empId,
          'orgid': orgId,
          'locationid': locationId,
        },
      );

      

      if (response.statusCode == 200) {
     final data = jsonDecode(response.body);

  if (data["status"] == 'success') {
    parseHistoryData(data);
 } else {
    setState(() {
      _error = data['message'] ?? 'No data available';
    });
  }
}
 else {
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

Future<void> cancelLateEarlyRequest(int id, int index) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/cancel_early_late_request');

    print('🔹 Cancel Request URL: $url');
    print('🔹 Request Headers: {empid: $empId, orgid: $orgId, locationid: $locationId}');
    print('🔹 Request Body: ${jsonEncode({'id': id})}');


    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // ✅ Remove locally
        setState(() {
          historyData['Pending']?.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record canceled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Refresh latest data
        fetchLateInHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to cancel request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server error: ${response.statusCode}'),
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
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : '';
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parsedTime = DateFormat("HH:mm").parse(time);
      return DateFormat("h:mm a").format(parsedTime);
    } catch (_) {
      return time;
    }
  }

  Widget _buildList(String tab) {
    List<LateEarlyRequest> records = historyData[tab] ?? [];

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
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Posting Type: ${request.posting_type == 'LI' ? 'Late In' : 'Early Out'}',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87, 
        fontWeight: FontWeight.normal, 
      ),
    ),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: request.type == 'PERSONAL_WORK'
            ? Colors.blue.shade100
            : Colors.green.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        request.type == 'PERSONAL_WORK'
            ? 'Personal Work'
            : 'Official Work',
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold),
      ),
    ),
  ],
),



                Text('Date: ${request.post_date}'),
                Text('Time: ${_formatTime(request.le_time)}'),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            
                          ),
                          onPressed: () async {
                            

                            await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => LateEarlyRequestApp(
      existingData: request.toJson(),
     
    ),
  ),
);
fetchLateInHistory();
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
            fontSize: 20,
          ),
        ),
        content: const Text("Are you sure you want to cancel the record?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog only
            },
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF346CB0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context); // close popup first
              
              if (request.id != null) {
                await cancelLateEarlyRequest(request.id!, index);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Missing record ID'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.white),
            ),
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
            'Late In / Early Out History',
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
            Container(height: 130, color: const Color(0xFF346CB0)),
            Column(
              children: [
                const SizedBox(height: 5),
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
                                child: GestureDetector(
                                  onTap: () => _selectDate(true),
                                  child: _buildDateField(_fromDate, 'From'),
                                ),
                              ),const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child: _buildDateField(_toDate, 'To'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 45,child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF346CB0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: fetchLateInHistory,
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                        builder: (context) => const LateEarlyRequestApp()),
                  );
                  fetchLateInHistory();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Late In/Early Out",
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.black87, size: 18),
          const SizedBox(width: 8),
          Text(date != null ? _formatDate(date) : hint,
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}