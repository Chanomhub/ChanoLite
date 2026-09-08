import 'package:chanolite/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User & Profile Model Tests', () {
    test('User fromJson, toJson, and copyWith', () {
      final json = {
        'roles': ['user', 'vip'],
        'email': 'user@example.com',
        'username': 'testuser',
        'bio': 'Gamer & Modder',
        'image': 'https://example.com/avatar.jpg',
        'backgroundImage': 'https://example.com/bg.jpg',
        'points': 500,
        'shrtflyApiKey': 'key123',
        'token': 'jwt_token_abc',
        'refreshToken': 'jwt_refresh_xyz',
        'expiresIn': 3600,
        'socialMediaLinks': [
          {'platform': 'twitter', 'url': 'https://twitter.com/test'},
          {'platform': 'discord', 'url': 'https://discord.gg/test'},
        ],
      };

      final user = User.fromJson(json);
      expect(user.roles, ['user', 'vip']);
      expect(user.email, 'user@example.com');
      expect(user.username, 'testuser');
      expect(user.bio, 'Gamer & Modder');
      expect(user.image, 'https://example.com/avatar.jpg');
      expect(user.backgroundImage, 'https://example.com/bg.jpg');
      expect(user.points, 500);
      expect(user.shrtflyApiKey, 'key123');
      expect(user.token, 'jwt_token_abc');
      expect(user.refreshToken, 'jwt_refresh_xyz');
      expect(user.expiresIn, 3600);
      expect(user.socialMediaLinks.length, 2);
      expect(user.socialMediaLinks.first.platform, 'twitter');

      final outJson = user.toJson();
      expect(outJson['email'], 'user@example.com');
      expect(outJson['points'], 500);
      expect(outJson['token'], 'jwt_token_abc');

      final updatedUser = user.copyWith(
        points: 600,
        token: 'new_token',
      );
      expect(updatedUser.points, 600);
      expect(updatedUser.token, 'new_token');
      expect(updatedUser.email, 'user@example.com');
    });

    test('User handles string points and missing fields gracefully', () {
      final json = {
        'email': 'minimal@example.com',
        'username': 'minimal',
        'points': '250',
        'token': 'token123',
      };
      final user = User.fromJson(json);
      expect(user.points, 250);
      expect(user.roles, isEmpty);
      expect(user.socialMediaLinks, isEmpty);
    });

    test('Profile and Responses fromJson', () {
      final profileJson = {
        'username': 'creator1',
        'bio': 'Game Creator',
        'image': 'https://example.com/pic.png',
        'backgroundImage': null,
        'following': true,
        'socialMediaLinks': [
          {'platform': 'youtube', 'url': 'https://youtube.com/c1'}
        ],
      };

      final profile = Profile.fromJson(profileJson);
      expect(profile.username, 'creator1');
      expect(profile.following, isTrue);
      expect(profile.socialMediaLinks.length, 1);

      final userResponse = UserResponse.fromJson({
        'user': {
          'roles': ['user'],
          'email': 'a@b.com',
          'username': 'ab',
          'points': 0,
          'token': 't',
          'socialMediaLinks': [],
        }
      });
      expect(userResponse.user.username, 'ab');

      final profileResponse = ProfileResponse.fromJson({
        'profile': profileJson,
      });
      expect(profileResponse.profile.username, 'creator1');
    });
  });
}
