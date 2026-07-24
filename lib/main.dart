import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await savedNews.load();
  runApp(const GeotixApp());
}

const navy = Color(0xFF02070D);
const panel = Color(0xFF0C1D29);
const cyan = Color(0xFF59D9FF);
const muted = Color(0xFF91A6B3);
final savedNews = SavedNewsStore();

class GeotixApp extends StatelessWidget {
  const GeotixApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GEOTIX',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: navy,
          colorScheme: ColorScheme.fromSeed(seedColor: cyan, brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF061B2A), navy], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              final globe = (constraints.maxWidth * .58).clamp(180.0, compact ? 215.0 : 270.0).toDouble();
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth < 380 ? 20 : 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(children: [
                    SizedBox(height: compact ? 18 : 38),
                    const Text('WELCOME TO', style: TextStyle(color: cyan, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    FittedBox(child: Text('GEOTIX', style: TextStyle(fontSize: compact ? 38 : 46, letterSpacing: 7, fontWeight: FontWeight.w900))),
                    SizedBox(height: compact ? 28 : 60),
                    GlobeArt(size: globe),
                    SizedBox(height: compact ? 30 : 60),
                    const FittedBox(child: Text('See the world as it happens.', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 12),
                    const Text('Reality news mapped from country to district.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 15, height: 1.5)),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF19BDEB), foregroundColor: const Color(0xFF001018), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeShell())),
                        child: const Text('START EXPLORING  →', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}

class GlobeArt extends StatelessWidget {
  const GlobeArt({super.key, required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF1A83C7), Color(0xFF063858), Color(0xFF02121E)]),
          border: Border.all(color: cyan, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x6657D9FF), blurRadius: 42, spreadRadius: 2)],
        ),
        child: Icon(Icons.public, size: size * .72, color: const Color(0xFF6BE4FF)),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [GlobePage(), ExplorePage(), AlertsPage(), SavedPage()];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: index == 0 ? null : AppBar(
          backgroundColor: const Color(0xFF061523),
          surfaceTintColor: Colors.transparent,
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GEOTIX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)),
            Text('3D REALITY NEWS', style: TextStyle(color: cyan, fontSize: 8, letterSpacing: 2)),
          ]),
          actions: [
            Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF0E382C), borderRadius: BorderRadius.circular(20)), child: const Text('● LIVE', style: TextStyle(color: Color(0xFF51E5A8), fontSize: 10, fontWeight: FontWeight.bold)))),
            IconButton(onPressed: () => setState(() => index = 2), icon: const Icon(Icons.notifications_outlined)),
          ],
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF061523),
          indicatorColor: const Color(0xFF16445A),
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.public), label: 'Globe'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
          ],
        ),
      );
}

class GlobePage extends StatefulWidget {
  const GlobePage({super.key});
  @override
  State<GlobePage> createState() => _GlobePageState();
}

class _GlobePageState extends State<GlobePage> {
  late final WebViewController controller;
  Timer? clockTimer;
  late double selectedHour;
  bool isLive = true;
  String place = 'Chennai';
  String region = 'Tamil Nadu, India';
  int stories = 12;
  bool markerSheetOpen = false;
  void select(String p, String r, int s) => setState(() { place = p; region = r; stories = s; });

