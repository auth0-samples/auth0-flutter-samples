import 'package:flutter/material.dart';

class UserWidget extends StatelessWidget {
  dynamic user;
  UserWidget({required final this.user, final Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // id, name, email, email verified, updated_at
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (user.pictureURL != null)
        Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CircleAvatar(
              radius: 56,
              child: ClipOval(child: Image.network(user.pictureURL.toString())),
            )),
      Card(
          child: Column(children: [
        UserEntryWidget(propertyName: 'Id', propertyValue: user.sub),
        UserEntryWidget(propertyName: 'Name', propertyValue: user.name),
        UserEntryWidget(propertyName: 'Email', propertyValue: user.email),
        UserEntryWidget(
            propertyName: 'Email Verified?',
            propertyValue: user.isEmailVerified.toString()),
        UserEntryWidget(
            propertyName: 'Updated at',
            propertyValue: user.updatedAt?.toIso8601String()),
      ]))
    ]);
  }
}

class UserEntryWidget extends StatelessWidget {
  String propertyName;
  String? propertyValue;
  UserEntryWidget(
      {required final this.propertyName,
      required final this.propertyValue,
      final Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(propertyName), Text(propertyValue ?? '')],
        ));
  }
}