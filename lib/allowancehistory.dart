
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'allowanceentry.dart';
import 'config.dart';


class AllowanceRequest {
  final String refno;
  final String indeType;
  final String indeId;
  final String indeName;
  final String monthName;
  final String effYear;
  final String effMonth;
  final String statusRemarks;
  final String summarizedAmount;
  final String requestDate;
 
  AllowanceRequest({
    required this.refno,
    required this.indeType,
    required this.indeId,
    required this.indeName,
    required this.monthName,
    required this.effYear,
    required this.effMonth,
    required this.statusRemarks,
    required this.summarizedAmount,
    required this.requestDate,
  });

  factory AllowanceRequest.fromJson(Map<String, dynamic> json) {
    return AllowanceRequest(
      refno: json['refno']?.toString() ?? '-',
      indeType: json['inde_type']?.toString() ?? '',
      indeId: json['inde_id']?.toString() ?? '',
      indeName: json['inde_name']?.toString() ?? '-',
      monthName: json['month_name']?.toString() ?? '-',
      effYear: json['eff_year']?.toString() ?? '-',
      effMonth: json['eff_month']?.toString() ?? '-',
      statusRemarks: json['status_remarks']?.toString() ?? '',
      summarizedAmount: json['summarized_amount']?.toString() ?? '',
      requestDate: json['request_date']?.toString() ?? '-',
     
 );
  }
}


class AllowanceHistoryPage extends StatefulWidget {
  final Map<String, dynamic>? allowanceData;

  const AllowanceHistoryPage({super.key, this.allowanceData});

  @override
  State<AllowanceHistoryPage> createState() => _AllowanceHistoryPageState();
}

class _AllowanceHistoryPageState extends State<AllowanceHistoryPage> {
  final List<String> tabs = ['Pending', 'Approved', 'Cancel'];
  
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  String? _error;
  

  Map<String, List<AllowanceRequest>> historyData = {
     'Pending': [],
     'Approved': [],
     'Cancel' : [],
     };
 //final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};
  @override
  void initState() {
    super.initState();
    if (widget.allowanceData != null) {
      parseHistoryData(widget.allowanceData!);
    } else {
      fetchAllowanceHistory();
    }
  }


  void parseHistoryData(Map<String, dynamic> data) {
   final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};
  
    Map<String, List<AllowanceRequest>> parsedData = {
      'Pending': [],
      'Approved': [],
      'Cancel': [],
      
    };

    if (statusWiseHistory is Map) {
      statusWiseHistory.forEach((key, value) {
        final safeKey = key.toString();
        if (value is List && parsedData.containsKey(safeKey)) {
          parsedData[safeKey] = value
              .map((item) =>
                  AllowanceRequest.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      });
    }

    setState(() {
      historyData = parsedData;
     
    });
  }

  Future<void> fetchAllowanceHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';
   

    if (empId.isEmpty || orgId.isEmpty || locationId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '⚠️ Missing employee details. Please log in again.';
      });
      return;
    }

  
    final url = Uri.parse('$baseUrl/api/v1/allowance_get');

    try {
     

      final response = await http.get(
  url,
  headers: {
    'Content-Type': 'application/json',
    'empid': empId,
    'orgid': orgId,
    'locationid': locationId,
  },
);

      debugPrint('Allowance GET URL: $url');
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          parseHistoryData(data);
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


  Future<void> cancelAllowance(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString('employee_id') ?? '';
      final orgId = prefs.getString('org_id') ?? '';
      final locationId = prefs.getString('location_id') ?? '';

      final url = Uri.parse('$baseUrl/api/v1/cancel_allowance');
 
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'empid': empId,
           'orgid': orgId,
           'locationid' :locationId,
        },
        body: jsonEncode({'id': id}),
      );

    final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchAllowanceHistory();
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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy/MM/dd').format(date) : '';
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

 
  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 13, color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildList(String tab) {
   List<AllowanceRequest> records = historyData[tab] ?? [];

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF346CB0)));
    }
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
      padding: const EdgeInsets.only(bottom: 80),
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
        _infoRow('Refno', request.refno),
        _infoRow('Allowance Type', request.indeName,
            valueColor: const Color(0xFF346CB0)),
        _infoRow('Eff. Month', '${request.effYear} / ${request.effMonth}'),
        _infoRow('Allowance Amount', request.summarizedAmount),
        _infoRow('Remarks',
            request.statusRemarks.isNotEmpty ? request.statusRemarks : '-'),
       _infoRow('Request Date', request.requestDate),
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
                        builder: (_) => const AllowanceEntryPage(),
                      ),
                    );
                    fetchAllowanceHistory();
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label:
                      const Text('Update', style: TextStyle(fontSize: 12)),
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
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel",
                                  style: TextStyle(color: Colors.grey)),
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
                                await cancelAllowance(request.indeId);
                              },
                              child: const Text("OK",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.delete, size: 14),
                  label:
                      const Text('Cancel', style: TextStyle(fontSize: 12)),
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
            "Allowance History",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
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
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Color(0xFF346CB0)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fromDate != null
                                              ? _formatDate(_fromDate)
                                              : 'From',
                                          style: const TextStyle(
                                              fontSize: 14),
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
                                      borderRadius:
                                          BorderRadius.circular(8),
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
                                          style: const TextStyle(
                                              fontSize: 14),
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
                              onPressed: () => fetchAllowanceHistory(),
                              child: const Text(
                                'Filter',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white),
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
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.bold),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AllowanceEntryPage()),
                  ).then((_) => fetchAllowanceHistory());
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Allowance",
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