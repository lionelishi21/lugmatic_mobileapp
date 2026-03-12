class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String contentType;
  final String contentId;
  final int likes;
  final bool isLiked;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.contentType,
    required this.contentId,
    this.likes = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String name = 'Unknown';
    String avatar = '';
    String uId = '';

    if (user is Map) {
      name = user['name'] ?? 'Unknown';
      avatar = user['image'] ?? user['avatar'] ?? '';
      uId = user['_id'] ?? user['id'] ?? '';
    } else {
      uId = user?.toString() ?? '';
    }

    return CommentModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: uId,
      userName: name,
      userAvatar: avatar,
      content: json['content'] ?? '',
      contentType: json['contentType'] ?? '',
      contentId: json['contentId'] ?? '',
      likes: json['likesCount'] ?? json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'contentType': contentType,
      'contentId': contentId,
      'likes': likes,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
