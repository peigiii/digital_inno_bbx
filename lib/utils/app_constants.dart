/// BBX App Global Constants
library;

/// API and Network Config
class ApiConstants {
  static const String baseUrl = 'https://api.bbx.com'; // Production
  static const String devBaseUrl = 'https://dev-api.bbx.com'; // Dev
  static const String verificationUrl = 'https://bbx.com/verify'; // Compliance

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);
}

/// Pagination Config
class PaginationConstants {
  static const int defaultPageSize = 20;
  static const int smallPageSize = 10;
  static const int largePageSize = 50;
  static const double loadMoreThreshold = 0.9; // Load more at 90% scroll
}

/// File Upload Config
class FileConstants {
  // File Size Limits (Bytes)
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Image Count Limits
  static const int maxListingImages = 9;
  static const int maxReviewImages = 9;
  static const int maxShippingProofImages = 5;
  static const int maxDisputeEvidenceImages = 10;

  // Image Compression Config
  static const int avatarMaxWidth = 500;
  static const int avatarMaxHeight = 500;
  static const int imageMaxWidth = 1920;
  static const int imageMaxHeight = 1080;
  static const int imageQuality = 85;

  // Supported File Formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedDocumentFormats = ['pdf', 'doc', 'docx'];
}

/// Waste Type Constants
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

/// Unit Constants
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

/// User Type Constants
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
    producer: 'Producer',
    processor: 'Processor',
    recycler: 'Recycler',
    publicUser: 'Public User',
  };
}

/// Subscription Plan Constants
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
    free: 'Free',
    basic: 'Basic (RM 49.90/m)',
    professional: 'Professional (RM 149.90/m)',
    enterprise: 'Enterprise (RM 499.90/m)',
  };
}

/// Listing Status Constants
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

/// Offer Status Constants
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

/// Transaction Status Constants
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

/// Escrow Status Constants
class EscrowStatusConstants {
  static const String held = 'held';
  static const String released = 'released';
  static const String refunded = 'refunded';
}

/// Payment Method Constants
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
    fpx: 'FPX Online Banking',
    ewallet: 'E-Wallet (Touch \'n Go / GrabPay)',
    creditCard: 'Credit/Debit Card',
    cash: 'Cash',
  };
}

/// Verification Type Constants
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

/// Verification Status Constants
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

/// Dispute Type Constants
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
    notReceived: 'Item Not Received',
    wrongItem: 'Wrong Item',
    qualityIssue: 'Quality Issue',
    other: 'Other',
  };
}

/// Report Type Constants
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

/// Credit Level Constants
class CreditLevelConstants {
  static const String excellent = 'excellent';
  static const String good = 'good';
  static const String fair = 'fair';
  static const String average = 'average';
  static const String poor = 'poor';

  static Map<String, String> get displayNames => {
    excellent: 'Excellent',
    good: 'Good',
    fair: 'Fair',
    average: 'Average',
    poor: 'Poor',
  };
}

/// Admin Email List
class AdminConstants {
  static const List<String> adminEmails = [
    'admin@bbx.com',
    'peiyin5917@gmail.com',
    'peigiii@gmail.com',
  ];
}

/// Platform Fee Constants
class FeeConstants {
  static const double platformFeePercent = 3.0; // 3% Platform Fee
  static const double minPlatformFee = 5.0; // Min RM 5.00
  static const double maxPlatformFee = 500.0; // Max RM 500.00

  static const double paymentGatewayFeePercent = 1.5; // 1.5% Gateway Fee
  static const double minPaymentGatewayFee = 1.0; // Min RM 1.00
}

/// Refund Config
class RefundConstants {
  static const int disputePeriodDays = 7; // 7 days dispute period
  static const int refundProcessingDays = 3; // 3 days processing
}

/// Review Config
class ReviewConstants {
  static const int minReviewLength = 10; // Min 10 chars
  static const int maxReviewLength = 500; // Max 500 chars
  static const int minRating = 1;
  static const int maxRating = 5;
}

/// Rewards Config
class RewardsConstants {
  static const int signUpBonus = 50; // Sign up bonus
  static const int listingBonus = 10; // Listing bonus
  static const int transactionBonus = 100; // Transaction bonus
  static const int reviewBonus = 20; // Review bonus

  static const int pointsPerRM = 10; // 10 points = RM 1.00
}

/// Firestore Collection Names
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

/// Firebase Storage Paths
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
