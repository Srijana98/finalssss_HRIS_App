// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'advancesalaryentry.dart';
// import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'config.dart'; 


// class AdvanceSalaryRequest {
//   final String advace_amount;
//   final String takendate;
//   final String deduct_type;
//   final String deduct_year;
//   final String deduct_month;
//   final String reason;

//   AdvanceSalaryRequest({
//     required this.advace_amount,
//     required this.takendate,
//     required this.deduct_type,
//     required this.deduct_year,
//     required this.deduct_month,
//     required this.reason,
   
//   });

//   factory AdvanceSalaryRequest.fromJson(Map<String, dynamic> json) {
//     return AdvanceSalaryRequest(
//       advace_amount: json['advace_amount'] ?? '',
//       takendate: json['takendate'] ?? json['takendate_en'] ?? json['takendate_np'] ?? '',
//       deduct_type: json['deduct_type'] ?? '',
//       deduct_year: json['deduct_year'] ?? '',
//       deduct_month: json['deduct_month'] ?? '',
//       reason: json['reason'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'advace_amount': advace_amount,
//       'takendate': takendate,
//       'deduct_type': deduct_type,
//       'deduct_year': deduct_year,
//       'deduct_month': deduct_month,
//       'reason': reason,
//     };
//   }
// }



// class AdvanceSalaryHistoryPage extends StatefulWidget {

//   final Map<String, dynamic>? AdsalaryData;

//   const AdvanceSalaryHistoryPage({super.key, this.AdsalaryData});
//   @override
//   State<AdvanceSalaryHistoryPage> createState() => _AdvanceSalaryHistoryPageState();
// }

// class _AdvanceSalaryHistoryPageState extends State<AdvanceSalaryHistoryPage> {
//   final List<String> tabs = [ 'Pending', 'Review', 'Approved', 'Reject'];
//   DateTime? _fromDate;
//   DateTime? _toDate;

//   bool _isLoading = false;
//   String? _error;


// Map<String, List<AdvanceSalaryRequest>> historyData = {
//     'Pending': [],
//     'Review': [],
//     'Approved': [],
//     'Reject': [],
//   };


//   // @override
//   void initState() {
//     super.initState();
//     if (widget.AdsalaryData != null) {
//       parseHistoryData(widget.AdsalaryData!);
//     } else {
//       fetchAdvanceSalaryHistory();
//     }
//   }



  

// void parseHistoryData(Map<String, dynamic> data) {
//   final statusWiseHistory = data['data']?['statusWiseHistory'] ?? {};

//   Map<String, List<AdvanceSalaryRequest>> parsedData = {
//     'Pending': [],
//     'Review': [],
//     'Approved': [],
//     'Reject': [],
//   };

//   if (statusWiseHistory is Map) {
//     statusWiseHistory.forEach((key, value) {
//       // Ensure key is string and value is list
//       final safeKey = key.toString();
//       if (value is List) {
//         parsedData[safeKey] = value
//             .map((item) => AdvanceSalaryRequest.fromJson(item as Map<String, dynamic>))
//             .toList();
//       }
//     });
//   }

//   setState(() {
//     historyData = parsedData;
//   });
// }



//   Future<void> fetchAdvanceSalaryHistory() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     final prefs = await SharedPreferences.getInstance();
//     final empId = prefs.getString('employee_id') ?? '';
//     final orgId = prefs.getString('org_id') ?? '';
//     final locationId = prefs.getString('location_id') ?? '';
//     final token = prefs.getString('token') ?? '';

//     final url = Uri.parse('$baseUrl/api/v1/advance_salary_get');

//     if (empId.isEmpty || orgId.isEmpty || locationId.isEmpty) {
//       setState(() {
//         _isLoading = false;
//         _error = '⚠️ Missing employee details. Please log in again.';
//       });
//       return;
//     }

//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'empid': empId,
//           'orgid': orgId,
//           'locationid': locationId,
//         },
//       );

      

//   if (response.statusCode == 200) {
//   final data = jsonDecode(response.body);

//   if (data["status"] == 'success') {
//     parseHistoryData(data);

//     // ✅ Merge local saved records
//     final prefs = await SharedPreferences.getInstance();
//     List<String> savedRequests = prefs.getStringList('advance_salary_local') ?? [];
//     for (var jsonStr in savedRequests) {
//       final obj = AdvanceSalaryRequest.fromJson(jsonDecode(jsonStr));
//       historyData['Pending']?.add(obj); // Add to Pending by default
      
//     }

//   } else {
//     setState(() {
//       _error = data['message'] ?? 'No data available';
//     });
//   }
// }

//       else {
//         setState(() {
//           _error = 'Server error: ${response.statusCode}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Error: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }


// Future<void> _selectDate(bool isFrom) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isFrom) {
//           _fromDate = picked;
//         } else {
//           _toDate = picked;
//         }
//       });
//     }
//   }

//   String _formatDate(DateTime? date) {
//     return date != null ? DateFormat('yyyy-MM-dd').format(date) : '';
//   }
//   Widget _buildList(String tab) {
//   List<AdvanceSalaryRequest> records = historyData[tab] ?? [];

//   if (_isLoading) return const Center(child: CircularProgressIndicator());
//   if (_error != null) {
//     return Center(
//         child: Text(_error!, style: const TextStyle(color: Colors.red)));
//   }
//   if (records.isEmpty) {
//     return Center(
//         child: Text('No $tab records',
//             style: const TextStyle(color: Colors.grey)));
//   }

