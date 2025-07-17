import 'package:flutter/material.dart';
import 'package:highlight/highlight.dart' show highlight, Node;

/// Highlight Flutter Widget
class HighlightView extends StatefulWidget {
  /// The original code to be highlighted
  final String source;

  /// Highlight language
  ///
  /// It is recommended to give it a value for performance
  ///
  /// [All available languages](https://github.com/pd4d10/highlight/tree/master/highlight/lib/languages)
  final String? language;

  /// Highlight theme
  ///
  /// [All available themes](https://github.com/pd4d10/highlight/blob/master/flutter_highlight/lib/themes)
  final Map<String, TextStyle> theme;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Text styles
  ///
  /// Specify text styles such as font family and font size
  final TextStyle? textStyle;

  /// Enable line numbers
  final bool lineNumbers;

  /// Enable control bar with zoom and line wrap functionality
  final bool controlBar;

  /// Enable text selection (default: false)
  final bool textSelectable;

  /// Custom icons for control bar
  final Icon zoomInIcon;
  final Icon zoomOutIcon;
  final Icon lineWrapIcon;

  /// Color for control bar icons
  final Color? barIconColor;

  /// Minimum zoom scale factor
  final double minZoom;

  /// Maximum zoom scale factor
  final double maxZoom;

  /// Zoom step size
  final double zoomStep;

  HighlightView(
    String input, {
    Key? key,
    this.language,
    this.theme = const {},
    this.padding,
    this.textStyle,
    int tabSize = 8,
    this.lineNumbers = false,
    this.controlBar = false,
    this.textSelectable = false,
    this.zoomInIcon = const Icon(Icons.zoom_in),
    this.zoomOutIcon = const Icon(Icons.zoom_out),
    this.lineWrapIcon = const Icon(Icons.wrap_text),
    this.barIconColor,
    this.minZoom = 0.5,
    this.maxZoom = 3.0,
    this.zoomStep = 0.1,
  })  : source = input.replaceAll('\t', ' ' * tabSize),
        super(key: key);

  static const _rootKey = 'root';
  static const _defaultFontColor = Color(0xff000000);
  static const _defaultBackgroundColor = Color(0xffffffff);
  static const _defaultFontFamily = 'monospace';

  @override
  State<HighlightView> createState() => _HighlightViewState();
}

class _HighlightViewState extends State<HighlightView> {
  double _fontScaleFactor = 1.0;
  bool _isLineWrapEnabled = true;

  List<TextSpan> _convert(List<Node> nodes) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    void traverse(Node node) {
      if (node.value != null) {
        currentSpans.add(node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(text: node.value, style: widget.theme[node.className!]));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans
            .add(TextSpan(children: tmp, style: widget.theme[node.className!]));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          traverse(n);
          if (n == node.children!.last) {
            currentSpans = stack.isEmpty ? spans : stack.removeLast();
          }
        }
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return spans;
  }

