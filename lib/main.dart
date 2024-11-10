import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  Future<List<dynamic>> fetchNews() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/news'));

    if (response.statusCode == 200) {
      List<dynamic> newsList = json.decode(response.body);

      // 카테고리별로 구분자를 포함한 리스트 준비
      List<dynamic> organizedNews = [];
      String? currentCategory;

      for (var news in newsList) {
        if (news['category'] != currentCategory) {
          // 새로운 카테고리 구분자 추가
          currentCategory = news['category'];
          organizedNews.add({
            'type': 'category',
            'category': currentCategory,
          });
        }
        // 뉴스 카드 추가
        organizedNews.add({
          'type': 'news',
          'data': news,
        });
      }

      return organizedNews;
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Summary'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load news: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No news available.'));
          } else {
            final organizedNews = snapshot.data!;

            return ListView.builder(
              itemCount: organizedNews.length,
              itemBuilder: (context, index) {
                final item = organizedNews[index];

                // 카테고리 구분자 표시
                if (item['type'] == 'category') {
                  return Container(
                    key: ValueKey("category-${item['category']}"),
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, color: Colors.white),
                        SizedBox(width: 10.0),
                        Text(
                          item['category'],
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 뉴스 카드 표시
                final news = item['data'];
                return Card(
                  key: ValueKey("news-${news['title']}"),
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news['title'],
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text('요약 (한국어): ${news['translated_summary_ko']}'),
                        SizedBox(height: 4.0),
                        Text('요약 (일본어): ${news['translated_summary_jp']}'),
                        SizedBox(height: 4.0),
                        Text('영어 요약 원문: ${news['summary_text']}'),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () => _launchURL(news['link']),
                          child: Text(
                            '원문 링크: ${news['link']}',
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}