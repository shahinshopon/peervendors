import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:peervendors/Responsive/sizeconfig.dart';
import 'package:peervendors/Static/colordata.dart';
import 'package:peervendors/client/api_request.dart';
import 'package:peervendors/helpers/dialogs/progress_dialog.dart';
import 'package:peervendors/helpers/utils.dart';
import 'package:peervendors/models/product_list_home.dart';
import 'package:peervendors/models/send_email.dart';
import 'package:peervendors/models/user_model.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class AddReview extends StatefulWidget {
  final UserModel userModel;
  final AdsDetail adDetails;
  ReviewData previousReview;

  AddReview({Key key, this.userModel, this.adDetails, this.previousReview})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => MyAddReview();
}

class MyAddReview extends State<AddReview> {
  final _reviewController = TextEditingController();
  double _rating = 4.0;
  @override
  void initState() {
    super.initState();
    setUserPrefs();
  }

  setUserPrefs() {
    if (widget.previousReview != null) {
      setState(() {
        //print(widget.previousReview.reviewStar);
        _reviewController.text = widget.previousReview.reviewText;
        _rating = widget.previousReview.reviewStar;
      });
    }
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
            child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  SizedBox(height: SizeConfig.screenHeight * 0.01),
                  Utils.buildPageSummary(
                      AppLocalizations.of(context).reviewSummaryMessage),
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
                    maxLines: 3,
                    maxLength: 198,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).reviews,
                      hintText: AppLocalizations.of(context).reviewHint,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    validator: (name) {
                      if (name.isEmpty) {
                        return AppLocalizations.of(context).writeAReview;
                      }
                      return null;
                    },
                    style: TextStyle(color: colorBlack, fontSize: 18),
                  ),
                  SizedBox(height: SizeConfig.screenHeight * 0.035),
                  Utils.customButton(SizeConfig.screenWidth * 0.5,
                      AppLocalizations.of(context).submit.toUpperCase(), () {
                    if (_rating < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                AppLocalizations.of(context).putAStarRating),
                            backgroundColor: colorError),
                      );
                    } else if (_reviewController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(AppLocalizations.of(context).writeAReview),
                            backgroundColor: colorError),
                      );
                    } else {
                      prepareData();
                    }
                  }),
                ],
              ),
            ),
          ),
        )),
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
      'ad_id': widget.adDetails.ad_id.toString(),
      'review_text': _reviewController.text.toString(),
      'review_star': _rating.toString(),
      'reviewer_id': widget.userModel.user_id.toString(),
      'seller_id': widget.adDetails.seller_id.toString()
    };
    if (widget.previousReview != null) {
      params['review_id_to_update'] = widget.previousReview.reviewId.toString();
    }
    ApiRequest.postReview(params).then((value) {
      Navigator.pop(context);
      if (value != null) {
        Utils.showToast(
            context, AppLocalizations.of(context).reviewAdded, colorSuccess);
        Navigator.pop(context);
      } else {
        Utils.showToast(
            context, AppLocalizations.of(context).errorToAddReview, colorError);
      }
    });
  }
}
