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
          SnackBar(content: Text('获取位置信息失败: $e')),
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
        throw Exception('用户未登�?);
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
              throw Exception('提交超时，请检查网络连�?);
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('废料信息发布成功�?),
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

        // Navigate to marketplace
        Navigator.pushReplacementNamed(context, '/marketplace');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: $e'),
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
        title: const Text('发布废料信息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/marketplace');
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
                      'BBX 废料交换平台',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    Text(
                      '将您的生物质废料转化为收�?,
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
                        '废料信息',
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
                          labelText: '废料标题',
                          prefixIcon: Icon(Icons.title),
                          hintText: '例如：高质量棕榈空果�?,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入废料标�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Waste Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedWasteType,
                        decoration: const InputDecoration(
                          labelText: '废料类型',
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
                            return '请选择废料类型';
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
                                labelText: '数量',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入数�?;
                                }
                                if (double.tryParse(value) == null) {
                                  return '请输入有效数�?;
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
                                labelText: '单位',
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
                                  return '请选择单位';
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
                          labelText: '单价 (RM)',
                          prefixIcon: Icon(Icons.monetization_on),
                          hintText: '每单位价�?,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入单�?;
                          }
                          if (double.tryParse(value) == null) {
                            return '请输入有效价�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '详细描述',
                          prefixIcon: Icon(Icons.description),
                          hintText: '描述废料的质量、处理状态等',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入详细描�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contact Field
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: '联系方式',
                          prefixIcon: Icon(Icons.contact_phone),
                          hintText: '电话号码或邮�?,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入联系方�?;
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
                                '附加信息',
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
                                              '点击拍照上传废料图片',
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
                                          ? const Text('正在获取位置信息...')
                                          : Text(
                                              _currentPosition != null
                                                  ? '位置已获�?
                                                  : '位置信息未获�?,
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
                                        child: const Text('重新获取'),
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
                                  '发布废料信息',
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
                      'PCDS 2030 合规保证',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '所有发布的废料信息将经过PCDS 2030合规性审�?确保符合可持续发展标�?,
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
