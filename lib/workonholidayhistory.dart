import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'workonholiday.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';



class WorkOnHolidayHistoryModel {
  final String? id;
  final String? refNo;
  final String? purpose;
  final String? fromDateBs;
  final String? toDateBs;
  final String? fromDateAd;
  final String? toDateAd;
  final String? attachment;
  final String? dateType; // 'NP' or 'EN'
  final String? holidayId;
  

  WorkOnHolidayHistoryModel({
    this.id,
    this.refNo,
    this.purpose,
    this.fromDateBs,
    this.toDateBs,
    this.fromDateAd,
    this.toDateAd,
    this.attachment,
    this.dateType, // add this
    this.holidayId, 
   
  });

  factory WorkOnHolidayHistoryModel.fromJson(Map<String, dynamic> json) {
    return WorkOnHolidayHistoryModel(
     id: json['id']?.toString(), 
      refNo: json['refno'],
      purpose: json['purpose'],
      fromDateBs: json['from_datebs'],
      toDateBs: json['to_datebs'],
      fromDateAd: json['from_datead'],
      toDateAd: json['to_datead'],
      attachment: json['attachment'], 
      dateType: json['date_type'], // add this
      holidayId: json['holiday_id']?.toString(), 
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'refno': refNo,
      'purpose': purpose,
      'from_datebs': fromDateBs,
      'to_datebs': toDateBs,
      'from_datead': fromDateAd,
      'to_datead': toDateAd,
      'attachment': attachment,
      'date_type': dateType, // add this
      'holiday_id': holidayId,
     
      
    };
  }
}

class WorkonHolidayHistoryPage extends StatefulWidget {
  @override
  State<WorkonHolidayHistoryPage> createState() => _WorkonHolidayHistoryPageState();
}

class _WorkonHolidayHistoryPageState extends State<WorkonHolidayHistoryPage> {
  final List<String> tabs = [ 'Pending', 'Approved', 'Review', 'Cancel'];
  DateTime? _fromDate;
  DateTime? _toDate;

