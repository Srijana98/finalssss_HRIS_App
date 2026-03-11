
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'dashboardpage.dart';
import 'substituteleaveentry.dart';

class SubstituteHistoryPage extends StatefulWidget {
  @override
  State<SubstituteHistoryPage> createState() => _SubstituteHistoryPageState();
}

class _SubstituteHistoryPageState extends State<SubstituteHistoryPage> {
  final List<String> tabs = ['Pending', 'Review', 'Approved', 'Reject'];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;
  Map<String, dynamic>? _apiData;
  

  List<dynamic> _pendingLeaves = [];
  List<dynamic> _reviewLeaves = [];
  List<dynamic> _approvedLeaves = [];
  List<dynamic> _rejectLeaves = [];
  
  String _empId = '';
  String _orgId = '';
  String _locationId = '';
  

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetch();
  }

  Future<void> _loadUserDataAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _empId = prefs.getString('employee_id') ?? '';
    _orgId = prefs.getString('org_id') ?? '';
    _locationId = prefs.getString('location_id') ?? '';

    print("====== DEBUG SUBSTITUTE HISTORY ======");
    print("employee_id: $_empId");
    print("org_id: $_orgId");
    print("location_id: $_locationId");
   

    if (_empId.isNotEmpty && _orgId.isNotEmpty && _locationId.isNotEmpty) {
      _fetchSubstituteLeaveData();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found. Please login again.')),
      );
    }
  }

  
Future<void> _fetchSubstituteLeaveData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/deposit_substitute_leave'),
      headers: {
        'empid': _empId,
        'orgid': _orgId,
        'locationid': _locationId,
        'date_type': 'EN',
      },
    );

    print("====== API RESPONSE ======");
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _apiData = data;
        if (data['status'] == 'success' && data['data'] != null) {
          final statusWiseHistory = data['data']['statusWiseHistory'] ?? {};
          _pendingLeaves = statusWiseHistory['Pending'] ?? [];
          _reviewLeaves = statusWiseHistory['Review'] ?? [];
          _approvedLeaves = statusWiseHistory['Approved'] ?? [];
          _rejectLeaves = statusWiseHistory['Reject'] ?? []; 
          
          print("Pending: ${_pendingLeaves.length}");
          print("Review: ${_reviewLeaves.length}");
          print("Approved: ${_approvedLeaves.length}");
          print("Reject: ${_rejectLeaves.length}"); 
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${response.statusCode}')),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    print("====== ERROR ======");
    print("$e");
  }
}


Future<void> cancelSubstituteRequest(String id, int index) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/substitue_leave_cancel_record');

    final requestBody = {
      "id": int.parse(id),
    };

    print('🔹 Cancel Substitute URL: $url');
    print('🔹 Headers: {empid: $empId, orgid: $orgId, locationid: $locationId}');
    print('🔹 Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
      body: jsonEncode(requestBody),
    );

    print('🔹 Response Code: ${response.statusCode}');
    print('🔹 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _pendingLeaves.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Record canceled successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchSubstituteLeaveData(); 
       } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to cancel request"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (response.statusCode == 422) {
      print('🔴 422 Validation Error');
      final errorData = jsonDecode(response.body);
      print('🔴 Full Error: $errorData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Validation Error: ${errorData['message'] ?? 'Invalid data'}"),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server Error ${response.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('🔴 Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
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

  Widget buildDateField(DateTime? date, String hint) {
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
          Text(
            date != null ? _formatDate(date) : hint,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave, String status, int index) {
    final List<dynamic> substitutes =
        leave['substitutes'] as List<dynamic>? ?? [];

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
            ...substitutes.asMap().entries.map((entry) {
              final int subIndex = entry.key;
              final dynamic substitute = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (substitutes.length > 1) ...[
                    Text(
                      'Entry ${subIndex + 1}:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF346CB0),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  Text(
                    'Duty Date: ${substitute['substitute_datebs'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 4),

             
                  const Text(
                    'Attendance: No Attendance Record',
                    style: TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Remarks: ${substitute['substitute_remarks']?.isNotEmpty == true ? substitute['substitute_remarks'] : 'No remarks'}',
                    style: const TextStyle(fontSize: 14),
                  ),

                  if (subIndex < substitutes.length - 1) ...[
                   
                  ],
                ],
              );
            }).toList(),

            Text(
              'General Remarks: ${leave['remarks']?.isNotEmpty == true ? leave['remarks'] : 'No remarks'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            
            Text(
              'Request Date: ${leave['postdatebs'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (status == 'Pending')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
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
                              builder: (_) => SubstituteLeavePage(
                                existingLeaveData: leave,
                              ),
                            ),
                          );
                          _fetchSubstituteLeaveData();
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Update', style: TextStyle(fontSize: 12)),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
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
    Navigator.pop(context); 
    
    await cancelSubstituteRequest(
      leave['leave_assign_masterid']!.toString(),
      index,
    );
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
                        label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
            "Substitute Leave History",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
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
                                        child: buildDateField(_fromDate, 'From'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _selectDate(false),
                                        child: buildDateField(_toDate, 'To'),
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
                                    onPressed: () {
                                      _fetchSubstituteLeaveData();
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
    children: [
    
      _pendingLeaves.isEmpty
          ? const Center(child: Text("No Pending Records"))
          : ListView.builder(
              itemCount: _pendingLeaves.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(
                  _pendingLeaves[index],
                  'Pending',
                  index,
                );
              },
            ),

      _reviewLeaves.isEmpty
          ? const Center(child: Text("No Review Records"))
          : ListView.builder(
              itemCount: _reviewLeaves.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(
                  _reviewLeaves[index],
                  'Review',
                  index,
                );
              },
            ),

    
      _approvedLeaves.isEmpty
          ? const Center(child: Text("No Approved Records"))
          : ListView.builder(
              itemCount: _approvedLeaves.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(
                  _approvedLeaves[index],
                  'Approved',
                  index,
                );
              },
            ),
      _rejectLeaves.isEmpty
          ? const Center(child: Text("No Rejected Records"))
          : ListView.builder(
              itemCount: _rejectLeaves.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(
                  _rejectLeaves[index],
                  'Reject',
                  index,
                );
              },
            ),
    ],
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
                            builder: (context) => SubstituteLeavePage(),
                          ),
                        );
                        _fetchSubstituteLeaveData();
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Request Substitute Leave Entry",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF346CB0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}







