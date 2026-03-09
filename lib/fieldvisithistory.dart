import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fieldvisitentry.dart';
import 'dashboardpage.dart';
import 'config.dart';

class FieldVisitRequest {
  final int? id;
  final String travelType;
  final String fromDate;
  final String toDate;
  final String fieldDate;
  final String visitPlace;
  final String travelVehicle;
  final String purpose;
  final String requestDate;

  FieldVisitRequest({
    this.id,
    required this.travelType,
    required this.fromDate,
    required this.toDate,
    required this.fieldDate,
    required this.visitPlace,
    required this.travelVehicle,
    required this.purpose,
    required this.requestDate,
  });

  

  factory FieldVisitRequest.fromJson(Map<String, dynamic> json) {
  final fromAd = json['from_datead'] ?? json['from_date'] ?? '';
  final toAd = json['to_datead'] ?? json['to_date'] ?? '';

  return FieldVisitRequest(
    id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
    travelType: json['travel_type'] ?? '',
    fromDate: fromAd,
    toDate: toAd,
    fieldDate: '$fromAd - $toAd',
    visitPlace: json['visitplace'] ?? '',
    travelVehicle: json['mode_of_transportation']?.toString() ?? '',
    purpose: json['purpose'] ?? '',
    requestDate: '${json['postdatebs'] ?? ''} - ${json['posttime'] ?? ''}',
  );
}

  Map<String, dynamic> toJson() {
    final map = {
      'travel_type': travelType,
      'from_date': fromDate,
      'to_date': toDate,
      'visitplace': visitPlace,
      'mode_of_transportation': travelVehicle,
      'purpose': purpose,
      'remarks': '',
      'hotel_booking_required': 'N',
      'advance_for_travel': 'N',
      'advance_amount': 0,
      'budget': '',
      'summarized_remarks': [],
    };
    if (id != null) map['id'] = id!;
    return map;
  }
}

class FieldVisitHistoryPage extends StatefulWidget {
  const FieldVisitHistoryPage({super.key});

  @override
  State<FieldVisitHistoryPage> createState() => _FieldVisitHistoryPageState();
}

class _FieldVisitHistoryPageState extends State<FieldVisitHistoryPage> {
  final List<String> tabs = ['Pending', 'Approved', 'Review', 'Cancel'];
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = true;
  Map<String, List<FieldVisitRequest>> historyData = {
    'Pending': [],
    'Approved': [],
    'Review': [],
    'Cancel': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchFieldVisitData();
  }

  // Fetch all history
  Future<void> _fetchFieldVisitData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '1';
    final orgId = prefs.getString('org_id') ?? '1';
    final locationId = prefs.getString('location_id') ?? '1';
    final token = prefs.getString('token') ?? '';

    final endDate = _toDate ?? DateTime.now();
    final startDate = _fromDate ?? DateTime(endDate.year, endDate.month - 6, 1);

    final uri = Uri.parse('$baseUrl/api/v1/get_field_visit_data');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'empid': empId,
          'orgid': orgId,
          'locationid': locationId,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final statusWise = jsonResponse['data']?['statusWiseHistory'] ?? {};

        final Map<String, List<FieldVisitRequest>> parsed = {
          'Pending': [], 'Approved': [], 'Review': [], 'Cancel': [],
        };

