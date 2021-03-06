import 'package:churchdata/utils/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopiableProperty extends StatelessWidget {
  const CopiableProperty(this.name, this.value, {Key key})
      : assert(name != null),
        super(key: key);

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(value ?? ''),
      trailing: value != null && value.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.copy),
              tooltip: 'نسخ',
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            )
          : IconButton(
              icon: Icon(Icons.warning),
              tooltip: 'بيانات غير كاملة',
              onPressed: null,
              color: Colors.red,
            ),
    );
  }
}

class PhoneNumberProperty extends StatelessWidget {
  const PhoneNumberProperty(this.name, this.value, this.phoneCall, {Key key})
      : super(key: key);

  final String name;
  final String value;
  final void Function(String, PhoneCallAction) phoneCall;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(value ?? ''),
      trailing: value != null && value.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.phone),
                  tooltip: 'اجراء مكالمة',
                  onPressed: () => phoneCall(value, PhoneCallAction.Call),
                ),
                IconButton(
                  icon: Image.asset('assets/whatsapp.png',
                      width: IconTheme.of(context).size,
                      height: IconTheme.of(context).size,
                      color: Theme.of(context).iconTheme.color),
                  tooltip: 'ارسال رسالة (واتساب)',
                  onPressed: () => phoneCall(value, PhoneCallAction.Whatsapp),
                ),
                IconButton(
                  icon: Icon(Icons.message),
                  tooltip: 'ارسال رسالة',
                  onPressed: () => phoneCall(value, PhoneCallAction.Message),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  tooltip: 'نسخ',
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: value)),
                ),
              ],
            )
          : IconButton(
              icon: Icon(Icons.warning),
              tooltip: 'بيانات غير كاملة',
              onPressed: null,
              color: Colors.red,
            ),
    );
  }
}