  Future<void> showMarkerNews(String p, String r, int count) async {
    if (!mounted || markerSheetOpen) return;
    select(p, r, count);
    markerSheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF081B2A),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF247395)),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFF617787), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.location_on, color: cyan),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text(r, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0x332FE6A0), borderRadius: BorderRadius.circular(20)), child: const Text('● LIVE', style: TextStyle(color: Color(0xFF51E5A8), fontSize: 11, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF102A3D), borderRadius: BorderRadius.circular(19)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BREAKING', style: TextStyle(color: Color(0xFFFF6478), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
                const SizedBox(height: 7),
                Text('Important local development reported in $p', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 9),
                Text('8 min ago  •  $count active stories', style: const TextStyle(color: muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LocationNewsScreen(place: p, region: r, storyCount: count)));
              },
              icon: const Icon(Icons.radar),
              label: const Text('VIEW ALL STORIES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8)),
            )),
          ]),
        ),
      ),
    );
    markerSheetOpen = false;
  }

  double get currentLocalHour {
    final now = DateTime.now();
    return now.hour + now.minute / 60 + now.second / 3600;
  }

  String formatHour(double value) {
    var hour = value.floor() % 24;
    var minute = ((value - value.floor()) * 60).round();
    if (minute == 60) { hour = (hour + 1) % 24; minute = 0; }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void applyGlobeTime(double localHour) {
    final offset = DateTime.now().timeZoneOffset.inMinutes / 60;
    final utcHour = (localHour - offset + 24) % 24;
    controller.runJavaScript('setGeotixHour(${utcHour.toStringAsFixed(4)})');
  }

  void changeHour(double value) {
    setState(() { selectedHour = value; isLive = false; });
    applyGlobeTime(value);
  }

  void returnToLive() {
    setState(() { selectedHour = currentLocalHour; isLive = true; });
    controller.runJavaScript('setGeotixHour(null)');
  }

  void searchGlobe(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    controller.runJavaScript('searchGeotixPlace(${jsonEncode(query)})');
  }

  @override
  void initState() {
    super.initState();
    selectedHour = currentLocalHour;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(navy)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => controller.runJavaScript('setGeotixHour(null)'),
      ))
      ..addJavaScriptChannel(
        'Geotix',
        onMessageReceived: (message) {
          final parts = message.message.split('|');
          if (parts.length == 3) {
            select(parts[0], parts[1], int.tryParse(parts[2]) ?? 0);
          }
        },
      )
      ..addJavaScriptChannel(
        'GeotixStatus',
        onMessageReceived: (message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..addJavaScriptChannel(
        'GeotixStory',
        onMessageReceived: (message) {
          final parts = message.message.split('|');
          if (parts.length == 3) {
            showMarkerNews(parts[0], parts[1], int.tryParse(parts[2]) ?? 0);
          }
        },
      )
      ..loadFlutterAsset('assets/globe.html');
    clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isLive && mounted) setState(() => selectedHour = currentLocalHour);
    });
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth < 380 ? 14.0 : 20.0;
        final compact = c.maxHeight < 650;
        return SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: ColoredBox(
            color: navy,
            child: Stack(fit: StackFit.expand, children: [
            Positioned.fill(
              child: WebViewWidget(
                controller: controller,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: compact ? 210 : 235,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [navy, navy.withOpacity(.92), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(side, 12, side, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('GEOTIX', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        Text('3D REALITY NEWS', style: TextStyle(color: cyan, fontSize: 8, letterSpacing: 2.2)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xCC0E382C), borderRadius: BorderRadius.circular(20)),
                      child: const Text('● LIVE', style: TextStyle(color: Color(0xFF51E5A8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_outlined)),
                  ]),
                  SizedBox(height: compact ? 8 : 14),
                  TextField(
                    textInputAction: TextInputAction.search,
                    onSubmitted: searchGlobe,
                    decoration: InputDecoration(
                      hintText: 'Search country, state or district',
                      hintStyle: const TextStyle(color: Color(0xFF718795)),
                      prefixIcon: const Icon(Icons.search),
                      helperText: 'Location search © OpenStreetMap contributors',
                      helperStyle: const TextStyle(color: Color(0xFF607785), fontSize: 8),
                      filled: true,
                      fillColor: const Color(0xE60C1D29),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ]),
              ),
            ),
            Positioned(
              left: side,
              right: side,
              bottom: compact ? 10 : 16,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xB3061523), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Drag to rotate  •  Pinch to zoom  •  Tap a marker', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD0DFE7), fontSize: 10)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.fromLTRB(compact ? 10 : 13, 8, compact ? 10 : 13, 7),
                  decoration: BoxDecoration(
                    color: const Color(0xE60A1730),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF244C75)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Icon(isLive ? Icons.sensors : Icons.history, color: isLive ? const Color(0xFF51E5A8) : cyan, size: 17),
                      const SizedBox(width: 7),
                      Text(isLive ? 'LIVE NOW' : 'VIEWING ${formatHour(selectedHour)}', style: TextStyle(color: isLive ? const Color(0xFF51E5A8) : cyan, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const Spacer(),
                      if (!isLive) TextButton(onPressed: returnToLive, child: const Text('RETURN LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                      if (isLive) Text(formatHour(selectedHour), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), overlayShape: const RoundSliderOverlayShape(overlayRadius: 14)),
                      child: Slider(value: selectedHour.clamp(0, 24).toDouble(), min: 0, max: 24, divisions: 96, onChanged: changeHour),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('00:00', style: TextStyle(color: muted, fontSize: 8)),
                        Text('06:00', style: TextStyle(color: muted, fontSize: 8)),
                        Text('12:00', style: TextStyle(color: muted, fontSize: 8)),
                        Text('18:00', style: TextStyle(color: muted, fontSize: 8)),
                        Text('24:00', style: TextStyle(color: muted, fontSize: 8)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 13 : 16),
                  decoration: BoxDecoration(
                    color: const Color(0xE60C1D29),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xAA29708F)),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 22)],
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_on, color: cyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SELECTED LOCATION', style: TextStyle(color: cyan, fontSize: 9, letterSpacing: 1.5)),
                      const SizedBox(height: 3),
                      Text(place, style: TextStyle(fontSize: compact ? 17 : 20, fontWeight: FontWeight.bold)),
                      Text('$region • $stories active stories', style: const TextStyle(color: muted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationNewsScreen(
                            place: place,
                            region: region,
                            storyCount: stories,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 27),
                    ),
                  ]),
                ),
              ]),
            ),
            ]),
          ),
        );
      });
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String filter = 'All';
  final searchController = TextEditingController();
  List<Story> items = [];
  bool loading = true;
  String searchedPlace = 'Chennai';
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadNews('Chennai'));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadNews(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { loading = true; error = null; searchedPlace = query; filter = 'All'; });
    try {
      final result = await LiveNewsService.fetch(query, 'Searched location');
      if (!mounted) return;
      setState(() { items = result; loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { loading = false; error = 'Could not load news for $query.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = filter == 'All' ? items : items.where((s) => s.category == filter.toUpperCase()).toList();
    return LayoutBuilder(builder: (context, c) => ListView(
          padding: EdgeInsets.symmetric(horizontal: c.maxWidth < 380 ? 14 : 20, vertical: 18),
          children: [
            const Text('DISCOVER BY PLACE', style: TextStyle(color: cyan, letterSpacing: 2, fontSize: 11)),
            const SizedBox(height: 5),
            const Text('Explore reality news', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SearchBox(hint: 'Search country, state, city or district', controller: searchController, onSubmitted: loadNews),
            const SizedBox(height: 14),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Breaking', 'Local', 'Weather', 'Technology', 'Travel'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f), selectedColor: const Color(0xFF19BDEB), labelStyle: TextStyle(color: filter == f ? const Color(0xFF001018) : Colors.white, fontWeight: FontWeight.bold)),
            )).toList())),
            const SizedBox(height: 16),
            if (loading) const Padding(padding: EdgeInsets.all(44), child: Center(child: CircularProgressIndicator(color: cyan)))
            else if (error != null) InfoCard(child: Column(children: [
              const Icon(Icons.cloud_off, color: muted, size: 42),
              const SizedBox(height: 10),
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => loadNews(searchedPlace), icon: const Icon(Icons.refresh), label: const Text('RETRY')),
            ]))
            else if (shown.isEmpty) InfoCard(child: Column(children: [
              const Icon(Icons.manage_search, color: cyan, size: 42),
              const SizedBox(height: 10),
              Text(filter == 'All' ? 'No headlines found for $searchedPlace.' : 'No $filter headlines found for $searchedPlace.', textAlign: TextAlign.center),
            ]))
            else ...shown.map((story) => StoryCard(
              story: story,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(story: story))),
            )),
          ],
        ));
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: const [
        Text('LIVE UPDATES', style: TextStyle(color: cyan, letterSpacing: 2, fontSize: 11)),
        SizedBox(height: 6),
        Text('Alerts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 18),
        StoryCard(story: Story('BREAKING', 'Chennai, Tamil Nadu', 'Transport update affects your followed district', '12 min ago', Color(0xFFFF4C61))),
        StoryCard(story: Story('WEATHER', 'London, United Kingdom', 'Weather advisory remains active', '45 min ago', Color(0xFF8B7CFF))),
      ]);
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: savedNews,
        builder: (context, _) {
          if (savedNews.items.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bookmark_outline, size: 72, color: cyan),
                SizedBox(height: 16),
                Text('No saved stories yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Tap the bookmark on a story to keep it here.', textAlign: TextAlign.center, style: TextStyle(color: muted)),
              ]),
            ));
          }
          return LayoutBuilder(builder: (context, c) => ListView(
            padding: EdgeInsets.fromLTRB(c.maxWidth < 380 ? 14 : 20, 18, c.maxWidth < 380 ? 14 : 20, 30),
            children: [
              const Text('YOUR COLLECTION', style: TextStyle(color: cyan, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 5),
              Text('${savedNews.items.length} saved ${savedNews.items.length == 1 ? 'story' : 'stories'}', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              ...savedNews.items.map((story) => StoryCard(
                story: story,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(story: story))),
              )),
            ],
          ));
        },
      );
}

