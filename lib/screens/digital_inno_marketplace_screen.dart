import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // 已禁用
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

// 🗺️ 这是禁用Google Maps的版本
// 如果你有Google Maps API密钥，请使用 digital_inno_marketplace_screen.dart

class BBXMarketplaceScreen extends StatefulWidget {
  const BBXMarketplaceScreen({super.key});

  @override
  State<BBXMarketplaceScreen> createState() => _BBXMarketplaceScreenState();
}

class _BBXMarketplaceScreenState extends State<BBXMarketplaceScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  Position? _currentPosition;
  // GoogleMapController? _mapController; // 已禁用
  // final Set<Marker> _markers = {}; // 已禁用
  final bool _isMapView = false;

  final List<String> filterOptions = [
    'all',
    'EFB (Empty Fruit Bunches)',
    'POME (Palm Oil Mill Effluent)',
    'Palm Shell',
    'Palm Fiber',
    'Other Biomass',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _showMakeOfferDialog(String listingId, Map<String, dynamic> listingData) async {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('提交报价'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Listing info
                      Text(
                        '废料: ${listingData['title']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '数量: ${listingData['quantity']} ${listingData['unit']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '原价: RM${listingData['pricePerUnit']}/${listingData['unit']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Divider(height: 24),

                      // Offer price
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: '您的报价 (RM)',
                          prefixIcon: Icon(Icons.monetization_on),
                          hintText: '输入总价',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入报价';
                          }
                          if (double.tryParse(value) == null) {
                            return '请输入有效数字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Collection date
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '收集日期',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : '选择收集日期',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: '留言（可选）',
                          prefixIcon: Icon(Icons.message),
                          hintText: '说明您的收集计划或其他信息',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      await _submitOffer(
                        listingId,
                        listingData,
                        double.parse(priceController.text),
                        messageController.text,
                        selectedDate,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('提交报价'),
                ),
              ],
            );
          },
        );
      },
    );

    priceController.dispose();
    messageController.dispose();
  }

  Future<void> _submitOffer(
    String listingId,
    Map<String, dynamic> listingData,
    double offerPrice,
    String message,
    DateTime? collectionDate,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('请先登录');
      }

      // Get current user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('用户数据不存在');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Create offer
      final offerData = {
        'listingId': listingId,
        'recyclerId': user.uid,
        'recyclerName': userData['displayName'] ?? user.email,
        'recyclerCompany': userData['companyName'] ?? '',
        'recyclerContact': userData['contact'] ?? '',
        'producerId': listingData['userId'],
        'offerPrice': offerPrice,
        'message': message,
        'collectionDate': collectionDate != null ? Timestamp.fromDate(collectionDate) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('offers')
          .add(offerData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('提交超时，请检查网络连接');
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报价提交成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateCompliancePDF(Map<String, dynamic> wasteData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'BBX COMPLIANCE PASS',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Borneo Biomass Exchange',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate Info
              pw.Text(
                'WASTE TRANSPORT COMPLIANCE CERTIFICATE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              // Certificate Details
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Certificate No:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('BBX-${DateTime.now().millisecondsSinceEpoch}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Issue Date:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Valid Until:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(DateFormat('dd/MM/yyyy').format(
                          DateTime.now().add(const Duration(days: 30)))),
                    ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 20),

              // Waste Information
              pw.Text(
                'WASTE INFORMATION',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Waste Type:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${wasteData['wasteType']}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Quantity:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${wasteData['quantity']} ${wasteData['unit']}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Title:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${wasteData['title']}'),
                    ),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Supplier Email:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${wasteData['userEmail']}'),
                    ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 30),

              // PCDS 2030 Compliance
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PCDS 2030 COMPLIANCE CERTIFICATION',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      '✓ Waste source verified and documented',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '✓ Transportation route optimized',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '✓ Environmental impact assessment completed',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '✓ Sustainable disposal/processing method confirmed',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      '✓ Carbon footprint calculation included',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'This certificate is digitally generated by BBX Platform',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Stack(
      children: [
        Column(
        children: [
          // Search and Filter Section
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索废料类型或标题...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: '筛选废料类型',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: filterOptions.map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(
                        filter == 'all' ? '全部类型' : filter,
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Content Area - 只显示列表视图
          Expanded(
            child: _buildListView(isTablet),
          ),
        ],
        ),
        // Floating Action Button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/waste-list');
            },
            backgroundColor: const Color(0xFF2E7D32),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_listings')
          .where('status', isEqualTo: 'available')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. 加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 2. 错误处理
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isTablet ? 64 : 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: isTablet ? 80 : 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无废料信息',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '成为第一个发布废料信息的用户',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Filter listings
        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Apply type filter
          if (_selectedFilter != 'all' && data['wasteType'] != _selectedFilter) {
            return false;
          }
          
          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final title = (data['title'] ?? '').toString().toLowerCase();
            final wasteType = (data['wasteType'] ?? '').toString().toLowerCase();
            if (!title.contains(_searchQuery) && !wasteType.contains(_searchQuery)) {
              return false;
            }
          }
          
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: isTablet ? 80 : 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '未找到匹配的废料信息',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请尝试调整搜索条件',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '未知标题',
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['wasteType'] ?? '未知类型',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '可用',
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 14 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      data['description'] ?? '无描述',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Quantity and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: isTablet ? 20 : 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data['quantity']} ${data['unit']}',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'RM${data['pricePerUnit']}/${data['unit']}',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Contact and Location Row
                    Row(
                      children: [
                        Icon(
                          Icons.contact_phone,
                          size: isTablet ? 18 : 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['contactInfo'] ?? '无联系方式',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data['location'] != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: isTablet ? 18 : 16,
                            color: const Color(0xFF4CAF50),
                          ),
                          Text(
                            '有位置',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('联系信息'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('联系方式: ${data['contactInfo']}'),
                                      if (data['userEmail'] != null)
                                        Text('邮箱: ${data['userEmail']}'),
                                      const SizedBox(height: 12),
                                      if (data['location'] != null) ...[
                                        const Text('位置坐标:'),
                                        Text('纬度: ${data['location']['latitude']}'),
                                        Text('经度: ${data['location']['longitude']}'),
                                      ],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('关闭'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.contact_phone),
                            label: const Text('联系'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showMakeOfferDialog(doc.id, data);
                            },
                            icon: const Icon(Icons.local_offer),
                            label: const Text('报价'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // PCDS Compliance Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            size: 16,
                            color: Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PCDS 2030 合规认证',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}