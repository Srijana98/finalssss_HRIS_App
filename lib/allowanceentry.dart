
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'allowancehistory.dart';


class AllowanceEntryPage extends StatefulWidget {
  const AllowanceEntryPage({super.key});

  @override
  State<AllowanceEntryPage> createState() => _AllowanceEntryPageState();
}

class _AllowanceEntryPageState extends State<AllowanceEntryPage> {
  final TextEditingController _allowanceAmountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _allowanceType;
  String? _effectiveYear;
  String? _effectiveMonth;

  List<Map<String, dynamic>> _allowanceTypes = [];
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _months = [];

  bool _isLoading = true;

  final Color _customBlue = const Color(0xFF346CB0);

  @override
  void initState() {
    super.initState();
    _fetchAllowanceDefaults();
  }



  Future<void> _fetchAllowanceDefaults() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    print("employee_id: $empId");
    print("org_id: $orgId");
    print("location_id: $locationId");
   

    final url = Uri.parse('$baseUrl/api/v1/allowance_default_load');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'empid': empId,
        'orgid': orgId,
        'locationid': locationId,
      },
    );

    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
        _allowanceTypes = (data['allowance_types'] as List).map((item) {
            return {
              'inde_id': item['id'],  
              'inde_type': item['inde_type'],
              'inde_name': item['inde_name'],
            };
          }).toList();
          _years = List<Map<String, dynamic>>.from(data['years'] ?? []);
          _months = List<Map<String, dynamic>>.from(data['months'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Failed to load data');
      }
    } else {
      setState(() => _isLoading = false);
      _showErrorMessage('Server error: ${response.statusCode}');
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showErrorMessage('Error: $e');
    print("Error fetching allowance defaults: $e");
  }
}

Future<void> _submitAllowanceRequest() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';
    final locationId = prefs.getString('location_id') ?? '';

    
    final selectedAllowance = _allowanceTypes.firstWhere(
      (e) => e['inde_name'].toString() == _allowanceType,
      orElse: () => {},
    );
    final indeId = selectedAllowance['inde_id']?.toString() ?? '';

    final url = Uri.parse('$baseUrl/api/v1/allowanceRequest');

   
    print("=== REQUEST HEADERS ===");
    print("empid: $empId");
    print("orgid: $orgId");
    print("locationid: $locationId");

  
    final requestBody = {
      'inde_type': _allowanceType,
      'inde_id': indeId,
      'eff_year': _effectiveYear,
      'eff_month': _effectiveMonth,
      'amount': _allowanceAmountController.text,
      'remarks': _remarksController.text,
    };
    print("=== REQUEST BODY ===");
    print(jsonEncode(requestBody));

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

 
    print("=== RESPONSE STATUS ===");
    print(response.statusCode);
    print("=== RESPONSE BODY ===");
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // if (data['status'] == 'success') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Allowance request submitted successfully'), backgroundColor: Colors.green),
      //   );
      //   Navigator.pop(context);
      // } 

      if (data['status'] == 'success') {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allowance request submitted successfully'), backgroundColor: Colors.green),
         );
  
      
        Navigator.pushReplacement(
          context,
       MaterialPageRoute(builder: (context) =>  AllowanceHistoryPage()),
        );
        }
      
      else {
        _showErrorMessage(data['message'] ?? 'Submission failed');
      }
    } else {
      _showErrorMessage('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print("=== ERROR ===");
    print(e);
    _showErrorMessage('Error: $e');
  }
}


  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration inputUnderlineDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
    );
  }

  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2)),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: inputUnderlineDecoration(),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: inputUnderlineDecoration(),
      keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _customBlue,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Allowance Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: _customBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildRow(
                      'Allowance Type:',
                      _buildDropdownField(
                        items: _allowanceTypes.map((e) => e['inde_name'].toString()).toList(),
                        value: _allowanceType,
                        onChanged: (val) => setState(() => _allowanceType = val),
                      ),
                    ),
                    _buildRow(
                      'Effective Year:',
                      _buildDropdownField(
                        items: _years.map((e) => e['year'].toString()).toList(),
                        value: _effectiveYear,
                        onChanged: (val) => setState(() => _effectiveYear = val),
                      ),
                    ),
                    _buildRow(
                      'Effective Month:',
                      _buildDropdownField(
                        items: _months.map((e) => e['namenp'].toString()).toList(),
                        value: _effectiveMonth,
                        onChanged: (val) => setState(() => _effectiveMonth = val),
                      ),
                    ),
                    _buildRow('Allowance Amount:', _buildTextField(_allowanceAmountController)),
                    _buildRow('Remarks:', _buildTextField(_remarksController, maxLines: 4)),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                 
                       onPressed: () {
             if (_allowanceType == null || _effectiveYear == null || 
            _effectiveMonth == null || _allowanceAmountController.text.isEmpty) {
             _showErrorMessage('Please fill all required fields');
               return;
              }
              _submitAllowanceRequest();
                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _customBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _allowanceAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}


