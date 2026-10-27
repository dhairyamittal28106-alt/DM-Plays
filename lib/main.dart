import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';


import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';


final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  MediaKit.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DmPlaysApp());
}

class AppColors {
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color accentTeal = Color(0xFF00E5FF);
}

class DmPlaysApp extends StatelessWidget {
  const DmPlaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'DM Plays',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBackground,
            primaryColor: AppColors.accentTeal,
            cardColor: AppColors.lightCard,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.black), titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(selectedItemColor: AppColors.accentTeal, unselectedItemColor: Colors.grey),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBackground,
            primaryColor: AppColors.accentTeal,
            cardColor: AppColors.darkCard,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.white), titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF0A0A0A), selectedItemColor: AppColors.accentTeal, unselectedItemColor: Colors.grey),
          ),
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/app_icon.png', width: 150, height: 150),
                const SizedBox(height: 30),
                const CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
              ],
            ),
          ),
          const Positioned(
            bottom: 50, left: 0, right: 0,
            child: Center(
              child: Text(
                "#MadeWithLoveByDM",
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Courier'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class Channel {
  final String name;
  final String url;
  final String group;
  final String? logoUrl;
  Channel({required this.name, required this.url, required this.group, this.logoUrl});
}


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final String m3uUrl = "https://iptv-org.github.io/iptv/index.category.m3u";
  Map<String, List<Channel>> groupedChannels = {};
  List<Channel> allChannelsList = []; 
  List<Channel> featuredChannels = [];
  List<Channel> indianChannels = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAndGroupChannels();
  }

   Future<void> fetchAndGroupChannels() async {
    try {
      final response = await http.get(Uri.parse(m3uUrl));
      if (response.statusCode == 200) {
        Map<String, List<Channel>> tempGrouped = {};
        List<Channel> tempAll = [];
        List<Channel> tempIndian = [];
        
        List<String> lines = const LineSplitter().convert(response.body);

        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('#EXTINF')) {
            String line = lines[i];
            String name = line.split(',').last.trim();
            
            String group = "General";
            if (line.contains('group-title="')) {
               int start = line.indexOf('group-title="') + 13;
               int end = line.indexOf('"', start);
               if (start != -1 && end != -1) group = line.substring(start, end);
            }
            if (group.isEmpty || group == "") group = "General";

            String? logo;
             if (line.contains('tvg-logo="')) {
               int start = line.indexOf('tvg-logo="') + 10;
               int end = line.indexOf('"', start);
               if (start != -1 && end != -1) logo = line.substring(start, end);
            }
            
            if (i + 1 < lines.length) {
              String url = lines[i + 1].trim();
              if (url.isNotEmpty && !url.startsWith('#')) {
                final channel = Channel(name: name, url: url, group: group, logoUrl: logo);
                tempAll.add(channel);

                if (!tempGrouped.containsKey(group)) {
                  tempGrouped[group] = [];
                }
                tempGrouped[group]!.add(channel);

                String lowerName = name.toLowerCase();
                String lowerGroup = group.toLowerCase();
                if (lowerGroup.contains("india") || lowerName.contains("india") || lowerName.contains("hindi") || lowerName.contains("tamil") || lowerName.contains("telugu") || lowerName.contains("star ") || lowerName.contains("zee ") || lowerName.contains("sony") || lowerName.contains("aaj tak")) {
                  tempIndian.add(channel);
                }
              }
            }
          }
        }
        
        tempAll.shuffle(Random());
        List<Channel> featured = [];
        if (tempIndian.isNotEmpty) featured.addAll(tempIndian.take(5));
        featured.addAll(tempAll.take(5));
        featured.shuffle();

        setState(() {
          groupedChannels = tempGrouped;
          allChannelsList = tempAll;
          indianChannels = tempIndian;
          featuredChannels = featured;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(groupedChannels: groupedChannels, featuredChannels: featuredChannels, indianChannels: indianChannels, isLoading: isLoading),
      SearchScreen(allChannels: allChannelsList), 
      const ProfileScreen(), 
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  final Map<String, List<Channel>> groupedChannels;
  final List<Channel> featuredChannels;
  final List<Channel> indianChannels;
  final bool isLoading;

  const HomeScreen({
    super.key,
    required this.groupedChannels,
    required this.featuredChannels,
    required this.indianChannels,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingSkeleton();

    List<String> sortedKeys = groupedChannels.keys.toList();
    sortedKeys.sort((a,b) {
       if(a.contains("Sport") && !b.contains("Sport")) return -1;
       if(a.contains("News") && !b.contains("News")) return -1;
       if(a.contains("Movie") && !b.contains("Movie")) return -1;
       return a.compareTo(b);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
          title: const Text("DM PLAYS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.accentTeal)),
        ),
        
        SliverToBoxAdapter(
          child: Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(height: 220.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.85),
                items: featuredChannels.map((channel) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: () => _openPlayer(context, channel),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(0, 2))],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                               ClipRRect(
                                 borderRadius: BorderRadius.circular(12),
                                 child: Image.network("https://wallpaperaccess.com/full/302831.jpg", fit: BoxFit.cover, color: Colors.black.withOpacity(0.4), colorBlendMode: BlendMode.darken),
                               ),
                              Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(channel.name, style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const Center(child: Icon(Icons.play_circle_outline, size: 60, color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        if (indianChannels.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildCategoryRow(context, "Top Picks for India 🇮🇳", indianChannels, textColor),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              String category = sortedKeys[index];
              List<Channel> channels = groupedChannels[category]!;
              if (channels.isEmpty) return const SizedBox.shrink();
              return _buildCategoryRow(context, category, channels, textColor);
            },
            childCount: sortedKeys.length,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, String title, List<Channel> channels, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: channels.length > 50 ? 50 : channels.length,
            padding: const EdgeInsets.only(left: 16),
            itemBuilder: (context, i) {
              final channel = channels[i];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _openPlayer(context, channel),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            boxShadow: Theme.of(context).brightness == Brightness.light ? [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))] : [],
                          ),
                          child: Center(
                            child: channel.logoUrl != null 
                              ? Image.network(channel.logoUrl!, errorBuilder: (c,e,s) => Icon(Icons.tv, color: Colors.grey.shade400))
                              : Text(channel.name[0], style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPlayer(BuildContext context, Channel channel) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(url: channel.url, channelName: channel.name)));
  }
}


class SearchScreen extends StatefulWidget {
  final List<Channel> allChannels;
  const SearchScreen({super.key, required this.allChannels});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Channel> filtered = [];
  final TextEditingController _controller = TextEditingController();

  void _search(String query) {
    if (query.isEmpty) {
      setState(() => filtered = []);
      return;
    }
    setState(() {
      filtered = widget.allChannels.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).take(50).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: _search,
          autofocus: true,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(hintText: "Search channels (e.g. Star Sports)...", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
        ),
      ),
      body: filtered.isEmpty 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search, size: 80, color: Colors.grey), const SizedBox(height: 10), const Text("Find your favorite channels", style: TextStyle(color: Colors.grey))]))
        : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
            final channel = filtered[index];
            return ListTile(leading: const Icon(Icons.tv, color: AppColors.accentTeal), title: Text(channel.name), subtitle: Text(channel.group, style: const TextStyle(color: Colors.grey)), onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(url: channel.url, channelName: channel.name)));});
          }),
    );
  }
}


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const CircleAvatar(radius: 60, backgroundColor: Colors.transparent, backgroundImage: AssetImage('assets/app_icon.png')),
            const SizedBox(height: 20),
            const Text("DM PLAYS", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentTeal)),
            const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            _buildProfileItem(context, Icons.settings, "Settings", () {Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));}),
            _buildProfileItem(context, Icons.favorite, "My Favorites (Coming Soon)", () {}),
            _buildProfileItem(context, Icons.info, "About Developer", () {Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDeveloperScreen()));}),
            _buildProfileItem(context, Icons.logout, "Exit App", () => SystemNavigator.pop(), color: Colors.red),
          ]),
      ),
    );
  }
  Widget _buildProfileItem(BuildContext context, IconData icon, String text, VoidCallback onTap, {Color? color}) {
    Color textColor = color ?? Theme.of(context).textTheme.bodyLarge!.color!;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), boxShadow: Theme.of(context).brightness == Brightness.light ? [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))] : []), child: Row(children: [Icon(icon, color: textColor), const SizedBox(width: 20), Text(text, style: TextStyle(color: textColor, fontSize: 16)), const Spacer(), Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.withOpacity(0.5))]))));
  }
}


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Settings")), body: ListView(children: [ValueListenableBuilder<ThemeMode>(valueListenable: _themeNotifier, builder: (_, mode, __) { bool isDark = mode == ThemeMode.dark; return SwitchListTile(title: const Text("Dark Mode"), subtitle: const Text("Toggle between Light and Dark themes"), secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode), value: isDark, activeColor: AppColors.accentTeal, onChanged: (val) { _themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light; }); })]));
  }
}

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("About Developer")), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('assets/app_icon.png', width: 120, height: 120), const SizedBox(height: 20), const Text("Developed by DM", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Padding(padding: EdgeInsets.symmetric(horizontal: 40), child: Text("Thank you for using DM Plays. This app was built to provide the best free streaming experience.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))), const SizedBox(height: 50), const Text("#MadeWithLoveByDM", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Courier'))])));
  }
}


class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String channelName;
  const VideoPlayerScreen({super.key, required this.url, required this.channelName});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    
    player = Player();
    controller = VideoController(player);
    
    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    
    player.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            
            Center(
              child: Video(controller: controller),
            ),
            
            Positioned(
              top: 10, left: 10, 
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white), 
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(baseColor: Colors.grey[900]!, highlightColor: Colors.grey[800]!, child: ListView(children: [Container(height: 250, color: Colors.black), const SizedBox(height: 10), Container(height: 200, color: Colors.black)]));
  }
}