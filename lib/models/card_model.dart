class GoStopCard {
  final int id;
  final int month; // 1 ~ 12
  final String type; // '광', '띠', '피', etc.
  final String name;
  final String imageUrl;
  final bool isBonus;

  GoStopCard({
    required this.id,
    required this.month,
    required this.type,
    required this.name,
    required this.imageUrl,
    this.isBonus = false,
  });
  
  // 폭탄카드 생성 팩토리 메서드
  factory GoStopCard.bomb() {
    return GoStopCard(
      id: -1, // 폭탄카드는 특별한 ID
      month: 0, // 폭탄카드는 월이 없음
      type: '폭탄',
      name: '폭탄',
      imageUrl: 'assets/cards/bomb.png',
      isBonus: false,
    );
  }
  
  // 폭탄카드인지 확인
  bool get isBomb => type == '폭탄';
}