class LocationNewsScreen extends StatefulWidget {
  const LocationNewsScreen({
    super.key,
    required this.place,
    required this.region,
    required this.storyCount,
  });

  final String place;
  final String region;
  final int storyCount;

  @override
  State<LocationNewsScreen> createState() => _LocationNewsScreenState();
}

class _LocationNewsScreenState extends State<LocationNewsScreen> {
  late Future<List<Story>> newsFuture;

  @override
  void initState() {
    super.initState();
    newsFuture = LiveNewsService.fetch(widget.place, widget.region);
  }

  void retry() => setState(() {
        newsFuture = LiveNewsService.fetch(widget.place, widget.region);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF061523),
          title: Text(widget.place, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: LayoutBuilder(builder: (context, c) {
          final side = c.maxWidth < 380 ? 14.0 : 20.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.fromLTRB(side, 18, side, 30),
                children: [
                  const Text('REALITY NEWS BY PLACE', style: TextStyle(color: cyan, fontSize: 10, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(widget.place, style: TextStyle(fontSize: c.maxWidth < 380 ? 27 : 32, fontWeight: FontWeight.w900)),
                  Text(widget.region, style: const TextStyle(color: muted, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFF092236), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF18506B))),
                    child: Row(children: [
                      const Icon(Icons.radar, color: cyan),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Live headlines near ${widget.place}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      const Text('LIVE', style: TextStyle(color: Color(0xFF51E5A8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<Story>>(
                    future: newsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(padding: EdgeInsets.all(42), child: Center(child: CircularProgressIndicator(color: cyan)));
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return InfoCard(child: Column(children: [
                          const Icon(Icons.cloud_off, color: muted, size: 42),
                          const SizedBox(height: 10),
                          const Text('Live news is temporarily unavailable.', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Check your internet connection and try again.', style: TextStyle(color: muted, fontSize: 12)),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('RETRY')),
                        ]));
                      }
                      return Column(children: snapshot.data!.map((story) => StoryCard(
                        story: story,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(story: story))),
                      )).toList());
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      );
}

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF061523),
          title: const Text('GEOTIX NEWS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          actions: [AnimatedBuilder(
            animation: savedNews,
            builder: (context, _) => IconButton(
              tooltip: savedNews.contains(story) ? 'Remove from saved' : 'Save story',
              onPressed: () {
                final wasSaved = savedNews.contains(story);
                savedNews.toggle(story);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(wasSaved ? 'Removed from Saved' : 'Story saved'),
                  duration: const Duration(seconds: 1),
                ));
              },
              icon: Icon(savedNews.contains(story) ? Icons.bookmark : Icons.bookmark_border, color: savedNews.contains(story) ? cyan : null),
            ),
          )],
        ),
        body: LayoutBuilder(builder: (context, c) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(c.maxWidth < 380 ? 16 : 22, 20, c.maxWidth < 380 ? 16 : 22, 36),
                  children: [
                    Container(
                      height: (c.maxWidth * .48).clamp(180.0, 330.0).toDouble(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [story.color.withOpacity(.85), const Color(0xFF061523)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(child: Icon(Icons.public, size: 100, color: Colors.white70)),
                    ),
                    const SizedBox(height: 20),
                    Text('${story.category} • ${story.time}', style: TextStyle(color: story.color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    Text(story.title, style: TextStyle(fontSize: c.maxWidth < 380 ? 26 : 31, fontWeight: FontWeight.w900, height: 1.15)),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.location_on, color: cyan, size: 19),
                      const SizedBox(width: 7),
                      Expanded(child: Text(story.place, style: const TextStyle(color: muted))),
                    ]),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF0D2A24), borderRadius: BorderRadius.circular(16)),
                      child: const Row(children: [
                        Icon(Icons.verified, color: Color(0xFF51E5A8)),
                        SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Publisher source', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Open the original report to verify full details', style: TextStyle(color: muted, fontSize: 11)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    Text('Reported by ${story.source}. GEOTIX displays the headline and location context from the live feed. Open the original source for the complete report.', style: const TextStyle(fontSize: 16, height: 1.65, color: Color(0xFFD4E0E7))),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: story.url.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleWebScreen(title: story.source, url: story.url))),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('VIEW ORIGINAL SOURCE'),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      );
}

class Story {
  const Story(this.category, this.place, this.title, this.time, this.color, {this.url = '', this.source = 'News source'});
  final String category, place, title, time, url, source;
  final Color color;

  Map<String, dynamic> toJson() => {
        'category': category,
        'place': place,
        'title': title,
        'time': time,
        'color': color.toARGB32(),
        'url': url,
        'source': source,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        json['category'] as String? ?? 'LATEST',
        json['place'] as String? ?? 'Unknown location',
        json['title'] as String? ?? 'Untitled story',
        json['time'] as String? ?? 'Recently',
        Color(json['color'] as int? ?? 0xFF19BDEB),
        url: json['url'] as String? ?? '',
        source: json['source'] as String? ?? 'News source',
      );
}

class SavedNewsStore extends ChangeNotifier {
  static const String _storageKey = 'geotix_saved_stories_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final List<Story> _items = [];
  List<Story> get items => List.unmodifiable(_items);

  Future<void> load() async {
    try {
      final saved = await _preferences.getString(_storageKey);
      if (saved == null || saved.isEmpty) return;
      final decoded = jsonDecode(saved) as List<dynamic>;
      _items
        ..clear()
        ..addAll(decoded.whereType<Map<String, dynamic>>().map(Story.fromJson));
    } catch (_) {
      _items.clear();
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_items.map((story) => story.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }

  String _key(Story story) => story.url.isNotEmpty ? story.url : '${story.title}|${story.place}';
  bool contains(Story story) => _items.any((item) => _key(item) == _key(story));

  void toggle(Story story) {
    final index = _items.indexWhere((item) => _key(item) == _key(story));
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.insert(0, story);
    }
    notifyListeners();
    unawaited(_persist());
  }
}

class LiveNewsService {
  static Future<List<Story>> fetch(String place, String region) async {
    final query = Uri.encodeQueryComponent('"$place" news');
    final uri = Uri.parse('https://news.google.com/rss/search?q=$query&hl=en-IN&gl=IN&ceid=IN:en');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'GEOTIX/1.0');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) throw HttpException('News request failed');
      final xml = await utf8.decoder.bind(response).join();
      final items = RegExp(r'<item>([\s\S]*?)</item>', caseSensitive: false).allMatches(xml).take(15);
      return items.map((match) {
        final item = match.group(1)!;
        final rawTitle = _tag(item, 'title');
        final title = _decode(rawTitle);
        final source = _decode(_tag(item, 'source')).trim().isEmpty ? _publisherFromTitle(title) : _decode(_tag(item, 'source'));
        final category = _category(title);
        return Story(
          category,
          '$place, $region',
          title,
          _timeAgo(_tag(item, 'pubDate')),
          _categoryColor(category),
          url: _decode(_tag(item, 'link')),
          source: source,
        );
      }).where((story) => story.title.isNotEmpty).toList();
    } finally {
      client.close(force: true);
    }
  }