        statusWise.forEach((key, value) {
          if (value is List) {
            parsed[key.toString()] = value
                .map((e) => FieldVisitRequest.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        });

        setState(() => historyData = parsed);
      } else {
        _showSnack("Failed to load data");
      }
    } catch (e) {
      _showSnack("Network error");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<Map<String, dynamic>?> _fetchFieldVisitById(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final empId = prefs.getString('employee_id') ?? '1';
  final orgId = prefs.getString('org_id') ?? '1';
  final locationId = prefs.getString('location_id') ?? '1';
  final token = prefs.getString('token') ?? '';

  final url = Uri.parse('$baseUrl/api/v1/get_field_visit_data_by_id');

  try {
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
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success' && jsonResponse['data']?['record'] != null) {
        final record = Map<String, dynamic>.from(jsonResponse['data']['record']);

       
        record['from_date'] = record['from_datead'];
        record['to_date'] = record['to_datead'];
        record['mode_of_transportation'] = record['travel_vehicle'] ?? record['mode_of_transportation'];
        record['budget'] = record['budget_head_id']?.toString();
        record['summarized_remarks'] = record['summarizedRemarks'] ?? [];
     

        return record;
      }
    }
    if (mounted) _showSnack('Failed to load record');
  } catch (e) {
    if (mounted) _showSnack('Error: $e');
  }
  return null;
}
  Future<void> cancelFieldVisitRequest(int id, int index) async {
  final prefs = await SharedPreferences.getInstance();
  final empId = prefs.getString('employee_id') ?? '1';
  final orgId = prefs.getString('org_id') ?? '1';
  final locationId = prefs.getString('location_id') ?? '1';
  final token = prefs.getString('token') ?? '';

  final url = Uri.parse('$baseUrl/api/v1/cancel_field_visit_request');

  try {
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
        setState(() {
          historyData['Pending']?.removeAt(index);
        });
        _showSnack('Record canceled successfully', success: true);
        _fetchFieldVisitData(); // Refresh list
      } else {
        _showSnack(data['message'] ?? 'Failed to cancel');
      }
    } else {
      _showSnack('Server error');
    }
  } catch (e) {
    _showSnack('Error: $e');
  }
}
 void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
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

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCard(FieldVisitRequest request, {bool showActions = false, required int index}) {
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
            buildInfoRow('Travel Type', request.travelType == 'N' ? 'National' : 'International'),
            buildInfoRow('Field Date', request.fieldDate),
            buildInfoRow('Visit Place', request.visitPlace),
            buildInfoRow('Travel Vehicle', request.travelVehicle),
            buildInfoRow('Purpose', request.purpose.isNotEmpty ? request.purpose : 'No purpose'),
            buildInfoRow('Request Date', request.requestDate),

            if (showActions)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Update Button
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                     

                   onPressed: () async {
                  if (request.id == null) return _showSnack('Invalid ID');

                 final fullData = await _fetchFieldVisitById(request.id!);
                 if (fullData != null && mounted) {
                 final saved = await Navigator.push(
                 context,
                 MaterialPageRoute(
                 builder: (_) => FieldVisitEntryPage(existingData: fullData),
                 ),
                );

    // Only refresh if saved
                       if (saved == true) {
                      _fetchFieldVisitData();
                      }
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
        builder: (dialogContext) => AlertDialog(
          title: const Text("HRMS says,", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: const Text("Are you sure you want to cancel the record?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF346CB0)),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (request.id != null) {
                  await cancelFieldVisitRequest(request.id!, index);
                }
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
  Widget _buildList(String tab) {
    final records = historyData[tab] ?? [];

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (records.isEmpty) return const Center(child: Text('No records found', style: TextStyle(color: Colors.grey)));

      return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
      return _buildCard(records[index], showActions: tab == 'Pending', index: index);
      },
    );
  }

    Widget _buildDateField(DateTime? date, String hint) {
    return GestureDetector(
      onTap: () => _selectDate(hint == 'From'),
      child: Container(
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
            Text(date != null ? _formatDate(date) : hint, style: const TextStyle(fontSize: 14)),
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
          title: const Text("Field Visit History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage())),
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
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDateField(_fromDate, 'From')),
                              const SizedBox(width: 10),
                              Expanded(child: _buildDateField(_toDate, 'To')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF346CB0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _fetchFieldVisitData,
                              child: const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
            // Floating Add Button
            Positioned(
              bottom: 20,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const FieldVisitEntryPage()));
                  _fetchFieldVisitData();
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Field Visit", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF346CB0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}