  TextPainter _createTextPainter(List<TextSpan> spans, TextStyle textStyle) {
    return TextPainter(
      textScaler: TextScaler.linear(_fontScaleFactor),
      text: TextSpan(style: textStyle, children: spans),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  TextStyle _getTextStyle() {
    var textStyle = TextStyle(
      fontFamily: HighlightView._defaultFontFamily,
      color: widget.theme[HighlightView._rootKey]?.color ??
          HighlightView._defaultFontColor,
    );
    if (widget.textStyle != null) {
      textStyle = textStyle.merge(widget.textStyle);
    }
    return textStyle;
  }

  Color _getBackgroundColor() {
    return widget.theme[HighlightView._rootKey]?.backgroundColor ??
        HighlightView._defaultBackgroundColor;
  }

  List<TextSpan> _buildLineNumbers(List<LineMetrics> lineMetrics) {
    var realLineNumber = 0;
    var lineNumberSpans = <TextSpan>[];
    var prevSoftBreak = false;

    for (var line in lineMetrics) {
      var lineText = (realLineNumber + 1).toString();
      lineText += '\n';
      if (!prevSoftBreak) realLineNumber += 1;

      lineNumberSpans.add(TextSpan(text: !prevSoftBreak ? lineText : '\n'));
      prevSoftBreak = !line.hardBreak;
    }

    // Handle trailing line number
    if (lineNumberSpans.isNotEmpty) {
      lineNumberSpans.removeLast();
      lineNumberSpans.add(TextSpan(text: realLineNumber.toString()));
    }

    return lineNumberSpans;
  }

  Widget _buildControlBar() {
    return Container(
      color: _getBackgroundColor(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            color: widget.barIconColor ?? Colors.grey.shade300,
            disabledColor: Colors.grey,
            tooltip: 'Zoom out',
            icon: widget.zoomOutIcon,
            onPressed: _fontScaleFactor > widget.minZoom
                ? () => setState(() {
                      _fontScaleFactor = (_fontScaleFactor - widget.zoomStep)
                          .clamp(widget.minZoom, widget.maxZoom);
                    })
                : null,
          ),
          IconButton(
            icon: widget.zoomInIcon,
            color: widget.barIconColor ?? Colors.grey.shade300,
            tooltip: 'Zoom in',
            disabledColor: Colors.grey,
            onPressed: _fontScaleFactor < widget.maxZoom
                ? () => setState(() {
                      _fontScaleFactor = (_fontScaleFactor + widget.zoomStep)
                          .clamp(widget.minZoom, widget.maxZoom);
                    })
                : null,
          ),
          IconButton(
            icon: widget.lineWrapIcon,
            color: _isLineWrapEnabled
                ? widget.barIconColor ?? Colors.grey.shade300
                : Colors.orange,
            tooltip: 'Toggle line wrap',
            onPressed: () => setState(() {
              _isLineWrapEnabled = !_isLineWrapEnabled;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(List<TextSpan> spans, TextStyle textStyle) {
    if (widget.textSelectable) {
      return Container(
        color: _getBackgroundColor(),
        padding: widget.padding,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText.rich(
                TextSpan(
                  style: textStyle.copyWith(
                    fontSize: (textStyle.fontSize ?? 14) * _fontScaleFactor,
                  ),
                  children: spans,
                ),
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      );
    } else {
      final painter = _createTextPainter(spans, textStyle);
      painter.layout(
        maxWidth: _isLineWrapEnabled
            ? double.infinity
            : double.infinity, // Let the parent container handle the width
      );

      return Container(
        color: _getBackgroundColor(),
        padding: widget.padding,
        child: Scrollbar(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CustomPaint(
                painter: _CodePainter(painter),
                size: painter.size,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildWithLineNumbers(List<TextSpan> spans, TextStyle textStyle,
      List<LineMetrics> lineMetrics) {
    final lineNumberSpans = _buildLineNumbers(lineMetrics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.controlBar) _buildControlBar(),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: _getBackgroundColor(),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: IntrinsicHeight(
                  child: Container(
                    color: _getBackgroundColor(),
                    child: RichText(
                      textAlign: TextAlign.end,
                      textScaler: TextScaler.linear(_fontScaleFactor),
                      text: TextSpan(
                        style: textStyle.copyWith(
                          color: Colors.grey.shade600,
                          backgroundColor: _getBackgroundColor(),
                        ),
                        children: lineNumberSpans,
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(child: _buildCodeContent(spans, textStyle)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = _getTextStyle();
        final converted = _convert(
          widget.language != null
              ? highlight.parse(widget.source, language: widget.language).nodes!
              : highlight.parse(widget.source, autoDetection: true).nodes!,
        );

        if (widget.lineNumbers) {
          final painter = _createTextPainter(converted, textStyle);
          painter.layout(
            maxWidth: _isLineWrapEnabled
                ? double.infinity
                : constraints.maxWidth - (textStyle.fontSize ?? 14) * 3,
          );
          final lineMetrics = painter.computeLineMetrics();
          if (lineMetrics.isEmpty) {
            return Container(
              color: _getBackgroundColor(),
              padding: widget.padding,
              child: const Text('No content to display'),
            );
          }
          return _buildWithLineNumbers(converted, textStyle, lineMetrics);
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.controlBar) _buildControlBar(),
              Flexible(child: _buildCodeContent(converted, textStyle)),
            ],
          );
        }
      },
    );
  }
}

class _CodePainter extends CustomPainter {
  final TextPainter textPainter;

  const _CodePainter(this.textPainter);

  @override
  void paint(Canvas canvas, Size size) {
    textPainter.paint(canvas, const Offset(4, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _CodePainter ||
        oldDelegate.textPainter != textPainter;
  }
}
