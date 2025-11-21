import 'package:cloud_firestore/cloud_firestore.dart';

/// 物流更新记录模型
class LogisticsUpdateModel {
  final String id;
  final String transactionId; // 所属交易ID
  final String status; // 状态更�?
  final String? location; // 当前位置
  final String description; // 描述信息
  final String? imageUrl; // 图片证明（如取货照片�?
  final String createdBy; // 创建人ID
  final DateTime createdAt; // 创建时间

  LogisticsUpdateModel({
    required this.id,
    required this.transactionId,
    required this.status,
    this.location,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  /// �?Firestore 文档创建
  factory LogisticsUpdateModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogisticsUpdateModel.fromMap(doc.id, data);
  }

  /// �?Map 创建
  factory LogisticsUpdateModel.fromMap(String id, Map<String, dynamic> data) {
    return LogisticsUpdateModel(
      id: id,
      transactionId: data['transactionId'] ?? '',
      status: data['status'] ?? '',
      location: data['location'],
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 转换�?Map（用于Firestore�?
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'status': status,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 复制并修改部分字�?
  LogisticsUpdateModel copyWith({
    String? status,
    String? location,
    String? description,
    String? imageUrl,
  }) {
    return LogisticsUpdateModel(
      id: id,
      transactionId: transactionId,
      status: status ?? this.status,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  /// 获取状态显示文�?
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '待发�?;
      case 'picked_up':
        return '已取�?;
      case 'in_transit':
        return '运输�?;
      case 'delivered':
        return '已送达';
      case 'completed':
        return '已完�?;
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'LogisticsUpdateModel(id: $id, transactionId: $transactionId, status: $status, description: $description)';
  }
}
