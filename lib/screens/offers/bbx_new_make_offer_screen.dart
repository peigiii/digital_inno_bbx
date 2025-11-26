import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_notification.dart';
import '../../models/listing_model.dart';

class BBXNewMakeOfferScreen extends StatefulWidget {
  final Listing listing;

  const BBXNewMakeOfferScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BBXNewMakeOfferScreen> createState() => _BBXNewMakeOfferScreenState();
}

class _BBXNewMakeOfferScreenState extends State<BBXNewMakeOfferScreen> {
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _pickupDate;
  String _deliveryMethod = 'pickup'; // pickup ?delivery
  String? _selectedQuickAmount;
  bool _isSubmitting = false;

  double get _offerAmount {
    return double.tryParse(_offerController.text) ?? 0.0;
  }

  double get _discount {
    if (_offerAmount == 0 || widget.listing.pricePerUnit == 0) return 0;
    return ((widget.listing.pricePerUnit - _offerAmount) /
            widget.listing.pricePerUnit * 100);
  }

  Color get _discountColor {
    if (_discount < 5) return AppTheme.neutral500;
    if (_discount < 10) return AppTheme.warning;
    if (_discount < 20) return AppTheme.success;
    return AppTheme.error;
  }

  double get _totalAmount {
    final platformFee = _offerAmount * 0.03;
    return _offerAmount + platformFee;
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                    Container(
            margin: const EdgeInsets.only(top: AppTheme.spacing12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutral400,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),

                    Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                const Text('SubmitQuote', style: AppTheme.heading2),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.neutral600,
                ),
              ],
            ),
          ),

                    Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    _buildListingCard(),

                  const SizedBox(height: AppTheme.spacing24),

                                    _buildOfferAmountInput(),

                  const SizedBox(height: AppTheme.spacing16),

                                    _buildQuickAmounts(),

                  const SizedBox(height: AppTheme.spacing24),

                                    _buildDeliveryInfo(),

                  const SizedBox(height: AppTheme.spacing24),

                                    _buildMessage(),

                  const SizedBox(height: AppTheme.spacing24),

                                    _buildPriceDetails(),
                ],
              ),
            ),
          ),

                    _buildBottomAction(),
        ],
      ),
    );
  }

    Widget _buildListingCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Image.network(
              widget.listing.images.isNotEmpty ? widget.listing.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: AppTheme.neutral200,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: AppTheme.body1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}',
                      style: AppTheme.caption.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.neutral500,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}',
                      style: AppTheme.heading4.copyWith(
                        color: AppTheme.primary500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildOfferAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Quote', style: AppTheme.heading3),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.neutral300),
            borderRadius: AppTheme.borderRadiusLarge,
          ),
          child: TextField(
            controller: _offerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: AppTheme.bold,
              color: AppTheme.primary500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                fontSize: 40,
                fontWeight: AppTheme.bold,
                color: AppTheme.primary500,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedQuickAmount = null;
              });
            },
          ),
        ),
        if (_offerAmount > 0) ...[
          const SizedBox(height: AppTheme.spacing8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: _discountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'CompareOrig?{_discount >= 0 ? "? : "?} ${_discount.abs().toStringAsFixed(1)}%',
                style: AppTheme.caption.copyWith(
                  color: _discountColor,
                  fontWeight: AppTheme.semibold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

    Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Select', style: AppTheme.body2),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAmountButton('Original Price9?, 0.9),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildQuickAmountButton('Original Price8?, 0.8),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildQuickAmountButton('Original Price7?, 0.7),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, double discount) {
    final isSelected = _selectedQuickAmount == label;
    final amount = widget.listing.pricePerUnit * discount;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuickAmount = label;
          _offerController.text = amount.toStringAsFixed(2);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary500 : AppTheme.neutral100,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Text(
          label,
          style: AppTheme.body2.copyWith(
            color: isSelected ? Colors.white : AppTheme.neutral700,
            fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

    Widget _buildDeliveryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Info', style: AppTheme.heading3),
        const SizedBox(height: AppTheme.spacing12),

                ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary500),
          title: const Text('Receive GoodsDate', style: AppTheme.body1),
          trailing: Text(
            _pickupDate != null
                ? '${_pickupDate!.month}?{_pickupDate!.day}?
                : 'SelectDate',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() {
                _pickupDate = date;
              });
            }
          },
        ),

        const Divider(),

                const Text('Receiving Method', style: AppTheme.body1),
        const SizedBox(height: AppTheme.spacing8),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'pickup',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
          title: Row(
            children: [
              const Icon(Icons.directions_car_rounded, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              const Text('SelfLift'),
            ],
          ),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'delivery',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
          title: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              const Text('SendGoods'),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '(May charge extra fees)',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

    Widget _buildMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Message', style: AppTheme.heading3),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '(Can?',
              style: AppTheme.caption.copyWith(
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Explain your needs to the seller?..',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

    Widget _buildPriceDetails() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('PriceDetail', style: AppTheme.body1),
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: Column(
            children: [
              _buildPriceRow('QuoteAmount', _offerAmount),
              const SizedBox(height: AppTheme.spacing8),
              _buildPriceRow('PlatformService?(3%)', _offerAmount * 0.03),
              const Divider(height: AppTheme.spacing24),
              _buildPriceRow(
                'Estimated Total',
                _totalAmount,
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTheme.heading4
              : AppTheme.body2.copyWith(color: AppTheme.neutral600),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: isTotal
              ? AppTheme.heading3.copyWith(color: AppTheme.primary500)
              : AppTheme.body2,
        ),
      ],
    );
  }

    Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.neutral300, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated Total', style: AppTheme.body1),
                Text(
                  'RM ${_totalAmount.toStringAsFixed(2)}',
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.primary500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            BBXPrimaryButton(
              text: 'SubmitQuote',
              isLoading: _isSubmitting,
              onPressed: _offerAmount > 0 && _pickupDate != null
                  ? _submitOffer
                  : null,
            ),
          ],
        ),
      ),
    );
  }

    Future<void> _submitOffer() async {
    if (_offerAmount == 0) {
      BBXNotification.showError(context, 'PleaseInputQuoteGold?);
      return;
    }

    if (_pickupDate == null) {
      BBXNotification.showError(context, 'Select receivingDate');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'PleaseFirstLogin';

      await FirebaseFirestore.instance.collection('offers').add({
        'listingId': widget.listing.id,
        'sellerId': widget.listing.userId,
        'buyerId': user.uid,
        'offerPrice': _offerAmount,
        'originalPrice': widget.listing.pricePerUnit,
        'quantity': widget.listing.quantity,
        'totalAmount': _totalAmount,
        'deliveryMethod': _deliveryMethod,
        'pickupDate': Timestamp.fromDate(_pickupDate!),
        'message': _messageController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

            showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              const Text('QuoteAlreadyLift?, style: AppTheme.heading2),
              const SizedBox(height: AppTheme.spacing8),
              const Text(
                'SellerWillAt24HoursInnerReturn?,
                style: AppTheme.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            BBXPrimaryButton(
              text: 'View MyQuote',
              onPressed: () {
                Navigator.pop(context);                 Navigator.pop(context);                 Navigator.pushNamed(context, '/my-offers');
              },
            ),
          ],
        ),
      );

            Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);           Navigator.pop(context);         }
      });
    } catch (e) {
      BBXNotification.showError(context, 'Submission failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
