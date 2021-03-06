import 'dart:async';
import 'dart:ffi';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:churchdata/views/EditPage/EditFamily.dart';
import 'package:churchdata/views/EditPage/EditPerson.dart';
import 'package:churchdata/views/EditPage/EditStreet.dart';
import 'package:churchdata/views/EditPage/UpdateUserDataErrorP.dart';
import 'package:churchdata/views/InfoPage/AreaInfo.dart';
import 'package:churchdata/views/InfoPage/FamilyInfo.dart';
import 'package:churchdata/views/InfoPage/PersonInfo.dart';
import 'package:churchdata/views/InfoPage/StreetInfo.dart';
import 'package:churchdata/views/InfoPage/UserInfo.dart';
import 'package:churchdata/views/ui/UserRegisteration.dart';
import 'package:churchdata/views/utils/DataMap.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity/connectivity.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User
    hide UserInfo;
import 'package:firebase_messaging/firebase_messaging.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart'
    hide User
    hide UserInfo;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Person;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart';

import 'Models/HivePersistenceProvider.dart';
import 'Models/OrderOptions.dart';
import 'Models/ThemeNotifier.dart';
import 'Models/User.dart';
import 'Models.dart';
import 'utils/Helpers.dart';
import 'utils/globals.dart';
import 'views/EditPage/EditArea.dart';
import 'views/ui/AdditionalSettings.dart';
import 'views/ui/AuthScreen.dart';
import 'views/ui/Login.dart';
import 'views/ui/MyAccount.dart';
import 'views/ui/NotificationsPage.dart';
import 'views/ui/Root.dart';
import 'views/ui/SearchQuery.dart';
import 'views/ui/Settings.dart' as settingsui;
import 'views/ui/Updates.dart';
import 'views/utils/LoadingWidget.dart';

void main() {
  FlutterError.onError = (flutterError) {
    FirebaseCrashlytics.instance.recordFlutterError(flutterError);
  };
  ErrorWidget.builder = (error) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordFlutterError(error);
    }
    return Container(
        color: Colors.white,
        child: Text(
          'حدث خطأ:' '\n' + error.summary.toString(),
        ));
  };

  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp().then(
    (_) async {
      if (auth.FirebaseAuth.instance.currentUser?.uid != null)
        await User.instance.initialized;
      final User user = User.instance;
      await _initConfigs();

      var settings = Hive.box('Settings');
      var primary = settings.get('PrimaryColorIndex', defaultValue: 7);
      var accent = primary;
      var darkTheme = settings.get('DarkTheme');
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderOptions>(
              create: (_) => OrderOptions(),
            ),
            ChangeNotifierProvider<User>.value(value: user),
            ChangeNotifierProvider<ThemeNotifier>(
              create: (_) => ThemeNotifier(
                ThemeData(
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                      backgroundColor: primaries[primary ?? 7]),
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                          primary: primaries[primary ?? 7])),
                  textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                          primary: primaries[primary ?? 7])),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                          primary: primaries[primary ?? 7])),
                  brightness: darkTheme != null
                      ? (darkTheme ? Brightness.dark : Brightness.light)
                      : WidgetsBinding.instance.window.platformBrightness,
                  accentColor: accents[accent ?? 7],
                  primaryColor: primaries[primary ?? 7],
                ),
              ),
            ),
          ],
          builder: (context, _) => App(),
        ),
      );
    },
  );
}

Future _initConfigs() async {
  //Hive initialization:
  await Hive.initFlutter();

  await Hive.openBox('Settings');
  await Hive.openBox<bool>('FeatureDiscovery');
  await Hive.openBox<Map>('NotificationsSettings');
  await Hive.openBox<String>('PhotosURLsCache');

  //Notifications:
  if (!kIsWeb) await AndroidAlarmManager.initialize();

  if (!kIsWeb)
    await FlutterLocalNotificationsPlugin().initialize(
        InitializationSettings(
            android: AndroidInitializationSettings('warning')),
        onSelectNotification: onNotificationClicked);
}

