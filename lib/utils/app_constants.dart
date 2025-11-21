/// BBX 应用全局常量配置
library;

/// API 和网络配�?
class ApiConstants {
  static const String baseUrl = 'https://api.bbx.com'; // 生产环境
  static const String devBaseUrl = 'https://dev-api.bbx.com'; // 开发环�?
  static const String verificationUrl = 'https://bbx.com/verify'; // 合规验证URL

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);
}

/// 分页配置
class PaginationConstants {
  static const int defaultPageSize = 20;
  static const int smallPageSize = 10;
  static const int largePageSize = 50;
  static const double loadMoreThreshold = 0.9; // 滚动�?0%时加载更�?
}

/// 文件上传配置
class FileConstants {
  // 文件大小限制（字节）
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // 图片数量限制
  static const int maxListingImages = 9;
  static const int maxReviewImages = 9;
  static const int maxShippingProofImages = 5;
  static const int maxDisputeEvidenceImages = 10;

  // 图片压缩配置
  static const int avatarMaxWidth = 500;
  static const int avatarMaxHeight = 500;
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1080;
  static const int imageQuality = 85;

  // 支持的文件格�?
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx'];
}

/// 废料类型常量
class WasteTypeConstants {
  static const String efb = 'EFB (Empty Fruit Bunches)';
  static const String pome = 'POME (Palm Oil Mill Effluent)';
  static const String palmShell = 'Palm Shell';
  static const String palmFiber = 'Palm Fiber';
  static const String palmKernelCake = 'Palm Kernel Cake';
  static const String coconutHusk = 'Coconut Husk';
  static const String riceHusk = 'Rice Husk';
  static const String sugarcaneBagasse = 'Sugarcane Bagasse';
  static const String woodChips = 'Wood Chips';
  static const String otherBiomass = 'Other Biomass';

  static const List<String> allTypes = [
    efb,
    pome,
    palmShell,
    palmFiber,
    palmKernelCake,
    coconutHusk,
    riceHusk,
    sugarcaneBagasse,
    woodChips,
    otherBiomass,
  ];
}

/// 计量单位常量
class UnitConstants {
  static const String tons = 'Tons';
  static const String cubicMeters = 'Cubic Meters';
  static const String liters = 'Liters';
  static const String kilograms = 'Kilograms';
  static const String truckloads = 'Truckloads';

  static const List<String> allUnits = [
    tons,
    cubicMeters,
    liters,
    kilograms,
    truckloads,
  ];
}

/// 用户类型常量
class UserTypeConstants {
  static const String producer = 'producer';
  static const String processor = 'processor';
  static const String recycler = 'recycler';
  static const String publicUser = 'public';

  static const List<String> allTypes = [
    producer,
    processor,
    recycler,
    publicUser,
  ];

  static Map<String, String> get displayNames => {
    producer: '生产�?(Producer)',
    processor: '处理�?(Processor)',
    recycler: '回收�?(Recycler)',
    publicUser: '普通用�?,
  };
}

/// 订阅计划常量
class SubscriptionConstants {
  static const String free = 'free';
  static const String basic = 'basic';
  static const String professional = 'professional';
  static const String enterprise = 'enterprise';

  static const List<String> allPlans = [
    free,
    basic,
    professional,
    enterprise,
  ];

  static Map<String, double> get monthlyPrices => {
    free: 0,
    basic: 49.90,
    professional: 149.90,
    enterprise: 499.90,
  };

  static Map<String, String> get displayNames => {
    free: '免费�?,
    basic: '基础�?(RM 49.90/�?',
    professional: '专业�?(RM 149.90/�?',
    enterprise: '企业�?(RM 499.90/�?',
  };
}

/// 列表状态常�?
class ListingStatusConstants {
  static const String available = 'available';
  static const String pending = 'pending';
  static const String sold = 'sold';
  static const String expired = 'expired';

  static const List<String> allStatuses = [
    available,
    pending,
    sold,
    expired,
  ];
}

/// 报价状态常�?
class OfferStatusConstants {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    pending,
    accepted,
    rejected,
    cancelled,
  ];
}

/// 交易状态常�?
class TransactionStatusConstants {
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String shipped = 'shipped';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String refundRequested = 'refund_requested';
  static const String refunded = 'refunded';
  static const String refundRejected = 'refund_rejected';
  static const String disputed = 'disputed';

  static const List<String> allStatuses = [
    pending,
    paid,
    shipped,
    completed,
    cancelled,
    refundRequested,
    refunded,
    refundRejected,
    disputed,
  ];
}

/// 托管状态常�?
class EscrowStatusConstants {
  static const String held = 'held';
  static const String released = 'released';
  static const String refunded = 'refunded';
}

