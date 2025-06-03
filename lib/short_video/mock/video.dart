import 'dart:io';

Socket? socket;
var videoList = [
  'test-video-10.MP4',
  'test-video-6.mp4',
  'test-video-9.MP4',
  'test-video-8.MP4',
  'test-video-7.MP4',
  'test-video-1.mp4',
  'test-video-2.mp4',
  'test-video-3.mp4',
  'test-video-4.mp4',
];

class UserVideo {
  final String id;
  final String url;
  final String cover;
  final String title;
  final String author;
  final int likeCount;
  final int commentCount;
  final String? desc;

  UserVideo({
    required this.id,
    required this.url,
    required this.cover,
    required this.title,
    required this.author,
    required this.likeCount,
    required this.commentCount,
    this.desc,
  });

  static List<UserVideo> fetchVideo() {
    return videoList.asMap().entries.map((entry) {
      final index = entry.key;
      final videoName = entry.value;
      return UserVideo(
        id: '${index + 1}',
        url: 'https://static.ybhospital.net/$videoName',
        cover: '',
        title: videoName,
        author: '测试用户',
        likeCount: 1000 + index * 100,
        commentCount: 100 + index * 10,
        desc: videoName,
      );
    }).toList();
  }

  @override
  String toString() {
    return 'image:$cover\nvideo:$url';
  }
}