class App extends StatefulWidget {
  App({Key key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  StreamSubscription<ConnectivityResult> connection;
  StreamSubscription userTokenListener;

  bool showFormOnce = false;

  @override
  Widget build(BuildContext context) {
    return FeatureDiscovery.withProvider(
      persistenceProvider: HivePersistenceProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'بيانات الكنيسة',
        initialRoute: '/',
        routes: {
          '/': buildLoadAppWidget,
          'Login': (context) => LoginScreen(),
          'Data/EditArea': (context) =>
              EditArea(area: ModalRoute.of(context).settings.arguments),
          'Data/EditStreet': (context) {
            if (ModalRoute.of(context).settings.arguments is Street)
              return EditStreet(
                  street: ModalRoute.of(context).settings.arguments);
            else {
              Street street = Street.empty()
                ..areaId = ModalRoute.of(context).settings.arguments;
              return EditStreet(street: street);
            }
          },
          'Data/EditFamily': (context) {
            if (ModalRoute.of(context).settings.arguments is Family)
              return EditFamily(
                  family: ModalRoute.of(context).settings.arguments);
            else if (ModalRoute.of(context).settings.arguments is Map) {
              Family family = Family.empty()
                ..streetId = (ModalRoute.of(context).settings.arguments
                    as Map)['StreetId']
                ..insideFamily =
                    (ModalRoute.of(context).settings.arguments as Map)['Family']
                ..isStore = (ModalRoute.of(context).settings.arguments
                    as Map)['IsStore'];
              if (family.streetId != null) family.setAreaIdFromStreet();
              return EditFamily(family: family);
            } else {
              Family family = Family.empty()
                ..streetId = ModalRoute.of(context).settings.arguments;
              if (family.streetId != null) family.setAreaIdFromStreet();
              return EditFamily(family: family);
            }
          },
          'Data/EditPerson': (context) {
            if (ModalRoute.of(context).settings.arguments is Person)
              return EditPerson(
                  person: ModalRoute.of(context).settings.arguments);
            else {
              Person person = Person()
                ..familyId = ModalRoute.of(context).settings.arguments;
              if (person.familyId != null) person.setStreetIdFromFamily();
              return EditPerson(person: person);
            }
          },
          'MyAccount': (context) => MyAccount(),
          'Notifications': (context) => NotificationsPage(),
          'Update': (context) => Update(),
          'Search': (context) => SearchQuery(),
          'DataMap': (context) => DataMap(),
          'AreaInfo': (context) =>
              AreaInfo(area: ModalRoute.of(context).settings.arguments),
          'StreetInfo': (context) =>
              StreetInfo(street: ModalRoute.of(context).settings.arguments),
          'FamilyInfo': (context) =>
              FamilyInfo(family: ModalRoute.of(context).settings.arguments),
          'PersonInfo': (context) =>
              PersonInfo(person: ModalRoute.of(context).settings.arguments),
          'UserInfo': (context) =>
              UserInfo(user: ModalRoute.of(context).settings.arguments),
          'Settings': (context) => settingsui.Settings(),
          'Settings/Churches': (context) => ChurchesPage(),
          'Settings/Fathers': (context) => FathersPage(),
          'Settings/Jobs': (context) => JobsPage(),
          'Settings/StudyYears': (context) => StudyYearsPage(),
          'Settings/Colleges': (context) => CollegesPage(),
          'Settings/ServingTypes': (context) => ServingTypesPage(),
          'Settings/PersonTypes': (context) => PersonTypesPage(),
          'UpdateUserDataError': (context) => UpdateUserDataErrorPage(
              person: ModalRoute.of(context).settings.arguments),
          'EditUserData': (context) => FutureBuilder<Person>(
                future: User.getCurrentPerson(),
                builder: (context, data) {
                  if (data.hasError)
                    return Center(child: ErrorWidget(data.error));
                  if (!data.hasData)
                    return Scaffold(
                      resizeToAvoidBottomInset: !kIsWeb,
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  return EditPerson(person: data.data, userData: true);
                },
              ),
        },
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('ar', 'EG'),
        ],
        themeMode: context.watch<ThemeNotifier>().getTheme().brightness ==
                Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        locale: Locale('ar', 'EG'),
        theme: context.watch<ThemeNotifier>().getTheme(),
        darkTheme: context.watch<ThemeNotifier>().getTheme(),
      ),
    );
  }

  Widget buildLoadAppWidget(BuildContext context) {
    return FutureBuilder<void>(
      future: loadApp(context),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return Loading(
            showVersionInfo: true,
          );

        if (snapshot.hasError && User.instance.password != null) {
          if (snapshot.error.toString() ==
              'Exception: Error Update User Data') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showErrorUpdateDataDialog(context: context);
            });
          }
          return Loading(
            error: true,
            message: snapshot.error.toString(),
            showVersionInfo: true,
          );
        }

