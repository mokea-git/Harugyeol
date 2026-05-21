import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'place_map_picker.dart';
import 'place_model.dart';
import 'places_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  List<PlaceModel> _places = [];
  Position? _position;
  List<PlaceModel> _nearbyPlaces = [];
  bool _loading = true;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final places = await PlacesService.instance.getPlaces();
    if (!mounted) return;
    setState(() {
      _places = List.from(places);
      _loading = false;
    });
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    setState(() => _locationLoading = true);
    final pos = await PlacesService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      final nearby = await PlacesService.instance.getNearbyPlaces(pos);
      if (!mounted) return;
      setState(() {
        _position = pos;
        _nearbyPlaces = nearby;
        _locationLoading = false;
      });
    } else {
      setState(() => _locationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _places.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text('장소 추가',
            style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A34), Color(0xFF2D5244), Color(0xFF3E6B4E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '내 장소',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _locationLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54),
                        )
                      : IconButton(
                          onPressed: _refreshLocation,
                          icon: const Icon(Icons.my_location_rounded,
                              color: Colors.white70, size: 22),
                        ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildLocationStatus(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_locationLoading) {
      return Row(children: [
        const Icon(Icons.location_searching_rounded,
            color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Text('위치 확인 중...',
            style:
                GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white38)),
      ]);
    }
    if (_position == null) {
      return GestureDetector(
        onTap: _refreshLocation,
        child: Row(children: [
          const Icon(Icons.location_off_rounded,
              color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Text('위치 권한 없음 · 탭해서 다시 시도',
              style: GoogleFonts.notoSansKr(
                  fontSize: 13, color: Colors.white38)),
        ]),
      );
    }
    if (_nearbyPlaces.isNotEmpty) {
      return Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
              color: Color(0xFF4CAF50), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '지금 ${_nearbyPlaces.first.name}에 있어요',
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            color: const Color(0xFF8BBF84),
            fontWeight: FontWeight.w600,
          ),
        ),
      ]);
    }
    return Row(children: [
      const Icon(Icons.location_on_rounded, color: Colors.white38, size: 14),
      const SizedBox(width: 6),
      Text('위치 확인됨 · 등록된 장소 근처 없음',
          style:
              GoogleFonts.notoSansKr(fontSize: 13, color: Colors.white38)),
    ]);
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.add_location_alt_rounded,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('등록된 장소가 없어요',
              style: GoogleFonts.notoSansKr(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            '학교, 학원, 직장 등 자주 가는 곳을\n추가하면 방문 기록을 남겨드려요',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddSheet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('첫 장소 추가하기'),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _places.length,
        itemBuilder: (context, i) {
          final place = _places[i];
          final isNearby = _nearbyPlaces.any((p) => p.id == place.id);
          return _PlaceCard(
            place: place,
            isNearby: isNearby,
            onTap: () => _showHistorySheet(place),
            onCheckIn: () => _checkIn(place),
            onDelete: () => _confirmDelete(place),
          )
              .animate(
                  delay: Duration(milliseconds: i * 60))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _checkIn(PlaceModel place) async {
    await PlacesService.instance.recordCheckIn(place.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${place.name} 체크인 완료!',
          style: GoogleFonts.notoSansKr()),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _confirmDelete(PlaceModel place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('"${place.name}" 삭제',
                style: GoogleFonts.notoSansKr(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('방문 기록도 모두 삭제돼요',
                style: GoogleFonts.notoSansKr(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('취소')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: const Text('삭제'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (confirm == true) {
      await PlacesService.instance.deletePlace(place.id);
      await _loadAll();
    }
  }

  void _showHistorySheet(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VisitHistorySheet(place: place),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPlaceSheet(
        initialPosition: _position,
        onAdded: (place) async {
          await PlacesService.instance.addPlace(place);
          await _loadAll();
        },
      ),
    );
  }
}

// ─── Place Card ──────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final bool isNearby;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;
  final VoidCallback onDelete;

  const _PlaceCard({
    required this.place,
    required this.isNearby,
    required this.onTap,
    required this.onCheckIn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isNearby
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 카테고리 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: place.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(place.categoryIcon,
                      color: place.categoryColor, size: 24),
                ),
                const SizedBox(width: 14),
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          place.name,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isNearby) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('여기',
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                )),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                place.categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            place.categoryLabel,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 11,
                              color: place.categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('반경 ${place.radiusMeters}m',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 12, color: AppColors.textHint)),
                      ]),
                    ],
                  ),
                ),
                // 우측 액션
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isNearby)
                      GestureDetector(
                        onTap: onCheckIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('체크인',
                              style: GoogleFonts.notoSansKr(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              )),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.textHint, size: 20),
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Visit History Sheet ─────────────────────────────────────────────────────

