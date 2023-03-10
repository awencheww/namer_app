import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];
  var i = 0;

  GlobalKey? historyListKey;

  void addNew() {
    if (history.contains(current)) {
      current = WordPair.random();
    }
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  void getNext() {
    if (history.isNotEmpty) {
      if (i > 0) {
        i--;
        current = (i != 0) ? history.elementAt(i - 1) : history.elementAt(i);
      }
    } else {
      print('History is empty.');
    }
    notifyListeners();
  }

  void getPrevious() {
    if (history.isNotEmpty) {
      if (i != history.length) {
        /// this ensures that it will throw RangeError of index
        /// and make sure that current WordPair
        /// after clicking [Previous] or [Next] button
        current = (i == history.length)
            ? history.elementAt(i + 1)
            : history.elementAt(i);
        i++;
      }
    } else {
      print('History is empty.');
    }
    notifyListeners();
  }

  var favorites = <WordPair>[];
  void toggleFavorite([WordPair? pair]) {
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
} //MyAppState

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
} //NyHomePage

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    /// The container for the current page, with its background color
    /// and subtle switching animation.
    var mainArea = ColoredBox(
      // color: Colors.deepOrange.shade200,
      color: Theme.of(context).colorScheme.outlineVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          /// Use a more mobile-friendly layout with BottomNavigationBar
          /// or narrow screens
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.favorite),
                      label: 'Favorite',
                    ),
                  ],
                  currentIndex: selectedIndex,
                  onTap: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(child: mainArea),
            ],
          );
        }
      }),
    );
  }
} //_MyHomePageState

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(
            height: 10,
          ),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 5),
              ElevatedButton.icon(
                onPressed: () {
                  appState.addNew();
                },
                icon: Icon(Icons.add),
                label: Text('New WordPair'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => appState.getPrevious(),
                child: Text('Previous'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => appState.getNext(),
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(
            flex: 1,
          ),
        ],
      ),
    );
  }
} // GeneratorPage

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),

          /// Make sure that the compound word wraps correctly when the window
          /// is too narrow.
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} //BigCard

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yat.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('You have ' '${appState.favorites.length} favorites:'),
        ),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      semanticLabel: 'Delete',
                    ),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }
} //FavoritesPage

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items
  final _key = GlobalKey();

  /// Used to "fade out" the history items at the top, to suggest continuation,
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to  half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          /// get the current selectedIndex pair
          final pair = appState.history[index];

          /// get the first item in a List[]
          final firstPair = appState.history.first;

          /// ternary operator for displaying star icon or with favorite icon Wrap with Row
          /// Note: this is to display star icon IF it is newly added WordPair
          ///       ELSE will depend on toggleFavorite function if click or not
          /// With the ff. conditions:
          /// 1. if firstPair is the first item in a List AND `appState.favorites.contains(pair)` means the current pair
          ///    then, will display "favorite" AND "star" icon if `toggleFavorite function` is click or tap
          final icon = (firstPair == appState.history[index] &&
                  appState.favorites.contains(pair))
              ? Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 12,
                    ),
                    Icon(
                      Icons.star,
                      size: 12,
                    ),
                  ],
                )

              /// 2. if this is not the first item in a List and `toggleFavorite function` is click
              ///    then, will display "favorite" icon only
              : (appState.favorites.contains(pair))
                  ? Row(children: [
                      Icon(
                        Icons.favorite,
                        size: 12,
                      ),
                    ])

                  /// 3. if `toggleFavorite function` not click
                  ///     then, display "star" icon only
                  : (firstPair == appState.history[index])
                      ? Icon(
                          Icons.star,
                          size: 12,
                        )
                      : SizedBox();
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: icon,
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
