import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/guest_restrictions.dart';
import '../utils/coin_service.dart';
import '../l10n/app_localizations.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final GuestRestrictions _guestRestrictions = GuestRestrictions();
  final List<String> _purchaseHistory = [];

  Future<void> _addCoinsForItem(String itemId) async {
    int coins = 0;
    switch (itemId) {
      case 'starter_package': coins = 1000; break;
      case 'premium_package': coins = 5500; break;
      case 'mega_package': coins = 17000; break;
      case 'battlepass_season1': coins = 0; break;
      case 'gold_card_theme': coins = 0; break;
      case 'special_avatar': coins = 0; break;
    }
    if (coins > 0) {
      await CoinService.instance.addCoins(coins);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shop),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[900]!,
              Colors.green[700]!,
              Colors.green[500]!,
            ],
          ),
        ),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final isGuest = authProvider.isGuest;
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 게스트 모드 안내
                if (isGuest) _buildGuestNotice(),
                const SizedBox(height: 24),

                // 코인 패키지
                _buildShopSection(
                  title: AppLocalizations.of(context)!.coinPackages,
                  icon: Icons.monetization_on,
                  children: [
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.starterPackage,
                      description: AppLocalizations.of(context)!.coins1000,
                      price: '₩4,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('starter_package') : null,
                    ),
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.premiumPackage,
                      description: AppLocalizations.of(context)!.coins5000Bonus500,
                      price: '₩19,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('premium_package') : null,
                    ),
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.megaPackage,
                      description: AppLocalizations.of(context)!.coins15000Bonus2000,
                      price: '₩49,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('mega_package') : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 배틀패스
                _buildShopSection(
                  title: AppLocalizations.of(context)!.battlepass,
                  icon: Icons.card_giftcard,
                  children: [
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.battlepassSeason1,
                      description: AppLocalizations.of(context)!.specialReward30days,
                      price: '₩9,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('battlepass_season1') : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 특별 아이템
                _buildShopSection(
                  title: AppLocalizations.of(context)!.specialItems,
                  icon: Icons.star,
                  children: [
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.goldCardTheme,
                      description: AppLocalizations.of(context)!.specialCardDesign,
                      price: '₩2,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('gold_card_theme') : null,
                    ),
                    _buildShopItem(
                      title: AppLocalizations.of(context)!.specialAvatar,
                      description: AppLocalizations.of(context)!.uniqueCharacterAvatar,
                      price: '₩1,900',
                      isAvailable: !isGuest,
                      onTap: !isGuest ? () => _purchaseItem('special_avatar') : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 광고 보상 (게스트용)
                if (isGuest) _buildAdRewardSection(),
                const SizedBox(height: 24),
                // 구매 내역 표시
                if (_purchaseHistory.isNotEmpty)
                  _buildPurchaseHistorySection(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGuestNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_cart,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.guestModeNotice,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.guestModeDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 로그아웃 후 로그인 화면으로 이동
                context.read<AuthProvider>().signOut().then((_) {
                  Navigator.of(context).pushReplacementNamed('/login');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.createAccount,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.yellow, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShopItem({
    required String title,
    required String description,
    required String price,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isAvailable ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: isAvailable ? Colors.white70 : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: isAvailable ? Colors.yellow : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isAvailable)
                    Text(
                      AppLocalizations.of(context)!.purchaseUnavailable,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              if (!isAvailable)
                const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 20,
                )
              else
                const Icon(
                  Icons.shopping_cart,
                  color: Colors.yellow,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdRewardSection() {
    return FutureBuilder<int>(
      future: _guestRestrictions.getRemainingAdRewards(true),
      builder: (context, snapshot) {
        final remainingRewards = snapshot.data ?? 0;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.adReward,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: InkWell(
                  onTap: remainingRewards > 0 ? () => _watchAdReward() : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.watchAdReward,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.earn50Coins,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.remainingRewards(remainingRewards),
                              style: TextStyle(
                                color: remainingRewards > 0 ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (remainingRewards > 0)
                              const Icon(
                                Icons.play_arrow,
                                color: Colors.blue,
                                size: 20,
                              )
                            else
                              const Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 20,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _purchaseItem(String itemId) {
    // IAP 구매 로직
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: Text(
            AppLocalizations.of(context)!.purchaseConfirmation,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(context)!.confirmPurchase(itemId),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _addCoinsForItem(itemId);
                setState(() {
                  _purchaseHistory.insert(0, itemId);
                  if (_purchaseHistory.length > 5) {
                    _purchaseHistory.removeLast();
                  }
                });
                _showPurchaseSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.purchase),
            ),
          ],
        );
      },
    );
  }

  Future<void> _watchAdReward() async {
    final canWatch = await _guestRestrictions.canWatchAdReward(true);
    
    if (!canWatch) {
      _showUpgradeDialog('adReward');
      return;
    }

    // 광고 시청 로직 (실제 구현 필요)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: Text(
            AppLocalizations.of(context)!.watchAd,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(context)!.watchAdToEarnCoins,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // 광고 시청 완료 후 보상 지급
                await _guestRestrictions.recordAdReward(true);
                _showAdRewardSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.watchAd),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.purchaseCompleted),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAdRewardSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.earned50Coins),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showUpgradeDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[800],
          title: Text(
            AppLocalizations.of(context)!.featureRestricted,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _guestRestrictions.getUpgradeMessage(feature),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.later,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 로그아웃 후 로그인 화면으로 이동
                context.read<AuthProvider>().signOut().then((_) {
                  Navigator.of(context).pushReplacementNamed('/login');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.createAccount),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurchaseHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.recentPurchases, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final item in _purchaseHistory)
            Text('- $item', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
} 