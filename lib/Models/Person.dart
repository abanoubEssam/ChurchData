import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../utils/Helpers.dart';
import '../Models.dart';
import '../Models/super_classes.dart';
import 'User.dart';
import '../utils/globals.dart';

class Person extends DataObject with PhotoObject, ChildObject<Family> {
  DocumentReference familyId;
  DocumentReference streetId;
  DocumentReference areaId;

  String phone;
  Map<String, dynamic> phones; //Other phones if any
  Timestamp birthDate;

  Timestamp lastConfession;
  Timestamp lastTanawol;
  Timestamp lastCall;

  bool isStudent;
  DocumentReference studyYear;
  DocumentReference college;
  DocumentReference job;
  String jobDescription;
  String qualification;
  String type;
  bool isServant;

  DocumentReference servingAreaId;

  DocumentReference church;
  String meeting;

  DocumentReference cFather;
  DocumentReference state;
  String notes;
  DocumentReference servingType;

  String lastEdit;

  Person(
      {String id = '',
      this.areaId,
      this.streetId,
      this.familyId,
      String name = '',
      this.phone = '',
      this.phones,
      bool hasPhoto = false,
      this.birthDate,
      this.lastTanawol,
      this.lastCall,
      this.lastConfession,
      this.isStudent = false,
      this.studyYear,
      this.job,
      this.college,
      this.jobDescription = '',
      this.qualification = '',
      this.type = '',
      this.notes = '',
      this.isServant = false,
      this.servingAreaId,
      this.church,
      this.meeting = '',
      this.cFather,
      this.state,
      this.servingType,
      this.lastEdit,
      Color color = Colors.transparent})
      : super(id, name, color) {
    this.hasPhoto = hasPhoto;
    phones ??= {};
    defaultIcon = Icons.person;
  }

  Person._createFromData(Map<dynamic, dynamic> data, String id)
      : super.createFromData(data, id) {
    familyId = data['FamilyId'];
    streetId = data['StreetId'];
    areaId = data['AreaId'];

    phone = data['Phone'];
    phones = data['Phones']?.cast<String, dynamic>() ?? {};

    hasPhoto = data['HasPhoto'] ?? false;
    defaultIcon = Icons.person;

    isStudent = data['IsStudent'];
    studyYear = data['StudyYear'];
    college = data['College'];

    birthDate = data['BirthDate'];
    lastConfession = data['LastConfession'];
    lastTanawol = data['LastTanawol'];
    lastCall = data['LastCall'];

    job = data['Job'];
    jobDescription = data['JobDescription'];
    qualification = data['Qualification'];

    type = data['Type'];

    notes = data['Notes'];
    isServant = data['IsServant'];
    servingAreaId = data['ServingAreaId'];

    church = data['Church'];
    meeting = data['Meeting'];
    cFather = data['CFather'];

    state = data['State'];
    servingType = data['ServingType'];

    lastEdit = data['LastEdit'];
  }

  Timestamp get birthDay => birthDate != null
      ? Timestamp.fromDate(
          DateTime(1970, birthDate.toDate().month, birthDate.toDate().day),
        )
      : null;

  @override
  DocumentReference get parentId => familyId;

  @override
  Reference get photoRef =>
      FirebaseStorage.instance.ref().child('PersonsPhotos/$id');

  @override
  DocumentReference get ref => FirebaseFirestore.instance.doc('Persons/$id');

