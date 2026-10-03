import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghclient/common/utils/toast_utils.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(
  BuildContext context,
  String url, {
  String errorMessage = '无法打开链接，请稍后重试',
}) async {
  try {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ToastUtils.show(context, message: errorMessage, type: ToastType.error);
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      ToastUtils.show(context, message: errorMessage, type: ToastType.error);
    }
    return false;
  }
}

Future<void> copyText(
  BuildContext context,
  String text, {
  String successMessage = '已复制',
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ToastUtils.show(context, message: successMessage, type: ToastType.success);
  }
}
