import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/dialogs/progress_dialog.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class AppFeedback extends StatefulWidget {
  final int reviewerId;

  AppFeedback({Key key, this.reviewerId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => MyAppFeedback();
}

class MyAppFeedback extends State<AppFeedback> {
  final _reviewController = TextEditingController();
  double _rating = 4.0;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue,
          title: Text(AppLocalizations.of(context).reviewsAndRatings),
        ),
        backgroundColor: colorWhite,
        body: SafeArea(
            child: !isLoading
                ? SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(height: SizeConfig.screenHeight * 0.01),
                            Utils.buildPageSummary(
                                AppLocalizations.of(context).appReviewText),
                            SizedBox(height: SizeConfig.screenHeight * 0.01),
                            SmoothStarRating(
                              allowHalfRating: true,
                              onRated: (v) {
                                _rating = v;
                              },
                              starCount: 5,
                              rating: _rating,
                              size: 40.0,
                              isReadOnly: false,
                              color: Colors.yellow[600],
                              borderColor: colorGrey400,
                              spacing: 4,
                              filledIconData: Icons.star,
                              halfFilledIconData: Icons.star_half,
                              defaultIconData: Icons.star_border,
                            ),
                            SizedBox(height: SizeConfig.screenHeight * 0.025),
                            TextFormField(
                              controller: _reviewController,
                              maxLines: 4,
                              maxLength: 198,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)
                                    .reviewHint, // reviews,
                                hintText: AppLocalizations.of(context).reviews,
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                              validator: (feedback) {
                                if (feedback.isEmpty) {
                                  return AppLocalizations.of(context)
                                      .writeAReview;
                                } else if (feedback.length < 10) {
                                  return AppLocalizations.of(context)
                                      .enterMinimum2Letters
                                      .replaceAll('2', '10');
                                }
                                return null;
                              },
                              style: const TextStyle(
                                  color: colorBlack, fontSize: 18),
                            ),
                            SizedBox(height: SizeConfig.screenHeight * 0.035),
                            ElevatedButton(
                                style: Utils.roundedButtonStyle(),
                                child: Text(AppLocalizations.of(context)
                                    .submit
                                    .toUpperCase()),
                                onPressed: () {
                                  if (_rating < 0) {
                                    Utils.showToast(
                                        context,
                                        AppLocalizations.of(context)
                                            .putAStarRating,
                                        colorError);
                                  } else if (_reviewController.text.isEmpty) {
                                    Utils.showToast(
                                        context,
                                        AppLocalizations.of(context)
                                            .writeAReview,
                                        colorError);
                                  } else if (_reviewController.text.length <
                                      10) {
                                    Utils.showToast(
                                        context,
                                        AppLocalizations.of(context)
                                            .enterMinimum2Letters
                                            .replaceAll('2', '10'),
                                        colorError);
                                  } else {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    prepareData();
                                  }
                                }),
                          ],
                        ),
                      ),
                    ),
                  )
                : Utils.loadingWidget(
                    AppLocalizations.of(context).loadingPleaseWait)),
        bottomNavigationBar: Utils.buildBottomBar());
  }

  prepareData() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        addReview(context);
        return WillPopScope(
          onWillPop: () => Future.value(false),
          child: ProgressDialog(
              message: AppLocalizations.of(context).loadingPleaseWait),
        );
      },
    );
  }

  addReview(BuildContext context) {
    Map<String, String> params = {
      'review_text': _reviewController.text.toString(),
      'review_star': _rating.toString(),
      'reviewer_id': widget.reviewerId.toString(),
    };
    ApiRequest.postReview(params, isForApp: true).then((value) {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
      if (value != null) {
        Utils.showToast(
            context, AppLocalizations.of(context).reviewAdded, colorSuccess,
            duration: 5);
        Navigator.pop(context);
      } else {
        Utils.showToast(
            context, AppLocalizations.of(context).errorToAddReview, colorError);
      }
    });
  }
}
