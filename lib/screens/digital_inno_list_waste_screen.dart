import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../services/image_upload_service.dart';

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
  final _addressController = TextEditingController();

  String? _selectedWasteType;
  String? _selectedUnit;
  String? _selectedCity;
  final List<XFile> _selectedImages = [];
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  // Waste types list
  final List<String> wasteTypes = [
    'Coffee Grounds',
    'Palm Fiber',
    'Food Waste',
    'Paper Waste',
    'Plastic Waste',
    'Metal Scrap',
    'Electronic Waste',
    'Textile Waste',
    'Wood Waste',
    'Glass Waste',
    'Organic Waste',
    'Chemical Waste',
    'Construction Waste',
    'EFB (Empty Fruit Bunches)',
    'POME (Palm Oil Mill Effluent)',
    'Palm Shell',
    'Palm Kernel Cake',
    'Coconut Husk',
    'Rice Husk',
    'Sugarcane Bagasse',
    'Wood Chips',
    'Other Biomass',
    'Other',
  ];

  // Units list
  final List<String> units = [
    'kg',
    'ton',
    'liters',
    'pieces',
    'bags',
    'boxes',
    'pallets',
    'cubic meters',
    'truckloads',
  ];

  // Malaysian cities list
  final List<String> cities = [
    'Kuala Lumpur',
    'Petaling Jaya',
    'Shah Alam',
    'Subang Jaya',
    'Johor Bahru',
    'Penang',
    'Ipoh',
    'Kuching',
    'Kota Kinabalu',
    'Melaka',
    'Seremban',
    'Kuantan',
    'Kota Bharu',
    'Alor Setar',
    'Miri',
    'Sandakan',
    'Klang',
    'Kajang',
    'Ampang',
    'Putrajaya',
    'Cyberjaya',
    'Other',
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
    _addressController.dispose();
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
      debugPrint('Failed to get location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (image != null && _selectedImages.length < 5) {
                        setState(() {
                          _selectedImages.add(image);
                        });
                      }
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      final List<XFile> images = await picker.pickMultiImage(
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (images.isNotEmpty) {
                        setState(() {
                          // Add images up to max 5
                          final remaining = 5 - _selectedImages.length;
                          _selectedImages.addAll(images.take(remaining));
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _uploadStatus = 'Preparing...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please login first');
      }

      debugPrint('🚀 Starting listing submission for user: ${user.uid}');
      debugPrint('📸 Number of images to upload: ${_selectedImages.length}');

      List<String> imageUrls = [];

      // Upload images to ImgBB (free service)
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _uploadStatus = 'Uploading images...';
        });

        debugPrint('📤 Uploading images to ImgBB...');

        imageUrls = await ImageUploadService.uploadMultipleImages(
          _selectedImages,
          onProgress: (progress, current, total) {
            if (mounted) {
              setState(() {
                _uploadProgress = progress;
                _uploadStatus = 'Uploading image $current of $total...';
              });
            }
          },
        );

        debugPrint('📊 Successfully uploaded ${imageUrls.length}/${_selectedImages.length} images');

        // Show warning if some images failed
        if (imageUrls.length < _selectedImages.length && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${imageUrls.length} of ${_selectedImages.length} images uploaded successfully.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      setState(() {
        _uploadStatus = 'Saving listing...';
        _uploadProgress = 0.9;
      });

      // Prepare listing data
      final listingData = {
        'title': _titleController.text.trim(),
        'wasteType': _selectedWasteType,
        'quantity': double.tryParse(_quantityController.text) ?? 0,
        'unit': _selectedUnit,
        'pricePerUnit': double.tryParse(_priceController.text) ?? 0,
        'pickupCity': _selectedCity,
        'pickupAddress': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'contactInfo': _contactController.text.trim(),
        'imageUrls': imageUrls,
        'imageUrl': imageUrls.isNotEmpty ? imageUrls.first : null,
        'location': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude,
              }
            : null,
        'status': 'available',
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'complianceStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      debugPrint('💾 Saving listing to Firestore...');

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('listings')
          .add(listingData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Firestore save timeout');
            },
          );

      debugPrint('✅ Listing saved successfully with ID: ${docRef.id}');

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Done!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    imageUrls.isNotEmpty
                        ? 'Listing posted with ${imageUrls.length} image(s)!'
                        : 'Listing posted successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _quantityController.clear();
        _priceController.clear();
        _contactController.clear();
        _addressController.clear();
        setState(() {
          _selectedWasteType = null;
          _selectedUnit = null;
          _selectedCity = null;
          _selectedImages.clear();
        });

        // Navigate back or to marketplace
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'index': 1},
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting listing: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Failed to post listing'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitListing(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Post Listing'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
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
            tooltip: 'View Marketplace',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.info_outline),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Fresh Coffee Grounds',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Waste Type
              DropdownButtonFormField<String>(
                value: _selectedWasteType,
                decoration: InputDecoration(
                  labelText: 'Waste Type *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: wasteTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (v) => setState(() => _selectedWasteType = v),
                validator: (v) => v == null ? 'Please select waste type' : null,
              ),
              const SizedBox(height: 16),

              // Quantity and Unit Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity *',
                        hintText: '30',
                        prefixIcon: const Icon(Icons.inventory),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(v!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: units.map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price per Unit
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price per Unit (RM) *',
                  hintText: '0.20',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'RM ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Price is required';
                  if (double.tryParse(v!) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location Section
              _buildSectionHeader('Location', Icons.location_on),
              const SizedBox(height: 16),

              // Pickup City
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'Pickup City *',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: cities.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) => v == null ? 'Please select city' : null,
              ),
              const SizedBox(height: 16),

              // Detailed Address (Optional)
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Detailed Address (Optional)',
                  hintText: 'Street, building, etc.',
                  prefixIcon: const Icon(Icons.place),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),

              // GPS Location Status
              _buildLocationStatus(),
              const SizedBox(height: 24),

              // Description Section
              _buildSectionHeader('Description', Icons.description),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your item in detail...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Contact Number (Optional)
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Number (Optional)',
                  hintText: '+60 12-345 6789',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Upload Progress
              if (_isLoading) ...[
                _buildUploadProgress(),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _uploadStatus.isNotEmpty ? _uploadStatus : 'Processing...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Text(
                          'Post Listing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Compliance Info
              _buildComplianceInfo(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _uploadStatus,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedImages.length}/5',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Add Photo Button
                if (_selectedImages.length < 5)
                  InkWell(
                    onTap: _isLoading ? null : _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2E7D32),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: _isLoading ? Colors.grey : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: _isLoading ? Colors.grey : const Color(0xFF2E7D32),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selected Images
                ..._selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (!_isLoading)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Cover',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.cloud_done, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _selectedImages.isEmpty
                      ? 'Add up to 5 photos (free hosting by ImgBB)'
                      : '${_selectedImages.length} photo(s) selected • Free hosting by ImgBB',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
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
            _currentPosition != null ? Icons.location_on : Icons.location_off,
            color: _currentPosition != null
                ? const Color(0xFF2E7D32)
                : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _isLocationLoading
                ? const Text('Getting GPS location...')
                : Text(
                    _currentPosition != null
                        ? 'GPS Location Acquired'
                        : 'GPS Location Not Available',
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
    );
  }

  Widget _buildComplianceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            color: Color(0xFF2E7D32),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PCDS 2030 Compliant',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                Text(
                  'All listings are reviewed for sustainability standards.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