  static String _tag(String item, String name) {
    final match = RegExp('<$name(?:\\s[^>]*)?>([\\s\\S]*?)</$name>', caseSensitive: false).firstMatch(item);
    return match?.group(1)?.replaceAll('<![CDATA[', '').replaceAll(']]>', '').trim() ?? '';
  }

  static String _decode(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  static String _publisherFromTitle(String title) {
    final index = title.lastIndexOf(' - ');
    return index < 0 ? 'News source' : title.substring(index + 3);
  }

  static String _category(String title) {
    final value = title.toLowerCase();
    if (RegExp(r'weather|rain|storm|cyclone|flood|heatwave|forecast').hasMatch(value)) return 'WEATHER';
    if (RegExp(r'technology|tech|artificial intelligence|\bai\b|robot|software|startup').hasMatch(value)) return 'TECHNOLOGY';
    if (RegExp(r'travel|tourism|tourist|airport|flight|railway|train|hotel').hasMatch(value)) return 'TRAVEL';
    if (RegExp(r'breaking|accident|fire|earthquake|explosion|emergency|killed').hasMatch(value)) return 'BREAKING';
    return 'LOCAL';
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'BREAKING': return const Color(0xFFFF4C61);
      case 'WEATHER': return const Color(0xFF8B7CFF);
      case 'TRAVEL': return const Color(0xFFFFB84D);
      case 'TECHNOLOGY': return const Color(0xFF19BDEB);
      default: return const Color(0xFF51E5A8);
    }
  }

