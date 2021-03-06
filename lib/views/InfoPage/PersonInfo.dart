import 'dart:async';
import 'dart:ui';

import 'package:churchdata/Models.dart';
import 'package:churchdata/Models/Area.dart';
import 'package:churchdata/Models/User.dart';
import 'package:churchdata/utils/Helpers.dart';
import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/views/utils/CopiableProperty.dart';
import 'package:churchdata/views/utils/DataObjectWidget.dart';
import 'package:churchdata/views/utils/HistoryProperty.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_phone_state/flutter_phone_state.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PersonInfo extends StatelessWidget {
  final Person person;
  final List<String> choices = [
    'إضافة إلى جهات الاتصال',
    'نسخ في لوحة الاتصال',
    'إرسال رسالة',
    'إرسال رسالة (واتساب)',
    'ارسال إشعار للمستخدمين عن الشخص'
  ];

  PersonInfo({Key key, this.person}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FeatureDiscovery.discoverFeatures(context, [
        'Person.MoreOptions',
      ]),
    );
    return Scaffold(
      body: Selector<User, bool>(
        selector: (_, user) => user.write,
        builder: (context, permission, _) => StreamBuilder<Person>(
          initialData: person,
          stream: person.ref.snapshots().map(Person.fromDoc),
          builder: (context, snapshot) {
            final Person person = snapshot.data;
            if (person == null)
              return Scaffold(
                body: Center(
                  child: Text('تم حذف الشخص'),
                ),
              );
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: person.color != Colors.transparent
                        ? person.color
                        : null,
                    actions: <Widget>[
                      if (permission)
                        IconButton(
                          icon: Builder(
                            builder: (context) => IconShadowWidget(
                              Icon(
                                Icons.edit,
                                color: IconTheme.of(context).color,
                              ),
                            ),
                          ),
                          onPressed: () async {
                            dynamic result = await Navigator.of(context)
                                .pushNamed('Data/EditPerson',
                                    arguments: person);
                            if (result is DocumentReference) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم الحفظ بنجاح'),
                                ),
                              );
                            } else if (result == 'deleted')
                              Navigator.of(context).pop();
                          },
                          tooltip: 'تعديل',
                        ),
                      IconButton(
                        icon: Builder(
                          builder: (context) => IconShadowWidget(
                            Icon(
                              Icons.share,
                              color: IconTheme.of(context).color,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          await Share.share(
                            await sharePerson(person),
                          );
                        },
                        tooltip: 'مشاركة برابط',
                      ),
                      DescribedFeatureOverlay(
                        onBackgroundTap: () async {
                          await FeatureDiscovery.completeCurrentStep(context);
                          return true;
                        },
                        onDismiss: () async {
                          await FeatureDiscovery.completeCurrentStep(context);
                          return true;
                        },
                        backgroundDismissible: true,
                        contentLocation: ContentLocation.below,
                        featureId: 'Person.MoreOptions',
                        tapTarget: Icon(
                          Icons.more_vert,
                        ),
                        title: Text('المزيد من الخيارات'),
                        description: Column(
                          children: <Widget>[
                            Text(
                                'يمكنك ايجاد المزيد من الخيارات من هنا مثل: اشعار المستخدمين عن الشخص\ىنسخ في لوحة الاتصال\ىاضافة لجهات الاتصال\ىارسال رسالة\ىارسال رسالة من خلال الواتساب'),
                            OutlinedButton(
                              child: Text(
                                'تخطي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color,
                                ),
                              ),
                              onPressed: () =>
                                  FeatureDiscovery.completeCurrentStep(context),
                            ),
                          ],
                        ),
                        backgroundColor: Theme.of(context).accentColor,
                        targetColor: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.bodyText1.color,
                        child: PopupMenuButton(
                          onSelected: (p) {
                            sendNotification(context, person);
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                value: '',
                                child: Text('ارسال اشعار للمستخدمين عن الشخص'),
                              )
                            ];
                          },
                        ),
                      ),
                    ],
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                          title: AnimatedOpacity(
                            duration: Duration(milliseconds: 300),
                            opacity: constraints.biggest.height >
                                    kToolbarHeight * 1.7
                                ? 0
                                : 1,
                            child: Text(person.name),
                          ),
                          background: person.photo),
                    ),
                  ),
                ];
              },
              body: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListTile(
                        title: Hero(
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                person.name,
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                            tag: person.id + '-name'),
                      ),
                      PhoneNumberProperty(
                        'رقم الهاتف:',
                        person.phone,
                        (n, action) => _phoneCall(context, n, action),
                      ),
                      if (person.phones != null)
                        ...person.phones.entries
                            .map((e) => PhoneNumberProperty(
                                  e.key,
                                  e.value,
                                  (n, action) => _phoneCall(context, n, action),
                                ))
                            .toList(),
                      ListTile(
                        title: Text('السن:'),
                        subtitle: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(toDurationString(person.birthDate,
                                  appendSince: false)),
                            ),
                            Text(
                                person.birthDate != null
                                    ? DateFormat('yyyy/M/d').format(
                                        person.birthDate.toDate(),
                                      )
                                    : '',
                                style: Theme.of(context).textTheme.overline),
                          ],
                        ),
                      ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('الوظيفة:'),
                          subtitle: FutureBuilder(
                              future: person.getJobName(),
                              builder: (context, data) {
                                if (data.hasData) return Text(data.data);
                                return LinearProgressIndicator();
                              }),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('تفاصيل الوظيفة:'),
                          subtitle: Text(person.jobDescription ?? ''),
                        ),
                      if (!person.isStudent)
                        ListTile(
                          title: Text('المؤهل:'),
                          subtitle: Text(person.qualification ?? ''),
                        ),
                      if (person.isStudent)
                        ListTile(
                          title: Text('السنة الدراسية:'),
                          subtitle: FutureBuilder(
                            future: person.getStudyYearName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            },
                          ),
                        ),
                      if (person.isStudent)
                        FutureBuilder(
                          future: Future.wait(
                            [
                              (person.studyYear?.get(dataSource) ??
                                  Future(() => null)),
                              person.getCollegeName()
                            ],
                          ),
                          builder: (context, data) {
                            if (data.hasData &&
                                data.data[0]?.data != null &&
                                (data.data[0]?.data()['IsCollegeYear'] ??
                                    false))
                              return ListTile(
                                  title: Text('الكلية'),
                                  subtitle: Text(data.data[1]));
                            else if (data.hasData) return Container();
                            return LinearProgressIndicator();
                          },
                        ),
                      ListTile(
                        title: Text('نوع الفرد:'),
                        subtitle: FutureBuilder(
                            future: person.getStringType(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      ListTile(
                        title: Text('الكنيسة:'),
                        subtitle: FutureBuilder(
                            future: person.getChurchName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      ListTile(
                        title: Text('الاجتماع المشارك به:'),
                        subtitle: Text(person.meeting ?? ''),
                      ),
                      ListTile(
                        title: Text('اب الاعتراف:'),
                        subtitle: FutureBuilder(
                            future: person.getCFatherName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            }),
                      ),
                      TimeHistoryProperty(
                          'تاريخ أخر اعتراف:',
                          person.lastConfession,
                          person.ref.collection('ConfessionHistory')),
                      TimeHistoryProperty(
                          'تاريخ أخر تناول:',
                          person.lastTanawol,
                          person.ref.collection('TanawolHistory')),
                      ListTile(
                        title: Text('الحالة:'),
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: (person.state?.get(dataSource) ??
                              Future(() => null)),
                          builder: (context, data) {
                            if (data.hasData)
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(data.data.data()['Name']),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    color: Color(
                                      int.parse(
                                          "0xff${data.data.data()['Color']}"),
                                    ),
                                  )
                                ],
                              );
                            return Container();
                          },
                        ),
                      ),
                      HistoryProperty('تاريخ أخر مكالمة:', person.lastCall,
                          person.ref.collection('CallHistory')),
                      if ((person.notes ?? '') != '')
                        CopiableProperty('ملاحظات:', person.notes),
                      ListTile(
                          title: Text('خادم؟:'),
                          subtitle: Text(person.isServant ? 'نعم' : 'لا')),
                      if (person.isServant)
                        Selector<User, bool>(
                          selector: (_, user) => user.superAccess,
                          builder: (context, permission, _) =>
                              FutureBuilder<String>(
                                  future: person.getServingAreaName(),
                                  builder: (context, data) {
                                    if (data.hasData && permission)
                                      return ListTile(
                                        title: Text('منطقة الخدمة'),
                                        subtitle: Text(data.data),
                                      );
                                    return Container();
                                  }),
                        ),
                      if (person.isServant)
                        ListTile(
                          title: Text('نوع الخدمة:'),
                          subtitle: FutureBuilder(
                            future: person.getServingTypeName(),
                            builder: (context, data) {
                              if (data.hasData) return Text(data.data);
                              return LinearProgressIndicator();
                            },
                          ),
                        ),
                      Divider(
                        thickness: 1,
                      ),
                      ListTile(
                        title: Text('داخل منطقة:'),
                        subtitle: person.areaId != null &&
                                person.areaId.parent.id != 'null'
                            ? FutureBuilder<Area>(
                                future: Area.fromId(person.areaId.id),
                                builder: (context, area) => area.hasData
                                    ? DataObjectWidget<Area>(area.data,
                                        isDense: true)
                                    : LinearProgressIndicator(),
                              )
                            : Text('غير موجودة'),
                      ),
                      ListTile(
                        title: Text('داخل شارع:'),
                        subtitle: person.streetId != null &&
                                person.streetId.parent.id != 'null'
                            ? FutureBuilder<Street>(
                                future: Street.fromId(person.streetId.id),
                                builder: (context, street) => street.hasData
                                    ? DataObjectWidget<Street>(street.data,
                                        isDense: true)
                                    : LinearProgressIndicator(),
                              )
                            : Text('غير موجود'),
                      ),
                      if (person.familyId != null &&
                          person.familyId.parent.id != 'null')
                        ListTile(
                          title: Text('داخل عائلة:'),
                          subtitle: FutureBuilder<Family>(
                            future: Family.fromId(person.familyId.id),
                            builder: (context, family) => family.hasData
                                ? DataObjectWidget<Family>(family.data)
                                : LinearProgressIndicator(),
                          ),
                        ),
                      EditHistoryProperty(
                          'أخر تحديث للبيانات:',
                          person.lastEdit,
                          person.ref.collection('EditHistory')),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _phoneCall(
      BuildContext context, String item, PhoneCallAction action) async {
    if (action == PhoneCallAction.AddToContacts) {
      if ((await Permission.contacts.request()).isGranted)
        await Contacts.addContact(
          Contact(
              givenName: person.name,
              phones: [Item(label: 'Mobile', value: item)]),
        );
    } else if (action == PhoneCallAction.Call && (item ?? '') != '') {
      var result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text('هل تريد اجراء مكالمة الأن'),
          actions: [
            OutlinedButton.icon(
              icon: Icon(Icons.call),
              label: Text('اجراء مكالمة الأن'),
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton.icon(
              icon: Icon(Icons.dialpad),
              label: Text('نسخ في لوحة الاتصال فقط'),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );
      if (result == null) return;
      if (result) {
        await Permission.phone.request();
        await FlutterPhoneState.startPhoneCall(getPhone(item, false)).done;
        var recordLastCall = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text('هل تريد تسجيل تاريخ هذه المكالمة؟'),
            actions: [
              TextButton(
                  child: Text('نعم'),
                  onPressed: () => Navigator.pop(context, true)),
              TextButton(
                  child: Text('لا'),
                  onPressed: () => Navigator.pop(context, false)),
            ],
          ),
        );
        if (recordLastCall == true) {
          await person.ref.update({
            'LastEdit': auth.FirebaseAuth.instance.currentUser.uid,
            'LastCall': Timestamp.now()
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم بنجاح'),
            ),
          );
        }
      } else
        await launch('tel://' + getPhone(item, false));
    } else if (action == PhoneCallAction.Message) {
      await launch('sms://' + getPhone(item, false));
    } else if (action == PhoneCallAction.Whatsapp) {
      await launch(
          'whatsapp://send?phone=+' + getPhone(item).replaceAll('+', ''));
    }
  }
}