  Map<String, List<WorkOnHolidayHistoryModel>> statusWiseHistory = {
  'Pending': [],
  'Approved': [],
  'Review': [],
  'Cancel': [],
};

bool isLoading = true;

@override
  void initState() {
    super.initState();
    debugPrint('🔹 initState called');
    fetchWorkOnHolidayHistory();
  }

Future<void> fetchWorkOnHolidayHistory() async {
  setState(() {
    isLoading = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empid = prefs.getString('employee_id');
    String? orgid = prefs.getString('org_id');
    String? locationid = prefs.getString('location_id');

    if (empid == null || orgid == null || locationid == null) {
      throw Exception("Missing employee information. Please log in again.");
    }

    final url = Uri.parse('$baseUrl/api/v1/work_from_home?entry_type=WORKFROMHOLI');

    final headers = {
      'empid': empid,
      'orgid': orgid,
      'locationid': locationid,
    };

    debugPrint('🔹 Sending GET request...');
    debugPrint('🔹 URL: $url');
    debugPrint('🔹 Headers: $headers');
    
    final response = await http.get(url, headers: headers);
    
    debugPrint('📥 Response Status Code: ${response.statusCode}');
    debugPrint('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        debugPrint('✅ JSON decoded successfully');
        debugPrint('🔍 Full data structure: $data');

        if (data['status'] == 'success') {
          // Check if data exists and has the right structure
          if (data['data'] == null) {
            debugPrint('❌ data["data"] is null!');
            return;
          }

          debugPrint('🔍 data["data"]: ${data['data']}');

          // Check different possible structures
          if (data['data']['statusWiseHistory'] != null) {
            debugPrint('✅ Found statusWiseHistory');
            debugPrint('🧩 Keys: ${data['data']['statusWiseHistory'].keys}');
            
            final Map<String, dynamic> rawHistory = data['data']['statusWiseHistory'];
            final Map<String, List<WorkOnHolidayHistoryModel>> parsedHistory = {};

            rawHistory.forEach((key, value) {
              debugPrint('🔍 Processing key: $key with ${value.length} items');
              
              parsedHistory[key] = List<WorkOnHolidayHistoryModel>.from(
                value.map((item) {
                  debugPrint('🔍 Item: $item');
                  return WorkOnHolidayHistoryModel.fromJson(item);
                }),
              );
            });

            setState(() {
              statusWiseHistory = parsedHistory;
            });
            
            debugPrint('✅ Final statusWiseHistory: ${statusWiseHistory.keys}');
            statusWiseHistory.forEach((key, value) {
              debugPrint('   $key: ${value.length} records');
            });
            
          } else if (data['data'] is List) {
            // If the API returns a flat list instead
            debugPrint('⚠️ API returned a list, not statusWiseHistory object');
            // Handle accordingly
          } else {
            debugPrint('❌ Unexpected data structure!');
            debugPrint('🔍 Available keys in data: ${data['data'].keys}');
          }
          
        } else {
          debugPrint('⚠️ API returned failure: ${data['message']}');
        }
      } catch (e, stackTrace) {
        debugPrint('❌ JSON decode error: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        debugPrint('Response body: ${response.body}');
      }
    } else {
      debugPrint('❌ Request failed with status: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    debugPrint("🔥 Exception in fetchWorkOnHolidayHistory: $e");
    debugPrint("🔥 Stack trace: $stackTrace");
  } finally {
    setState(() {
      isLoading = false;
    });
    debugPrint('🔹 fetchWorkOnHolidayHistory() ended.');
    debugPrint('🔹 isLoading: $isLoading');
  }
}

Future<void> cancelWorkOnHolidayRequest(String id, int index) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    final url = Uri.parse('$baseUrl/api/v1/cancel_employee_record');

    print('🔹 Cancel WFH URL: $url');
    print('🔹 Headers: {empid: $empId, orgid: $orgId, locationid: $locationId}');
    print('🔹 Body: ${jsonEncode({"id": id})}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
      body: jsonEncode({"id": id}),
    );

    print('🔹 Response Code: ${response.statusCode}');
    print('🔹 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        // Remove locally from pending list
        setState(() {
          statusWiseHistory['Pending']?.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Record canceled successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh API data
        fetchWorkOnHolidayHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Failed to cancel request"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server Error ${response.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
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
///Widget buildCardItem(Map<String, dynamic> item, String tab, int index) {
  Widget buildCardItem(WorkOnHolidayHistoryModel item, String tab, int index) {

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
          
          Text(
  'Ref. No: ${item.refNo ?? 'N/A'}',
  style: const TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 4),
Row(
  children: [
    Expanded(child: Text('Purpose: ${item.purpose ?? 'N/A'}')),
    OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // smaller
    minimumSize: const Size(60, 28), // make the button smaller
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () async {
    String pdfUrl = item.attachment!;
    if (!pdfUrl.startsWith('http')) {
      pdfUrl = '$baseUrl/$pdfUrl';
    }
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the file")),
      );
    }
  },
  icon: const Icon(Icons.download, size: 14, color: Color(0xFF346CB0)),
  label: const Text('Attachment',
      style: TextStyle(fontSize: 11, color: Color(0xFF346CB0))), // smaller font
)

  ],
),


Builder(
  builder: (context) {
    String fromDate = item.fromDateBs ?? '';
    String toDate = item.toDateBs ?? '';

    // Try to calculate number of days
    int daysCount = 0;
    try {
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        DateTime start = DateFormat('yyyy/MM/dd').parse(fromDate);
        DateTime end = DateFormat('yyyy/MM/dd').parse(toDate);
        daysCount = end.difference(start).inDays + 1;
      }
    } catch (e) {
      // just ignore parse errors
    }

    return Text(
      daysCount > 0
          ? 'Duration: $daysCount Days ($fromDate - $toDate)'
          : 'Duration: ($fromDate - $toDate)',
      style: const TextStyle(fontSize: 14),
    );
  },
),

          const SizedBox(height: 8),

          // Show buttons only in Pending tab
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
                      // Navigate to update form
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkonHolidayEntryPage(
                            existingData: item.toJson(),
                            // if your WorkFromHomeEntryPage supports editing, pass item
                          ),
                        ),
                      );
                      fetchWorkOnHolidayHistory();
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
                                borderRadius: BorderRadius.circular(12)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
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
                                  await cancelWorkOnHolidayRequest(item.id!, index);

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
          elevation: 0,
          title: const Text(
            "Work On Holiday History",
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
                                // Add filter logic if needed
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
                  unselectedLabelColor: Colors.grey,labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                ),
                

                Expanded(
  child: isLoading
      ? const Center(child: CircularProgressIndicator())
      : TabBarView(
          children: tabs.map((tab) {
            final records = statusWiseHistory[tab] ?? [];
            
            if (records.isEmpty) {
              return Center(
                child: Text(
                  'No $tab records',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: records.length,
              itemBuilder: (context, index) {
                return buildCardItem(records[index], tab, index);
              },
            );
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
                   MaterialPageRoute(builder: (context) => WorkonHolidayEntryPage()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Request Work on Holiday", style: TextStyle(color: Colors.white)),
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


