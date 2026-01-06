
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
      print("==========================");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _apiData = data;
          if (data['status'] == 'success' && data['data'] != null) {
            final statusWiseHistory = data['data']['statusWiseHistory'] ?? {};
            _pendingLeaves = statusWiseHistory['Pending'] ?? [];
           
            
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
      print("===================");
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
Widget _buildLeaveCard(Map<String, dynamic> leave, String status) {
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
            final int index = entry.key;
            final dynamic substitute = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (substitutes.length > 1) ...[
                  Text(
                    'Entry ${index + 1}:',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF346CB0),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                /// Duty Date
                Text(
                  'Duty Date: ${substitute['substitute_datebs'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 4),

                /// Attendance
                const Text(
                  'Attendance: No Attendance Record',
                  style: TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 4),

                /// Remarks
                Text(
                  'Remarks: ${substitute['substitute_remarks']?.isNotEmpty == true ? substitute['substitute_remarks'] : 'No remarks'}',
                  style: const TextStyle(fontSize: 14),
                ),

                if (index < substitutes.length - 1) ...[
                 
                ],
              ],
            );
          }).toList(),


          /// General Remarks (only once)
          Text(
            'General Remarks: ${leave['remarks']?.isNotEmpty == true ? leave['remarks'] : 'No remarks'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          /// Request Date (only once)
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
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Update', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubstituteLeavePage(),
                          ),
                        );
                        _fetchSubstituteLeaveData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, size: 14),
                      label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {},
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
                                      setState(() {});
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
      // Pending
      _pendingLeaves.isEmpty
          ? const Center(child: Text("No Pending Records"))
          : ListView.builder(
              itemCount: _pendingLeaves.length,
              itemBuilder: (context, index) {
                return _buildLeaveCard(
                  _pendingLeaves[index],
                  'Pending',
                );
              },
            ),

      // Review
      const Center(child: Text("No Review Records")),

      // Approved
      const Center(child: Text("No Approved Records")),

      // Reject
      const Center(child: Text("No Rejected Records")),
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