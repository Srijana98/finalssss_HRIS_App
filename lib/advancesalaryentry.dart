
import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config.dart'; 
import 'adsalaryhistory.dart';


class AdvanceSalaryEntryPage extends StatefulWidget {
  final AdvanceSalaryRequest? existingData;

  const AdvanceSalaryEntryPage({super.key, this.existingData});

  @override
  State<AdvanceSalaryEntryPage> createState() => _AdvanceSalaryEntryPageState();
}



class _AdvanceSalaryEntryPageState extends State<AdvanceSalaryEntryPage> {
  final TextEditingController _advanceAmountController = TextEditingController();
  final TextEditingController _takenDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _installmentPeriodController = TextEditingController();

  bool _takenDateIsBS = true;

  double _remainingAmount = 0.0;



  final List<String> _deductTypes = ['Fixed Month', 'Installment Per Month'];
  final List<String> _years = ['2080', '2081', '2082', '2083', '2084', '2085'];
  final List<String> _months = [
    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
  ];

String deductTypeForAPI(String? selectedType) {
  if (selectedType == 'Installment Per Month') return 'MONTHLY';
  if (selectedType == 'Fixed Month') return 'FIXED';
  return selectedType ?? '';
}

@override
void initState() {
  super.initState();
  if (widget.existingData != null) {
    _prefillForm(widget.existingData!);
  }
}

void _prefillForm(AdvanceSalaryRequest data) {
  _advanceAmountController.text = data.advace_amount;
  _takenDateController.text = data.takendate;
  _remarksController.text = data.reason;

  setState(() {
    _selectedDeductType =
        (data.deduct_type.toUpperCase() == 'MONTHLY') ? 'Installment Per Month' : 'Fixed Month';

    if (_years.contains(data.deduct_year)) {
      _selectedStartYear = data.deduct_year;
    }

  
    int monthIndex = int.tryParse(data.deduct_month) ?? 0;
    if (monthIndex > 0 && monthIndex <= _months.length) {
      _selectedStartMonth = _months[monthIndex - 1];
    }
  });

 
  if (_selectedDeductType == 'Installment Per Month') {
    _generateInstallmentSchedule();
  }
}



Future<void> _submitAdvanceSalary() async {
  final prefs = await SharedPreferences.getInstance();

  final empId = prefs.getString('employee_id') ?? '';
  final orgId = prefs.getString('org_id') ?? '';
  final locationId = prefs.getString('location_id') ?? '';

  if (empId.isEmpty || orgId.isEmpty || locationId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User info not found. Please login again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final url = Uri.parse('$baseUrl/api/v1/advance_salary_request');

  // ✅ Use form-data (not JSON)
  final request = http.MultipartRequest('POST', url);
  request.headers.addAll({
    'empid': empId,
    'orgid': orgId,
    'locationid': locationId,
    'date_type': _takenDateIsBS ? 'NP' : 'EN', 

    

  });


  request.fields['advace_amount'] = _advanceAmountController.text;
  request.fields['takendate'] = _takenDateController.text;
  request.fields['deduct_type'] = deductTypeForAPI(_selectedDeductType);
  request.fields['deduct_year'] = _selectedStartYear ?? '';
  request.fields['deduct_month'] =
      (_months.indexOf(_selectedStartMonth ?? '') + 1).toString();
  request.fields['reason'] = _remarksController.text;
  


request.fields['paid_over'] =
    _installmentPeriodController.text.isNotEmpty
        ? _installmentPeriodController.text
        : '0';


if (_selectedDeductType == 'Installment Per Month' && _installmentSchedule.isNotEmpty) {
  final installmentsList = _buildInstallmentListForAPI();
  request.fields['installments'] = jsonEncode(installmentsList);
}


  print('📡 API URL: $url');
  print('📝 Headers: ${request.headers}');
  print('🗂 Fields: ${request.fields}');
  print('🗓 Date Type: ${_takenDateIsBS ? 'NP' : 'EN'}');
 


  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('🔹 Status Code: ${response.statusCode}');
    print('🔹 Body: ${response.body}');

    


 
if (response.statusCode == 200 || response.statusCode == 201) {
  final data = jsonDecode(response.body);

  if (data['status'] == 'success') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Advance salary request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdvanceSalaryHistoryPage()),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed: ${data['message'] ?? 'Unknown error'}'),
        backgroundColor: Colors.red,
      ),
    );
  }
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed: ${response.body}'),
      backgroundColor: Colors.red,
    ),
  );
}

  } catch (e) {
    print('⚠ Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error occurred while submitting request.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}



  String? _selectedDeductType;
  String? _selectedStartYear;
  String? _selectedStartMonth;
 

  List<Map<String, dynamic>> _installmentSchedule = [];


  final Color _customBlue = const Color(0xFF346CB0);

  @override
  void dispose() {
    _advanceAmountController.dispose();
    _takenDateController.dispose();
    _remarksController.dispose();
    _installmentPeriodController.dispose();
    super.dispose();
  }

  


Future<void> _selectDate(BuildContext context) async {
  if (_takenDateIsBS) {
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: NepaliDateTime.now(),
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime(2090),
    );
    if (picked != null) {
      setState(() {
        _takenDateController.text =
            '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      });
    }
  } else {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _takenDateController.text = DateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }
}

List<Map<String, dynamic>> _buildInstallmentListForAPI() {
  return _installmentSchedule.map((item) {
    final parts = item['yearMonth'].split('-');
    final year = int.tryParse(parts[0]) ?? 0;
    final monthName = parts.length > 1 ? parts[1] : '';
    final monthIndex = _months.indexOf(monthName) + 1; 

    final amount = double.tryParse(item['paymentController'].text) ?? 0.0;

    return {
      'year': year,
      'month': monthIndex,
      'target_amount': amount,
    };
  }).toList();
}

void _calculateRemainingAmount() {
  final advanceAmount = double.tryParse(_advanceAmountController.text) ?? 0.0;
  double totalEntered = 0.0;

  for (var item in _installmentSchedule) {
    final val = double.tryParse(item['paymentController'].text) ?? 0.0;
    totalEntered += val;
  }

  setState(() {
    _remainingAmount = (advanceAmount - totalEntered);
    if (_remainingAmount < 0) _remainingAmount = 0; 
  });
}




void _generateInstallmentSchedule() {
  if (_selectedDeductType != 'Installment Per Month' || 
      _selectedStartYear == null || 
      _selectedStartMonth == null || 
      _installmentPeriodController.text.isEmpty ||
      _advanceAmountController.text.isEmpty) {
    setState(() {
      _installmentSchedule.clear();
    });
    return;
  }

  final period = int.tryParse(_installmentPeriodController.text) ?? 0;
  final amount = double.tryParse(_advanceAmountController.text) ?? 0.0;

  if (period <= 0 || amount <= 0) {
    setState(() {
      _installmentSchedule.clear();
    });
    return;
  }

  final startMonthIndex = _months.indexOf(_selectedStartMonth!);
  if (startMonthIndex == -1) return;

  final schedule = <Map<String, dynamic>>[];
  int currentYear = int.parse(_selectedStartYear!);
  int currentMonthIndex = startMonthIndex;
  double monthlyPayment = amount / period;

  for (int i = 0; i < period; i++) {
    schedule.add({
      'sn': (i + 1).toString(),
      'yearMonth': '$currentYear-${_months[currentMonthIndex]}',
      'paymentController': TextEditingController(text: monthlyPayment.toStringAsFixed(2)),
    });

    currentMonthIndex++;
    if (currentMonthIndex >= _months.length) {
      currentMonthIndex = 0;
      currentYear++;
    }
  }

 

  setState(() {
  _installmentSchedule = schedule;
});
_calculateRemainingAmount(); 

}


InputDecoration _underlineInputDecoration({String? hint, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    isDense: true,
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFCCCCCC)), 
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFCCCCCC)), 
    ),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
  );
}

  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          field,
        ],
      ),
    );
  }
