import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/subscription.dart';
import '../../models/event.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_logo.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final LiveEvent? ppvEvent;
  const PaymentScreen({super.key, this.ppvEvent});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _regionTab;

  int _selectedPlanIndex = 1; // 0 = daily, 1 = monthly
  PaymentMethod? _selectedMethod;
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPending = false;
  String? _resultMessage;
  bool? _resultSuccess;
  String? _ussdCode;

  bool get _isPpv => widget.ppvEvent != null;
  bool get _isDrcTab => _regionTab.index == 0;

  SubscriptionType get _selectedPlan =>
      _selectedPlanIndex == 0 ? SubscriptionType.daily : SubscriptionType.monthly;

  int get _amountFc => _isPpv
      ? widget.ppvEvent!.priceFc
      : (_selectedPlanIndex == 0 ? AppConstants.dailyPriceFc : AppConstants.monthlyPriceFc);

  double get _amountUsd => _isPpv
      ? (_amountFc / 2850)
      : (_selectedPlanIndex == 0 ? AppConstants.dailyPriceUsd : AppConstants.monthlyPriceUsd);

  double get _amountEur => _isPpv
      ? (_amountFc / 3000)
      : (_selectedPlanIndex == 0 ? AppConstants.dailyPriceEur : AppConstants.monthlyPriceEur);

  @override
  void initState() {
    super.initState();
    _regionTab = TabController(length: 2, vsync: this);
    _regionTab.addListener(() => setState(() {
          _selectedMethod = null;
          _resetResult();
        }));
  }

  @override
  void dispose() {
    _regionTab.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _resetResult() {
    _resultMessage = null;
    _resultSuccess = null;
    _ussdCode = null;
    _isPending = false;
  }

  // ── DRC payment flow ────────────────────────────────────────────────────────

  Future<void> _processMobileMoney() async {
    if (_selectedMethod == null) {
      _showSnack('Choisissez un mode de paiement');
      return;
    }
    if (_phoneController.text.length < 8) {
      _showSnack('Entrez votre numéro de téléphone');
      return;
    }
    setState(() { _isLoading = true; _resetResult(); });

    final service = ref.read(paymentServiceProvider);
    final code = service.getUssdCode(_selectedMethod!, _amountFc);

    setState(() {
      _isLoading = false;
      _isPending = true;
      _ussdCode = code;
      _resultMessage = 'Composez ce code sur votre téléphone et confirmez avec votre PIN.';
    });

    // Immediately open the dialer
    await service.dialUssd(_selectedMethod!, _amountFc);
  }

  Future<void> _confirmMobileMoney() async {
    setState(() => _isLoading = true);
    final service = ref.read(paymentServiceProvider);

    PaymentResult result;
    if (_isPpv) {
      await service.confirmEventAccess(widget.ppvEvent!.id);
      result = PaymentResult(
        isSuccess: true, isPending: false,
        message: 'Accès PPV confirmé ! Profitez du spectacle.',
        amountFc: _amountFc,
      );
    } else {
      result = await service.confirmMobileMoneyPayment(
        plan: _selectedPlan,
        amountFc: _amountFc,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isPending = false;
        _ussdCode = null;
        _resultMessage = result.message;
        _resultSuccess = result.isSuccess;
      });
      if (result.isSuccess) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  // ── International PayPal flow ───────────────────────────────────────────────

  Future<void> _openPayPal() async {
    setState(() { _isLoading = true; _resetResult(); });
    final service = ref.read(paymentServiceProvider);
    final opened = await service.openPayPal(amountUsd: _amountUsd);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (opened) {
        _isPending = true;
        _resultMessage = 'Finalisez le paiement dans PayPal, '
            'puis revenez ici et appuyez sur "Confirmer".';
      } else {
        _resultSuccess = false;
        _resultMessage = 'Impossible d\'ouvrir PayPal. Vérifiez votre connexion.';
      }
    });
  }

  Future<void> _confirmPayPal() async {
    setState(() => _isLoading = true);
    final service = ref.read(paymentServiceProvider);

    PaymentResult result;
    if (_isPpv) {
      await service.confirmEventAccess(widget.ppvEvent!.id);
      result = PaymentResult(
        isSuccess: true, isPending: false,
        message: 'Accès PPV confirmé ! Profitez du spectacle.',
        amountFc: _amountFc,
      );
    } else {
      result = await service.confirmPayPalPayment(
        plan: _selectedPlan,
        amountUsd: _amountUsd,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isPending = false;
        _resultMessage = result.message;
        _resultSuccess = result.isSuccess;
      });
      if (result.isSuccess) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.bgCard),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        title: Text(
          _isPpv ? 'Accès PPV' : 'S\'abonner à OmniFlix',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: AppLogo(size: AppLogoSize.small),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Region tab bar ──────────────────────────────────────────────────
          Container(
            color: AppColors.bgCard,
            child: TabBar(
              controller: _regionTab,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '🇨🇩  RDC — Mobile Money'),
                Tab(text: '🌍  International — PayPal'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _regionTab,
              children: [
                _DrcTab(parent: this),
                _IntlTab(parent: this),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── DRC Tab ────────────────────────────────────────────────────────────────────

class _DrcTab extends StatelessWidget {
  final _PaymentScreenState parent;
  const _DrcTab({required this.parent});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!parent._isPpv) ...[
            _PlanSelector(
              selectedIndex: parent._selectedPlanIndex,
              onSelect: (i) => parent.setState(() => parent._selectedPlanIndex = i),
              region: PaymentRegion.drc,
            ),
            const SizedBox(height: 20),
          ] else ...[
            _PpvInfoCard(event: parent.widget.ppvEvent!),
            const SizedBox(height: 20),
          ],

          const Text('Mode de paiement',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          // M-Pesa first (user's dedicated account)
          _MobileMoneyCard(
            id: 'mpesa', name: 'M-Pesa (Vodacom)', emoji: '🟢',
            color: const Color(0xFF00A651),
            subtitle: 'Compte marchand OmniFlix',
            selected: parent._selectedMethod == PaymentMethod.mpesa,
            onTap: () => parent.setState(() => parent._selectedMethod = PaymentMethod.mpesa),
          ),
          _MobileMoneyCard(
            id: 'airtel', name: 'Airtel Money', emoji: '🔴',
            color: const Color(0xFFE60000),
            selected: parent._selectedMethod == PaymentMethod.airtel,
            onTap: () => parent.setState(() => parent._selectedMethod = PaymentMethod.airtel),
          ),
          _MobileMoneyCard(
            id: 'orange', name: 'Orange Money', emoji: '🟠',
            color: const Color(0xFFFF6600),
            selected: parent._selectedMethod == PaymentMethod.orange,
            onTap: () => parent.setState(() => parent._selectedMethod = PaymentMethod.orange),
          ),
          _MobileMoneyCard(
            id: 'africell', name: 'Africell Money', emoji: '🔵',
            color: const Color(0xFF0066CC),
            selected: parent._selectedMethod == PaymentMethod.africell,
            onTap: () => parent.setState(() => parent._selectedMethod = PaymentMethod.africell),
          ),

          const SizedBox(height: 16),

          // Phone number
          const Text('Votre numéro',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: parent._phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, letterSpacing: 1),
            decoration: const InputDecoration(
              prefixText: '+243 ',
              prefixStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              hintText: '8X XXX XXXX',
              counterText: '',
            ),
            maxLength: 9,
          ),
          const SizedBox(height: 4),
          const Text('Numéro associé à votre compte Mobile Money',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),

          const SizedBox(height: 20),

          // USSD code box (shown when pending)
          if (parent._isPending && parent._ussdCode != null) ...[
            _UssdCodeBox(
              code: parent._ussdCode!,
              onDial: () async {
                final service = parent.ref.read(paymentServiceProvider);
                await service.dialUssd(parent._selectedMethod!, parent._amountFc);
              },
            ),
            const SizedBox(height: 12),
          ],

          _ResultBanner(
            message: parent._resultMessage,
            isSuccess: parent._resultSuccess,
          ),

          // Action button
          if (parent._isPending) ...[
            _ActionButton(
              label: 'J\'ai payé — Confirmer l\'abonnement',
              icon: Icons.check_circle_rounded,
              color: AppColors.live,
              isLoading: parent._isLoading,
              onPressed: parent._confirmMobileMoney,
            ),
          ] else ...[
            _ActionButton(
              label: 'Payer ${Formatters.formatPrice(parent._amountFc)}',
              icon: Icons.send_to_mobile_rounded,
              color: AppColors.primary,
              isLoading: parent._isLoading,
              onPressed: parent._processMobileMoney,
            ),
          ],

          const SizedBox(height: 12),
          _SecureNote(
            text: 'Paiement sécurisé • Reçu confirmé sur votre téléphone\n'
                'Compte marchand : ${AppConstants.mpesaMerchantFull}',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── International Tab ──────────────────────────────────────────────────────────

class _IntlTab extends StatelessWidget {
  final _PaymentScreenState parent;
  const _IntlTab({required this.parent});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!parent._isPpv) ...[
            _PlanSelector(
              selectedIndex: parent._selectedPlanIndex,
              onSelect: (i) => parent.setState(() => parent._selectedPlanIndex = i),
              region: PaymentRegion.international,
            ),
            const SizedBox(height: 20),
          ] else ...[
            _PpvInfoCard(event: parent.widget.ppvEvent!, showUsd: true),
            const SizedBox(height: 20),
          ],

          // PayPal card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF009CDE).withOpacity(
                  parent._selectedMethod == PaymentMethod.paypal ? 1 : 0.3,
                ),
                width: parent._selectedMethod == PaymentMethod.paypal ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009CDE).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('🅿', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PayPal',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          Text('Carte bancaire, compte PayPal, SEPA',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009CDE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Recommandé',
                          style: TextStyle(
                              fontSize: 9, color: Color(0xFF009CDE),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.bgCardLight),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _IntlBadge(text: '🔒 SSL sécurisé'),
                    const SizedBox(width: 8),
                    _IntlBadge(text: '🌍 200+ pays'),
                    const SizedBox(width: 8),
                    _IntlBadge(text: '💳 Visa/MC'),
                  ],
                ),

                const SizedBox(height: 14),

                // Price display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${parent._amountUsd.toStringAsFixed(2)} USD',
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '/ €${parent._amountEur.toStringAsFixed(2)} EUR',
                        style: const TextStyle(
                          fontSize: 14, color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _ResultBanner(
            message: parent._resultMessage,
            isSuccess: parent._resultSuccess,
          ),

          if (parent._isPending) ...[
            _ActionButton(
              label: 'J\'ai payé sur PayPal — Confirmer',
              icon: Icons.check_circle_rounded,
              color: AppColors.live,
              isLoading: parent._isLoading,
              onPressed: parent._confirmPayPal,
            ),
          ] else ...[
            _ActionButton(
              label: 'Payer avec PayPal',
              icon: Icons.open_in_new_rounded,
              color: const Color(0xFF009CDE),
              isLoading: parent._isLoading,
              onPressed: () {
                parent.setState(() => parent._selectedMethod = PaymentMethod.paypal);
                parent._openPayPal();
              },
            ),
          ],

          const SizedBox(height: 12),
          const _SecureNote(
            text: 'Vous serez redirigé vers PayPal.com pour finaliser.\n'
                'Votre abonnement est activé après confirmation.',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Plan Selector ──────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final PaymentRegion region;

  const _PlanSelector({
    required this.selectedIndex,
    required this.onSelect,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    final isDrc = region == PaymentRegion.drc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choisir votre formule',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PlanCard(
                name: 'Pass Journée',
                priceLabel: isDrc
                    ? Formatters.formatPrice(AppConstants.dailyPriceFc)
                    : '\$${AppConstants.dailyPriceUsd.toStringAsFixed(2)}',
                subLabel: isDrc ? 'FC / 24h' : 'USD / 24h',
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PlanCard(
                name: 'Mensuel',
                priceLabel: isDrc
                    ? Formatters.formatPrice(AppConstants.monthlyPriceFc)
                    : '\$${AppConstants.monthlyPriceUsd.toStringAsFixed(2)}',
                subLabel: isDrc ? 'FC / mois' : 'USD / mois',
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
            children: const [
              _FeatureRow(icon: Icons.live_tv_rounded, text: 'TV en Direct illimité'),
              _FeatureRow(icon: Icons.movie_rounded, text: 'Films & Séries en Français'),
              _FeatureRow(icon: Icons.sports_esports_rounded, text: 'Catalogue de Jeux + ROMs'),
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
  final String priceLabel;
  final String subLabel;
  final bool selected;
  final VoidCallback onTap;
  final bool isBest;

  const _PlanCard({
    required this.name,
    required this.priceLabel,
    required this.subLabel,
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
                child: const Text('MEILLEUR PRIX',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                        color: Colors.black)),
              )
            else
              const SizedBox(height: 14),
            const SizedBox(height: 6),
            Text(name,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(priceLabel,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            Text(subLabel,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Money Card ──────────────────────────────────────────────────────────

class _MobileMoneyCard extends StatelessWidget {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MobileMoneyCard({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.bgCardLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: selected ? color : AppColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? color : AppColors.textMuted, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── USSD Code Box ──────────────────────────────────────────────────────────────

class _UssdCodeBox extends StatelessWidget {
  final String code;
  final VoidCallback onDial;

  const _UssdCodeBox({required this.code, required this.onDial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.live.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.live.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dialpad_rounded, size: 16, color: AppColors.live),
              SizedBox(width: 6),
              Text('Code USSD à composer',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.live)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copié'),
                      backgroundColor: AppColors.bgCard,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: AppColors.textSecondary),
                tooltip: 'Copier',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDial,
              icon: const Icon(Icons.phone_rounded, size: 16),
              label: const Text('Ouvrir le composeur',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.live,
                side: BorderSide(color: AppColors.live.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              )
            : Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: AppColors.bgCardLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String? message;
  final bool? isSuccess;

  const _ResultBanner({this.message, this.isSuccess});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final success = isSuccess ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (success ? AppColors.live : AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (success ? AppColors.live : AppColors.primary).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.info_rounded,
              color: success ? AppColors.live : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message!,
                  style: TextStyle(
                      fontSize: 12,
                      color: success ? AppColors.live : AppColors.primary,
                      height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecureNote extends StatelessWidget {
  final String text;
  const _SecureNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.security_rounded, color: AppColors.live, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
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
          Icon(icon, size: 15, color: AppColors.live),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _IntlBadge extends StatelessWidget {
  final String text;
  const _IntlBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    );
  }
}

class _PpvInfoCard extends StatelessWidget {
  final LiveEvent event;
  final bool showUsd;
  const _PpvInfoCard({required this.event, this.showUsd = false});

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
          Text(event.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (event.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(event.subtitle!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.ppv),
              const SizedBox(width: 6),
              Text(
                showUsd
                    ? 'Accès unique: \$${(event.priceFc / 2850).toStringAsFixed(2)} USD'
                    : 'Accès unique: ${Formatters.formatPrice(event.priceFc)}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ppv),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
