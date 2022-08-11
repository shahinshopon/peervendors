import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/render_nested_dropdowns.dart';

class PrivacyOrFAQs extends StatefulWidget {
  final bool isPrivacy;
  @override
  State<StatefulWidget> createState() => MyPrivacyOrFaQs();
  PrivacyOrFAQs({Key key, @required this.isPrivacy}) : super(key: key);
}

class MyPrivacyOrFaQs extends State<PrivacyOrFAQs> {
  bool isLoading = false;
  Subject _faq;
  int _expandedParentIndex = -1;
  bool _isExpandedParent = false;
  int _expandedChildIndex = -1;
  bool _isExpandedChild = false;

  @override
  void initState() {
    isLoading = true;
    String asset2Load = widget.isPrivacy
        ? 'assets/files/privacy.json'
        : 'assets/files/faq.json';
    rootBundle.loadString(asset2Load).then((value) {
      _faq = Subject.fromJson(json.decode(value));
      isLoading = false;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: colorWhite,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(widget.isPrivacy
              ? AppLocalizations.of(context).privacyPolicy
              : AppLocalizations.of(context).faq),
          centerTitle: true,
          backgroundColor: Colors.blue,
          elevation: 5,
        ),
        body: SafeArea(
          child: isLoading
              ? Utils.loadingWidget(
                  AppLocalizations.of(context).loadingPleaseWait)
              : ListView.separated(
                  separatorBuilder: (context, index) {
                    return Divider(
                        thickness: 0, height: 1, color: colorGrey300);
                  },
                  shrinkWrap: true,
                  itemCount: _faq.sections.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, indexParent) {
                    return ExpansionTile(
                      title: Text(
                        _faq.sections[indexParent].heading,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(
                        _expandedParentIndex == indexParent && _isExpandedParent
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                      onExpansionChanged: (value) {
                        setState(() {
                          _expandedParentIndex = indexParent;
                          _isExpandedParent = value;
                        });
                      },
                      children: [
                        ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          itemCount: _faq.sections[indexParent].topics.length,
                          itemBuilder: (context, indexChild) {
                            return ExpansionTile(
                              title: Text(
                                _faq.sections[indexParent].topics[indexChild]
                                    .title,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Icon(
                                _expandedChildIndex == indexChild &&
                                        _isExpandedChild
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                              ),
                              onExpansionChanged: (value) {
                                setState(() {
                                  _expandedChildIndex = indexChild;
                                  _isExpandedChild = value;
                                });
                              },
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, bottom: 8),
                                  child: Text(
                                    _faq.sections[indexParent]
                                        .topics[indexChild].content,
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(color: colorGrey700),
                                  ),
                                )
                              ],
                            );
                          },
                        )
                      ],
                    );
                  },
                ),
        ),
        bottomNavigationBar: Utils.buildBottomBar());
  }
}
