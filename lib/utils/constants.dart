import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF1F8E9);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 12.0;

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

class WasteTypes {
  static const List<String> all = [
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
}

class Units {
  static const List<String> all = [
    'Tons',
    'Cubic Meters',
    'Liters',
    'Kilograms',
    'Truckloads',
  ];
}

class UserTypes {
  static const String producer = 'producer';
  static const String processor = 'processor';
  static const String public = 'public';
  static const String recycler = 'recycler';
}

class OfferStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
}

class ListingStatus {
  static const String available = 'available';
  static const String sold = 'sold';
  static const String expired = 'expired';
}

class SubscriptionPlans {
  static const String free = 'Free';
  static const String pro = 'Pro';
  static const String businessA = 'Business A';
  static const String businessB = 'Business B';

  static const Map<String, double> prices = {
    free: 0,
    pro: 199,
    businessA: 299,
    businessB: 399,
  };

  static const Map<String, int> maxListings = {
    free: 5,
    pro: -1, // unlimited
    businessA: -1,
    businessB: -1,
  };
}
