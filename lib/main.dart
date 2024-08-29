import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fluttertoast/fluttertoast.dart';
import 'event_creation_page.dart';
import 'event_details_page.dart';
import 'env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Countries',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _activeEventsFuture;
  late Future<List<Map<String, dynamic>>> _futureEventsFuture;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('initState called');
    _tabController = TabController(length: 2, vsync: this);
    _checkAuthState();
    _initializeEventFutures();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, checking auth state');
      _checkAuthState();
    }
  }

  void _checkAuthState() {
    print('_checkAuthState called');
    final currentUser = Supabase.instance.client.auth.currentUser;
    print('Current user: $currentUser');
    final isLoggedIn = currentUser != null;
    print('User is logged in: $isLoggedIn');
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  void _initializeEventFutures() {
    _activeEventsFuture = _fetchActiveEvents();
    _futureEventsFuture = _fetchFutureEvents();
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building HomePage. isLoggedIn: $_isLoggedIn');
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoggedIn
                ? (() {
                    print('Building TabView');
                    return _buildTabView();
                  })()
                : (() {
                    print('Building AuthView');
                    return _buildAuthView();
                  })(),
          ),
        ],
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventCreationPage()),
              ),
              label: const Text('Host an event'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEventList(Future<List<Map<String, dynamic>>> eventsFuture) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final events = snapshot.data ?? [];
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(event['name'][0])),
                title: Text(event['name']),
                subtitle: Text(
                    '${event['host_id']} - Till ${_formatTime(event['end_time'])}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Spontaneous'),
      actions: _isLoggedIn
          ? [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _signOut();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Log out'),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ]
          : null,
      bottom: _isLoggedIn
          ? TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Active Events'),
                Tab(text: 'Future Events'),
              ],
            )
          : null,
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventList(_activeEventsFuture),
        _buildEventList(_futureEventsFuture),
      ],
    );
  }

  Widget _buildAuthView() {
    return SupaEmailAuth(
      redirectTo: kIsWeb ? null : 'io.mydomain.myapp://callback',
      onSignInComplete: (response) {
        print('Sign in complete. Response: $response');
        _checkAuthState();
        setState(() {});
      },
      onSignUpComplete: (response) {
        Fluttertoast.showToast(
            msg: "Check your email for a confirmation link",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      },
      metadataFields: [
        MetaDataField(
          prefixIcon: const Icon(Icons.person),
          label: 'Username',
          key: 'username',
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please enter something';
            }
            return null;
          },
        ),
      ],
    );
  }
}

Future<List<Map<String, dynamic>>> _fetchActiveEvents() async {
  final now = DateTime.now().toIso8601String();
  final response = await Supabase.instance.client
      .from('events')
      .select('*')
      .lte('start_time', now)
      .gt('end_time', now)
      .order('start_time', ascending: true);

  return (response as List<dynamic>).cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> _fetchFutureEvents() async {
  final now = DateTime.now().toIso8601String();
  final response = await Supabase.instance.client
      .from('events')
      .select('*')
      .gt('start_time', now)
      .order('start_time', ascending: true);

  return (response as List<dynamic>).cast<Map<String, dynamic>>();
}
