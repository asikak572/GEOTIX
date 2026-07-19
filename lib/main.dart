import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const GeotixApp());

const navy = Color(0xFF02070D);
const panel = Color(0xFF0C1D29);
const cyan = Color(0xFF59D9FF);
const muted = Color(0xFF91A6B3);

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
        appBar: AppBar(
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
  String place = 'Chennai';
  String region = 'Tamil Nadu, India';
  int stories = 12;
  void select(String p, String r, int s) => setState(() { place = p; region = r; stories = s; });

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(navy)
      ..addJavaScriptChannel(
        'Geotix',
        onMessageReceived: (message) {
          final parts = message.message.split('|');
          if (parts.length == 3) {
            select(parts[0], parts[1], int.tryParse(parts[2]) ?? 0);
          }
        },
      )
      ..loadFlutterAsset('assets/globe.html');
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final globeHeight = (c.maxHeight * .50).clamp(285.0, 470.0).toDouble();
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: c.maxWidth < 380 ? 14 : 20, vertical: 16),
          child: Column(children: [
            const Text('YOUR WORLD • RIGHT NOW', style: TextStyle(color: cyan, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 7),
            const FittedBox(child: Text('News has a place.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
            const SizedBox(height: 14),
            const SearchBox(hint: 'Search country, state or district'),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              height: globeHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF010B12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF164A61)),
                boxShadow: const [BoxShadow(color: Color(0x4459D9FF), blurRadius: 28)],
              ),
              child: WebViewWidget(controller: controller),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Drag to rotate • Pinch to zoom • Tap a marker', style: TextStyle(color: muted, fontSize: 11)),
            ),
            InfoCard(child: Row(children: [
              const Icon(Icons.location_on, color: cyan),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('SELECTED LOCATION', style: TextStyle(color: cyan, fontSize: 9, letterSpacing: 1.4)),
                Text(place, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                Text('$region • $stories active stories', style: const TextStyle(color: muted, fontSize: 12), overflow: TextOverflow.ellipsis),
              ])),
              const Icon(Icons.arrow_forward),
            ])),
          ]),
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
  final items = const [
    Story('BREAKING', 'Chennai, Tamil Nadu', 'Major transport update announced for Chennai', '12 min ago', Color(0xFFFF4C61)),
    Story('TECHNOLOGY', 'Tokyo, Japan', 'New robotics technology demonstrated in Tokyo', '28 min ago', Color(0xFF19BDEB)),
    Story('WEATHER', 'London, United Kingdom', 'Weather advisory issued across Greater London', '45 min ago', Color(0xFF8B7CFF)),
    Story('TRAVEL', 'Paris, France', 'New visitor route opens near central Paris', '1 hr ago', Color(0xFFFFB84D)),
  ];
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
            const SearchBox(hint: 'Search locations or stories'),
            const SizedBox(height: 14),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Breaking', 'Weather', 'Technology', 'Travel'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f), selectedColor: const Color(0xFF19BDEB), labelStyle: TextStyle(color: filter == f ? const Color(0xFF001018) : Colors.white, fontWeight: FontWeight.bold)),
            )).toList())),
            const SizedBox(height: 16),
            ...shown.map((story) => StoryCard(story: story)),
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
  Widget build(BuildContext context) => const Center(child: Padding(
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

class Story {
  const Story(this.category, this.place, this.title, this.time, this.color);
  final String category, place, title, time;
  final Color color;
}

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story});
  final Story story;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
        ])),
      );
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
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
