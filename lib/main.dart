import 'dart:io';

import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  runApp(
    DevicePreview(
      builder: (context) => MyApp(),
      enabled: !Platform.isAndroid,
    ),
  );
}

class FontListItem extends StatefulWidget {
  final int index;
  final String fontName;
  final bool supportsClipboard;
  const FontListItem({
    required this.fontName,
    required this.index,
    required this.supportsClipboard,
    super.key,
  });
  @override
  State<StatefulWidget> createState() => _FontListItemState();
}

class MainScreen extends StatelessWidget {
  final fontList = GoogleFonts.asMap().keys.toList();

  final clipboard = SystemClipboard.instance;
  MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supportsClipboard = clipboard != null;

    return ListView.builder(
      cacheExtent: 20,
      // separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) => FontListItem(
        fontName: fontList[index],
        index: index,
        supportsClipboard: supportsClipboard,
      ),
      itemCount: fontList.length,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello World App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hello World App'),
        ),
        body: MainScreen(),
      ),
    );
  }
}

class _FontListItemState extends State<FontListItem> {
  late Future<TextStyle> _fontLoader;
  @override
  void initState() {
    super.initState();
    _fontLoader = _loadFont();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fontLoader,
      builder: (context, snapshot) {
        final style = snapshot.data;
        return ListTile(
          subtitle: Text(widget.fontName),
          trailing: widget.supportsClipboard
              ? IconButton(
                  onPressed: () => _writeTextOnClipboard(widget.fontName),
                  icon: Icon(Icons.copy),
                )
              : null,
          enableFeedback: true,
          title: Text('Hello + World', style: style),
          leading: CircleAvatar(
            child: Text(widget.index.toString()),
          ),
        );
      },
    );
  }

  Future<void> _writeTextOnClipboard(String text) async {
    // copy [text] to the clipboard
    final item = DataWriterItem()..add(Formats.plainText(text));
    var isCopied = true;

    try {
      await SystemClipboard.instance?.write([item]);
    } catch (e) {
      // failed to copy
      isCopied = false;
    }

    // show banner with copied font name
    if (context.mounted) {
      // clear prev before new
      ScaffoldMessenger.of(context).clearMaterialBanners();
      // new
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          elevation: 4,
          content: Text(
            isCopied ? 'Copied: $text' : 'Failed to copy!',
            style: !isCopied
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearMaterialBanners();
                }
              },
              icon: Icon(Icons.close),
            ),
          ],
        ),
      );
      // auto clear after n sec
      Future.delayed(
        Duration(seconds: /* n = */ 2),
        () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).clearMaterialBanners();
          }
        },
      );
    }
  }

  Future<TextStyle> _loadFont() async {
    await GoogleFonts.pendingFonts([TextStyle(fontFamily: widget.fontName)]);
    return GoogleFonts.getFont(widget.fontName);
  }
}
