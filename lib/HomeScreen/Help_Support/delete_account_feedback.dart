import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/AuthenticationScreens/signup_and_login.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/user_model.dart';

class DeleteAccountFeedbackScreen extends StatefulWidget {
  final UserModel currentUser;
  DeleteAccountFeedbackScreen({Key key, @required this.currentUser})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateDeleteAccountFeedbackScreen();
}

class StateDeleteAccountFeedbackScreen
    extends State<DeleteAccountFeedbackScreen> {
  List<int> indexSelected = [];
  Set<String> selectedReasons = {};
  final double itemsElevation = 4;
  String otherReason;
  final _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(AppLocalizations.of(context)
            .deactivatedAccountMessage
            .split('.')[0]),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 5,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(4.0),
          child: ListView(
            padding: const EdgeInsets.all(0.0),
            children: getUninstallReasons(
                AppLocalizations.of(context).reasonForUninstalling),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.pink,
        child: Container(height: 50),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,
    );
  }

  List<Widget> getUninstallReasons(String uninstallReasons) {
    List<String> reasons = uninstallReasons.split('. ');
    List<Widget> resp = [
      Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(2),
          child: Text(
            AppLocalizations.of(context).whyDeleteAccount,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          )),
      Utils.buildSeparator(MediaQuery.of(context).size.width)
    ];
    resp.addAll(reasons
        .map((e) => (OutlinedButton(
              style: ElevatedButton.styleFrom(
                  primary:
                      selectedReasons.contains(e) ? Colors.grey : Colors.white),
              child: Container(child: Text(e + '.')),
              onPressed: () {
                selectedReasons.contains(e)
                    ? selectedReasons.remove(e)
                    : selectedReasons.add(e);
                // print(e);
                setState(() {});
              },
            )))
        .toList());
    resp.addAll([
      Form(
        key: _formKey,
        child: Visibility(
            visible: selectedReasons.contains(reasons.last),
            child: TextFormField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              maxLength: 100,
              autocorrect: true,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.always,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).whyDeleteAccount,
                focusedBorder: buildBoarder(color: Colors.green),
                focusedErrorBorder: buildBoarder(color: Colors.red),
                errorBorder: buildBoarder(color: Colors.red),
                enabledBorder: buildBoarder(),
                disabledBorder: buildBoarder(color: Colors.blueGrey),
                border: UnderlineInputBorder(),
              ),
              validator: (String value) {
                if (value != null && value.length > 10) {
                  return null;
                }
                return AppLocalizations.of(context)
                    .enterMinimum2Letters
                    .replaceAll('2', '10');
              },
              onSaved: (String value) {
                if (value != null && value.length > 10) {
                  setState(() {
                    otherReason = value;
                  });
                }
              },
            )),
      ),
      ElevatedButton(
        style: Utils.roundedButtonStyle(),
        child: Text(AppLocalizations.of(context).submit),
        onPressed: () {
          if (selectedReasons.isEmpty) {
            Utils.showToast(
                context,
                AppLocalizations.of(context).selectOneOrMoreReasons,
                Colors.redAccent);
          } else {
            String reasons = selectedReasons.join('|');
            if (_controller.text.isNotEmpty && _controller.text.length > 10) {
              reasons = '$reasons|typedReason--${_controller.text}';
            }
            ApiRequest.postReasonsForDeletingApp(params: {
              'reason': reasons,
              'user_lang': widget.currentUser.user_lang,
              'email': widget.currentUser.email,
              'country_code': widget.currentUser.country_code,
              'user_id': widget.currentUser.user_id.toString()
            }).then((value) {
              Utils.showToast(context,
                  AppLocalizations.of(context).deletionThanks, Colors.green);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SignupOrLogin()));
            });
          }
        },
      )
    ]);
    return resp;
  }

  OutlineInputBorder buildBoarder({Color color = Colors.blue}) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        color: color,
        width: 1,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(5)),
    );
  }
}