Widget _buildDateField(TextEditingController controller) {
  return Stack(
    children: [
      GestureDetector(
        onTap: () => _selectDate(context),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: _underlineInputDecoration(), 
          ),
        ),
      ),
      Positioned(
        right: 6,
        top: 6,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _takenDateIsBS = !_takenDateIsBS;
            });
            _selectDate(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF346CB0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _takenDateIsBS ? 'NP' : 'EN',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildDropdown(
      List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      isDense: true,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      decoration: _underlineInputDecoration(),
      style: const TextStyle(fontSize: 13, color: Colors.black),
      items: items.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

Widget _buildInstallmentScheduleTable() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text(
        'Installment Schedule',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Color(0xFF346CB0),
        ),
      ),
      const SizedBox(height: 10),
      Table(
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
        },
        children: [
          // Table header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'S.N',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Monthly Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Table rows
          ..._installmentSchedule.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(item['sn']!, style: const TextStyle(
                      fontSize: 13)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(item['yearMonth']!, style: const TextStyle(fontSize: 13)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    controller: item['paymentController'],
                    onChanged: (value) {
                      _calculateRemainingAmount(); 
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Remaining',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              readOnly: true,
              controller: TextEditingController(
                text: _remainingAmount.toStringAsFixed(2),
              ),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: _customBlue,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Advance Salary Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(
              'Advance Amount:',
              TextField(
                controller: _advanceAmountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: _underlineInputDecoration(),
                onChanged: (value) => _generateInstallmentSchedule(),
              ),
            ),
            _buildRow('Taken Date:', _buildDateField(_takenDateController)),
            _buildRow(
              'Deduct Type:',
              _buildDropdown(
                _deductTypes,
                _selectedDeductType,
                (value) {
                  setState(() {
                    _selectedDeductType = value;
                    _generateInstallmentSchedule();
                  });
                },
              ),
            ),
            if (_selectedDeductType == 'Installment Per Month')
              _buildRow(
                'Installment Period:',
                TextField(
                  controller: _installmentPeriodController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: _underlineInputDecoration(),
                  onChanged: (value) => _generateInstallmentSchedule(),
                ),
              ),
            _buildRow(
              'Start Year:',
              _buildDropdown(
                _years,
                _selectedStartYear,
                (value) {
                  setState(() => _selectedStartYear = value);
                  _generateInstallmentSchedule();
                },
              ),
            ),
            _buildRow(
              'Start Month:',
              _buildDropdown(
                _months,
                _selectedStartMonth,
                (value) {
                  setState(() => _selectedStartMonth = value);
                  _generateInstallmentSchedule();
                },
              ),
            ),
            
            if (_selectedDeductType == 'Installment Per Month' && 
                _installmentSchedule.isNotEmpty)
              _buildInstallmentScheduleTable(),
            _buildRow(
              'Remarks:',
              TextField(
                controller: _remarksController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
                decoration: _underlineInputDecoration(),
              ),
            ),
            const SizedBox(height: 30),
            

                Center(
               child: ElevatedButton(
               onPressed: () {
               _submitAdvanceSalary(); 
                 },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _customBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
    );
  }
}