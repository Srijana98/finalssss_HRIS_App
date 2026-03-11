import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'leaveentry.dart';
import 'dashboardpage.dart';
import 'config.dart';

class LeaveApplicationModel {
  final String id;
  final List<Map<String, dynamic>> leaveCategories;
  final String fromDateBs;
  final String toDateBs;
  final String? fromDateAd;
  final String? toDateAd;
  final String? attachment;
  final String? dateType;
  final String reason;
  final String? substituteEmployeeId;
  final String? halfleaveType;

  LeaveApplicationModel({
    required this.id,
    required this.leaveCategories,
    required this.fromDateBs,
    required this.toDateBs,
    this.fromDateAd,
    this.toDateAd,
    this.attachment,
    this.dateType,
    required this.reason,
    this.substituteEmployeeId,
    this.halfleaveType,
  });

  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> categories = [];
    
    if (json['leave_details'] != null && json['leave_details'] is List) {
      final details = json['leave_details'] as List;
      
      for (var detail in details) {
        categories.add({
          'name': detail['leavecategory'] ?? '',
          'days': detail['leave_count'] ?? '0',
        });
      }
    }

    return LeaveApplicationModel(
      id: json['id']?.toString() ?? '',
      leaveCategories: categories,
      fromDateBs: json['start_datebs'] ?? '',
      toDateBs: json['end_datebs'] ?? '',
      fromDateAd: json['start_datead'],
      toDateAd: json['end_datead'],
      attachment: json['attachment'],
      dateType: json['duration_type'],
      reason: json['reason'] ?? '',
      substituteEmployeeId: json['substitute_employee_id']?.toString(),
      halfleaveType: json['halfleave_type'],
    );
  }

  String get categoryDisplay {
    if (leaveCategories.isEmpty) return 'N/A';
    
    return leaveCategories
        .map((cat) => '${cat['name']}-${cat['days']}')
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leave_categories': leaveCategories,
      'start_datebs': fromDateBs,
      'end_datebs': toDateBs,
      'start_datead': fromDateAd,
      'end_datead': toDateAd,
      'attachment': attachment,
      'date_type': dateType,
      'reason': reason,
      'substitute_employee_id': substituteEmployeeId,
      'halfleave_type': halfleaveType,
    };
  }
}

