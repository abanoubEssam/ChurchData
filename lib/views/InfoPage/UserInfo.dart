import 'package:churchdata/Models/Area.dart';
import 'package:churchdata/Views/utils/List.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'
    if (dart.library.html) 'package:churchdata/FirebaseWeb.dart' hide User;
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../EditPage/EditUser.dart';

class UserInfo extends StatefulWidget {
  final User user;

  UserInfo({Key key, this.user}) : super(key: key);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (c) {
          return NestedScrollView(
            headerSliverBuilder: (context, _) => <Widget>[
              SliverAppBar(
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      dynamic result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (co) => UserP(user: user),
                        ),
                      );
                      if (result == 'unapproved') {
                        Navigator.of(context).pop();
                      } else if (result is String) {
                        user = await User.fromID(result);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم الحفظ بنجاح'),
                          ),
                        );
                      }
                    },
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () {
                      shareUser(user);
                    },
                    tooltip: 'مشاركة',
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () async {
                      var person = await user.getPerson();
                      if (person == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('لم يتم إيجاد بيانات للمستخدم'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      personTap(await user.getPerson(), context);
                    },
                    tooltip: 'عرض بيانات المستخدم داخل البرنامج',
                  ),
                ],
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(user.name),
                  background: user.getPhoto(false, false),
                ),
              ),
            ],
            body: ListView(
              children: <Widget>[
                ListTile(
                  title: Text('الاسم:'),
                  subtitle: Text(user.name),
                ),
                ListTile(
                  title: Text('البريد الاكتروني:'),
                  subtitle: Text(user.email ?? ''),
                ),
                ListTile(
                  title: Text('أخر ظهور على البرنامج:'),
                  subtitle: StreamBuilder(
                    stream: FirebaseDatabase.instance
                        .reference()
                        .child('Users/${user.uid}/lastSeen')
                        .onValue,
                    builder: (context, activity) {
                      if (activity.data?.snapshot?.value == 'Active') {
                        return Text('نشط الآن');
                      } else if (activity.data?.snapshot?.value != null) {
                        return Text(toDurationString(
                            Timestamp.fromMillisecondsSinceEpoch(
                                activity.data.snapshot.value)));
                      }
                      return Text('لا يمكن التحديد');
                    },
                  ),
                ),
                ListTile(
                  title: Text('الصلاحيات:',
                      style: Theme.of(context).textTheme.bodyText1),
                ),
                if (user.manageUsers == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xef3d, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إدارة المستخدمين'),
                  ),
                if (user.superAccess == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xef56, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('رؤية جميع البيانات'),
                  ),
                if (user.write == true)
                  ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('تعديل البيانات'),
                  ),
                if (user.exportAreas == true)
                  ListTile(
                    leading: Icon(Icons.cloud_download),
                    title: Text('تصدير منطقة لملف إكسل'),
                  ),
                if (user.birthdayNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7e9, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار أعياد الميلاد'),
                  ),
                if (user.confessionsNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار الاعتراف'),
                  ),
                if (user.tanawolNotify == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe7f7, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('إشعار التناول'),
                  ),
                if (user.approveLocations == true)
                  ListTile(
                    leading: Icon(
                      const IconData(0xe8e8, fontFamily: 'MaterialIconsR'),
                    ),
                    title: Text('التأكيد على المواقع'),
                  ),
                ElevatedButton.icon(
                  label: Text('رؤية البيانات كما يراها ' + user.name),
                  icon: Icon(Icons.visibility),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: ListenableProvider<SearchString>(
                        create: (_) => SearchString(),
                        builder: (context, _) => Column(
                          children: [
                            Text(
                              'يستطيع ' +
                                  user.name +
                                  ' رؤية ${user.write ? 'وتعديل ' : ''}المناطق التالية وما بداخلها:',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            Expanded(
                              child: DataObjectList<Area>(
                                options: ListOptions(
                                  generate: Area.fromDoc,
                                  tap: areaTap,
                                  documentsData: Area.getAllForUser(
                                      uid: user.superAccess ? null : user.uid),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }
}
