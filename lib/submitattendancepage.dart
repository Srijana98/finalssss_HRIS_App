import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'config.dart';

class SubmitAttendancePage extends StatefulWidget {
  const SubmitAttendancePage({super.key});

  @override
  State<SubmitAttendancePage> createState() => _SubmitAttendancePageState();
}

class _SubmitAttendancePageState extends State<SubmitAttendancePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final MapController _mapController = MapController();

  String _attendanceType = 'check_in';
  bool _obscurePassword = true;
  bool _showMap = false;

  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _hasInternetConnection = true;
  bool _locationServiceDisabled = false;
  bool _locationPermissionDenied = false;

  Position? _currentPosition;
  String _currentAddress = "Fetching location...";
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Attendance Location Variables
  List<Map<String, dynamic>> _attendanceLocations = [];
  String? _selectedAttendanceLocationId;
  bool _isLoadingAttendanceLocations = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _getCurrentLocation();
    _fetchAttendanceLocations();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _remarksController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) _handleConnectivityChange(result);
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((res) {
        if (mounted) _handleConnectivityChange(res);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasInternetConnection = false;
        });
      }
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      _hasInternetConnection = result != ConnectivityResult.none;
      if (_hasInternetConnection) _getCurrentLocation();
    });
  }

  Future<void> _fetchAttendanceLocations() async {
    setState(() {
      _isLoadingAttendanceLocations = true;
    });

    try {
      final url = Uri.parse('$baseUrl/api/v1/web_attendance');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _attendanceLocations = List<Map<String, dynamic>>.from(data['data']);
            _isLoadingAttendanceLocations = false;
          });
        } else {
          setState(() {
            _isLoadingAttendanceLocations = false;
          });


          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load attendance locations'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() {
          _isLoadingAttendanceLocations = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error loading attendance locations: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingAttendanceLocations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _currentAddress = address;
          _currentPosition = position;
          _isLoadingLocation = false;
        });

        // Move map to current location if map is visible
        if (_showMap && _currentPosition != null) {
          if (mounted) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            );
          }
        }
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

  Future<void> _submitAttendance() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your username/email and password',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please refresh location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final url = Uri.parse('$baseUrl/api/authenticate_user_for_attendance');

    final payload = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "attendance_locationid": _selectedAttendanceLocationId ?? "",
      "att_type": _attendanceType == 'check_in' ? "CHECKIN" : "CHECKOUT",
      "remarks": _remarksController.text,
      "gps_latitude": _currentPosition!.latitude.toString(),
      "gps_longitude": _currentPosition!.longitude.toString(),
      "address": _currentAddress,
    };

    try {
      final response = await http
          .post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      setState(() {
        _isSubmitting = false;
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Attendance submitted successfully."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMsg = "Attendance failed.";
        final message = data["message"];

        if (message != null) {
          if (message is String) {
            errorMsg = message;
          } else if (message is List) {
            errorMsg = message.map((e) => e.toString()).join(', ');
          } else {
            errorMsg = message.toString();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting attendance: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.all(10),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Location not available',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.employeeapp',
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors',
              },
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
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
    const primaryColor = Color(0xFF346CB0);
    const borderColor = Color(0xFFCCCCCC);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Mobile Attendance',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Location Field with Refresh and Map Toggle
                        TextFormField(
                          readOnly: true,
                          controller:
                              TextEditingController(text: _currentAddress),
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.location_on,
                                color: primaryColor),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Refresh Icon
                                IconButton(
                                  icon: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: primaryColor,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.refresh,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                  onPressed: _isLoadingLocation
                                      ? null
                                      : () {
                                          _getCurrentLocation();
                                        },
                                ),
                                // Map Expand/Collapse Icon
                                IconButton(
                                  icon: Icon(
                                    _showMap
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: primaryColor,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showMap = !_showMap;
                                    });
                                    if (_showMap && _currentPosition != null) {
                                      if (mounted) {
                                        _mapController.move(
                                          LatLng(_currentPosition!.latitude,
                                              _currentPosition!.longitude),
                                          15.0,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 9),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Map View (conditionally shown)
                        if (_showMap) ...[
                          _buildMapView(),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Username/Email',
                            prefixIcon:
                                const Icon(Icons.email, color: primaryColor),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(fontSize: 13),
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Attendance Location Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedAttendanceLocationId,
                          decoration: InputDecoration(
                            labelText: 'Attendance Location',
                            prefixIcon:
                                const Icon(Icons.place, color: primaryColor),
                            suffixIcon: _isLoadingAttendanceLocations
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 7, horizontal: 9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                          ),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black),
                          isExpanded: true,
                          menuMaxHeight:
                              MediaQuery.of(context).size.height * 0.35,
                          dropdownColor: Colors.white,
                          elevation: 8,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: primaryColor, size: 28),
                          selectedItemBuilder: (BuildContext context) {
                            return _attendanceLocations.map((location) {
                              return Text(
                                location['locname'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black),
                                overflow: TextOverflow.ellipsis,
                              );
                            }).toList();
                          },
                          items: _attendanceLocations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location['id'].toString(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 8.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      location['locname'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (location['lat'] != null &&
                                        location['long'] != null) ...[
                                      const SizedBox(height: 8),
                                      // Map preview for this location
                                      Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: FlutterMap(
                                            options: MapOptions(
                                              initialCenter: LatLng(
                                                double.parse(location['lat']
                                                    .toString()),
                                                double.parse(location['long']
                                                    .toString()),
                                              ),
                                              initialZoom: 15.0,
                                              interactionOptions:
                                                  const InteractionOptions(
                                                flags: InteractiveFlag.none,
                                              ),
                                            ),
                                            children: [
                                              TileLayer(
                                                urlTemplate:
                                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                                userAgentPackageName:
                                                    'com.example.employeeapp',
                                              ),
                                              MarkerLayer(
                                                markers: [
                                                  Marker(
                                                    point: LatLng(
                                                      double.parse(
                                                          location['lat']
                                                              .toString()),
                                                      double.parse(
                                                          location['long']
                                                              .toString()),
                                                    ),
                                                    width: 80,
                                                    height: 80,
                                                    child: const Icon(
                                                      Icons.location_pin,
                                                      color: primaryColor,
                                                      size: 40,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAttendanceLocationId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Attendance Type:',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Flexible(
                              child: RadioListTile<String>(
                                title: const Text('Check In',
                                    style: TextStyle(fontSize: 13)),
                                value: 'check_in',
                                groupValue: _attendanceType,
                                onChanged: (value) {
                                  setState(() {
                                    _attendanceType = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: primaryColor,
                              ),
                            ),
                            Flexible(
                              child: RadioListTile<String>(
                                title: const Text('Check Out',
                                    style: TextStyle(fontSize: 13)),
                                value: 'check_out',
                                groupValue: _attendanceType,
                                onChanged: (value) {
                                  setState(() {
                                    _attendanceType = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Remarks
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            labelText: 'Remarks',
                            labelStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black),
                            floatingLabelStyle: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(12, 18, 12, 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: primaryColor, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Attendance Button
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 180,
                            height: 40,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _submitAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                      'Submit Attendance',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_hasInternetConnection)
                _buildWarningBanner(
                    "No internet connection. Please check your connection."),
              if (_locationServiceDisabled)
                _buildWarningBanner(
                    "Location services are disabled. Please enable them."),
              if (_locationPermissionDenied)
                _buildWarningBanner(
                    "Location permission denied. Please grant from settings."),
            ],
          ),
        ],
      ),
    );
  }
}






















// submitattendancepage.dart of the gwt  with the checkbox 
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'config.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// class SubmitAttendancePage extends StatefulWidget {
//   const SubmitAttendancePage({super.key});

//   @override
//   State<SubmitAttendancePage> createState() => _SubmitAttendancePageState();
// }

// class _SubmitAttendancePageState extends State<SubmitAttendancePage> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _remarksController = TextEditingController();
//   final MapController _mapController = MapController();

//   String _attendanceType = 'check_in';
//   bool _obscurePassword = true;
//   bool _showMap = false;

//   bool _isLoadingLocation = false;
//   bool _isSubmitting = false;
//   bool _hasInternetConnection = true;
//   bool _locationServiceDisabled = false;
//   bool _locationPermissionDenied = false;
//   bool _rememberMe = false;

//   Position? _currentPosition;
//   String _currentAddress = "Fetching location...";
//   StreamSubscription<ConnectivityResult>? _connectivitySubscription;

//   // Attendance Location Variables
//   List<Map<String, dynamic>> _attendanceLocations = [];
//   String? _selectedAttendanceLocationId;
//   bool _isLoadingAttendanceLocations = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeConnectivity();
//     _getCurrentLocation();
//     _fetchAttendanceLocations();
//     _loadCredentials(); 
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _remarksController.dispose();
//     _mapController.dispose();
//     super.dispose();
//   }

  


// Future<void> _saveCredentials() async {
//   final prefs = await SharedPreferences.getInstance();
//   if (_rememberMe) {
//     await prefs.setString('saved_email', _emailController.text.trim());
//     await prefs.setString('saved_password', _passwordController.text);
//     await prefs.setBool('remember_me', true);
    
//     // Debug prints
//     print('✅ ========== CREDENTIALS SAVED ==========');
//     print('Email: ${_emailController.text.trim()}');
//     print('Password: ${_passwordController.text}');
//     print('Remember Me: true');
//     print('=========================================');
    
//     // Show confirmation
   
//   } else {
//     // Clear saved credentials if remember me is unchecked
//     await prefs.remove('saved_email');
//     await prefs.remove('saved_password');
//     await prefs.setBool('remember_me', false);
    
//     // Debug prints
//     print('❌ ========== CREDENTIALS CLEARED ==========');
//     print('Remember Me: false');
    
    
  
   
//   }
// }



// Future<void> _loadCredentials() async {
//   final prefs = await SharedPreferences.getInstance();
//   final rememberMe = prefs.getBool('remember_me') ?? false;
  
//   print('🔍 ========== LOADING CREDENTIALS ==========');
//   print('Remember Me Status: $rememberMe');
  
//   if (rememberMe) {
//     final savedEmail = prefs.getString('saved_email') ?? '';
//     final savedPassword = prefs.getString('saved_password') ?? '';
    
//     print('Found Saved Email: $savedEmail');
//     print('Found Saved Password: $savedPassword');
//     print('===========================================');
    
//     setState(() {
//       _rememberMe = rememberMe;
//       _emailController.text = savedEmail;
//       _passwordController.text = savedPassword;
//     });
    
//     // Show confirmation after build completes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
      
//     });
//   } else {
//     print('No saved credentials found or Remember Me was unchecked');
//     print('===========================================');
//   }
// }



//   Future<void> _login() async {
//   final Uri url = Uri.parse('https://gwt.xelwel.com');
  
//   try {
//     await launchUrl(
//       url,
//       mode: LaunchMode.externalApplication,
//     );
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('browser cannot be opened: ${e.toString()}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }

//   Future<void> _initializeConnectivity() async {
//     try {
//       final result = await Connectivity().checkConnectivity();
//       if (mounted) _handleConnectivityChange(result);
//       _connectivitySubscription =
//           Connectivity().onConnectivityChanged.listen((res) {
//         if (mounted) _handleConnectivityChange(res);
//       });
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _hasInternetConnection = false;
//         });
//       }
//     }
//   }

//   void _handleConnectivityChange(ConnectivityResult result) {
//     setState(() {
//       _hasInternetConnection = result != ConnectivityResult.none;
//       if (_hasInternetConnection) _getCurrentLocation();
//     });
//   }

//   Future<void> _fetchAttendanceLocations() async {
//     setState(() {
//       _isLoadingAttendanceLocations = true;
//     });

//     try {
//       final url = Uri.parse('https://gwt.xelwel.com/api/v1/web_attendance');
//       final response = await http.get(url).timeout(const Duration(seconds: 15));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['success'] == true && data['data'] != null) {
//           setState(() {
//             _attendanceLocations = List<Map<String, dynamic>>.from(data['data']);
//             _isLoadingAttendanceLocations = false;
//           });
//         } else {
//           setState(() {
//             _isLoadingAttendanceLocations = false;
//           });
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Failed to load attendance locations'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         }
//       } else {
//         setState(() {
//           _isLoadingAttendanceLocations = false;
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content:
//                   Text('Error loading attendance locations: ${response.statusCode}'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       setState(() {
//         _isLoadingAttendanceLocations = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() {
//       _isLoadingLocation = true;
//       _locationServiceDisabled = false;
//       _locationPermissionDenied = false;
//     });

//     if (!_hasInternetConnection) {
//       setState(() {
//         _isLoadingLocation = false;
//         _currentAddress = "Waiting for internet connection...";
//       });
//       return;
//     }

//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
       
//         setState(() {
//   _locationServiceDisabled = true;
//   _currentAddress = "Location services disabled.";
//   _isLoadingLocation = false;
// });
//         return;
//       }

//       final status = await Permission.location.request();
//       if (!status.isGranted) {
//         setState(() {
//           _locationPermissionDenied = true;
//           _currentAddress = "Location permission denied.";
//           _isLoadingLocation = false;
//         });
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.best,
//       ).timeout(const Duration(seconds: 15));

//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       ).timeout(const Duration(seconds: 10));

//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         final address = [
//           place.street,
//           place.subLocality,
//           place.locality,
//           place.administrativeArea,
//         ].where((e) => e != null && e.isNotEmpty).join(', ');

//         setState(() {
//           _currentAddress = address;
//           _currentPosition = position;
//           _isLoadingLocation = false;
//         });

//         // Move map to current location if map is visible
//         if (_showMap && _currentPosition != null) {
//           if (mounted) {
//             _mapController.move(
//               LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//               15.0,
//             );
//           }
//         }
//       }
//     } on TimeoutException {
//       setState(() {
//         _currentAddress = "Location request timed out.";
//         _isLoadingLocation = false;
//       });
//     } catch (e) {
//       setState(() {
//         _currentAddress = "Error: ${e.toString()}";
//         _isLoadingLocation = false;
//       });
//     }
//   }

//   Future<void> _submitAttendance() async {
//     if (_emailController.text.trim().isEmpty ||
//         _passwordController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please enter your username/email and password',
//             style: TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (_currentPosition == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location not available. Please refresh location'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isSubmitting = true;
//     });

//     final url = Uri.parse('$baseUrl/api/authenticate_user_for_attendance');

//     final payload = {
//       "email": _emailController.text.trim(),
//       "password": _passwordController.text,
//       "attendance_locationid": _selectedAttendanceLocationId ?? "",
//       "att_type": _attendanceType == 'check_in' ? "CHECKIN" : "CHECKOUT",
//       "remarks": _remarksController.text,
//       "gps_latitude": _currentPosition!.latitude.toString(),
//       "gps_longitude": _currentPosition!.longitude.toString(),
//       "address": _currentAddress,
//     };

//     try {
//       final response = await http
//           .post(url,
//               headers: {"Content-Type": "application/json"},
//               body: jsonEncode(payload))
//           .timeout(const Duration(seconds: 20));

//       setState(() {
//         _isSubmitting = false;
//       });

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data["status"] == "success") {

//         await _saveCredentials(); 

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Attendance submitted successfully."),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         String errorMsg = "Attendance failed.";
//         final message = data["message"];

//         if (message != null) {
//           if (message is String) {
//             errorMsg = message;
//           } else if (message is List) {
//             errorMsg = message.map((e) => e.toString()).join(', ');
//           } else {
//             errorMsg = message.toString();
//           }
//         }

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMsg),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isSubmitting = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error submitting attendance: ${e.toString()}"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }




//   Widget _buildWarningBanner(String message) {
//     return Container(
//       width: double.infinity,
//       color: Colors.red,
//       padding: const EdgeInsets.all(10),
//       child: Text(
//         message,
//         textAlign: TextAlign.center,
//         style: const TextStyle(
//             color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//       ),
//     );
//   }

//   Widget _buildMapView() {
//     if (_currentPosition == null) {
//       return Container(
//         height: 300,
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFFCCCCCC)),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.location_off, size: 48, color: Colors.grey),
//               SizedBox(height: 8),
//               Text('Location not available',
//                   style: TextStyle(color: Colors.grey)),
//             ],
//           ),
//         ),
//       );
//     }

//     return Container(
//       height: 300,
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFFCCCCCC)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8),
//         child: FlutterMap(
//           mapController: _mapController,
//           options: MapOptions(
//             initialCenter: LatLng(
//               _currentPosition!.latitude,
//               _currentPosition!.longitude,
//             ),
//             initialZoom: 15.0,
//           ),
//           children: [
//             TileLayer(
//               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.example.task9',
//               additionalOptions: const {
//                 'attribution': '© OpenStreetMap contributors',
//               },
//             ),
//             MarkerLayer(
//               markers: [
//                 Marker(
//                   point: LatLng(
//                     _currentPosition!.latitude,
//                     _currentPosition!.longitude,
//                   ),
//                   width: 80,
//                   height: 80,
//                   child: const Icon(
//                     Icons.location_pin,
//                     color: Colors.red,
//                     size: 40,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFF007A4D);
//     const borderColor = Color(0xFFCCCCCC);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: primaryColor,
//         iconTheme: const IconThemeData(color: Colors.white),
//         title: const Text(
//           'Mobile Attendance',
//           style: TextStyle(
//               color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: Form(
//                   key: _formKey,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Location Field with Refresh and Map Toggle
//                         TextFormField(
//                           readOnly: true,
//                           controller:
//                               TextEditingController(text: _currentAddress),
//                           maxLines: 2,
//                           minLines: 1,
//                           style: const TextStyle(fontSize: 13),
//                           decoration: InputDecoration(
//                             prefixIcon: const Icon(Icons.location_on,
//                                 color: primaryColor),
//                             suffixIcon: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 // Refresh Icon
//                                 IconButton(
//                                   icon: _isLoadingLocation
//                                       ? const SizedBox(
//                                           width: 20,
//                                           height: 20,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                             color: primaryColor,
//                                           ),
//                                         )
//                                       : const Icon(
//                                           Icons.refresh,
//                                           color: primaryColor,
//                                           size: 24,
//                                         ),
//                                   onPressed: _isLoadingLocation
//                                       ? null
//                                       : () {
//                                           _getCurrentLocation();
//                                         },
//                                 ),
//                                 // Map Expand/Collapse Icon
//                                 IconButton(
//                                   icon: Icon(
//                                     _showMap
//                                         ? Icons.expand_less
//                                         : Icons.expand_more,
//                                     color: primaryColor,
//                                     size: 28,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _showMap = !_showMap;
//                                     });
//                                     if (_showMap && _currentPosition != null) {
//                                       if (mounted) {
//                                         _mapController.move(
//                                           LatLng(_currentPosition!.latitude,
//                                               _currentPosition!.longitude),
//                                           15.0,
//                                         );
//                                       }
//                                     }
//                                   },
//                                 ),
//                               ],
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 7, horizontal: 9),
//                             isDense: true,
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: borderColor),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                   color: primaryColor, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),

//                         // Map View (conditionally shown)
//                         if (_showMap) ...[
//                           _buildMapView(),
//                           const SizedBox(height: 16),
//                         ],

//                         // Email
//                         TextFormField(
//                           controller: _emailController,
//                           style: const TextStyle(fontSize: 13),
//                           decoration: InputDecoration(
//                             labelText: 'Username/Email',
//                             prefixIcon:
//                                 const Icon(Icons.email, color: primaryColor),
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 7, horizontal: 9),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: borderColor),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                   color: primaryColor, width: 2),
//                             ),
//                           ),
//                           keyboardType: TextInputType.emailAddress,
//                         ),
//                         const SizedBox(height: 16),

//                         // Password
//                         TextFormField(
//                           controller: _passwordController,
//                           style: const TextStyle(fontSize: 13),
//                           obscureText: _obscurePassword,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             prefixIcon:
//                                 const Icon(Icons.lock, color: primaryColor),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _obscurePassword
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                                 color: primaryColor,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _obscurePassword = !_obscurePassword;
//                                 });
//                               },
//                             ),
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 7, horizontal: 9),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: borderColor),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                   color: primaryColor, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),

                    