class LeaveHistoryPage extends StatefulWidget {
  @override
  State<LeaveHistoryPage> createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> {
  final List<String> tabs = ['Pending', 'Review', 'Approved', 'Reject'];

  DateTime? _fromDate;
  DateTime? _toDate;

  String _currentDateType = 'NP';

  Map<String, List<LeaveApplicationModel>> statusWiseHistory = {
    'Pending': [],
    'Review': [],
    'Approved': [],
    'Reject': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🔹 initState called');
    fetchLeaveHistory();
  }

Future<void> fetchLeaveHistory() async {
  if (!mounted) return;
  setState(() => isLoading = true);

  try {
  
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('employee_id');
    String? orgid = prefs.getString('org_id');
    String? locationid = prefs.getString('location_id');
    String? savedDateType = prefs.getString('current_date_type');
    if (savedDateType != null) {
      _currentDateType = savedDateType;
    }

    debugPrint('👤 EMPID: $empid, ORGID: $orgid, LOCID: $locationid');
    debugPrint('📅 Date Type: $_currentDateType');

 
    if (empid == null || orgid == null || locationid == null ) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
      }
      return;
    }

 
    String apiUrl = '$baseUrl/api/v1/leave_applications';
    
    if (_fromDate != null || _toDate != null) {
      List<String> queryParams = [];
      
      if (_fromDate != null) {
        queryParams.add('start_date=${DateFormat('yyyy/MM/dd').format(_fromDate!)}');
      }
      
      if (_toDate != null) {
        queryParams.add('end_date=${DateFormat('yyyy/MM/dd').format(_toDate!)}');
      }
      
      if (queryParams.isNotEmpty) {
        apiUrl += '?${queryParams.join('&')}';
      }
    }

    final url = Uri.parse(apiUrl);
    
    debugPrint('🌐 Request URL: $url');

    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'empid': empid,
        'orgid': orgid,
        'locationid': locationid,
        'date_type': _currentDateType, 
      },
    );
    
    debugPrint('🔹 API call completed.');
    debugPrint('📥 Response Status Code: ${response.statusCode}');
    debugPrint('📄 Response Body: ${response.body}');

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['status'] == 'success') {
        final raw = data['data']?['statusWiseHistory'];
        
        if (raw == null) {
          debugPrint('⚠️ statusWiseHistory is null in response');
          if (mounted) {
            setState(() => isLoading = false);
          }
          return;
        }
        
        final Map<String, List<LeaveApplicationModel>> parsed = {
          'Pending': [],
          'Review': [],
          'Approved': [],
          'Reject': [],
        };

        if (raw is Map<String, dynamic>) {
          debugPrint('🔍 Keys in API response: ${raw.keys.toList()}');
          
          raw.forEach((key, value) {
            debugPrint('🔑 Processing key: $key with ${(value as List?)?.length ?? 0} items');
            
            if (value is List && parsed.containsKey(key)) {
              parsed[key] = value
                  .map<LeaveApplicationModel>((item) => LeaveApplicationModel.fromJson(item))
                  .toList();
                
              
              debugPrint('✅ Added ${parsed[key]!.length} items to $key tab');
            }
          });
          
          parsed.forEach((key, value) {
           debugPrint('📊 $key tab has ${value.length} items');
          });
        }

        if (mounted) {
          setState(() => statusWiseHistory = parsed);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Failed to fetch data")),
          );
        }
      }
    } else if (response.statusCode == 401) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unauthorized. Please login again.")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    }
  } catch (e) {
    debugPrint('❌ Error in fetchLeaveHistory: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  
  Future<void> cancelLeaveRequest(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString('employee_id') ?? '';
      final orgId = prefs.getString('org_id') ?? '';
      final locationId = prefs.getString('location_id') ?? '';

      final url = Uri.parse('$baseUrl/api/v1/leave_cancel');

      final requestBody = {
        "id": id,
        "status_remarks": "self cancel"
      };

      debugPrint('🔹 Cancel Leave URL: $url');
      debugPrint('🔹 Body: ${jsonEncode(requestBody)}');

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

      debugPrint('🔹 Response Code: ${response.statusCode}');
      debugPrint('🔹 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              statusWiseHistory['Pending']?.removeWhere((leave) => leave.id == id);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Leave request cancelled successfully"),
                backgroundColor: Colors.green,
              ),
            );

            fetchLeaveHistory();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? "Failed to cancel request"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Server Error ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    fetchLeaveHistory();
  }

  Widget _buildLeaveCard(LeaveApplicationModel leave, String tab) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF346CB0), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Category: ${leave.categoryDisplay}',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                if (leave.attachment != null && leave.attachment!.trim().isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: const Size(70, 34),
                      side: const BorderSide(color: Color(0xFF346CB0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      String url = leave.attachment!;
                      if (!url.startsWith('http')) url = '$baseUrl/$url';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cannot open file")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download, size: 15, color: Color(0xFF346CB0)),
                    label: const Text('File', style: TextStyle(fontSize: 12, color: Color(0xFF346CB0))),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Leave Date: ${leave.fromDateBs} - ${leave.toDateBs}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Reason: ${leave.reason.isEmpty ? 'N/A' : leave.reason}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),

            if (tab == 'Pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: Color(0xFF346CB0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeaveRequestPage(existingData: leave.toJson()),
                          ),
                        );

                        if (result == true) {
                          fetchLeaveHistory();
                        }
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
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
                                    Navigator.pop(dialogContext);
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
                                    Navigator.pop(dialogContext);
                                    await cancelLeaveRequest(leave.id);
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
          title: const Text(
            "Leave Request History",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
              (r) => false,
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(height: 130, color: const Color(0xFF346CB0)),
            Column(
              children: [
                const SizedBox(height: 10),
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
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fromDate == null
                                              ? 'From'
                                              : DateFormat('yyyy/MM/dd').format(_fromDate!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          _toDate == null
                                              ? 'To'
                                              : DateFormat('yyyy/MM/dd').format(_toDate!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: fetchLeaveHistory,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF346CB0),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Filter',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              if (_fromDate != null || _toDate != null) ...[
                                const SizedBox(width: 8),
                              
                              ],
                            ],
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
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF346CB0)),
                        )
                      : TabBarView(
                          children: tabs.map((tab) {
                            final leaves = statusWiseHistory[tab] ?? [];
                            if (leaves.isEmpty) {
                              return Center(
                                child: Text(
                                  "No $tab requests",
                                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 100),
                              itemCount: leaves.length,
                              itemBuilder: (_, i) => _buildLeaveCard(leaves[i], tab),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),

            Positioned(
              bottom: 20,
              right: 16,
              child: SizedBox(
                height: 42,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LeaveRequestPage()),
                    );

                    if (result == true) {
                      fetchLeaveHistory();
                    }
                  },
                  backgroundColor: const Color(0xFF346CB0),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    "Request Leave",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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






