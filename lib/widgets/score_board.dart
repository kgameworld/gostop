import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ScoreBoard extends StatelessWidget {
  final Map<String, dynamic> scoreDetails;
  final String playerName;
  final bool isAI;
  final bool isPiBak;
  final bool isGwangBak;
  final bool isHeundal; // 흔들 상태 추가

  const ScoreBoard({
    super.key,
    required this.scoreDetails,
    required this.playerName,
    this.isAI = false,
    this.isPiBak = false,
    this.isGwangBak = false,
    this.isHeundal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 플레이어 이름과 총점
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isHeundal) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 2),
                      Text(AppLocalizations.of(context)!.heundal, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11)), // 흔들
                      SizedBox(width: 2),
                      Text('x2배', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.yellow, fontSize: 11)), // 배수(고정)
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      '${scoreDetails['totalScore']}${AppLocalizations.of(context)!.points}', // 점수 단위도 다국어
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isPiBak)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.piBak, // 피박
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isGwangBak)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.gwangBak, // 광박
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // 점수 세부 내역
          if (scoreDetails['gwangScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.bright, scoreDetails['gwangScore'], Colors.yellow), // 광
          if (scoreDetails['ttiScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.ribbon, scoreDetails['ttiScore'], Colors.green), // 띠
          if (scoreDetails['piScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.junk, scoreDetails['piScore'], Colors.blue), // 피
          if (scoreDetails['animalScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.animal, scoreDetails['animalScore'], Colors.purple), // 동물
          if (scoreDetails['godoriScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.godori, scoreDetails['godoriScore'], Colors.orange), // 고도리
          if (scoreDetails['danScore'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.dan, scoreDetails['danScore'], Colors.pink), // 단
          if (scoreDetails['goBonus'] > 0)
            _buildScoreRow(context, AppLocalizations.of(context)!.goBonusLabel, scoreDetails['goBonus'], Colors.red), // 고보너스
          
          // 카드 개수 정보
          if (scoreDetails['gwangCards'].isNotEmpty)
            _buildCardCountRow(context, AppLocalizations.of(context)!.bright, scoreDetails['gwangCards'].length), // 광
          if (scoreDetails['ttiCards'].isNotEmpty)
            _buildCardCountRow(context, AppLocalizations.of(context)!.ribbon, scoreDetails['ttiCards'].length), // 띠
          if (scoreDetails['piCards'].isNotEmpty)
            _buildCardCountRow(context, AppLocalizations.of(context)!.junk, scoreDetails['piCards'].length, totalPi: scoreDetails['totalPi']), // 피
          if (scoreDetails['animalCards'].isNotEmpty)
            _buildCardCountRow(context, AppLocalizations.of(context)!.animal, scoreDetails['animalCards'].length), // 동물
        ],
      ),
    );
  }

  // 점수 항목 한 줄을 그리는 위젯 (context를 파라미터로 받음)
  Widget _buildScoreRow(BuildContext context, String label, int score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '+$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // 카드 개수 정보를 그리는 위젯 (context를 파라미터로 받음)
  Widget _buildCardCountRow(BuildContext context, String label, int count, {int? totalPi}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
          Text(
            totalPi != null
                ? '$count ${AppLocalizations.of(context)!.cardCountUnit}($totalPi${AppLocalizations.of(context)!.points})'
                : '$count ${AppLocalizations.of(context)!.cardCountUnit}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
} 