  Future<String> getAreaName() async {
    var tmp = (await areaId?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getCFatherName() async {
    var tmp = (await cFather?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getChurchName() async {
    var tmp = (await church?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getCollegeName() async {
    if (!isStudent) return '';
    var tmp = (await college?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getFamilyName() async {
    var tmp = (await familyId?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  @override
  Map<String, dynamic> getHumanReadableMap() => {
        'Name': name ?? '',
        'Phone': phone ?? '',
        'BirthDate': toDurationString(birthDate, appendSince: false),
        'BirthDay': birthDay != null
            ? DateFormat('d/M').format(
                birthDay.toDate(),
              )
            : '',
        'IsStudent': isStudent ? 'طالب' : '',
        'JobDescription': jobDescription ?? '',
        'Qualification': qualification ?? '',
        'Notes': notes ?? '',
        'IsServant': isServant ? 'خادم' : '',
        'Meeting': meeting ?? '',
        'LastTanawol': toDurationString(lastTanawol),
        'LastCall': toDurationString(lastCall),
        'LastConfession': toDurationString(lastConfession),
        'LastEdit': lastEdit
      };

  Future<String> getJobName() async {
    var tmp = (await job?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<Widget> getLeftWidget() async {
    if (Hive.box('Settings').get('ShowPersonState', defaultValue: false)) {
      var color = (await state?.get(dataSource))?.data();
      return color == null
          ? Container(width: 1, height: 1)
          : Container(
              height: 50,
              width: 50,
              color: Color(
                int.parse('0xff${color['Color']}'),
              ),
            );
    }
    return Container(width: 1, height: 1);
  }

  @override
  Map<String, dynamic> getMap() => {
        'FamilyId': familyId,
        'StreetId': streetId,
        'AreaId': areaId,
        'Name': name,
        'Phone': phone,
        'Phones': (phones?.map((k, v) => MapEntry(k, v)) ?? {})
          ..removeWhere((k, v) => v.toString().isEmpty),
        'HasPhoto': hasPhoto ?? false,
        'Color': color.value,
        'BirthDate': birthDate,
        'BirthDay': birthDay,
        'IsStudent': isStudent,
        'StudyYear': studyYear,
        'College': college,
        'Job': job,
        'JobDescription': jobDescription,
        'Qualification': qualification,
        'Type': type,
        'Notes': notes,
        'IsServant': isServant,
        'ServingAreaId': servingAreaId,
        'Church': church,
        'Meeting': meeting,
        'CFather': cFather,
        'State': state,
        'ServingType': servingType,
        'LastTanawol': lastTanawol,
        'LastCall': lastCall,
        'LastConfession': lastConfession,
        'LastEdit': lastEdit,
      };

  @override
  Future<String> getParentName() => getFamilyName();

  String getSearchString() {
    return ((name ?? '') +
            (phone ?? '') +
            (birthDate?.toString() ?? '') +
            (jobDescription ?? '') +
            (qualification ?? '') +
            (meeting ?? '') +
            (notes ?? '') +
            (type ?? ''))
        .toLowerCase()
        .replaceAll(
            RegExp(
              r'[أإآ]',
            ),
            'ا')
        .replaceAll(
            RegExp(
              r'[ى]',
            ),
            'ي');
  }

  @override
  Future<String> getSecondLine() async {
    String key = Hive.box('Settings').get('PersonSecondLine');
    if (key == 'Members') {
      return '';
    } else if (key == 'AreaId') {
      return await getAreaName();
    } else if (key == 'StreetId') {
      return await getStreetName();
    } else if (key == 'FamilyId') {
      return await getFamilyName();
    } else if (key == 'StudyYear') {
      return await getStudyYearName();
    } else if (key == 'College') {
      return await getCollegeName();
    } else if (key == 'Job') {
      return await getJobName();
    } else if (key == 'Type') {
      return await getStringType();
    } else if (key == 'ServingAreaId') {
      return await getServingAreaName();
    } else if (key == 'Church') {
      return await getChurchName();
    } else if (key == 'CFather') {
      return await getCFatherName();
    } else if (key == 'LastEdit') {
      return (await FirebaseFirestore.instance
              .doc('Users/$lastEdit')
              .get(dataSource))
          .data()['Name'];
    }
    return getHumanReadableMap()[key];
  }

  Future<String> getServingAreaName() async {
    if (!isServant) return '';
    var tmp = (await servingAreaId?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getServingTypeName() async {
    var tmp = (await servingType?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getStreetName() async {
    var tmp = (await streetId?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Future<String> getStringType() async {
    if (type == null || type.isEmpty) return '';
    var data = (await FirebaseFirestore.instance
            .collection('Types')
            .doc(type)
            ?.get(dataSource))
        ?.data();
    if (data == null) return '';
    return data['Name'] ?? 'لا يوجد';
  }

  Future<String> getStudyYearName() async {
    if (!isStudent) return '';
    var tmp = (await studyYear?.get(dataSource))?.data();
    if (tmp == null) return '';
    return tmp['Name'] ?? 'لا يوجد';
  }

  Map<String, dynamic> getUserRegisterationMap() => {
        'Name': name,
        'Phone': phone,
        'HasPhoto': hasPhoto ?? false,
        'Color': color.value,
        'BirthDate': birthDate?.millisecondsSinceEpoch,
        'BirthDay': birthDay?.millisecondsSinceEpoch,
        'IsStudent': isStudent,
        'StudyYear': studyYear?.path,
        'College': college?.path,
        'Job': job?.path,
        'JobDescription': jobDescription,
        'Qualification': qualification,
        'Type': type,
        'Notes': notes,
        'IsServant': isServant,
        'Church': church?.path,
        'Meeting': meeting,
        'CFather': cFather?.path,
        'ServingType': servingType?.path,
        'LastTanawol': lastTanawol?.millisecondsSinceEpoch,
        'LastConfession': lastConfession?.millisecondsSinceEpoch
      };

  Future setAreaIdFromStreet() async {
    areaId = (await streetId?.get(dataSource))?.data()['AreaId'];
  }

  Future setStreetIdFromFamily() async {
    streetId = (await familyId?.get(dataSource))?.data()['StreetId'];
    await setAreaIdFromStreet();
  }

  static Person fromDoc(DocumentSnapshot data) =>
      data.exists ? Person._createFromData(data.data(), data.id) : null;

  static Future<Person> fromId(String id) async => Person.fromDoc(
        await FirebaseFirestore.instance.doc('Persons/$id').get(),
      );

  static List<Person> getAll(List<DocumentSnapshot> persons) {
    return persons.map(Person.fromDoc).toList();
  }

  static Stream<QuerySnapshot> getAllForUser({
    String orderBy = 'Name',
    bool descending = false,
  }) async* {
    await for (var u in User.instance.stream)
      if (u.superAccess)
        await for (var s in FirebaseFirestore.instance
            .collection('Persons')
            .orderBy(orderBy, descending: descending)
            .snapshots()) yield s;
      else
        await for (var s in FirebaseFirestore.instance
            .collection('Persons')
            .where(
              'AreaId',
              whereIn: (await FirebaseFirestore.instance
                      .collection('Areas')
                      .where('Allowed',
                          arrayContains:
                              auth.FirebaseAuth.instance.currentUser.uid)
                      .get(dataSource))
                  .docs
                  .map((e) => e.reference)
                  .toList(),
            )
            .orderBy(orderBy, descending: descending)
            .snapshots()) yield s;
  }

  static Map<String, dynamic> getEmptyExportMap() => {
        'ID': 'id',
        'FamilyId': 'familyId',
        'StreetId': 'streetId',
        'AreaId': 'areaId',
        'Name': 'name',
        'Phone': 'phone',
        'HasPhoto': 'hasPhoto',
        'Color': 'color',
        'BirthDate': 'birthDate',
        'BirthDay': 'birthDay',
        'IsStudent': 'isStudent',
        'StudyYear': 'studyYear',
        'College': 'college',
        'Job': 'job',
        'JobDescription': 'jobDescription',
        'Qualification': 'qualification',
        'Type': 'type',
        'Notes': 'notes',
        'IsServant': 'isServant',
        'ServingAreaId': 'servingAreaId',
        'Church': 'church',
        'Meeting': 'meeting',
        'CFather': 'cFather',
        'State': 'state',
        'ServantUserId': 'servantUserId',
        'ServingType': 'servingType',
        'LastTanawol': 'lastTanawol',
        'LastConfession': 'lastConfession',
        'LastEdit': 'lastEdit'
      };

  static Map<String, dynamic> getHumanReadableMap2() => {
        'Name': 'الاسم',
        'Phone': 'رقم الهاتف',
        'Color': 'اللون',
        'BirthDate': 'تاريخ الميلاد',
        'BirthDay': 'يوم الميلاد',
        'IsStudent': 'طالب؟',
        'JobDescription': 'تفاصيل الوظيفة',
        'Qualification': 'المؤهل',
        'Notes': 'ملاحظات',
        'IsServant': 'خادم؟',
        'Meeting': 'الاجتماع المشارك به',
        'Type': 'نوع الفرد',
        'LastTanawol': 'تاريخ أخر تناول',
        'LastCall': 'تاريخ أخر مكالمة',
        'LastConfession': 'تاريخ أخر اعتراف',
        'LastEdit': 'أخر شخص قام بالتعديل'
      };

  // @override
  // fireWeb.Reference get webPhotoRef =>
  //     fireWeb.storage().ref('PersonsPhotos/$id');
}