//   return ListView.builder(
//     itemCount: records.length,
//     itemBuilder: (context, index) {
//       final request = records[index];

//       return Card(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         color: Colors.white,
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: const BorderSide(color: Color(0xFF346CB0)),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Amount + Deduct Type row
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Amount: ${request.advace_amount}',
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade100,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       request.deduct_type,
//                       style: const TextStyle(
//                           fontSize: 13, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text('Taken Date: ${request.takendate}'),
//               Text('Deduct Year/Month: ${request.deduct_year}/${request.deduct_month}'),
//               Text('Reason: ${request.reason.isNotEmpty ? request.reason : 'No reason'}'),
              
//               if (tab == 'Pending')
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     SizedBox(
//                       height: 30,
//                       child: OutlinedButton.icon(
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () async {
//                           // Navigate to AdvanceSalaryEntryPage with existing data
//                           await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => AdvanceSalaryEntryPage(
//                                 existingData: request.toJson(),
//                               ),
//                             ),
//                           );
//                           fetchAdvanceSalaryHistory(); // Refresh list
//                         },
//                         icon: const Icon(Icons.edit, size: 14),
//                         label: const Text('Update', style: TextStyle(fontSize: 12)),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     SizedBox(
//                       height: 30,
//                       child: OutlinedButton.icon(
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(horizontal: 8),
//                           foregroundColor: Colors.red,
//                           side: const BorderSide(color: Colors.red),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: const Text(
//                                   "HRMS says,",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                     fontSize: 20,
//                                   ),
//                                 ),
//                                 content: const Text(
//                                     "Are you sure you want to cancel the record?"),
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12)),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                     },
//                                     child: const Text(
//                                       "Cancel",
//                                       style: TextStyle(color: Colors.grey),
//                                     ),
//                                   ),
//                                   ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color(0xFF346CB0),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                     ),
//                                     onPressed: () {
//                                       Navigator.pop(context);
//                                       setState(() {
//                                         historyData['Pending']?.removeAt(index);
//                                       });
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                               'Record canceled successfully'),
//                                           backgroundColor: Colors.red,
//                                         ),
//                                       );
//                                     },
//                                     child: const Text(
//                                       "OK",
//                                       style: TextStyle(color: Colors.white),
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                         icon: const Icon(Icons.delete, size: 14),
//                         label:
//                             const Text('Cancel', style: TextStyle(fontSize: 12)),
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }


//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: tabs.length,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: const Color(0xFF346CB0),
//           elevation: 0,
//           title: const Text(
//             "Advance Salary History",
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Stack(
//           children: [
//             Container(
//               height: 130,
//               color: const Color(0xFF346CB0),
//             ),
//             Column(
//               children: [
//                 const SizedBox(height: 5),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Material(
//                     elevation: 6,
//                     borderRadius: BorderRadius.circular(16),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () => _selectDate(true),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Colors.grey.shade300),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.calendar_today, color: Color(0xFF346CB0)),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           _fromDate != null ? _formatDate(_fromDate) : 'From',
//                                           style: const TextStyle(fontSize: 16),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () => _selectDate(false),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Colors.grey.shade300),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         const Icon(Icons.calendar_today, color: Color(0xFF346CB0)),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           _toDate != null ? _formatDate(_toDate) : 'To',
//                                           style: const TextStyle(fontSize: 16),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           SizedBox(
//                             width: double.infinity,
//                             height: 45,
//                             child: ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF346CB0),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               onPressed: () {
//                                 // Add filter logic if needed
//                               },
//                               child: const Text(
//                                 'Filter',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TabBar(
//                   isScrollable: true,
//                   indicatorColor: const Color(0xFF346CB0),
//                   labelColor: const Color(0xFF346CB0),
//                   unselectedLabelColor: Colors.grey,
//                   labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//                   tabs: tabs.map((tab) => Tab(text: tab)).toList(),
//                 ),
//                 Expanded(
//                   child: TabBarView(
//                     children: tabs.map((tab) {
//                       return Center(
//                         child: Text(
//                           'No $tab records',
//                           style: const TextStyle(color: Colors.grey),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ],
//             ),
//             Positioned(
//               bottom: 20,
//               right: 16,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => AdvanceSalaryEntryPage()),
//                   );
//                 },
//                 icon: const Icon(Icons.add, color: Colors.white),
//                 label: const Text("Request Advance Salary", style: TextStyle(color: Colors.white)),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF346CB0),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(24),
//                   ),
//                   elevation: 4,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'advancesalaryentry.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class AdvanceSalaryHistoryPage extends StatefulWidget {
  @override
  State<AdvanceSalaryHistoryPage> createState() => _AdvanceSalaryHistoryPageState();
}

class _AdvanceSalaryHistoryPageState extends State<AdvanceSalaryHistoryPage> {
  final List<String> tabs = [ 'Pending', 'Review', 'Approved', 'Reject'];
  DateTime? _fromDate;
  DateTime? _toDate;

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
                  child: TabBarView(
                    children: tabs.map((tab) {
                      return Center(
                        child: Text(
                          'No $tab records',
                          style: const TextStyle(color: Colors.grey),
                        ),
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