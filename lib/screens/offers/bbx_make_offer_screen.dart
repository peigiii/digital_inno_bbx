import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../services/offer_service.dart';
import '../../utils/delivery_config.dart';

class BBXMakeOfferScreen extends StatefulWidget {
  final ListingModel listing;

  const BBXMakeOfferScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BBXMakeOfferScreen> createState() => _BBXMakeOfferScreenState();
}

class _BBXMakeOfferScreenState extends State<BBXMakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offerPriceController = TextEditingController();
  final _messageController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _offerService = OfferService();

  DateTime? _scheduledPickupDate;
  String _deliveryMethod = 'self_collect';   bool _isLoading = false;
  double? _discountPercentage;

  @override
  void dispose() {
    _offerPriceController.dispose();
    _messageController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

    String _formatLocation() {
    final location = widget.listing.location;
    if (location == null) return 'AddressNotLift?';

        if (location['address'] != null) {
      return location['address'].toString();
    }

        final lat = location['latitude'];
    final lng = location['longitude'];
    if (lat != null && lng != null) {
      return 'Location: $lat, $lng';
    }

    return 'AddressNotLift?';
  }

    void _calculateDiscount() {
    final offerPrice = double.tryParse(_offerPriceController.text);
    if (offerPrice != null && widget.listing.pricePerUnit > 0) {
      setState(() {
        _discountPercentage = ((widget.listing.pricePerUnit - offerPrice) / widget.listing.pricePerUnit * 100);
      });
    } else {
      setState(() {
        _discountPercentage = null;
      });
    }
  }

    Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final maxDate = now.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: maxDate,
      helpText: 'Select Est CollectionDate',
      cancelText: 'Cancel',
      confirmText: 'OK',
    );

    if (pickedDate != null) {
      setState(() {
        _scheduledPickupDate = pickedDate;
      });
    }
  }

    Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final offerPrice = double.parse(_offerPriceController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      await _offerService.createOffer(
        listingId: widget.listing.id,
        sellerId: widget.listing.userId,
        offerPrice: offerPrice,
        originalPrice: widget.listing.pricePerUnit,
        message: _messageController.text.trim(),
        scheduledPickupDate: _scheduledPickupDate,
        deliveryMethod: _deliveryMethod,
        deliveryNote: _deliveryNoteController.text.trim().isNotEmpty
            ? _deliveryNoteController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QuoteAlreadySubmit，WaitSellerReply'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SubmitQuote'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
                        _buildListingCard(),
            const SizedBox(height: 24),

                        _buildOfferPriceField(),
            const SizedBox(height: 24),

                        _buildPickupDateField(),
            const SizedBox(height: 24),

                        _buildDeliveryMethodSection(),
            const SizedBox(height: 24),

                        _buildMessageField(),
            const SizedBox(height: 24),

                        _buildHintBox(),
            const SizedBox(height: 24),

                        _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

    Widget _buildListingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listing.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${widget.listing.quantity} ${widget.listing.unit}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}/${widget.listing.unit}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildOfferPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QuoteAmount *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _offerPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'RM ',
            suffixText: '/${widget.listing.unit}',
            hintText: 'InputYour Quote',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'PleaseInputQuoteGold?';
            }
            final price = double.tryParse(value);
            if (price == null || price <= 0) {
              return 'PleaseInputValid of Amount';
            }
            return null;
          },
          onChanged: (value) {
            _calculateDiscount();
          },
        ),
        if (_discountPercentage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _discountPercentage! > 0 ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _discountPercentage! > 0 ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: _discountPercentage! > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _discountPercentage! > 0
                      ? 'Discount ${_discountPercentage!.toStringAsFixed(1)}%'
                      : 'HighAtOriginal Price ${(-_discountPercentage!).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _discountPercentage! > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

    Widget _buildPickupDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Est CollectionDate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectPickupDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  _scheduledPickupDate != null
                      ? DateFormat('yyyyYearMMMonthdd?).format(_scheduledPickupDate!)
                      : 'SelectDate',
                  style: TextStyle(
                    fontSize: 16,
                    color: _scheduledPickupDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildDeliveryMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚚 Carrier?*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

                RadioListTile<String>(
          title: const Text(
            'SelfLift',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'ToSellerPointSetLocationTake?,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatLocation(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          value: 'self_collect',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
        ),

        const SizedBox(height: 8),

                RadioListTile<String>(
          title: const Text(
            'Mail',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Seller arranges delivery?,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Shipping fee negotiable?AmountOuterPay)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          value: 'delivery',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
        ),

        const SizedBox(height: 16),

                TextFormField(
          controller: _deliveryNoteController,
          maxLines: 2,
          maxLength: 200,
          decoration: InputDecoration(
            labelText: '💬 Delivery Note?Can?',
            hintText: _deliveryMethod == 'self_collect'
                ? 'ExampleIf：HopeLookTomorrowAfternoonSelf?
                : 'ExampleIf：Hope to ship soon?,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AttachAddMessage（Optional）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Explain your needs or other info to the seller...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

    Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WarmInfo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '?QuoteValidPeriodFor 48 Hours\n'
                  '?SellerCanCanAccept、RejectOrReturnPrice\n'
                  '?PleaseSureProtectYour QuoteCombine?,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitOffer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'SubmitQuote',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}