  static String _timeAgo(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return 'Recently';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes.clamp(1, 59)} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
}

class ArticleWebScreen extends StatefulWidget {
  const ArticleWebScreen({super.key, required this.title, required this.url});
  final String title, url;
  @override
  State<ArticleWebScreen> createState() => _ArticleWebScreenState();
}

class _ArticleWebScreenState extends State<ArticleWebScreen> {
  late final WebViewController webController;
  int progress = 0;
  @override
  void initState() {
    super.initState();
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onProgress: (value) {
        if (mounted) setState(() => progress = value);
      }))
      ..loadRequest(Uri.parse(widget.url));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: Column(children: [
      if (progress < 100) LinearProgressIndicator(value: progress / 100, color: cyan, backgroundColor: panel),
      Expanded(child: WebViewWidget(controller: webController)),
    ]),
  );
}

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, this.onTap});
  final Story story;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: GestureDetector(
          onTap: onTap,
          child: InfoCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: story.color, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.location_on)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${story.category} • ${story.time}', style: TextStyle(color: story.color, fontSize: 9, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(story.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 6),
            Text(story.place, style: const TextStyle(color: muted, fontSize: 12), overflow: TextOverflow.ellipsis),
            const Text('✓ Verified source', style: TextStyle(color: Color(0xFF51E5A8), fontSize: 11)),
          ])),
          AnimatedBuilder(
            animation: savedNews,
            builder: (context, _) => IconButton(
              tooltip: savedNews.contains(story) ? 'Remove from saved' : 'Save story',
              onPressed: () {
                final wasSaved = savedNews.contains(story);
                savedNews.toggle(story);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(wasSaved ? 'Removed from Saved' : 'Story saved'),
                  duration: const Duration(seconds: 1),
                ));
              },
              icon: Icon(savedNews.contains(story) ? Icons.bookmark : Icons.bookmark_border, color: savedNews.contains(story) ? cyan : null),
            ),
          ),
          ])),
        ),
      );
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint, this.controller, this.onSubmitted});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF718795)), prefixIcon: const Icon(Icons.search), filled: true, fillColor: panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)),
      );
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF16394B))),
        child: child,
      );
}

class NewsMarker extends StatelessWidget {
  const NewsMarker({super.key, required this.number, required this.place, required this.selected, required this.onTap});
  final int number;
  final String place;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(duration: const Duration(milliseconds: 180), width: selected ? 46 : 40, height: selected ? 46 : 40, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? const Color(0xFFFF4C61) : const Color(0xFF19BDEB), shape: BoxShape.circle, border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: selected ? const Color(0x99FF4C61) : const Color(0x8059D9FF), blurRadius: 16)]), child: Text('$number', style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xDD02070D), borderRadius: BorderRadius.circular(6)), child: Text(place, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
      );
}
