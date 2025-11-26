import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BBXCertificatesScreen extends StatefulWidget {
  final String? userId; 
  const BBXCertificatesScreen({
    super.key,
    this.userId,
  });

  @override
  State<BBXCertificatesScreen> createState() => _BBXCertificatesScreenState();
}

class _BBXCertificatesScreenState extends State<BBXCertificatesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool get _isOwnProfile => widget.userId == null || widget.userId == _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final displayUserId = widget.userId ?? _auth.currentUser?.uid;

    if (displayUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CapitalQualityCertificate')),
        body: const Center(child: Text('PleaseFirstLogin')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CapitalQualityCertificate'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('certificates')
            .where('userId', isEqualTo: displayUserId)
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final certificates = snapshot.data!.docs;

          if (certificates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No certificate',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCertificateDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Upload Certificate'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final doc = certificates[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCertificateCard(doc.id, data);
                  },
                ),
              ),
              if (_isOwnProfile)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCertificateDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Upload Certificate'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCertificateCard(String certificateId, Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final status = data['status'] ?? 'pending';

    return GestureDetector(
      onTap: () => _showCertificateDetail(certificateId, data),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.description,
                              size: 48, color: Colors.grey[400]),
                        ),
                                    Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(status),
                  ),
                ],
              ),
            ),
                        Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCertificateTypeLabel(type),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (data['issuer'] != null)
                    Text(
                      data['issuer'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'AlreadyRecognize?;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'NotPass';
        break;
      default:
        color = Colors.orange;
        label = 'WaitAudit?;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddCertificateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddCertificateSheet(),
    );
  }

  void _showCertificateDetail(String certificateId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                        if (data['imageUrl'] != null)
              Image.network(
                data['imageUrl'],
                fit: BoxFit.contain,
              ),
                        Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCertificateTypeLabel(data['type']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data['issuer'] != null)
                    Text('AwardSendInstitution: ${data['issuer']}'),
                  if (data['number'] != null)
                    Text('CertificateNo.: ${data['number']}'),
                  if (data['validUntil'] != null)
                    Text('ValidPeriodTo: ${_formatDate(data['validUntil'])}'),
                  const SizedBox(height: 8),
                  _buildStatusBadge(data['status'] ?? 'pending'),
                  if (data['reviewNote'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'AuditRemark: ${data['reviewNote']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
                        Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'business_license':
        return 'Business LicensePhoto';
      case 'industry_cert':
        return 'Industry QualsCertificate';
      case 'iso_cert':
        return 'ISO Authenticate';
      case 'environmental_cert':
        return 'RingProtectAuthenticate';
      case 'quality_cert':
        return 'QualityAuthenticate';
      case 'safety_cert':
        return 'SecureProduction License?';
      case 'other':
        return 'OtherCertificate';
      default:
        return 'Certificate';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class AddCertificateSheet extends StatefulWidget {
  const AddCertificateSheet({super.key});

  @override
  State<AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<AddCertificateSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'business_license';
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  DateTime? _validUntil;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _issuerController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('certificates/$userId/$fileName');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _imageUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Failed: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PleaseUpload CertificateImg?)),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;

      await _firestore.collection('certificates').add({
        'userId': userId,
        'type': _selectedType,
        'issuer': _issuerController.text,
        'number': _numberController.text,
        'validUntil': _validUntil != null ? Timestamp.fromDate(_validUntil!) : null,
        'imageUrl': _imageUrl,
        'status': 'pending',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CertificateAlreadySubmit，WaitPending Audit')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              const Text(
                'Upload Certificate',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

                            const Text('Certificate Type', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'business_license', child: Text('Business LicensePhoto')),
                  DropdownMenuItem(value: 'industry_cert', child: Text('Industry QualsCertificate')),
                  DropdownMenuItem(value: 'iso_cert', child: Text('ISO Authenticate')),
                  DropdownMenuItem(value: 'environmental_cert', child: Text('RingProtectAuthenticate')),
                  DropdownMenuItem(value: 'quality_cert', child: Text('QualityAuthenticate')),
                  DropdownMenuItem(value: 'safety_cert', child: Text('SecureProduction License?)),
                  DropdownMenuItem(value: 'other', child: Text('OtherCertificate')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

                            const Text('AwardSendInstitution', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'ExampleIf：CountryAQSIQ',
                ),
              ),
              const SizedBox(height: 16),

                            const Text('CertificateNo.', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _numberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'CertificateNo.',
                ),
              ),
              const SizedBox(height: 16),

                            const Text('ValidPeriodTo (Can?', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _validUntil = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _validUntil != null
                        ? '${_validUntil!.year}-${_validUntil!.month.toString().padLeft(2, '0')}-${_validUntil!.day.toString().padLeft(2, '0')}'
                        : 'SelectDate',
                  ),
                ),
              ),
              const SizedBox(height: 24),

                            const Text('CertificateImage', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (_imageUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_imageUrl!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageUrl = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('SelectImage'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              const SizedBox(height: 24),

                            SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('SubmitAudit'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
