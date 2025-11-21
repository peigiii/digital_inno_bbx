import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class BBXUpdateLogisticsScreen extends StatefulWidget {
  final String transactionId;

  const BBXUpdateLogisticsScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<BBXUpdateLogisticsScreen> createState() => _BBXUpdateLogisticsScreenState();
}

class _BBXUpdateLogisticsScreenState extends State<BBXUpdateLogisticsScreen> {
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedStatus;
  File? _selectedPhoto;
  bool _isSubmitting = false;
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await _transactionService.getTransactionDetails(widget.transactionId);
      setState(() {
        _transaction = transaction;
        _selectedStatus = _getNextStatus(transaction.shippingStatus);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load failed: $e')),
        );
      }
    }
  }

    String? _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'picked_up';
      case 'picked_up':
        return 'in_transit';
      case 'in_transit':
        return 'delivered';
      default:
        return null;
    }
  }

    List<String> _getAvailableStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return ['picked_up'];
      case 'picked_up':
        return ['in_transit', 'delivered'];
      case 'in_transit':
        return ['delivered'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Update Logistics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final availableStatuses = _getAvailableStatuses(_transaction!.shippingStatus);

    if (availableStatuses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Update Logistics')),
        body: const Center(
          child: Text('Cannot update logistics status in current state'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Logistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _transaction!.shippingStatusDisplay,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

                        const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select New Status',
              ),
              items: availableStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusDisplayText(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 24),

                        const Text(
              'Location (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'e.g. Warehouse KL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 24),

                        const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Describe current logistics status',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Enter description...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

                        const Text(
              'Photo Proof (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: _selectedPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedPhoto!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedPhoto = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (_selectedPhoto != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Photo'),
              ),
            ],

            const SizedBox(height: 32),

                        Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

    Future<void> _pickPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

                final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size must be less than 5MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedPhoto = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pick photo failed: $e')),
        );
      }
    }
  }

    Future<void> _submitUpdate() async {
        if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select status')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _transactionService.updateShippingStatus(
        transactionId: widget.transactionId,
        newStatus: _selectedStatus!,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        description: _descriptionController.text.trim(),
        photo: _selectedPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logistics updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

    String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }
}