class _VisitHistorySheet extends StatefulWidget {
  final PlaceModel place;
  const _VisitHistorySheet({required this.place});

  @override
  State<_VisitHistorySheet> createState() => _VisitHistorySheetState();
}

class _VisitHistorySheetState extends State<_VisitHistorySheet> {
  List<PlaceVisit> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final visits =
        await PlacesService.instance.getVisitsForPlace(widget.place.id);
    if (!mounted) return;
    setState(() {
      _visits = visits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // 장소 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.place.categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.place.categoryIcon,
                      color: widget.place.categoryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.place.name,
                            style: GoogleFonts.notoSansKr(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          _loading
                              ? '로딩 중...'
                              : '${_visits.length}번 방문',
                          style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ]),
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 24),
            ),
            // 목록
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _visits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded,
                                  size: 52, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text('방문 기록이 없어요',
                                  style: GoogleFonts.notoSansKr(
                                      fontSize: 16,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text(
                                '근처에서 체크인하면 기록이 남아요',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 13,
                                    color: AppColors.textHint),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemCount: _visits.length,
                          itemBuilder: (ctx, i) =>
                              _VisitTile(visit: _visits[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final PlaceVisit visit;
  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(
        visit.arrivedAt.year, visit.arrivedAt.month, visit.arrivedAt.day);

    String dayLabel;
    if (day == today) {
      dayLabel = '오늘';
    } else if (day == yesterday) {
      dayLabel = '어제';
    } else {
      dayLabel = '${visit.arrivedAt.month}월 ${visit.arrivedAt.day}일';
    }

    final time =
        '${_pad(visit.arrivedAt.hour)}:${_pad(visit.arrivedAt.minute)}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.location_on_rounded,
            color: AppColors.primary, size: 20),
      ),
      title: Text('$dayLabel $time',
          style: GoogleFonts.notoSansKr(
              fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(visit.durationLabel,
          style: GoogleFonts.notoSansKr(
              fontSize: 13, color: AppColors.textSecondary)),
      trailing: visit.departedAt == null
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('방문 중',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            )
          : null,
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Add Place Sheet ──────────────────────────────────────────────────────────

class _AddPlaceSheet extends StatefulWidget {
  final Position? initialPosition;
  final void Function(PlaceModel) onAdded;

  const _AddPlaceSheet({this.initialPosition, required this.onAdded});

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _nameCtrl = TextEditingController();
  String _category = PlaceCategory.school;
  double? _lat;
  double? _lng;
  int _radius = 150;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _lat = widget.initialPosition!.latitude;
      _lng = widget.initialPosition!.longitude;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<PlaceMapPickerResult>(
      MaterialPageRoute(
        builder: (_) => PlaceMapPicker(
          initialLat: _lat,
          initialLng: _lng,
          initialRadius: _radius,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _radius = result.radiusMeters;
      });
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('장소 이름을 입력해 주세요',
            style: GoogleFonts.notoSansKr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('위치를 먼저 설정해 주세요',
            style: GoogleFonts.notoSansKr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    final place = PlaceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: _category,
      latitude: _lat!,
      longitude: _lng!,
      radiusMeters: _radius,
      createdAt: DateTime.now(),
    );
    Navigator.pop(context);
    widget.onAdded(place);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('장소 추가',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              // 이름
              _label('장소 이름'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '예: 강남학원, 우리학교',
                  hintStyle:
                      GoogleFonts.notoSansKr(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.notoSansKr(fontSize: 15),
              ),

              const SizedBox(height: 20),

              // 카테고리
              _label('카테고리'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlaceCategory.all.map((cat) {
                  final selected = cat == _category;
                  final color = PlaceCategory.color(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              selected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(PlaceCategory.icon(cat),
                            size: 15,
                            color: selected
                                ? color
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          PlaceCategory.label(cat),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? color
                                : AppColors.textSecondary,
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 위치 + 반경 (지도 픽커)
              _label('위치 및 반경'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openMapPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: _lat != null
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _lat != null
                            ? AppColors.primarySurface
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _lat != null
                            ? Icons.map_rounded
                            : Icons.add_location_alt_rounded,
                        size: 20,
                        color: _lat != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lat != null ? '위치 설정됨' : '지도에서 위치 선택',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _lat != null
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (_lat != null)
                            Text(
                              '반경 ${_radius}m · ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                              style: GoogleFonts.notoSansKr(
                                  fontSize: 12, color: AppColors.textHint),
                            )
                          else
                            Text('탭해서 지도에서 위치와 반경을 설정하세요',
                                style: GoogleFonts.notoSansKr(
                                    fontSize: 12,
                                    color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Icon(
                      _lat != null
                          ? Icons.edit_location_alt_rounded
                          : Icons.chevron_right_rounded,
                      color: _lat != null
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 22,
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text('저장',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
      );
}