        return Consumer<User>(
          builder: (context, user, child) {
            if (user.uid == null) {
              return const LoginScreen();
            } else if (user.approved && user.password != null) {
              return const AuthScreen(nextWidget: Root());
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (user.personRef == null && !showFormOnce) {
                  showFormOnce = true;
                  if (kIsWeb ||
                      await Navigator.of(context).pushNamed('EditUserData')
                          is firestore.DocumentReference) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم الحفظ بنجاح'),
                      ),
                    );
                  }
                }
              });
              return const UserRegisteration();
            }
          },
        );
      },
    );
  }

  Future configureFirebaseMessaging() async {
    if (!Hive.box('Settings')
            .get('FCM_Token_Registered', defaultValue: false) &&
        auth.FirebaseAuth.instance.currentUser != null) {
      try {
        if (kIsWeb)
          await firestore.FirebaseFirestore.instance.enablePersistence();
        firestore.FirebaseFirestore.instance.settings = firestore.Settings(
          persistenceEnabled: true,
          sslEnabled: true,
          cacheSizeBytes: Hive.box('Settings')
              .get('cacheSize', defaultValue: 300 * 1024 * 1024),
        );
        // ignore: empty_catches
      } catch (e) {}
      try {
        bool permission =
            await FirebaseMessaging.instance.requestNotificationPermissions();
        if (permission == true || permission == null)
          await FirebaseFunctions.instance
              .httpsCallable('registerFCMToken')
              .call({'token': await FirebaseMessaging.instance.getToken()});
        if (permission == true || permission == null)
          await Hive.box('Settings').put('FCM_Token_Registered', true);
      } catch (err, stkTrace) {
        print(err.toString());
        await FirebaseCrashlytics.instance
            .setCustomKey('LastErrorIn', 'AppState.initState');
        await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      }
    }
    if (configureMessaging) {
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
      FirebaseMessaging.onMessage.listen(onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((m) async {
        await showPendingMessage();
      });
      configureMessaging = false;
    }
  }

  @override
  void dispose() {
    connection?.cancel();
    userTokenListener?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    connection = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        dataSource =
            firestore.GetOptions(source: firestore.Source.serverAndCache);
        if (!kIsWeb && (mainScfld?.currentState?.mounted ?? false))
          ScaffoldMessenger.of(mainScfld.currentContext).showSnackBar(SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text('تم استرجاع الاتصال بالانترنت'),
          ));
      } else {
        dataSource = firestore.GetOptions(source: firestore.Source.cache);

        if (!kIsWeb && (mainScfld?.currentState?.mounted ?? false))
          ScaffoldMessenger.of(mainScfld.currentContext).showSnackBar(SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('لا يوجد اتصال بالانترنت!'),
          ));
      }
    });

    setLocaleMessages(
      'ar',
      ArMessages(),
    );
  }

  Future<void> loadApp(BuildContext context) async {
    var result = await UpdateHelper.setupRemoteConfig();
    if (result != null && result.getString('LoadApp') == 'false') {
      await Updates.showUpdateDialog(context, canCancel: false);
      throw Exception('يجب التحديث لأخر إصدار لتشغيل البرنامج');
    } else {
      if (User.instance?.uid != null) {
        await configureFirebaseMessaging();
        if (!kIsWeb)
          await FirebaseCrashlytics.instance
              .setCustomKey('UID', User.instance.uid);
        if (!await User.instance.userDataUpToDate()) {
          throw Exception('Error Update User Data');
        }
      }
    }
  }
}
