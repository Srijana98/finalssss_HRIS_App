import 'package:flutter/material.dart';

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

  final Color _customBlue = const Color(0xFF346CB0);

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

  void handleSubmit() {
    print("=== Submit Button Pressed ===");
    print("Allowance Type: $_allowanceType");
    print("Effective Year: $_effectiveYear");
    print("Effective Month: $_effectiveMonth");
    print("Amount: ${_allowanceAmountController.text}");
    print("Remarks: ${_remarksController.text}");
  }

  void handleSaveAndPrint() {
    print("=== Save & Print Button Pressed ===");
    print("Ready to print allowance entry.");
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildRow(
                'Allowance Type:',
                _buildDropdownField(
                  items: ['Extra Duty', 'Incharge/Hazard/Extra', 'Night Allowance', 'Allowance'],
                  value: _allowanceType,
                  onChanged: (val) => setState(() => _allowanceType = val),
                ),
              ),
              _buildRow(
                'Effective Year:',
                _buildDropdownField(
                  items: ['2083', '2084', '2085'],
                  value: _effectiveYear,
                  onChanged: (val) => setState(() => _effectiveYear = val),
                ),
              ),
              _buildRow(
                'Effective Month:',
                _buildDropdownField(
                  items: [
                    'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin',
                    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
                  ],
                  value: _effectiveMonth,
                  onChanged: (val) => setState(() => _effectiveMonth = val),
                ),
              ),
              _buildRow('Allowance Amount:', _buildTextField(_allowanceAmountController)),
              _buildRow('Remarks:', _buildTextField(_remarksController, maxLines: 4)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: handleSaveAndPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _customBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save & Print', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _customBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
