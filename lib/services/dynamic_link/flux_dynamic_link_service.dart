import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flux_dynamic_link/flux_dynamic_link.dart';
import 'package:inspireui/utils/logs.dart';

import '../../common/config/models/dynamic_link/dynamic_link.dart';
import '../../common/config/models/dynamic_link/flux_dynamic_link_config.dart';
import '../../common/tools.dart';
import '../../models/entities/user.dart';
import 'dynamic_link_service.dart';

class FluxDynamicLinkService extends DynamicLinkService {
  late final FluxDynamicLink _fluxDynamicLink;
  final FluxDynamicLinkConfig fluxDynamicLinkConfig;

  FluxDynamicLinkService({
    required super.linkService,
    required this.fluxDynamicLinkConfig,
  }) : super(DynamicLinkType.fluxDynamicLink);

  bool get _isValidate => fluxDynamicLinkConfig.isValidate;
  Completer? _completer;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_isValidate == false) {
      printLog('[FluxDynamicLinkService] FluxDynamicLinkConfig is not valid');
      return;
    }
    await _checkAndInitService();
  }

  @override
  Future<String?> createDynamicLink(String url, {required User? user}) async {
    if (_isValidate) {
      await _checkAndInitService();

      printLog('[FluxDynamicLinkService] createDynamicLink: $url');
      final hashCodeLink = crypto.md5
          .convert(utf8.encode('$hashCode$url${DateTime.now()}'))
          .toString()
          .substring(0, 6)
          .toUpperCase();

      final deeplink = fluxDynamicLinkConfig.createDeepLink(hashCodeLink);

      try {
        final result = await _fluxDynamicLink.createShortenedLink(
          CreateFluxDynamicLinkForm(
            slug: hashCodeLink,
            webFallbackUrl: url,
            playstoreUrl: fluxDynamicLinkConfig.androidUrl ?? url,
            appstoreUrl: fluxDynamicLinkConfig.iosUrl ?? url,
            androidDeeplink: deeplink,
            iosDeeplink: deeplink,
            androidPackage: fluxDynamicLinkConfig.androidPackage,
            metadata: user?.id?.isNotEmpty ?? false
                ? LinkMetadata(data: {'user_id': user!.id, 'email': user.email})
                : null,
          ),
        );

        return fluxDynamicLinkConfig.createShortLink(result.slug);
      } catch (e, trace) {
        printError(e, trace);
      }
    }

    return null;
  }

  @override
  Future<void> handleLink(String url) async {
    if (_isValidate) {
      await _checkAndInitService();
      await _fluxDynamicLink.handleDynamicLink(url);
    }
  }

  @override
  bool isSupportedLink(String url) {
    return _isValidate;
  }

  Future<void> _checkAndInitService() async {
    if (_completer != null) {
      await _completer!.future;
      return;
    }

    if (_initialized == false) {
      // Set callback for install referrer detection BEFORE initialize
      FluxDynamicLink.setOnInstallReferrerDetected((result) {
        log('Install Referrer Detected!');
        log('Platform: ${result.platform}');
        log('Match Type: ${result.matchType}');
        log('Deep Link: ${result.deepLink}');
        log('Session ID: ${result.sessionId}');
        log('Metadata: ${result.metadata}');

        // You can use this to show a welcome screen, navigate to a specific page, etc.
        // For example, if you want to apply a coupon from the metadata:
        if (result.metadata != null && result.metadata!['coupon'] != null) {
          log('Applying coupon: ${result.metadata!['coupon']}');
        }
      });

      _completer = Completer();
      await FluxDynamicLink.initialize(
        publicKey: fluxDynamicLinkConfig.publicKey,
        linkDomain: fluxDynamicLinkConfig.linkDomain,
      );
      _fluxDynamicLink = FluxDynamicLink.instance;
      _fluxDynamicLink.dynamicLinkStream.listen((String? url) {
        if (url?.isNotEmpty ?? false) {
          linkService.handleWebLink(url!.toUri()!);
        }
      });

      _initialized = true;
      _completer!.complete();
      _completer = null;
    }
  }
}
