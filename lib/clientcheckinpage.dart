import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'getattendance.dart';

class ClientCheckInPage extends StatefulWidget {
  const ClientCheckInPage({super.key});

  @override
  State<ClientCheckInPage> createState() => _ClientCheckInPageState();
}

class _ClientCheckInPageState extends State<ClientCheckInPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  bool isCheckIn = true;
  bool _isLoadingLocation = false;
  String _currentAddress = "Fetching location...";
  Position? _currentPosition;

  bool _hasInternetConnection = true;
  bool _locationServiceDisabled = false;
  bool _locationPermissionDenied = false;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  String? _employeeId;
  String? _orgId;

  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeConnectivity();
    _getCurrentLocation();
    _fetchClientList();
  }

  @override
  void dispose() {
    addressController.dispose();
    remarksController.dispose();
    timeController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = prefs.getString('employee_id');
      _orgId = prefs.getString('org_id');
    });
  }

  Future<void> _initializeConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _handleConnectivityChange(connectivityResult);
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      _hasInternetConnection = result != ConnectivityResult.none;
      if (_hasInternetConnection) {
        _getCurrentLocation();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationServiceDisabled = false;
      _locationPermissionDenied = false;
    });

    if (!_hasInternetConnection) {
      setState(() {
        _isLoadingLocation = false;
        _currentAddress = "Waiting for internet connection...";
      });
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationServiceDisabled = true;
          _currentAddress = "Location services disabled.";
          _isLoadingLocation = false;
        });
        return;
      }

      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationPermissionDenied = true;
          _currentAddress = "Location permission denied.";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 15));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final formattedAddress = _formatAddress(placemarks.first);
        setState(() {
          _currentAddress = formattedAddress;
          _currentPosition = position;
          addressController.text = formattedAddress;
          _isLoadingLocation = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _currentAddress = "Location request timed out.";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Error: ${e.toString()}";
        _isLoadingLocation = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  Future<void> _fetchClientList() async {
    try {
      final response =
          await http.post(Uri.parse('$baseUrl/api/v1/get_client_list'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            _clients = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        }
      } else {
        print('Failed to load clients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  Future<void> _submitClientCheck() async {
    if (_currentPosition == null || _employeeId == null || _orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Required data missing. Please retry.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final remarks = remarksController.text.trim();
    final type = isCheckIn ? 'CHECKIN' : 'CHECKOUT';
    final now = DateTime.now();
    final dateAd = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final client = _clients.firstWhere(
      (c) => c['id'].toString() == _selectedClientId,
      orElse: () => {'comp_name': 'Unknown Client'},
    );

    final attendanceRecord = {
      'att_datead': dateAd,
      'att_time': time,
      'client_name': client['comp_name'] ?? client['comp_namenp'] ?? 'Unknown Client',
      'attendance_type': type,
      'remarks': remarks,
      'gps_latitude': _currentPosition!.latitude.toString(),
      'gps_longitude': _currentPosition!.longitude.toString(),
      'client_id': _selectedClientId,
    };

    await _saveAttendanceRecord(attendanceRecord);

    final apiResponse = await _sendToApi();

    if (apiResponse != null && apiResponse['status'] == 'success') {
      final updatedRecord = {
        ...attendanceRecord,
        'id': apiResponse['data']['id']?.toString() ?? 'N/A',
      };
      await _updateLastAttendanceRecord(updatedRecord);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type successful at $time'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GetAttendancePage(token: ''),
        ),
      );
    }
  }

  

  Future<Map<String, dynamic>?> _sendToApi() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'empid': _employeeId!,
        'org_id': _orgId!,
        

      };

      final body = jsonEncode({
        'client_id': _selectedClientId,
        'attendance_type': isCheckIn ? 'CHECKIN' : 'CHECKOUT',
        'att_time': timeController.text,
        'remarks': remarksController.text.trim(),
        'gps_latitude': _currentPosition!.latitude,
        'gps_longitude': _currentPosition!.longitude,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/save_client_checkin'),
        headers: headers,
        body: body,
      );

      return jsonDecode(response.body);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync with server: $e'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }
  }

  Future<void> _saveAttendanceRecord(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final existingRecords = prefs.getStringList('client_attendance') ?? [];
    existingRecords.add(jsonEncode(record));
    await prefs.setStringList('client_attendance', existingRecords);
  }

   Future<void> _updateLastAttendanceRecord(Map<String, dynamic> updatedRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final existingRecords = prefs.getStringList('client_attendance') ?? [];
    if (existingRecords.isNotEmpty) {
      existingRecords.removeLast();
      existingRecords.add(jsonEncode(updatedRecord));
      await prefs.setStringList('client_attendance', existingRecords);
    }
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      width: double.infinity,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF346CB0);
    const borderColor = Color(0xFFCCCCCC);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: addressController,
                  readOnly: true,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                    suffixIcon: _isLoadingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  items: _clients.map<DropdownMenuItem<String>>((client) {
                    return DropdownMenuItem<String>(
                      value: client['id'].toString(),
                      child: Text(
                        client['comp_name'] ?? client['comp_namenp'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search Client',
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Attendance Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Check In', style: TextStyle(fontSize: 13)),
                        value: true,
                        groupValue: isCheckIn,
                        onChanged: (value) => setState(() => isCheckIn = value!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: primaryColor,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Check Out', style: TextStyle(fontSize: 13)),
                        value: false,
                        groupValue: isCheckIn,
                        onChanged: (value) => setState(() => isCheckIn = value!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: remarksController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Remarks',
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                    contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Check In/Out button (Smaller size) ---
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _submitClientCheck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isCheckIn ? 'Check In' : 'Check Out',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- History Button (Blue background) ---
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GetAttendancePage(token: '')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'History',
                        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_hasInternetConnection)
          _buildWarningBanner("No internet connection. Please check your internet connection."),
        if (_locationServiceDisabled)
          _buildWarningBanner("Location services are disabled. Please enable your location services."),
        if (_locationPermissionDenied)
          _buildWarningBanner("Location permission denied. Please access your location services"),
      ],
    );
  }
}
