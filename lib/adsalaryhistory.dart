import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'advancesalaryentry.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart'; 
import 'dart:convert';

class AdvanceSalaryRequest {
  final String id;
  final String advace_amount;
  final String takendate;
  final String deduct_type;
  final String deduct_year;
  final String deduct_month;
  final String reason;
  final String paid_over;
  final List<dynamic> monthly_installments; 

  AdvanceSalaryRequest({
    required this.id,
    required this.advace_amount,
    required this.takendate,
    required this.deduct_type,
    required this.deduct_year,
    required this.deduct_month,
    required this.reason,
    required this.paid_over,
    this.monthly_installments = const [], 
   
  });

  factory AdvanceSalaryRequest.fromJson(Map<String, dynamic> json) {
    return AdvanceSalaryRequest(
      
      id: json['id'].toString(),
      advace_amount: json['advace_amount'] ?? '',
      takendate: json['taken_datebs'] ?? '',
      deduct_type: json['deduct_type'] ?? '',
      deduct_year: json['deduct_year'] ?? '',
      deduct_month: json['deduct_month'] ?? '',
      reason: json['reason'] ?? '',
      paid_over: json['paid_over'] ?? '0',
      monthly_installments: json['monthly_installments'] ?? [],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advace_amount': advace_amount,
      'takendate': takendate,
      'deduct_type': deduct_type,
      'deduct_year': deduct_year,
      'deduct_month': deduct_month,
      'reason': reason,
      'paid_over': paid_over,
      'monthly_installments': monthly_installments,
    };
  }
}



class AdvanceSalaryHistoryPage extends StatefulWidget {

  final Map<String, dynamic>? AdsalaryData;

  const AdvanceSalaryHistoryPage({super.key, this.AdsalaryData});
  @override
  State<AdvanceSalaryHistoryPage> createState() => _AdvanceSalaryHistoryPageState();
}

class _AdvanceSalaryHistoryPageState extends State<AdvanceSalaryHistoryPage> {
  final List<String> tabs = [ 'Pending', 'Review', 'Approved', 'Reject'];
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _error;


Map<String, List<AdvanceSalaryRequest>> historyData = {
    'Pending': [],
    'Review': [],
    'Approved': [],
    'Reject': [],
  };


  
  void initState() {
    super.initState();
    if (widget.AdsalaryData != null) {
      parseHistoryData(widget.AdsalaryData!);
    } else {
      fetchAdvanceSalaryHistory();
    }
  }
  
void parseHistoryData(Map<String, dynamic> data) {
  final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};

  Map<String, List<AdvanceSalaryRequest>> parsedData = {
    'Pending': [],
    'Review': [],
    'Approved': [],
    'Reject': [],
  };

  if (statusWiseHistory is Map) {
    statusWiseHistory.forEach((key, value) {
      final safeKey = key.toString();
      if (value is List) {
        parsedData[safeKey] = value
            .map((item) => AdvanceSalaryRequest.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    });
  }

  setState(() {
    historyData = parsedData;
  });
}



  Future<void> fetchAdvanceSalaryHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
    final token = prefs.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/advance_salary_get');

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


  
Future<void> cancelAdvanceSalary(String id, int index) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    final url = Uri.parse(
      '$baseUrl/api/v1/cancel_salary_advance',
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
     fetchAdvanceSalaryHistory();

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
  List<AdvanceSalaryRequest> records = historyData[tab] ?? [];

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
                    'Advance Amount: ${request.advace_amount}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            
              Text('Deduct Type: ${request.deduct_type}'),
              Text('Deduct Year: ${request.deduct_year}'),
              Text('Deduct Month: ${request.deduct_month}'),



if (request.deduct_type.toUpperCase() == 'MONTHLY' && 
    request.monthly_installments.isNotEmpty) ...[
  const Text(
    'Monthly Installments:',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: Color(0xFF346CB0),
    ),
  ),
  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: request.monthly_installments.map((installment) {
        final monthNames = [
          'BAISAKH', 'JESTHA', 'ASHADH', 'SHRAWAN', 'BHADRA', 'ASHWIN',
          'KARTIK', 'MANGSIR', 'POUSH', 'MAGH', 'FALGUN', 'CHAITRA'
        ];
        int monthIndex = int.tryParse(installment['month'].toString()) ?? 0;
        String monthName = (monthIndex > 0 && monthIndex <= 12) 
            ? monthNames[monthIndex - 1] 
            : installment['month'].toString();
        
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF346CB0).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF346CB0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${monthName.substring(0, 3)}, ${installment['year']}: Rs. ${installment['target_amount']}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF346CB0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  ),
] else if (request.deduct_type.toUpperCase() == 'FIXED') ...[
  const Text(
    'Monthly Installments: 0',
    style: TextStyle(
      fontSize: 13,
      color: Colors.black87,
    ),
  ),
],
          
              Text('Reason: ${request.reason.isNotEmpty ? request.reason : 'No reason'}'),
              
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
                              builder: (_) => AdvanceSalaryEntryPage(
                                existingData: request,
                              ),
                            ),
                          );
                          await fetchAdvanceSalaryHistory();
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
                                content: const Text(
                                    "Are you sure you want to cancel the record?"),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
                                      await cancelAdvanceSalary(request.id, index);
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
            "Advance Salary History",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
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
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFF346CB0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fromDate != null ? _formatDate(_fromDate) : 'From',
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFF346CB0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _toDate != null ? _formatDate(_toDate) : 'To',
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
                              onPressed: () {
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
    children: tabs.map((tab) {
      return _buildList(tab); 
    }).toList(),
  ),
),

              ],
            ),
            Positioned(
              bottom: 20,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdvanceSalaryEntryPage()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Advance Salary", style: TextStyle(color: Colors.white)),
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



