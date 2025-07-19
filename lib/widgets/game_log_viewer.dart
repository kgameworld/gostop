import 'package:flutter/material.dart';
import '../utils/game_logger.dart';

class GameLogViewer extends StatefulWidget {
  final GameLogger logger;
  final bool isVisible;

  const GameLogViewer({
    super.key,
    required this.logger,
    this.isVisible = false,
  });

  @override
  State<GameLogViewer> createState() => _GameLogViewerState();
}

class _GameLogViewerState extends State<GameLogViewer> {
  LogLevel _selectedLevel = LogLevel.info;
  int? _selectedPlayer;
  int? _selectedTurn;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      width: 400,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildLogList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.article, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            '게임 로그',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: () {
              _showValidationReport();
            },
            tooltip: '검증 리포트',
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              widget.logger.clearLogs();
              setState(() {});
            },
            tooltip: '로그 초기화',
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Column(
        children: [
          // 레벨 필터
          Row(
            children: [
              const Text('레벨:', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: LogLevel.values.map((level) => FilterChip(
                  label: Text(_getLevelText(level), style: TextStyle(fontSize: 10)),
                  selected: _selectedLevel == level,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLevel = selected ? level : LogLevel.info;
                    });
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: _getLevelColor(level),
                  labelStyle: TextStyle(
                    color: _selectedLevel == level ? Colors.white : Colors.grey[300],
                  ),
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 플레이어/턴 필터
          Row(
            children: [
              const Text('플레이어:', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButton<int?>(
                value: _selectedPlayer,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  const DropdownMenuItem(value: 1, child: Text('P1')),
                  const DropdownMenuItem(value: 2, child: Text('P2')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPlayer = value;
                  });
                },
                ),
              ),
              const SizedBox(width: 16),
              const Text('턴:', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButton<int?>(
                value: _selectedTurn,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white, fontSize: 12),
                  isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  ...List.generate(widget.logger.getLogs().isNotEmpty ? 
                    widget.logger.getLogs().map((log) => log.turnNumber).reduce((a, b) => a > b ? a : b) : 0, 
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('T${index + 1}'),
                    )
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTurn = value;
                  });
                },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    List<LogEntry> filteredLogs = widget.logger.getLogs();

    // 레벨 필터
    if (_selectedLevel != LogLevel.info) {
      filteredLogs = filteredLogs.where((log) => log.level == _selectedLevel).toList();
    }

    // 플레이어 필터
    if (_selectedPlayer != null) {
      filteredLogs = filteredLogs.where((log) => log.playerNumber == _selectedPlayer).toList();
    }

    // 턴 필터
    if (_selectedTurn != null) {
      filteredLogs = filteredLogs.where((log) => log.turnNumber == _selectedTurn).toList();
    }

    // 중복 제거 (같은 메시지가 연속으로 기록될 경우)
    final Set<String> seen = {};
    filteredLogs = filteredLogs.where((log) {
      final key = '${log.turnNumber}-${log.playerNumber}-${log.message}-${log.level.name}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getLogBackgroundColor(log.level),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getLevelColor(log.level),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLevelColor(log.level),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getLevelText(log.level),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                'T${log.turnNumber} P${log.playerNumber}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                log.phase,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          if (log.data != null && log.data!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                log.data!.entries.map((e) => '${e.key}=${e.value}').join(', '),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final totalLogs = widget.logger.getLogs().length;
    final errorLogs = widget.logger.getErrorLogs().length;
    final warningLogs = widget.logger.getWarningLogs().length;
    final validationFailures = widget.logger.getValidationFailures().length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
            '총 $totalLogs개',
            style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
          ),
          const SizedBox(width: 16),
          if (errorLogs > 0)
                Flexible(
                  child: Text(
              '에러 $errorLogs개',
              style: const TextStyle(color: Colors.red, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          if (warningLogs > 0) ...[
            const SizedBox(width: 8),
                Flexible(
                  child: Text(
              '경고 $warningLogs개',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ],
          if (validationFailures > 0) ...[
            const SizedBox(width: 8),
                Flexible(
                  child: Text(
              '검증실패 $validationFailures개',
              style: const TextStyle(color: Colors.pink, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
          const Spacer(),
          Row(
            children: [
              Checkbox(
                value: _autoScroll,
                onChanged: (value) {
                  setState(() {
                    _autoScroll = value ?? true;
                  });
                },
                fillColor: WidgetStateProperty.all(Colors.grey[600]),
                checkColor: Colors.white,
              ),
              const Text(
                '자동 스크롤',
                style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLevelText(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.rule:
        return 'RULE';
      case LogLevel.actual:
        return 'ACTUAL';
      case LogLevel.validation:
        return 'VALID';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.warning:
        return 'WARN';
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.rule:
        return Colors.purple;
      case LogLevel.actual:
        return Colors.green;
      case LogLevel.validation:
        return Colors.teal;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
    }
  }

  Color _getLogBackgroundColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.grey[850]!;
      case LogLevel.rule:
        return Colors.purple.withOpacity(0.1);
      case LogLevel.actual:
        return Colors.green.withOpacity(0.1);
      case LogLevel.validation:
        return Colors.teal.withOpacity(0.1);
      case LogLevel.error:
        return Colors.red.withOpacity(0.1);
      case LogLevel.warning:
        return Colors.orange.withOpacity(0.1);
    }
  }

  void _showValidationReport() {
    final report = widget.logger.generateValidationReport();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('검증 리포트'),
        content: SingleChildScrollView(
          child: Text(
            report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 