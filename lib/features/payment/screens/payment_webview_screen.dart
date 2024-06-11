import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';
import 'package:sixam_mart/features/wallet/widgets/fund_payment_dialog_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final OrderModel orderModel;
  final bool isCashOnDelivery;
  final String? addFundUrl;
  final String paymentMethod;
  final String guestId;
  final String contactNumber;
  const PaymentWebViewScreen({super.key, required this.orderModel, required this.isCashOnDelivery, this.addFundUrl, required this.paymentMethod,
    required this.guestId, required this.contactNumber});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentWebViewScreen> {
  late String selectedUrl;
  bool _isLoading = true;
  final bool _canRedirect = true;
  double? _maximumCodOrderAmount;
  PullToRefreshController? pullToRefreshController;
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();

    if(widget.addFundUrl == null  || (widget.addFundUrl != null && widget.addFundUrl!.isEmpty)){
      selectedUrl = '${AppConstants.baseUrl}/payment-mobile?customer_id=${widget.orderModel.userId == 0 ? widget.guestId : widget.orderModel.userId}&order_id=${widget.orderModel.id}&payment_method=${widget.paymentMethod}';
    }else{
      selectedUrl = widget.addFundUrl!;
    }


    _initData();
  }

  void _initData() async {
    if(widget.addFundUrl == null  || (widget.addFundUrl != null && widget.addFundUrl!.isEmpty)){
      for(ZoneData zData in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
        for(Modules m in zData.modules!) {
          if(m.id == Get.find<SplashController>().module!.id) {
            _maximumCodOrderAmount = m.pivot!.maximumCodOrderAmount;
            break;
          }
        }
      }
    }

    pullToRefreshController = GetPlatform.isWeb || ![TargetPlatform.iOS, TargetPlatform.android].contains(defaultTargetPlatform) ? null : PullToRefreshController(
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          webViewController?.loadUrl(urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (value) async {
        _exitApp();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBar(title: '', onBackPressed: () => _exitApp(), backButton: true),
        body: Stack(
          children: [
             InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(selectedUrl)),
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              pullToRefreshController: pullToRefreshController,
              initialOptions: InAppWebViewGroupOptions(crossPlatform: InAppWebViewOptions(useShouldOverrideUrlLoading: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 10; Pixel 3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Mobile Safari/537.36 CustomScheme/sameasnapp CustomScheme/wave',
              ), android: AndroidInAppWebViewOptions(useHybridComposition: true)),
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },
              onLoadStart: (controller, url) async {
                // _redirect(url.toString());
                Get.find<OrderController>().paymentRedirect(url: url.toString(), canRedirect: _canRedirect, onClose: (){} , addFundUrl: widget.addFundUrl, orderID: widget.orderModel.id.toString(), contactNumber: widget.contactNumber);
                setState(() {
                  _isLoading = true;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                Uri uri = navigationAction.request.url!;
                if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
                    Navigator.pushReplacementNamed(context, RouteHelper.getInitialRoute());
                     return NavigationActionPolicy.CANCEL;
                  }
                  if(["wave"].contains(uri.scheme)){
                  await launchUrl(uri ,mode: LaunchMode.externalNonBrowserApplication);
                Navigator.pushReplacementNamed(context, RouteHelper.getInitialRoute());
                return NavigationActionPolicy.CANCEL;
                }
                  
                }
                //  if (["orange"].contains(uri)) {
                //      await launchUrl(uri, mode: LaunchMode.externalApplication);
                //     Navigator.pushReplacementNamed(context, RouteHelper.getOrderTrackingRoute(widget.orderModel.id, widget.contactNumber));
                //      return NavigationActionPolicy.CANCEL;
                //     debugPrint('erraur');
                //    }
                  
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                pullToRefreshController?.endRefreshing();
                setState(() {
                  _isLoading = false;
                });
                if(["sameaosnapp"].contains(url!.scheme)){
                  await launchUrl(url! ,mode: LaunchMode.externalNonBrowserApplication);
                Navigator.pushReplacementNamed(context, RouteHelper.getInitialRoute());
                }
               //Get.find<OrderController>().paymentRedirect(url: url.toString(), canRedirect: _canRedirect, onClose: (){} , addFundUrl: widget.addFundUrl, orderID: widget.orderModel.id.toString(), contactNumber: widget.contactNumber);
                // _redirect(url.toString());
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController?.endRefreshing();
                }
                // setState(() {
                //   _value = progress / 100;
                // });
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint(consoleMessage.message);
              },
            ),
            _isLoading ? Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
            ) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Future<bool?> _exitApp() async {
    if((widget.addFundUrl == null  || (widget.addFundUrl != null && widget.addFundUrl!.isEmpty)) || !Get.find<SplashController>().configModel!.digitalPaymentInfo!.pluginPaymentGateways!){
      return Get.dialog(PaymentFailedDialog(
        orderID: widget.orderModel.id.toString(),
        orderAmount: widget.orderModel.orderAmount,
        maxCodOrderAmount: _maximumCodOrderAmount,
        orderType: widget.orderModel.orderType,
        isCashOnDelivery: widget.isCashOnDelivery,
      ));
    }else{
      return Get.dialog(const FundPaymentDialogWidget());
    }

  }

}