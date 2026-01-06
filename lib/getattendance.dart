
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetAttendancePage extends StatefulWidget {
  final String token;
  const GetAttendancePage({super.key, required this.token});

  @override
  State<GetAttendancePage> createState() => _GetAttendancePageState();
}

class _GetAttendancePageState extends State<GetAttendancePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> attendanceData = [];
  bool isLoading = true;

  DateTime? fromDate;
  DateTime? toDate;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList('client_attendance') ?? [];
    setState(() {
      attendanceData = records
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList()
          .reversed
          .toList();
      isLoading = false;
    });
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('yyyy-MM-dd').format(date) : '';
  }

  Future<void> _selectDate(bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate ?? DateTime.now() : toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
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
          Text(date != null ? _formatDate(date) : hint, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Client ID', item['client_id']?.toString() ?? '--'),
            _infoRow('Date', item['att_datead'] ?? '--/--/----'),
            _infoRow('Time', item['att_time'] ?? '--:--:--'),
            _infoRow('Client', item['client_name'] ?? 'Unknown Client'),
            _infoRow('Type', item['attendance_type'] ?? 'UNKNOWN'),
            _infoRow('Latitude', item['gps_latitude']?.toString() ?? '--'),
            _infoRow('Longitude', item['gps_longitude']?.toString() ?? '--'),
            if (item['remarks']?.isNotEmpty ?? false)
              _infoRow('Remarks', item['remarks']),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredData(int tabIndex) {
    final filtered = attendanceData.where((record) {
  
    
      // Filter by date range
      final recordDate = DateTime.tryParse(record['att_datead'] ?? '') ?? DateTime(2000);
      if (fromDate != null && recordDate.isBefore(fromDate!)) return false;
      if (toDate != null && recordDate.isAfter(toDate!)) return false;

      return true;
      }).toList();
     return filtered;
     }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF346CB0),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Client Check-In History",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                                  child: _buildDateField(fromDate, 'From'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(false),
                                  child: _buildDateField(toDate, 'To'),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {});
                              },
                              child: const Text(
                                'Filter',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: List.generate(4, (tabIndex) {
                            final filteredData = _getFilteredData(tabIndex);
                            return RefreshIndicator(
                              onRefresh: _loadAttendanceRecords,
                              child: filteredData.isEmpty
                                  ? const Center(child: Text("No client check in history found."))
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(top: 10),
                                      itemCount: filteredData.length,
                                      itemBuilder: (context, index) {
                                        return _buildAttendanceCard(filteredData[index]);
                                      },
                                    ),
                            );
                          }),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
