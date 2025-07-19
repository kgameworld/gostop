import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileCard extends StatelessWidget {
  final String avatarUrl;
  final String nickname;
  final String countryCode; // ISO country code
  final int level;
  final int coins;
  final double? height;
  final double? avatarSize;
  final double? fontSize;
  final double? iconSize;
  final double? coinFontSize;
  final double? levelFontSize;
  final Widget? handCards; // AI 손패 카드 위젯 추가
  final GlobalKey? handCardsKey; // AI 손패 카드 박스 GlobalKey
  const ProfileCard({
    super.key,
    required this.avatarUrl,
    required this.nickname,
    required this.countryCode,
    required this.level,
    required this.coins,
    this.height,
    this.avatarSize,
    this.fontSize,
    this.iconSize,
    this.coinFontSize,
    this.levelFontSize,
    this.handCards, // AI 손패 카드 위젯 추가
    this.handCardsKey, // AI 손패 카드 박스 GlobalKey
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder로 부모의 실제 높이에 맞춰 크기 자동 조정
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : (height ?? 70.0);
        // 공간이 부족하면 자동으로 줄어듦 (최소/최대값 제한)
        final avatar = (avatarSize ?? maxH * 0.45).clamp(16.0, 40.0);
        final mainFont = (fontSize ?? maxH * 0.28).clamp(10.0, 20.0);
        final icon = (iconSize ?? maxH * 0.22).clamp(10.0, 18.0);
        final coinFont = (coinFontSize ?? maxH * 0.22).clamp(8.0, 16.0);
        final cardHeight = maxH;
        final isExpand = height == double.infinity;
        // 너비를 기존의 70%로 축소
        final reducedWidth = (isExpand ? double.infinity : cardHeight * 4) * 0.7;
        return Container(
          width: reducedWidth,
          height: isExpand ? double.infinity : cardHeight * 1.3,
          constraints: isExpand
              ? const BoxConstraints()
              : BoxConstraints(
                  minHeight: cardHeight * 1.3,
                  maxHeight: cardHeight * 1.3,
                  minWidth: reducedWidth,
                  maxWidth: reducedWidth,
                ),
          // 왼쪽 정렬 효과를 위해 Align.left로 변경
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: isExpand ? 6 : cardHeight * 0.08,
            vertical: isExpand ? 4 : cardHeight * 0.07,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(cardHeight * 0.17),
          ),
          child: handCards != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AI 프로필 정보 (왼쪽) - 내 프로필박스와 동일한 위치
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1행: 프로필사진 + 닉네임
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: avatar / 2,
                              backgroundColor: Colors.grey.shade800,
                              child: ClipOval(
                                child: Image.asset(
                                  avatarUrl,
                                  width: avatar,
                                  height: avatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Icon(Icons.person, color: Colors.white, size: icon),
                                ),
                              ),
                            ),
                            SizedBox(width: cardHeight * 0.09),
                            Text(
                              nickname,
                              style: TextStyle(
                                fontSize: mainFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                        // 2행: 코인 상태창 (아래쪽에 딱 붙게)
                        if (!(nickname.toLowerCase().startsWith('ai')))
                          Padding(
                            padding: EdgeInsets.only(top: isExpand ? 2 : cardHeight * 0.07),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isExpand ? 6 : cardHeight * 0.06,
                                vertical: isExpand ? 2 : cardHeight * 0.025
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(cardHeight * 0.115),
                                border: Border.all(color: Colors.amberAccent, width: 0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amberAccent.withOpacity(0.7),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset('assets/icons/coin.png', width: icon, height: icon),
                                      Shimmer.fromColors(
                                        baseColor: Colors.transparent,
                                        highlightColor: Colors.white.withOpacity(0.7),
                                        period: const Duration(seconds: 2),
                                        child: Image.asset(
                                          'assets/icons/coin.png',
                                          width: icon,
                                          height: icon,
                                          color: Colors.white,
                                          colorBlendMode: BlendMode.srcATop,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: isExpand ? 4 : cardHeight * 0.025),
                                  Text(
                                    '$coins',
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: coinFont
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: cardHeight * 0.05),
                  // AI 손패 카드들 (오른쪽) - 새로운 박스로 감싸기
                  Expanded(
                    flex: 2,
                    child: Container(
                      key: handCardsKey, // 전달받은 GlobalKey 사용
                      padding: EdgeInsets.all(cardHeight * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(cardHeight * 0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: handCards!,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1행: 프로필사진 + 닉네임
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: avatar / 2,
                        backgroundColor: Colors.grey.shade800,
                        child: ClipOval(
                          child: Image.asset(
                            avatarUrl,
                            width: avatar,
                            height: avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Icon(Icons.person, color: Colors.white, size: icon),
                          ),
                        ),
                      ),
                      SizedBox(width: cardHeight * 0.09),
                      Text(
                        nickname,
                        style: TextStyle(
                          fontSize: mainFont,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                  // 2행: 코인 상태창 (아래쪽에 딱 붙게)
                  if (!(nickname.toLowerCase().startsWith('ai')))
                    Padding(
                      padding: EdgeInsets.only(top: isExpand ? 2 : cardHeight * 0.07),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpand ? 6 : cardHeight * 0.06,
                          vertical: isExpand ? 2 : cardHeight * 0.025
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(cardHeight * 0.115),
                          border: Border.all(color: Colors.amberAccent, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amberAccent.withOpacity(0.7),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset('assets/icons/coin.png', width: icon, height: icon),
                                Shimmer.fromColors(
                                  baseColor: Colors.transparent,
                                  highlightColor: Colors.white.withOpacity(0.7),
                                  period: const Duration(seconds: 2),
                                  child: Image.asset(
                                    'assets/icons/coin.png',
                                    width: icon,
                                    height: icon,
                                    color: Colors.white,
                                    colorBlendMode: BlendMode.srcATop,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: isExpand ? 4 : cardHeight * 0.025),
                            Text(
                              '$coins',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: coinFont
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        );
      },
    );
  }

  String _flagEmoji(String countryCode) {
    // Country code to regional indicator symbols
    return String.fromCharCodes(
      countryCode.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 65)),
    );
  }
} 