import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class DailyReportEntryPage extends StatefulWidget {
 const DailyReportEntryPage({super.key});
    
  @override
  State<DailyReportEntryPage> createState() => _DailyReportEntryPageState();
}

class _DailyReportEntryPageState extends State<DailyReportEntryPage> {
final TextEditingController _reportingDateController = TextEditingController();
final TextEditingController _reportingTitleController = TextEditingController();
final TextEditingController _workstationController = TextEditingController();
final TextEditingController _descriptionController = TextEditingController();
final TextEditingController _fuelLitreController = TextEditingController();
final TextEditingController _fuelPriceController = TextEditingController();
final TextEditingController _totalAmountController = TextEditingController();
final TextEditingController _vehicleNoController = TextEditingController();
final TextEditingController _odometerStartController = TextEditingController();
final TextEditingController _odometerEndController = TextEditingController();

  final List<String> _clients = ['Client A', 'Client B', 'Client C'];
  
  
  String? _selectedClient;
  File? _selectedFile;
  
  


  final List<String> _paymentOptions = ['Self', 'Company'];
  String? _selectedPayment;
  
 final List<String> _vehicleTypes = ['Bike', 'Car', 'Van', 'Truck'];
 String? _selectedVehicleType;
 

  bool _isBS = true; 
  bool _isFuelClaim = false;
 
  

  final Color _customBlue = const Color(0xFF346CB0);

  @override
  void dispose() {
    _reportingDateController.dispose();
    _reportingTitleController.dispose();
    _workstationController.dispose();
    _descriptionController.dispose();
    _fuelLitreController.dispose();
   _fuelPriceController.dispose();
   _totalAmountController.dispose();
   _vehicleNoController.dispose();
   _odometerStartController.dispose();
   _odometerEndController.dispose();
    super.dispose();
  }

  
  Future<void> _selectDate(TextEditingController controller) async {
  if (_isBS) {
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: NepaliDateTime.now(),
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime(2090),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
    }
  } else {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
    }
  }
}


  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Widget _buildRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 0.6,
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
        onTap: () => _selectDate(controller),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
              ),
            ),
          ),
        ),
      ),
    
      Positioned(
        right: 6,
        top: 6,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isBS = !_isBS;
            });
            _selectDate(controller);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF346CB0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _isBS ? 'BS' : 'AD',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedClient,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
        ),
      ),
      items: _clients
          .map((client) => DropdownMenuItem<String>(
                value: client,
                child: Text(client, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedClient = value),
    );
  }

  Widget _buildAttachmentField() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _pickFile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _customBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Choose File', style: TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _selectedFile != null ? _selectedFile!.path.split('/').last : 'No file selected',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daily Report Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildRow('Client:', _buildDropdownField()),
            _buildRow('Workstation:', _buildTextField(_workstationController)),
            _buildRow('Title:', _buildTextField(_reportingTitleController)),
            _buildRow('Date:', _buildDateField(_reportingDateController)),
            _buildRow('Description:', _buildTextField(_descriptionController, maxLines: 4)),
           

            Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Checkbox(
        value: _isFuelClaim,
        activeColor: _customBlue,
        onChanged: (val) => setState(() => _isFuelClaim = val ?? false),
      ),
     const Text ('Fuel Claim', style: TextStyle(fontWeight: FontWeight.w600, fontSize:13)),
      
    ],
  ),
),

if (_isFuelClaim) ...[
  _buildRow('Fuel Litre:', _buildTextField(_fuelLitreController)),
  _buildRow('Fuel Price:', _buildTextField(_fuelPriceController)),
  _buildRow(
  'Total Amount:',
  _buildTextField(_totalAmountController),
),
  _buildRow(
    'Payment:',
    DropdownButtonFormField<String>(
      value: null,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
      ),
      items: _paymentOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (val) => setState(() => _selectedPayment = val),
    ),
  ),
  _buildRow(
    'Vehicle Type:',
    DropdownButtonFormField<String>(
      value: null,
      icon: Icon(Icons.arrow_drop_down, color: _customBlue),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2)),
      ),
      items: _vehicleTypes
          .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (val) => setState(() => _selectedVehicleType = val),
    ),
  ),
  _buildRow('Vehicle No:', _buildTextField(_vehicleNoController)),
  _buildRow('Odometer Start:', _buildTextField(_odometerStartController)),
  _buildRow('Odometer End Value:', _buildTextField(_odometerEndController)),
],
            _buildRow('Attachment:', _buildAttachmentField()),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  print('Client: $_selectedClient');
                  print('Workstation: ${_workstationController.text}');
                  print('Title: ${_reportingTitleController.text}');
                  print('Date: ${_reportingDateController.text}');
                  print('Description: ${_descriptionController.text}');
                  print('File: ${_selectedFile?.path}');
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
