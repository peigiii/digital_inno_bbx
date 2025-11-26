import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BBXWriteReviewScreen extends StatefulWidget {
  final String transactionId;
  final String revieweeId;

  const BBXWriteReviewScreen({
    super.key,
    required this.transactionId,
    required this.revieweeId,
  });

  @override
  State<BBXWriteReviewScreen> createState() => _BBXWriteReviewScreenState();
}

class _BBXWriteReviewScreenState extends State<BBXWriteReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

    double _overallRating = 5.0;
  double _descriptionScore = 5.0;
  double _serviceScore = 5.0;
  double _deliveryScore = 5.0;

    final List<String> _positiveTags = ['Quality?, 'Service?, 'SendGoods?, 'Package?, 'PriceAffordable'];
  final List<String> _negativeTags = ['Quality?, 'Service?, 'SendGoods?, 'Package?, 'DescNoSymbol'];
  final Set<String> _selectedTags = {};

    final TextEditingController _commentController = TextEditingController();

    final List<String> _images = [];
  bool _isUploading = false;

    bool _isAnonymous = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MostManyUp?images?)),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      setState(() => _isUploading = true);

      for (var image in images) {
        if (_images.length >= 9) break;

        final userId = _auth.currentUser!.uid;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('review_images/$userId/$fileName');

        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();

        setState(() {
          _images.add(url);
        });
      }

      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Failed: $e')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty && _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in review content or select tags')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final userId = _auth.currentUser!.uid;

      await _firestore.collection('reviews').add({
        'transactionId': widget.transactionId,
        'reviewerId': userId,
        'revieweeId': widget.revieweeId,
        'overallRating': _overallRating,
        'descriptionScore': _descriptionScore,
        'serviceScore': _serviceScore,
        'deliveryScore': _deliveryScore,
        'tags': _selectedTags.toList(),
        'comment': _commentController.text,
        'images': _images,
        'isAnonymous': _isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ReviewAlreadyLift?)),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WriteReview'),
        elevation: 0,
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _submitReview,
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    const Text(
                    'TotalBodyReviewScore',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _overallRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildInteractiveStars(
                          _overallRating,
                          (rating) => setState(() => _overallRating = rating),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    'DetailedReviewScore',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildScoreSlider(
                    'DescMutualSymbol?,
                    _descriptionScore,
                    (value) => setState(() => _descriptionScore = value),
                  ),
                  _buildScoreSlider(
                    'ServiceStateDegree',
                    _serviceScore,
                    (value) => setState(() => _serviceScore = value),
                  ),
                  _buildScoreSlider(
                    'LogisticsSpeed',
                    _deliveryScore,
                    (value) => setState(() => _deliveryScore = value),
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    'QuickReview?,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RightFaceReview',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _positiveTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        selectedColor: Colors.green[100],
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NegativeFaceReview',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _negativeTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        selectedColor: Colors.red[100],
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    'Review Content',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'ShareYour UseBodyTest...',
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    'Upload Image (Most??',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_images.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _images.length + (_images.length < 9 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          return _buildAddImageButton();
                        }
                        return _buildImageItem(_images[index], index);
                      },
                    )
                  else
                    _buildAddImageButton(),
                  const SizedBox(height: 24),

                                    SwitchListTile(
                    title: const Text('AnonymousReview'),
                    subtitle: const Text('Other users will not see your identity info?),
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() => _isAnonymous = value);
                    },
                  ),
                  const SizedBox(height: 24),

                                    SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      child: const Text('SubmitReview'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInteractiveStars(double rating, Function(double) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: 40,
            color: Colors.amber,
          ),
        );
      }),
    );
  }

  Widget _buildScoreSlider(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < value ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImages,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(
                    'AddImage',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImageItem(String url, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _images.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
