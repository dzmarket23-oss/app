import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../../models/index.dart';

class ShortDescription extends StatelessWidget {
  final Product product;
  final bool show;

  const ShortDescription({required this.product, required this.show});

  String _parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (product.shortDescription == null || !show) {
      return const SizedBox();
    }

    final plainText = _parseHtmlString(product.shortDescription!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        plainText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
