import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'places_service.dart';

class PlaceMapPickerResult {
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const PlaceMapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}

class PlaceMapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final int initialRadius;

  const PlaceMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialRadius = 150,
  });

  @override
  State<PlaceMapPicker> createState() => _PlaceMapPickerState();
}

class _PlaceMapPickerState extends State<PlaceMapPicker> {
  late NLatLng _center;
  late int _radius;
  bool _gpsReady = false;
  bool _loadingGps = false;

  NaverMapController? _mapController;
  NCircleOverlay? _circleOverlay;

  // 검색
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _searchLoading = false;

  static const _radii = [50, 100, 150, 300, 500];
  static final _dio = Dio();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = NLatLng(widget.initialLat!, widget.initialLng!);
      _gpsReady = true;
    } else {
      _center = const NLatLng(37.5665, 126.9780); // 서울 (GPS 전 임시)
      _initGps();
    }
    _radius = widget.initialRadius;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initGps() async {
    final pos = await PlacesService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      _center = NLatLng(pos.latitude, pos.longitude);
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: _center),
      );
    }
    setState(() => _gpsReady = true);
    await _updateCircleOverlay();
  }

  Future<void> _addCircleOverlay() async {
    _circleOverlay = NCircleOverlay(
      id: 'radius_circle',
      center: _center,
      radius: _radius.toDouble(),
      color: AppColors.primary.withValues(alpha: 0.15),
      outlineColor: AppColors.primary,
      outlineWidth: 2,
    );
    await _mapController?.addOverlay(_circleOverlay!);
  }

  Future<void> _updateCircleOverlay() async {
    if (_circleOverlay == null) return;
    _circleOverlay!.setCenter(_center);
    _circleOverlay!.setRadius(_radius.toDouble());
  }

  Future<void> _moveToGps() async {
    setState(() => _loadingGps = true);
    final pos = await PlacesService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _loadingGps = false);
    if (pos != null) {
      final point = NLatLng(pos.latitude, pos.longitude);
      setState(() => _center = point);
      _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: point),
      );
      await _updateCircleOverlay();
    }
  }

  void _zoomIn() {
    _mapController?.updateCamera(NCameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.updateCamera(NCameraUpdate.zoomOut());
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchLoading = true;
      _searchResults = [];
    });
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 6,
          'accept-language': 'ko',
          'countrycodes': 'kr',
        },
        options: Options(
          headers: {'User-Agent': 'HarugyeolApp/1.0 (app.harugyeol)'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final list = (res.data as List).map((e) => _SearchResult(
            name: e['display_name'] as String,
            lat: double.parse(e['lat'] as String),
            lng: double.parse(e['lon'] as String),
          )).toList();
      setState(() => _searchResults = list);
    } catch (_) {
      // 검색 실패 시 빈 결과
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _selectResult(_SearchResult result) {
    final point = NLatLng(result.lat, result.lng);
    setState(() {
      _center = point;
      _isSearching = false;
      _searchResults = [];
      _searchCtrl.clear();
    });
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: point),
    );
    _updateCircleOverlay();
    FocusScope.of(context).unfocus();
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (!_gpsReady) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(children: [
                  _FloatingBtn(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                  ),
                ]),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('현재 위치를 가져오는 중...',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── 네이버 지도 ───────────────────────────────────────────────────────
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _center,
                zoom: 16,
              ),
              compassEnable: false,
              scaleBarEnable: false,
              logoAlign: NLogoAlign.leftBottom,
              logoMargin: EdgeInsets.only(
                left: 12,
                bottom: bottomPad + 280,
              ),
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              await _addCircleOverlay();
            },
            onCameraIdle: () async {
              if (_mapController == null) return;
              final pos = await _mapController!.getCameraPosition();
              if (!mounted) return;
              setState(() => _center = pos.target);
              await _updateCircleOverlay();
            },
          ),

          // ── 고정 핀 ──────────────────────────────────────────────────────────
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 46,
                  ),
                ),
              ),
            ),
          ),

          // ── 상단 바 ──────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _FloatingBtn(
                        onTap: _isSearching
                            ? _cancelSearch
                            : () => Navigator.pop(context),
                        child: Icon(
                          _isSearching
                              ? Icons.close_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isSearching) {
                              setState(() => _isSearching = true);
                            }
                          },
                          child: Container(
                            height: 44,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: _isSearching
                                ? Row(children: [
                                    const Icon(Icons.search_rounded,
                                        size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: '장소, 주소 검색',
                                          hintStyle: GoogleFonts.notoSansKr(
                                            fontSize: 13,
                                            color: AppColors.textHint,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                        textInputAction:
                                            TextInputAction.search,
                                        onSubmitted: _doSearch,
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    if (_searchLoading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary),
                                      )
                                    else if (_searchCtrl.text.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          setState(
                                              () => _searchResults = []);
                                        },
                                        child: const Icon(
                                            Icons.cancel_rounded,
                                            size: 18,
                                            color: AppColors.textHint),
                                      ),
                                  ])
                                : Row(children: [
                                    const Icon(Icons.search_rounded,
                                        size: 16, color: AppColors.textHint),
                                    const SizedBox(width: 8),
                                    Text(
                                      '장소, 주소 검색',
                                      style: GoogleFonts.notoSansKr(
                                        fontSize: 13,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FloatingBtn(
                        onTap: _loadingGps ? null : _moveToGps,
                        child: _loadingGps
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary),
                              )
                            : const Icon(Icons.my_location_rounded,
                                color: AppColors.primary, size: 22),
                      ),
                    ],
                  ),

                  // ── 검색 결과 드롭다운 ────────────────────────────────────────
                  if (_isSearching && _searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, indent: 52, endIndent: 16),
                          itemBuilder: (_, i) {
                            final r = _searchResults[i];
                            final parts = r.name.split(',');
                            final title = parts.first.trim();
                            final sub = parts.length > 1
                                ? parts.sublist(1).join(',').trim()
                                : '';
                            return InkWell(
                              onTap: () => _selectResult(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                child: Row(children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySurface,
                                      borderRadius:
                                          BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 18,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.notoSansKr(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            )),
                                        if (sub.isNotEmpty)
                                          Text(sub,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.notoSansKr(
                                                fontSize: 11,
                                                color: AppColors.textHint,
                                              )),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 줌 버튼 ──────────────────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: bottomPad + 300,
            child: Column(
              children: [
                _FloatingBtn(
                  onTap: _zoomIn,
                  child: const Icon(Icons.add_rounded,
                      size: 22, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                _FloatingBtn(
                  onTap: _zoomOut,
                  child: const Icon(Icons.remove_rounded,
                      size: 22, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          // ── 하단 패널 ─────────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('선택한 위치',
                            style: GoogleFonts.notoSansKr(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        Text(
                          '${_center.latitude.toStringAsFixed(5)}, '
                          '${_center.longitude.toStringAsFixed(5)}',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '반경 $_radius m',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  Text('감지 반경',
                      style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: _radii.map((r) {
                      final selected = r == _radius;
                      final label =
                          r >= 1000 ? '${r ~/ 1000}km' : '${r}m';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _radius = r);
                            _updateCircleOverlay();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 6),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        PlaceMapPickerResult(
                          latitude: _center.latitude,
                          longitude: _center.longitude,
                          radiusMeters: _radius,
                        ),
                      ),
                      child: Text(
                        '이 위치 사용',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String name;
  final double lat;
  final double lng;
  const _SearchResult(
      {required this.name, required this.lat, required this.lng});
}

// ─── 플로팅 버튼 ───────────────────────────────────────────────────────────────

class _FloatingBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _FloatingBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
