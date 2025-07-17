import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:url_launcher/url_launcher.dart';

import 'example_map.dart';

void main() => runApp(MyApp());

final title = 'Flutter Highlight Gallery';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String language = 'auto';
  String theme = 'a11y-dark';
  bool showLineNumbers = false;
  bool showControlBar = false;
  bool textSelectable = false;

  Widget _buildMenuContent(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: <Widget>[
        Text(text, style: TextStyle(fontSize: 16)),
        Icon(Icons.arrow_drop_down)
      ]),
    );
  }

  Widget _buildToggleButton(String label, bool value, VoidCallback onToggle) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          PopupMenuButton(
            child: _buildMenuContent(language),
            itemBuilder: (context) {
              return exampleMap.keys.map((key) {
                return CheckedPopupMenuItem(
                  value: key,
                  child: Text(key),
                  checked: language == key,
                );
              }).toList();
            },
            onSelected: (selected) {
              if (selected != null) {
                setState(() {
                  language = selected as String;
                });
              }
            },
          ),
          PopupMenuButton<String>(
            child: _buildMenuContent(theme),
            itemBuilder: (context) {
              return themeMap.keys.map((key) {
                return CheckedPopupMenuItem(
                  value: key,
                  child: Text(key),
                  checked: theme == key,
                );
              }).toList();
            },
            onSelected: (selected) {
              setState(() {
                theme = selected!;
              });
            },
          ),
          _buildToggleButton(
            'Line Numbers',
            showLineNumbers,
            () => setState(() => showLineNumbers = !showLineNumbers),
          ),
          _buildToggleButton(
            'Control Bar',
            showControlBar,
            () => setState(() => showControlBar = !showControlBar),
          ),
          _buildToggleButton(
            'Text Selectable',
            textSelectable,
            () => setState(() => textSelectable = !textSelectable),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Source Code',
            onPressed: () {
              launch('https://github.com/pd4d10/highlight');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Container(
          child: HighlightView(
            exampleMap[language] ?? '',
            language: language == 'auto' ? null : language,
            theme: themeMap[theme] ?? {},
            lineNumbers: showLineNumbers,
            controlBar: showControlBar,
            textSelectable: textSelectable,
            padding: EdgeInsets.all(12),
            textStyle: TextStyle(
              fontFamily:
                  'SFMono-Regular,Consolas,Liberation Mono,Menlo,monospace',
            ),
          ),
        ),
      ),
    );
  }
}