/// 支付方式常量
class PaymentMethodConstants {
  static const String fpx = 'fpx';
  static const String ewallet = 'ewallet';
  static const String creditCard = 'credit_card';
  static const String cash = 'cash';

  static const List<String> allMethods = [
    fpx,
    ewallet,
    creditCard,
    cash,
  ];

  static Map<String, String> get displayNames => {
    fpx: 'FPX 网银转账',
    ewallet: '电子钱包 (Touch \'n Go / GrabPay)',
    creditCard: '信用�?借记�?,
    cash: '现金支付',
  };
}

/// 认证类型常量
class VerificationTypeConstants {
  static const String phone = 'phone';
  static const String email = 'email';
  static const String business = 'business';
  static const String identity = 'identity';
  static const String bank = 'bank';

  static const List<String> allTypes = [
    phone,
    email,
    business,
    identity,
    bank,
  ];
}

/// 认证状态常�?
class VerificationStatusConstants {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  static const List<String> allStatuses = [
    pending,
    approved,
    rejected,
  ];
}

/// 争议类型常量
class DisputeTypeConstants {
  static const String notReceived = 'not_received';
  static const String wrongItem = 'wrong_item';
  static const String qualityIssue = 'quality_issue';
  static const String other = 'other';

  static const List<String> allTypes = [
    notReceived,
    wrongItem,
    qualityIssue,
    other,
  ];

  static Map<String, String> get displayNames => {
    notReceived: '未收到货�?,
    wrongItem: '货不对板',
    qualityIssue: '质量问题',
    other: '其他',
  };
}

/// 举报类型常量
class ReportTypeConstants {
  static const String falseInfo = 'false_info';
  static const String fraud = 'fraud';
  static const String qualityIssue = 'quality_issue';
  static const String spam = 'spam';
  static const String inappropriate = 'inappropriate';
  static const String other = 'other';

  static const List<String> allTypes = [
    falseInfo,
    fraud,
    qualityIssue,
    spam,
    inappropriate,
    other,
  ];
}

/// 信用等级常量
class CreditLevelConstants {
  static const String excellent = 'excellent';
  static const String good = 'good';
  static const String fair = 'fair';
  static const String average = 'average';
  static const String poor = 'poor';

  static Map<String, String> get displayNames => {
    excellent: '卓越',
    good: '优秀',
    fair: '良好',
    average: '一�?,
    poor: '较差',
  };
}

/// 管理员邮箱列表（应该从Firestore config读取，这里作为fallback�?
class AdminConstants {
  static const List<String> adminEmails = [
    'admin@bbx.com',
    'peiyin5917@gmail.com',
    'peigiii@gmail.com',
  ];
}

/// 平台费用常量
class FeeConstants {
  static const double platformFeePercent = 3.0; // 平台交易�?3%
  static const double minPlatformFee = 5.0; // 最低平台费 RM 5.00
  static const double maxPlatformFee = 500.0; // 最高平台费 RM 500.00

  static const double paymentGatewayFeePercent = 1.5; // 支付网关�?1.5%
  static const double minPaymentGatewayFee = 1.0; // 最低支付网关费 RM 1.00
}

/// 退款配�?
class RefundConstants {
  static const int disputePeriodDays = 7; // 争议�?�?
  static const int refundProcessingDays = 3; // 退款处�?�?
}

/// 评价配置
class ReviewConstants {
  static const int minReviewLength = 10; // 最�?0个字�?
  static const int maxReviewLength = 500; // 最�?00个字�?
  static const int minRating = 1;
  static const int maxRating = 5;
}

/// 积分配置
class RewardsConstants {
  static const int signUpBonus = 50; // 注册奖励50积分
  static const int listingBonus = 10; // 发布列表奖励10积分
  static const int transactionBonus = 100; // 完成交易奖励100积分
  static const int reviewBonus = 20; // 撰写评价奖励20积分

  static const int pointsPerRM = 10; // 10积分 = RM 1.00
}

/// Firestore Collection 名称
class CollectionConstants {
  static const String users = 'users';
  static const String listings = 'listings';
  static const String offers = 'offers';
  static const String transactions = 'transactions';
  static const String conversations = 'conversations';
  static const String messages = 'messages';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String verifications = 'verifications';
  static const String disputes = 'disputes';
  static const String reports = 'reports';
  static const String recyclers = 'recyclers';
  static const String rewards = 'rewards';
  static const String certificates = 'certificates';
}

/// Firebase Storage 路径
class StorageConstants {
  static const String avatars = 'avatars';
  static const String listingImages = 'listing_images';
  static const String reviewImages = 'review_images';
  static const String shippingProofs = 'shipping_proofs';
  static const String disputeEvidence = 'dispute_evidence';
  static const String reportEvidence = 'report_evidence';
  static const String verificationDocs = 'verifications';
  static const String certificates = 'certificates';
}
