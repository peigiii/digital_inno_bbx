import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class BBXListWasteScreen extends StatefulWidget {
  const BBXListWasteScreen({super.key});

  @override
  State<BBXListWasteScreen> createState() => _BBXListWasteScreenState();
}

class _BBXListWasteScreenState extends State<BBXListWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  
  String? _selectedWasteType;
  String? _selectedUnit;
  File? _selectedImage;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  final List<String> wasteTypes = [
    'EFB (Empty Fruit Bunches)',
    'POME (Palm Oil Mill Effluent)',
    'Palm Shell',
    'Palm Fiber',
    'Palm Kernel Cake',
    'Coconut Husk',
    'Rice Husk',
    'Sugarcane Bagasse',
    'Wood Chips',
    'Other Biomass',
  ];

  final List<String> units = [
    'Tons',
    'Cubic Meters',
    'Liters',
    'Kilograms',
    'Truckloads',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitWasteListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final wasteListing = {
        'userId': user.uid,
        'userEmail': user.email,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'wasteType': _selectedWasteType,
        'quantity': double.parse(_quantityController.text),
        'unit': _selectedUnit,
        'pricePerUnit': double.parse(_priceController.text),
        'contactInfo': _contactController.text.trim(),
        'location': _currentPosition != null ? {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        } : null,
        'imageUrl': null, // Will be updated if image is uploaded
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available',
        'complianceStatus': 'pending',
      };

      await FirebaseFirestore.instance
          .collection('listings')
          .add(wasteListing)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Submit timeout, please check connection');
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _quantityController.clear();
        _priceController.clear();
        _contactController.clear();
        setState(() {
          _selectedWasteType = null;
          _selectedUnit = null;
          _selectedImage = null;
        });

        // Navigate to marketplace tab in main screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'index': 1},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('List Waste'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
                arguments: {'index': 1},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.recycling,
                      size: isTablet ? 60 : 48,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BBX Waste Exchange',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      'Convert your biomass waste into revenue',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Listing Details',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                          hintText: 'e.g. High Quality EFB',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Waste Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedWasteType,
                        decoration: const InputDecoration(
                          labelText: 'Waste Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: wasteTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedWasteType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select waste type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantity and Unit Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter quantity';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                              ),
                              items: units.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedUnit = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Select unit';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Field
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price (RM)',
                          prefixIcon: Icon(Icons.monetization_on),
                          hintText: 'Price per unit',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Describe quality, condition etc.',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Field
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Info',
                          prefixIcon: Icon(Icons.contact_phone),
                          hintText: 'Phone or Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter contact info';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Image and Location Section
                      Card(
                        color: Colors.grey[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Additional Info',
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Image Picker
                              InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _selectedImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 40,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tap to take photo',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: isTablet ? 16 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Location Info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _currentPosition != null 
                                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _currentPosition != null 
                                          ? Icons.location_on 
                                          : Icons.location_off,
                                      color: _currentPosition != null 
                                          ? const Color(0xFF2E7D32) 
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _isLocationLoading
                                          ? const Text('Getting location...')
                                          : Text(
                                              _currentPosition != null
                                                  ? 'Location Acquired'
                                                  : 'Location Not Acquired',
                                              style: TextStyle(
                                                color: _currentPosition != null 
                                                    ? const Color(0xFF2E7D32) 
                                                    : Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                    if (_currentPosition == null && !_isLocationLoading)
                                      TextButton(
                                        onPressed: _getCurrentLocation,
                                        child: const Text('Retry'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitWasteListing,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Submit Listing',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PCDS 2030 Compliance Info
            Card(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFF2E7D32),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PCDS 2030 Compliant',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All listings are reviewed for PCDS 2030 compliance to ensure sustainability standards.',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
