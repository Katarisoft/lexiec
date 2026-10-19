import '../models/comment.dart';
import '../services/community_service.dart';

class CommunityRepository {
  CommunityRepository(this._service);

  final CommunityService _service;

  Future<CommentPage> comments(int topicId, {int page = 1}) =>
      _service.list(topicId, page: page);

  Future<Comment> publish(int topicId, String text) =>
      _service.create(topicId, text.trim());

  Future<Comment> edit(int commentId, String text) =>
      _service.update(commentId, text.trim());

  Future<void> remove(int commentId) => _service.delete(commentId);
}