// Row(
//   children: [
//     SizedBox(
//       height: 24,
//       width: 24,
//       child: Checkbox(
//         value: _rememberMe,
//         onChanged: (value) {
//           setState(() {
//             _rememberMe = value ?? false;
//           });
//         },
//         activeColor: primaryColor,
//         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//       ),
//     ),
//     const SizedBox(width: 8),
//     GestureDetector(
//       onTap: () {
//         setState(() {
//           _rememberMe = !_rememberMe;
//         });
//       },
//       child: const Text(
//         'Remember me?',
//         style: TextStyle(
//           fontSize: 15,
//           color: Colors.black87,
//           fontWeight: FontWeight.w600, 
//           decoration: TextDecoration.underline, 
//           decorationThickness: 1.5, 
//           height: 1.3, 
         
//         ),
//       ),
//     ),
//   ],
// ),



//    const SizedBox(height: 16),
//                         // Attendance Location Dropdown
//                         DropdownButtonFormField<String>(
//                           value: _selectedAttendanceLocationId,
//                           decoration: InputDecoration(
//                             labelText: 'Attendance Location',
//                             prefixIcon:
//                                 const Icon(Icons.place, color: primaryColor),
//                             suffixIcon: _isLoadingAttendanceLocations
//                                 ? const Padding(
//                                     padding: EdgeInsets.all(10),
//                                     child: SizedBox(
//                                       width: 20,
//                                       height: 20,
//                                       child: CircularProgressIndicator(
//                                           strokeWidth: 2),
//                                     ),
//                                   )
//                                 : null,
//                             isDense: true,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 7, horizontal: 9),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: borderColor),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                   color: primaryColor, width: 2),
//                             ),
//                           ),
//                           style: const TextStyle(
//                               fontSize: 13, color: Colors.black),
//                           isExpanded: true,
//                           menuMaxHeight:
//                               MediaQuery.of(context).size.height * 0.35,
//                           dropdownColor: Colors.white,
//                           elevation: 8,
//                           icon: const Icon(Icons.arrow_drop_down,
//                               color: primaryColor, size: 28),
//                           selectedItemBuilder: (BuildContext context) {
//                             return _attendanceLocations.map((location) {
//                               return Text(
//                                 location['locname'] ?? '',
//                                 style: const TextStyle(
//                                     fontSize: 13, color: Colors.black),
//                                 overflow: TextOverflow.ellipsis,
//                               );
//                             }).toList();
//                           },
//                           items: _attendanceLocations.map((location) {
//                             return DropdownMenuItem<String>(
//                               value: location['id'].toString(),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 12.0, horizontal: 8.0),
//                                 decoration: BoxDecoration(
//                                   border: Border(
//                                     bottom: BorderSide(
//                                       color: Colors.grey.shade200,
//                                       width: 0.5,
//                                     ),
//                                   ),
//                                 ),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       location['locname'] ?? '',
//                                       style: const TextStyle(
//                                         fontSize: 13,
//                                         color: Colors.black87,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     if (location['lat'] != null &&
//                                         location['long'] != null) ...[
//                                       const SizedBox(height: 8),
//                                       // Map preview for this location
//                                       Container(
//                                         height: 150,
//                                         decoration: BoxDecoration(
//                                           border: Border.all(
//                                               color: Colors.grey.shade300),
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: ClipRRect(
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                           child: FlutterMap(
//                                             options: MapOptions(
//                                               initialCenter: LatLng(
//                                                 double.parse(location['lat']
//                                                     .toString()),
//                                                 double.parse(location['long']
//                                                     .toString()),
//                                               ),
//                                               initialZoom: 15.0,
//                                               interactionOptions:
//                                                   const InteractionOptions(
//                                                 flags: InteractiveFlag.none,
//                                               ),
//                                             ),
//                                             children: [
//                                               TileLayer(
//                                                 urlTemplate:
//                                                     'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                                                 userAgentPackageName:
//                                                     'com.example.task9',
//                                               ),
//                                               MarkerLayer(
//                                                 markers: [
//                                                   Marker(
//                                                     point: LatLng(
//                                                       double.parse(
//                                                           location['lat']
//                                                               .toString()),
//                                                       double.parse(
//                                                           location['long']
//                                                               .toString()),
//                                                     ),
//                                                     width: 80,
//                                                     height: 80,
//                                                     child: const Icon(
//                                                       Icons.location_pin,
//                                                       color: primaryColor,
//                                                       size: 40,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           onChanged: (value) {
//                             setState(() {
//                               _selectedAttendanceLocationId = value;
//                             });
//                           },
//                         ),
//                         const SizedBox(height: 20),

//                         const Text(
//                           'Attendance Type:',
//                           style: TextStyle(
//                               fontSize: 13, fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             Flexible(
//                               child: RadioListTile<String>(
//                                 title: const Text('Check In',
//                                     style: TextStyle(fontSize: 13)),
//                                 value: 'check_in',
//                                 groupValue: _attendanceType,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _attendanceType = value!;
//                                   });
//                                 },
//                                 contentPadding: EdgeInsets.zero,
//                                 activeColor: primaryColor,
//                               ),
//                             ),
//                             Flexible(
//                               child: RadioListTile<String>(
//                                 title: const Text('Check Out',
//                                     style: TextStyle(fontSize: 13)),
//                                 value: 'check_out',
//                                 groupValue: _attendanceType,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _attendanceType = value!;
//                                   });
//                                 },
//                                 contentPadding: EdgeInsets.zero,
//                                 activeColor: primaryColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 20),

//                         // Remarks
//                         TextFormField(
//                           controller: _remarksController,
//                           maxLines: 3,
//                           style: const TextStyle(fontSize: 14),
//                           decoration: InputDecoration(
//                             alignLabelWithHint: true,
//                             labelText: 'Remarks',
//                             labelStyle: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black),
//                             floatingLabelStyle: const TextStyle(
//                               color: primaryColor,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             contentPadding:
//                                 const EdgeInsets.fromLTRB(12, 18, 12, 12),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: borderColor),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                   color: primaryColor, width: 2),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         // Submit Attendance Button
//                         Align(
//                           alignment: Alignment.center,
//                           child: SizedBox(
//                             width: 180,
//                             height: 40,
//                             child: ElevatedButton(
//                               onPressed:
//                                   _isSubmitting ? null : _submitAttendance,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: primaryColor,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                               ),
//                               child: _isSubmitting
//                                   ? const CircularProgressIndicator(
//                                       color: Colors.white, strokeWidth: 2)
//                                   : const Text(
//                                       'Submit Attendance',
//                                       style: TextStyle(
//                                           fontSize: 13,
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16), // Spacing between buttons
//                         // Login Button
//                         Align(
//                           alignment: Alignment.center,
//                           child: SizedBox(
//                             width: 180,
//                             height: 40,
//                             child: ElevatedButton(
//                               onPressed: _login,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Color(0xFF346CB0),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(20),
//                                 ),
//                               ),
//                               child: const Text(
//                                 'Login',
//                                 style: TextStyle(
//                                     fontSize: 13,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               if (!_hasInternetConnection)
//                 _buildWarningBanner(
//                     "No internet connection. Please check your connection."),
//               if (_locationServiceDisabled)
//                 _buildWarningBanner(
//                     "Location services are disabled. Please enable them."),
//               if (_locationPermissionDenied)
//                 _buildWarningBanner(
//                     "Location permission denied. Please grant from settings."),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

