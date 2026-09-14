import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/currency_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';

// ==========================================================
// PLATFORM
// ==========================================================
class _Platform {
  final String key;
  final String name;
  final FaIconData icon;
  final Color color;
  final List<String> keywords;

  const _Platform({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

// ==========================================================
// SMART SERVICE PARSER
// ==========================================================
class _ServiceMeta {
  final String? description;
  final String? avgTime;

  const _ServiceMeta({
    this.description,
    this.avgTime,
  });

  static _ServiceMeta fromRaw(
    Map<String, dynamic> s,
  ) {
    final name = (s['name'] ?? '').toString();
    final lower = name.toLowerCase();

    String? desc = s['description']?.toString();

    if (desc == null || desc.trim().isEmpty) {
      desc = _inferDescription(lower);
    }

    String? avgTime = s['avg_time']?.toString();

    if (avgTime == null || avgTime.trim().isEmpty) {
      avgTime = _inferAvgTime(lower);
    }

    return _ServiceMeta(
      description: desc,
      avgTime: avgTime,
    );
  }

  static String _inferDescription(
    String lower,
  ) {
    final parts = <String>[];

    if (lower.contains('real') ||
        lower.contains('active')) {
      parts.add('Real, active users');
    } else if (lower.contains('bot')) {
      parts.add('Bot accounts');
    } else if (lower.contains('website') ||
        lower.contains('traffic')) {
      parts.add('Real human traffic');
    } else {
      parts.add('High-quality delivery');
    }

    if (lower.contains('non drop') ||
        lower.contains('nondrop')) {
      parts.add('Non-drop guarantee');
    } else if (lower.contains('low drop')) {
      parts.add('Low drop rate');
    }

    if (lower.contains('instant') ||
        lower.contains('fastest')) {
      parts.add('Instant start');
    } else if (lower.contains('fast') ||
        lower.contains('high speed')) {
      parts.add('Fast start');
    }

    if (lower.contains('refill: yes') ||
        (lower.contains('refill') &&
            !lower.contains('refill: no'))) {
      parts.add('Auto-refill enabled');
    }

    if (lower.contains('lifetime')) {
      parts.add('Lifetime guarantee');
    }

    if (lower.contains('100%') ||
        lower.contains('guaranteed')) {
      parts.add('100% Guaranteed');
    }

    if (lower.contains('adsense') ||
        lower.contains('ad sense')) {
      parts.add('AdSense safe');
    }

    if (lower.contains('google')) {
      parts.add('Google sourced');
    }

    if (lower.contains('country') ||
        lower.contains('targeted') ||
        lower.contains('worldwide')) {
      parts.add('Geo-targeted');
    }

    return parts.join(' · ');
  }

  static String _inferAvgTime(
    String lower,
  ) {
    if (lower.contains('website') ||
        lower.contains('traffic')) {
      if (lower.contains('instant') ||
          lower.contains('fast')) {
        return '30 minutes - 2 hours';
      }

      return '1 - 6 hours';
    }

    if (lower.contains('instant') ||
        lower.contains('fastest')) {
      return '0 - 15 minutes';
    }

    if (lower.contains('fast') ||
        lower.contains('high speed')) {
      return '15 - 60 minutes';
    }

    if (lower.contains('view')) {
      return '30 - 90 minutes';
    }

    if (lower.contains('like')) {
      return '10 - 40 minutes';
    }

    if (lower.contains('follower') ||
        lower.contains('subscriber')) {
      return '1 - 6 hours';
    }

    if (lower.contains('comment')) {
      return '30 minutes - 4 hours';
    }

    if (lower.contains('member')) {
      return '1 - 12 hours';
    }

    if (lower.contains('share') ||
        lower.contains('repost')) {
      return '20 - 60 minutes';
    }

    if (lower.contains('play') ||
        lower.contains('stream')) {
      return '1 - 3 hours';
    }

    return '1 - 12 hours';
  }
}

// ==========================================================
// SERVICES SCREEN
// ==========================================================
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() =>
      _ServicesScreenState();
}

class _ServicesScreenState
    extends State<ServicesScreen> {
  static const _platforms = [
    _Platform(
      key: 'instagram',
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      color: Color(0xFFE4405F),
      keywords: [
        'instagram',
        'insta',
        'ig ',
      ],
    ),
    _Platform(
      key: 'youtube',
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      color: Color(0xFFFF0000),
      keywords: [
        'youtube',
        'yt ',
        'shorts',
      ],
    ),
    _Platform(
      key: 'facebook',
      name: 'Facebook',
      icon: FontAwesomeIcons.facebookF,
      color: Color(0xFF1877F2),
      keywords: [
        'facebook',
        'fb ',
      ],
    ),
    _Platform(
      key: 'telegram',
      name: 'Telegram',
      icon: FontAwesomeIcons.telegram,
      color: Color(0xFF229ED9),
      keywords: [
        'telegram',
        'tg ',
      ],
    ),
    _Platform(
      key: 'website',
      name: 'Website Traffic',
      icon: FontAwesomeIcons.globe,
      color: Color(0xFF10B981),
      keywords: [
        'website',
        'traffic',
        'web hits',
        'visitor',
        'adsense',
        'ad sense',
        'web ',
      ],
    ),
  ];

  static const _trafficKeywords = [
    'traffic',
    'web hits',
    'web visitor',
    'website',
    'adsense',
    'ad sense',
    'redirection',
    'redirect',
  ];

  static const _platformDetectionOrder = [
    {
      'key': 'instagram',
      'kws': [
        'instagram',
        'insta',
        'ig ',
      ],
    },
    {
      'key': 'youtube',
      'kws': [
        'youtube',
        'yt ',
        'shorts',
      ],
    },
    {
      'key': 'facebook',
      'kws': [
        'facebook',
        'fb ',
      ],
    },
    {
      'key': 'telegram',
      'kws': [
        'telegram',
        'tg ',
      ],
    },
  ];

  String? _selectedPlatform;

  // ========================================================
  // SUPABASE REALTIME STREAM
  // ONLY ACTIVE SERVICES ARE RETURNED
  // ========================================================
  Stream<List<Map<String, dynamic>>>
      _servicesStream() {
    return Supabase.instance.client
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('id', ascending: true);
  }

  String? _detectPlatform(
    Map<String, dynamic> s,
  ) {
    final cat =
        (s['category'] ?? '')
            .toString()
            .toLowerCase();

    final name =
        (s['name'] ?? '')
            .toString()
            .toLowerCase();

    final source =
        cat.isNotEmpty ? cat : name;

    int? earliestPos;
    String? detected;

    for (final entry
        in _platformDetectionOrder) {
      final key =
          entry['key'] as String;

      final kws =
          entry['kws'] as List<String>;

      for (final kw in kws) {
        final pos =
            source.indexOf(kw);

        if (pos >= 0) {
          if (earliestPos == null ||
              pos < earliestPos) {
            earliestPos = pos;
            detected = key;
          }

          break;
        }
      }
    }

    return detected;
  }

  bool _isTrafficService(
    Map<String, dynamic> s,
  ) {
    final cat =
        (s['category'] ?? '')
            .toString()
            .toLowerCase();

    final name =
        (s['name'] ?? '')
            .toString()
            .toLowerCase();

    for (final kw in _trafficKeywords) {
      if (cat.contains(kw) ||
          name.contains(kw)) {
        return true;
      }
    }

    return false;
  }

  List<Map<String, dynamic>>
      _filterByPlatform(
    List<Map<String, dynamic>> all,
    _Platform platform,
  ) {
    return all.where((s) {
      final isTraffic =
          _isTrafficService(s);

      if (platform.key == 'website') {
        return isTraffic;
      }

      if (isTraffic) {
        return false;
      }

      final detected =
          _detectPlatform(s);

      return detected ==
          platform.key;
    }).toList();
  }

  double _minPrice(
    List<Map<String, dynamic>> services,
  ) {
    if (services.isEmpty) {
      return 0;
    }

    double min =
        double.infinity;

    for (final s in services) {
      final p =
          double.tryParse(
                s['selling_rate']
                    .toString(),
              ) ??
              0;

      if (p > 0 && p < min) {
        min = p;
      }
    }

    return min ==
            double.infinity
        ? 0
        : min;
  }

  _Platform get _currentPlatform =>
      _platforms.firstWhere(
        (p) =>
            p.key ==
            _selectedPlatform,
      );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,
        elevation: 0,

        leading:
            _selectedPlatform !=
                    null
                ? IconButton(
                    icon:
                        const Icon(
                      Icons.arrow_back,
                      color: AppColors
                          .textPrimary,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPlatform =
                            null;
                      });
                    },
                  )
                : null,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
                color: AppColors
                    .textPrimary,
                letterSpacing: -0.5,
              ),
            ),

            if (_selectedPlatform !=
                null)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 2,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    FaIcon(
                      _currentPlatform
                          .icon,
                      size: 12,
                      color:
                          _currentPlatform
                              .color,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      _currentPlatform
                          .name,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _currentPlatform
                                .color,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      body: StreamBuilder<
          List<Map<String, dynamic>>>(
        stream:
            _servicesStream(),

        builder:
            (context, snapshot) {
          if (snapshot
                      .connectionState ==
                  ConnectionState
                      .waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  'Failed to load services.\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: AppColors
                        .textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }

          final all =
              snapshot.data ?? [];

          if (_selectedPlatform ==
              null) {
            return _buildPlatformGrid(
              all,
            );
          }

          return _OrderForm(
            platform:
                _currentPlatform,
            platformServices:
                _filterByPlatform(
              all,
              _currentPlatform,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatformGrid(
    List<Map<String, dynamic>> all,
  ) {
    final w =
        MediaQuery.of(context)
            .size
            .width;

    final isMobile =
        w < 720;

    final isTablet =
        w >= 720 &&
            w < 1100;

    final cardWidth = isMobile
        ? double.infinity
        : isTablet
            ? (w - 48 - 16) / 2
            : (w - 48 - 32) / 3;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),

      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 1200,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'Choose a platform',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                  color: AppColors
                      .textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Pick a platform to start placing your order.',
                style: TextStyle(
                  color: AppColors
                      .textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children:
                    _platforms.map(
                  (p) {
                    final services =
                        _filterByPlatform(
                      all,
                      p,
                    );

                    return SizedBox(
                      width: cardWidth ==
                              double
                                  .infinity
                          ? 320
                          : cardWidth,

                      child:
                          _PlatformCard(
                        platform: p,
                        serviceCount:
                            services
                                .length,
                        minPrice:
                            _minPrice(
                          services,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedPlatform =
                                p.key;
                          });
                        },
                      ),
                    );
                  },
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ORDER FORM
// ==========================================================
class _OrderForm
    extends StatefulWidget {
  final _Platform platform;

  final List<Map<String, dynamic>>
      platformServices;

  const _OrderForm({
    required this.platform,
    required this.platformServices,
  });

  @override
  State<_OrderForm> createState() =>
      _OrderFormState();
}

class _OrderFormState
    extends State<_OrderForm> {
  String? _selectedCategory;

  // Store service ID instead of
  // storing the complete Map.
  String? _selectedServiceId;

  final _linkController =
      TextEditingController();

  final _qtyController =
      TextEditingController();

  bool _placing = false;

  String? _error;

  @override
  void dispose() {
    _linkController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // ========================================================
  // GROUP SERVICES
  // ========================================================
  Map<String,
          List<Map<String, dynamic>>>
      get _grouped {
    final map =
        <String,
            List<Map<String, dynamic>>>{};

    for (final s
        in widget.platformServices) {
      final cat =
          (s['category'] ??
                  'Other')
              .toString();

      map.putIfAbsent(
        cat,
        () => [],
      ).add(s);
    }

    return map;
  }

  List<String>
      get _availableCategories {
    final keys =
        _grouped.keys.toList();

    keys.sort();

    return keys;
  }

  List<Map<String, dynamic>>
      get _servicesInCategory {
    if (_selectedCategory ==
        null) {
      return [];
    }

    return _grouped[
            _selectedCategory] ??
        [];
  }

  // ========================================================
  // CURRENT SELECTED SERVICE
  // ========================================================
  Map<String, dynamic>?
      get _selectedService {
    if (_selectedServiceId ==
        null) {
      return null;
    }

    for (final service
        in _servicesInCategory) {
      if (service['id']
              .toString() ==
          _selectedServiceId) {
        return service;
      }
    }

    return null;
  }

  // ========================================================
  // REALTIME UPDATE SAFETY
  // ========================================================
  @override
  void didUpdateWidget(
    covariant _OrderForm oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final categories =
        _grouped.keys.toSet();

    // Category disappeared
    if (_selectedCategory !=
            null &&
        !categories.contains(
          _selectedCategory,
        )) {
      _selectedCategory =
          null;

      _selectedServiceId =
          null;

      _linkController.clear();
      _qtyController.clear();

      _error = null;

      return;
    }

    // Selected service disappeared
    if (_selectedServiceId !=
        null) {
      final stillAvailable =
          widget.platformServices
              .any(
        (s) =>
            s['id'].toString() ==
            _selectedServiceId,
      );

      if (!stillAvailable) {
        _selectedServiceId =
            null;

        _linkController.clear();
        _qtyController.clear();

        _error =
            'This service is no longer available.';
      }
    }
  }

  // ========================================================
  // COST
  // ========================================================
  double get _cost {
    final service =
        _selectedService;

    if (service == null) {
      return 0;
    }

    final rate =
        double.tryParse(
              service[
                      'selling_rate']
                  .toString(),
            ) ??
            0;

    final qty =
        int.tryParse(
              _qtyController.text,
            ) ??
            0;

    return (rate / 1000) *
        qty;
  }

  // ========================================================
  // PLACE ORDER
  // ========================================================
  Future<void>
      _placeOrder() async {
    setState(() {
      _error = null;
    });

    final service =
        _selectedService;

    if (service == null) {
      setState(() {
        _error =
            'Please select a service.';
      });

      return;
    }

    if (_linkController.text
        .trim()
        .isEmpty) {
      setState(() {
        _error =
            'Please enter the link.';
      });

      return;
    }

    final qty =
        int.tryParse(
              _qtyController.text,
            ) ??
            0;

    final minOrder =
        int.tryParse(
              service[
                      'min_order']
                  .toString(),
            ) ??
            1;

    final maxOrder =
        int.tryParse(
              service[
                      'max_order']
                  .toString(),
            ) ??
            100000;

    if (qty < minOrder ||
        qty > maxOrder) {
      setState(() {
        _error =
            'Quantity must be between $minOrder and $maxOrder.';
      });

      return;
    }

    setState(() {
      _placing = true;
    });

    try {
      final api =
          context.read<
              ApiService>();

      final result =
          await api.addOrder(
        serviceId:
            int.parse(
          service['id'].toString(),
        ),
        link:
            _linkController.text
                .trim(),
        quantity: qty,
      );

      if (!mounted) return;

      final charged =
          double.tryParse(
                result['charge']
                    .toString(),
              ) ??
              0;

      final cur =
          context.read<
              CurrencyProvider>();

      setState(() {
        _placing = false;

        _linkController.clear();
        _qtyController.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed! ID: ${result['order']} · Charged: ${cur.format(charged)}',
          ),
          backgroundColor:
              AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _placing = false;

        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ========================================================
  // BUILD
  // ========================================================
  @override
  Widget build(
    BuildContext context,
  ) {
    final platform =
        widget.platform;

    final cur =
        context.watch<
            CurrencyProvider>();

    final w =
        MediaQuery.of(context)
            .size
            .width;

    final isMobile =
        w < 720;

    final categories =
        _availableCategories;

    final selectedService =
        _selectedService;

    final meta =
        selectedService != null
            ? _ServiceMeta.fromRaw(
                selectedService,
              )
            : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        isMobile ? 16 : 32,
      ),

      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 780,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
            children: [
              Container(
                padding:
                    EdgeInsets.all(
                  isMobile
                      ? 20
                      : 28,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      AppColors
                          .background,

                  borderRadius:
                      BorderRadius
                          .circular(16),

                  border:
                      Border.all(
                    color:
                        AppColors
                            .border,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    // ==================================================
                    // CATEGORY
                    // ==================================================
                    const _FieldLabel(
                      'Category',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _DropdownShell(
                      child:
                          DropdownButtonHideUnderline(
                        child:
                            DropdownButton<
                                String>(
                          value:
                              categories
                                      .contains(
                            _selectedCategory,
                          )
                                  ? _selectedCategory
                                  : null,

                          isExpanded:
                              true,

                          hint:
                              const Text(
                            'Select a category',
                            style:
                                TextStyle(
                              color:
                                  AppColors
                                      .textMuted,
                              fontSize:
                                  14,
                            ),
                          ),

                          icon:
                              const Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                            color:
                                AppColors
                                    .textSecondary,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          dropdownColor:
                              AppColors
                                  .surface,

                          itemHeight:
                              null,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                14,
                            vertical:
                                4,
                          ),

                          selectedItemBuilder:
                              (context) {
                            return categories
                                .map(
                              (c) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical:
                                        12,
                                  ),
                                  child:
                                      Text(
                                    c,
                                    style:
                                        const TextStyle(
                                      color:
                                          AppColors
                                              .textPrimary,
                                      fontSize:
                                          13.5,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      height:
                                          1.4,
                                    ),
                                  ),
                                );
                              },
                            ).toList();
                          },

                          items:
                              categories.map(
                            (c) {
                              final count =
                                  _grouped[c]
                                          ?.length ??
                                      0;

                              return DropdownMenuItem<
                                  String>(
                                value: c,

                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical:
                                        12,
                                  ),

                                  child:
                                      Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Expanded(
                                        child:
                                            Text(
                                          c,
                                          style:
                                              const TextStyle(
                                            color:
                                                AppColors
                                                    .textPrimary,
                                            fontSize:
                                                13.5,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            height:
                                                1.4,
                                          ),
                                          softWrap:
                                              true,
                                        ),
                                      ),

                                      const SizedBox(
                                        width:
                                            8,
                                      ),

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              8,
                                          vertical:
                                              3,
                                        ),

                                        decoration:
                                            BoxDecoration(
                                          color:
                                              AppColors
                                                  .primary
                                                  .withValues(
                                            alpha:
                                                0.1,
                                          ),

                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                        ),

                                        child:
                                            Text(
                                          '$count',
                                          style:
                                              const TextStyle(
                                            color:
                                                AppColors
                                                    .primary,
                                            fontSize:
                                                11,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              (c) {
                            setState(() {
                              _selectedCategory =
                                  c;

                              _selectedServiceId =
                                  null;

                              _error =
                                  null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // SERVICE
                    // ==================================================
                    const _FieldLabel(
                      'Service',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    _DropdownShell(
                      child:
                          DropdownButtonHideUnderline(
                        child:
                            DropdownButton<
                                String>(
                          value:
                              _servicesInCategory
                                      .any(
                            (s) =>
                                s['id']
                                    .toString() ==
                                _selectedServiceId,
                          )
                                  ? _selectedServiceId
                                  : null,

                          isExpanded:
                              true,

                          hint:
                              Text(
                            _selectedCategory ==
                                    null
                                ? 'Select a category first'
                                : 'Select a service',

                            style:
                                const TextStyle(
                              color:
                                  AppColors
                                      .textMuted,
                              fontSize:
                                  14,
                            ),
                          ),

                          icon:
                              const Icon(
                            Icons
                                .keyboard_arrow_down_rounded,
                            color:
                                AppColors
                                    .textSecondary,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          dropdownColor:
                              AppColors
                                  .surface,

                          itemHeight:
                              null,

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                14,
                            vertical:
                                4,
                          ),

                          selectedItemBuilder:
                              (context) {
                            return _servicesInCategory
                                .map(
                              (s) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical:
                                        12,
                                  ),

                                  child:
                                      Text(
                                    '${s['id']} - ${s['name']}',
                                    style:
                                        const TextStyle(
                                      color:
                                          AppColors
                                              .textPrimary,
                                      fontSize:
                                          12.5,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                      height:
                                          1.4,
                                    ),
                                  ),
                                );
                              },
                            ).toList();
                          },

                          items:
                              _servicesInCategory
                                  .map(
                            (s) {
                              final rate =
                                  double.tryParse(
                                        s['selling_rate']
                                            .toString(),
                                      ) ??
                                      0;

                              return DropdownMenuItem<
                                  String>(
                                value:
                                    s['id']
                                        .toString(),

                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical:
                                        12,
                                  ),

                                  child:
                                      Column(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [
                                      Text(
                                        '${s['id']} - ${s['name']}',
                                        style:
                                            const TextStyle(
                                          color:
                                              AppColors
                                                  .textPrimary,
                                          fontSize:
                                              12.5,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                          height:
                                              1.4,
                                        ),
                                      ),

                                      const SizedBox(
                                        height:
                                            4,
                                      ),

                                      Text(
                                        '${cur.format(rate)} per 1000',
                                        style:
                                            TextStyle(
                                          color:
                                              platform
                                                  .color,
                                          fontSize:
                                              11.5,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ).toList(),

                          onChanged:
                              _selectedCategory ==
                                          null ||
                                      _servicesInCategory
                                          .isEmpty
                                  ? null
                                  : (id) {
                                      setState(() {
                                        _selectedServiceId =
                                            id;

                                        _error =
                                            null;
                                      });
                                    },
                        ),
                      ),
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================
                    if (meta != null &&
                        meta.description !=
                            null &&
                        meta.description!
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 20,
                      ),

                      const _FieldLabel(
                        'Description',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(14),

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .surface,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),

                          border:
                              Border.all(
                            color:
                                AppColors
                                    .border,
                          ),
                        ),

                        child:
                            Text(
                          meta.description!,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textSecondary,
                            fontSize:
                                13,
                            height:
                                1.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // LINK
                    // ==================================================
                    const _FieldLabel(
                      'Link',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          _linkController,

                      enabled:
                          selectedService !=
                              null,

                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textPrimary,
                        fontSize:
                            14,
                      ),

                      decoration:
                          InputDecoration(
                        hintText:
                            platform.key ==
                                    'website'
                                ? 'Paste your website URL'
                                : 'Paste your link here',
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // QUANTITY
                    // ==================================================
                    const _FieldLabel(
                      'Quantity',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          _qtyController,

                      enabled:
                          selectedService !=
                              null,

                      keyboardType:
                          TextInputType
                              .number,

                      onChanged:
                          (_) =>
                              setState(
                        () {},
                      ),

                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textPrimary,
                        fontSize:
                            14,
                      ),

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Enter quantity',
                      ),
                    ),

                    if (selectedService !=
                        null) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Min: ${selectedService['min_order']} - Max: ${selectedService['max_order']}',

                        style:
                            const TextStyle(
                          color:
                              AppColors
                                  .textSecondary,
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],

                    // ==================================================
                    // AVERAGE TIME
                    // ==================================================
                    if (meta != null &&
                        meta.avgTime !=
                            null &&
                        meta.avgTime!
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 20,
                      ),

                      const _FieldLabel(
                        'Average time',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(14),

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .surface,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),

                          border:
                              Border.all(
                            color:
                                AppColors
                                    .border,
                          ),
                        ),

                        child:
                            Row(
                          children: [
                            const Icon(
                              Icons
                                  .schedule,
                              color:
                                  AppColors
                                      .textMuted,
                              size:
                                  16,
                            ),

                            const SizedBox(
                              width:
                                  10,
                            ),

                            Text(
                              meta.avgTime!,

                              style:
                                  const TextStyle(
                                color:
                                    AppColors
                                        .textPrimary,
                                fontSize:
                                    13,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ==================================================
                    // CHARGE
                    // ==================================================
                    const SizedBox(
                      height: 20,
                    ),

                    const _FieldLabel(
                      'Charge',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets
                              .all(16),

                      decoration:
                          BoxDecoration(
                        color:
                            platform
                                .color
                                .withValues(
                          alpha: 0.08,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),

                        border:
                            Border.all(
                          color:
                              platform
                                  .color
                                  .withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),

                      child:
                          Row(
                        children: [
                          Icon(
                            Icons
                                .receipt_long,
                            color:
                                platform
                                    .color,
                            size:
                                20,
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Text(
                            cur.format(
                              _cost,
                            ),

                            style:
                                TextStyle(
                              color:
                                  platform
                                      .color,
                              fontSize:
                                  22,
                              fontWeight:
                                  FontWeight
                                      .w800,
                              letterSpacing:
                                  -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // ERROR
                    // ==================================================
                    if (_error !=
                        null) ...[
                      const SizedBox(
                        height: 16,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .all(12),

                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .error
                              .withValues(
                            alpha: 0.08,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),

                          border:
                              Border.all(
                            color: AppColors
                                .error
                                .withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),

                        child:
                            Row(
                          children: [
                            const Icon(
                              Icons
                                  .error_outline,
                              color:
                                  AppColors
                                      .error,
                              size:
                                  16,
                            ),

                            const SizedBox(
                              width:
                                  8,
                            ),

                            Expanded(
                              child:
                                  Text(
                                _error!,
                                style:
                                    const TextStyle(
                                  color:
                                      AppColors
                                          .error,
                                  fontSize:
                                      12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ==================================================
                    // PLACE ORDER
                    // ==================================================
                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      height: 54,

                      child:
                          ElevatedButton(
                        onPressed:
                            _placing
                                ? null
                                : _placeOrder,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              platform
                                  .color,

                          foregroundColor:
                              Colors.white,

                          elevation:
                              0,

                          disabledBackgroundColor:
                              platform
                                  .color
                                  .withValues(
                            alpha:
                                0.4,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),

                        child: _placing
                            ? const SizedBox(
                                width:
                                    22,
                                height:
                                    22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'Place Order',
                                style:
                                    TextStyle(
                                  fontSize:
                                      16,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// SHARED WIDGETS
// ==========================================================
class _FieldLabel
    extends StatelessWidget {
  final String text;

  const _FieldLabel(
    this.text,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        fontSize: 13,
        fontWeight:
            FontWeight.w700,
        color:
            AppColors.textPrimary,
        letterSpacing:
            -0.2,
      ),
    );
  }
}

class _DropdownShell
    extends StatelessWidget {
  final Widget child;

  const _DropdownShell({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),

      padding:
          const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: ButtonTheme(
        alignedDropdown:
            true,
        child: child,
      ),
    );
  }
}

// ==========================================================
// PLATFORM CARD
// ==========================================================
class _PlatformCard
    extends StatelessWidget {
  final _Platform platform;
  final int serviceCount;
  final double minPrice;
  final VoidCallback onTap;

  const _PlatformCard({
    required this.platform,
    required this.serviceCount,
    required this.minPrice,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final cur =
        context.watch<
            CurrencyProvider>();

    final color =
        platform.color;

    return Material(
      color:
          AppColors.background,

      borderRadius:
          BorderRadius.circular(
        20,
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        splashColor:
            color.withValues(
          alpha: 0.12,
        ),

        highlightColor:
            color.withValues(
          alpha: 0.06,
        ),

        child: Container(
          padding:
              const EdgeInsets.all(
            24,
          ),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            border:
                Border.all(
              color:
                  AppColors.border,
              width:
                  1.5,
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  14,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.12,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),

                child: FaIcon(
                  platform.icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                platform.name,

                style:
                    const TextStyle(
                  color: AppColors
                      .textPrimary,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      -0.5,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '$serviceCount services',

                style:
                    const TextStyle(
                  color: AppColors
                      .textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              Row(
                children: [
                  if (minPrice > 0) ...[
                    const Text(
                      'From ',

                      style:
                          TextStyle(
                        color:
                            AppColors
                                .textMuted,
                        fontSize:
                            11,
                      ),
                    ),

                    Text(
                      cur.format(
                        minPrice,
                      ),

                      style:
                          TextStyle(
                        color:
                            color,
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      width: 2,
                    ),

                    const Text(
                      '/1000',

                      style:
                          TextStyle(
                        color:
                            AppColors
                                .textMuted,
                        fontSize:
                            10,
                      ),
                    ),
                  ],

                  const Spacer(),

                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color:
                        AppColors
                            .textMuted,
                    size: 18,
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