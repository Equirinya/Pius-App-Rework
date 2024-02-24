import 'dart:convert';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:PiusApp/connection.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart' as DOM;
import 'package:url_launcher/url_launcher.dart';

import '../database.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, required this.isar});

  final Isar isar;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool loading = false;
  bool initialized = false;
  late SharedPreferences prefs;

  @override
  initState() {
    super.initState();
    asyncInit();
  }

  void asyncInit() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('newsUpdateStart') ?? true) {
      ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
      if ((!(prefs.getBool("vertretungUpdateWifi") ?? false) || connectivityResult == ConnectivityResult.wifi)) {
        updateNews();
      }
    }
    setState(() {
      initialized = true;
    });
  }

  //alernative api: https://pius-gymnasium.de/wp-json/wp/v2/posts?per_page=25
  Future<void> updateNews([bool laodAll = false]) async {
    if (loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated bereits...'),
        ),
      );
      return;
    }
    setState(() {
      loading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String newsUrl = prefs.getString('website_news_termine') ?? 'https://www.pius-gymnasium.de/wp-json/wp/v2/posts';
    Uri uri = Uri.parse(newsUrl);
    Map<String, String> queryParameters = {};

    int numberOfNews = widget.isar.news.where().countSync();

    // if(loadOlder) {
    //   queryParameters.addAll({
    //     'per_page': '25',
    //     'page': (numberOfNews / 25).ceil().toString()
    //   });
    // }
    if (laodAll || numberOfNews == 0) {
      queryParameters.addAll({'per_page': '100'});
    } else {
      DateTime lastUpdate = DateTime.parse(prefs.getString('lastNewsUpdate') ?? DateTime.now().toIso8601String());
      queryParameters.addAll({'modified_after': lastUpdate.toIso8601String(), 'per_page': '50'});
    }

    Uri uriWithQuery = uri.replace(queryParameters: queryParameters);
    http.Response response = await http.get(uriWithQuery);

    if (response.statusCode != 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der News: ${response.statusCode}'),
          ),
        );
      }
      setState(() {
        loading = false;
      });
      return;
    }

    dynamic newsJson = jsonDecode(response.body);
    if (newsJson is List) {
      List<News> newNews = newsJson.map((json) {
        dynamic image = json["featured_image_src_large"];
        if (image is List) {
          image = image[0];
        } else {
          image = null;
        }
        String? teaser = parseFragment(json['excerpt']['rendered']).text;
        if (teaser?.isEmpty ?? false) {
          teaser = null;
        }
        String title = parseFragment(json['title']['rendered']).text ?? "";
        return News()
          ..id = json['id']
          ..title = title
          ..teaser = teaser
          ..content = json['content']['rendered']
          ..imageUrl = image
          ..created = DateTime.parse(json['date']);
      }).toList();
      await widget.isar.writeTxn(() async {
        await widget.isar.news.putAll(newNews);
      });
      prefs.setString('lastNewsUpdate', DateTime.now().toIso8601String());
    } else {
      if (kDebugMode) {
        print('News JSON is not a list');
        print(newsJson);
      }
      if (Map.from(newsJson).containsKey('code')) {
        // if(Map.from(newsJson)['code'] == 'rest_post_invalid_page_number') {
        //   //TODO
        //   return;
        // }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Laden der News: ${Map.from(newsJson)['message']}'),
            ),
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der News: ${response.statusCode}'),
          ),
        );
      }
    }
    setState(() {
      loading = false;
    });
  }

  // Future<void> updateNews() async {
  //   if (loading) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Updated bereits...'),
  //       ),
  //     );
  //     return;
  //   }
  //   setState(() {
  //     loading = true;
  //   });
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String newsUrl = prefs.getString('website_news_termine') ?? 'https://www.pius-gymnasium.de/blog';
  //   http.Response response = await http.get(Uri.parse(newsUrl));
  //   if (response.statusCode != 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Fehler beim Laden der News: ${response.statusCode}'),
  //       ),
  //     );
  //     setState(() {
  //       loading = false;
  //     });
  //     return;
  //   }
  //   DOM.Document document = parse(response.body);
  //   List<DOM.Element> newsElements = document.querySelectorAll('article');
  //
  //   List<News> newNews = newsElements.map((article) {
  //     DOM.Element? titleElement = article.querySelector('.entry-title a');
  //     DOM.Element? previewTextElement = article.querySelector('.entry-summary p');
  //     DOM.Element? previewImageElement = article.querySelector('.post-thumbnail-inner img');
  //     DOM.Element? contentLink = article.querySelector('.entry-actions a');
  //
  //     String title = titleElement?.text ?? '';
  //     String previewText = previewTextElement?.text ?? '';
  //     String previewImageUrl = previewImageElement?.attributes['src'] ?? '';
  //     String contentLinkUrl = contentLink?.attributes['href'] ?? '';
  //     return News()
  //       ..title = title
  //       ..teaser = previewText
  //       ..contentUrl = contentLinkUrl
  //       ..imageUrl = previewImageUrl;
  //   }).toList();
  //
  //   List<News> oldNews = await widget.isar.news.where().findAll();
  //   for (News news in newNews) {
  //     if (oldNews.any((element) => element.title == news.title)) {
  //       News oldNew = oldNews.firstWhere((element) => element.title == news.title && element.contentUrl == news.contentUrl);
  //       news.contentLastUpdated = oldNew.contentLastUpdated;
  //       news.htmlContent = oldNew.htmlContent;
  //     }
  //   }
  //   await widget.isar.writeTxn(() async {
  //     await widget.isar.news.clear();
  //     await widget.isar.news.putAll(newNews);
  //   });
  //   setState(() {
  //     loading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const CupertinoActivityIndicator();
    }
    List<News> news = widget.isar.news.where().sortByCreatedDesc().findAllSync();
    String? stand = prefs.getString("lastNewsUpdate");
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: AppBar(
          title: Text('News ${stand != null ? "(${DateFormat('dd.MM.yy HH:mm').format(DateTime.parse(stand))})" : ""}'),
          actions: [
            IconButton(
              icon: const Icon(Ionicons.refresh),
              onPressed: () => updateNews(true),
            ),
          ],
        ),
        body: Column(
          children: [
            if (loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: news.length,
                itemBuilder: (context, index) {
                  Widget tile = Padding(
                    padding: news[index].teaser != null ? EdgeInsets.zero : const EdgeInsets.only(top: 10.0, bottom: 18),
                    child: ListTile(
                        title: Text(news[index].title,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: SizedBox(
                            height: double.infinity,
                            width: size.width / 4,
                            child: news[index].imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: news[index].imageUrl!,
                                    placeholder: (context, url) => const CupertinoActivityIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        subtitle: news[index].teaser != null
                            ? Text(
                                news[index].teaser!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        isThreeLine: news[index].teaser != null,
                        onTap: () {
                          Navigator.of(context).push(Platform.isIOS ? CupertinoPageRoute(builder: (context) {
                            return CupertinoPageScaffold(
                              navigationBar: const CupertinoNavigationBar(
                                previousPageTitle: "News",

                              ),
                                child: SafeArea(child: buildNewsDetailPage(news, index, context)),
                            );
                          },
                          ) : MaterialPageRoute(
                            builder: (context) {
                              return Scaffold(
                                body: buildNewsDetailPage(news, index, context),
                              );
                            },
                          ));
                        }),
                  );

                  if (index == 0 || news[index].created.day != news[index - 1].created.day || news[index].created.month != news[index - 1].created.month) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 2),
                          child: Text(
                            DateFormat('dd.MM.yy').format(news[index].created),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        tile
                      ],
                    );
                  } else {
                    return tile;
                  }
                },
              ),
            )
          ],
        ));
  }

  Widget buildNewsDetailPage(List<News> news, int index, BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news[index].imageUrl != null)
            GestureDetector(
              onTap: () {
                showImageDetailDialog(context, news[index].imageUrl!);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: size.height / 2, minWidth: size.width),
                child: ClipRect(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(news[index].imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: CachedNetworkImage(
                        width: size.width,
                        fit: BoxFit.contain,
                        imageUrl: news[index].imageUrl!,
                        placeholder: (context, url) => const CupertinoActivityIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: news[index].imageUrl != null ? 8.0 : 24),
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 16),
            child: Text(
              DateFormat('dd.MM.yy HH:mm').format(news[index].created),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              news[index].title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 128.0, top: 16),
            child: HtmlWidget(
              news[index].content,
              onTapUrl: (url) {
                launchUrl(Uri.parse(url));
                return true;
              },
              textStyle: Theme.of(context).textTheme.bodyLarge,
              onTapImage: (p0) {
                showImageDetailDialog(context, p0.sources.first.url);
              },
            ),
          ),
        ],
      ),
    );
  }

  void showImageDetailDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        bool isClosing = false;
        return InteractiveViewer(
          maxScale: 4,
          child: TapRegion(
            onTapOutside: (tap) {
              if (isClosing) {
                return;
              }
              isClosing = true;
              Navigator.of(context).pop();
            },
            child: Center(
              child: Container(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
