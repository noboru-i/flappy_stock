class NewsData {
  const NewsData({
    required this.date,
    required this.title,
    required this.summary,
    required this.url,
  });

  final String date;
  final String title;
  final String summary;
  final String url;

  factory NewsData.fromJson(Map<String, dynamic> json) => NewsData(
    date: json['date'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    url: json['url'] as String,
  );
}
