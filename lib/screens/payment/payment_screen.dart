import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/subscription.dart';
import '../../models/event.dart';
import '../../providers/events_provider.dart';
import '../../services/payment_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final LiveEvent? ppvEvent;
  const PaymentScreen({super.key, this.ppvEvent});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _selectedPlanIndex = 1; // Default: monthly
  PaymentMethod? _selectedMethod;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _resultMessage;
  bool? _resultSuccess;

  bool get _isPpv => widget.ppvEvent != null;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isPpv ? 'Acheter l\'accès PPV' : 'S\'abonner à OmniFlix'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription plans or PPV info
            if (_isPpv)
              _PpvInfoCard(event: widget.ppvEvent!)
            else
              _PlanSelector(
                selectedIndex: _selectedPlanIndex,
                onSelect: (i) => setState(() => _selectedPlanIndex = i),
              ),

            const SizedBox(height: 24),

            // Mobile Money provider selection
            const Text(
              'Choisir le mode de paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...AppConstants.mobileMoneyProviders.map((provider) => _ProviderCard(
                  provider: provider,
                  selected: _selectedMethod?.name == provider['id'],
                  onTap: () => setState(() {
                    _selectedMethod = PaymentMethod.values.firstWhere(
                      (m) => m.name == provider['id'],
                      orElse: () => PaymentMethod.airtel,
                    );
                  }),
                )),

            const SizedBox(height: 20),

            // Phone number input
            const Text(
              'Numéro de téléphone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, letterSpacing: 1),
              decoration: const InputDecoration(
                prefixText: '+243 ',
                prefixStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 16),
                hintText: '8X XXX XXXX',
                counterText: '',
              ),
              maxLength: 9,
            ),

            const SizedBox(height: 8),
            Text(
              'Entrez le numéro associé à votre compte Mobile Money',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),

            const SizedBox(height: 24),

            // Result message
            if (_resultMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (_resultSuccess ?? false)
                      ? AppColors.live.withOpacity(0.1)
                      : AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_resultSuccess ?? false)
                        ? AppColors.live.withOpacity(0.4)
                        : AppColors.secondary.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_resultSuccess ?? false)
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: (_resultSuccess ?? false)
                          ? AppColors.live
                          : AppColors.secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _resultMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: (_resultSuccess ?? false)
                              ? AppColors.live
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.bgCardLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Security note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded,
                      color: AppColors.live, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé. Vous recevrez une confirmation sur votre téléphone.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    final amount = _isPpv
        ? widget.ppvEvent!.priceFc
        : (_selectedPlanIndex == 0
            ? AppConstants.dailyPriceFc
            : AppConstants.monthlyPriceFc);
    return 'Payer ${Formatters.formatPrice(amount)}';
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      _showSnack('Veuillez choisir un mode de paiement');
      return;
    }
    if (_phoneController.text.length < 8) {
      _showSnack('Veuillez entrer un numéro valide');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    final service = ref.read(paymentServiceProvider);
    PaymentResult result;

    if (_isPpv) {
      result = await service.payForEvent(
        eventId: widget.ppvEvent!.id,
        priceFc: widget.ppvEvent!.priceFc,
        method: _selectedMethod!,
        phoneNumber: '+243${_phoneController.text}',
      );
    } else {
      final plan = _selectedPlanIndex == 0
          ? SubscriptionType.daily
          : SubscriptionType.monthly;
      result = await service.initiatePayment(
        method: _selectedMethod!,
        plan: plan,
        phoneNumber: '+243${_phoneController.text}',
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _resultMessage = result.message;
        _resultSuccess = result.isSuccess;
      });

      if (result.isSuccess) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.bgCard));
  }
}

// -- Sub-widgets --

class _PlanSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const _PlanSelector(
      {required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir votre formule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PlanCard(
                name: 'Pass Journée',
                price: AppConstants.dailyPriceFc,
                duration: '1 jour',
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PlanCard(
                name: 'Mensuel',
                price: AppConstants.monthlyPriceFc,
                duration: '30 jours',
                selected: selectedIndex == 1,
                onTap: () => onSelect(1),
                isBest: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _FeatureRow(icon: Icons.live_tv_rounded, text: 'TV en Direct illimité'),
              _FeatureRow(icon: Icons.movie_rounded, text: 'Films & Séries en Français'),
              _FeatureRow(icon: Icons.sports_esports_rounded, text: 'Catalogue de Jeux'),
              _FeatureRow(icon: Icons.cast_rounded, text: 'Casting TV / Projecteur'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final int price;
  final String duration;
  final bool selected;
  final VoidCallback onTap;
  final bool isBest;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.duration,
    required this.selected,
    required this.onTap,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.bgCardLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MEILLEUR PRIX',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              )
            else
              const SizedBox(height: 14),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatPrice(price),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '/ $duration',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.live),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PpvInfoCard extends StatelessWidget {
  final LiveEvent event;
  const _PpvInfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ppv.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (event.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(event.subtitle!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_open_rounded,
                  size: 16, color: AppColors.ppv),
              const SizedBox(width: 6),
              Text(
                'Accès unique: ${Formatters.formatPrice(event.priceFc)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ppv,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, String> provider;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderCard(
      {required this.provider, required this.selected, required this.onTap});

  Color get _providerColor {
    try {
      final hex = provider['color']!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _providerColor.withOpacity(0.1) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _providerColor : AppColors.bgCardLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Provider icon placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _providerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  provider['name']![0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _providerColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider['name']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? _providerColor : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'USSD: ${provider['ussd']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? _providerColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _providerColor : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
