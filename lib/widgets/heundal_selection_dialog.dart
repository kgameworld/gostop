import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../l10n/app_localizations.dart';

class HeundalSelectionDialog extends StatelessWidget {
  final List<GoStopCard> heundalCards;
  final GoStopCard selectedCard;
  final Function(bool) onHeundalChoice;

  const HeundalSelectionDialog({
    super.key,
    required this.heundalCards,
    required this.selectedCard,
    required this.onHeundalChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400), // 최대 너비 제한
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단: 안내 텍스트
              Text(
                AppLocalizations.of(context)!.heundalQuestion, // 흔들 안내
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              // 중간: 흔들 카드(들) 중앙 정렬, 필드카드 크기(48x72)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: heundalCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 48, // 필드카드 크기
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: card.id == selectedCard.id 
                              ? Colors.orange 
                              : Colors.white.withOpacity(0.5),
                          width: card.id == selectedCard.id ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          card.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // 선택된 카드 설명
              Text(
                AppLocalizations.of(context)!.selectedCard(selectedCard.name), // 선택된 카드
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              // 하단: 버튼 가로 배치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 아니요 버튼
                  ElevatedButton(
                    onPressed: () => onHeundalChoice(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.no, // 아니요
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  // 흔들! 버튼
                  ElevatedButton(
                    onPressed: () => onHeundalChoice(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.heundal, // 흔들!
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 