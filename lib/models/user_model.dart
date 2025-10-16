
class User {
  final List<String> roles;
  final String email;
  final String username;
  final String? bio;
  final String? image;
  final String? backgroundImage;
  final int points;
  final String? shrtflyApiKey;
  final String token;
  final List<SocialMediaLink> socialMediaLinks;

  User({
    required this.roles,
    required this.email,
    required this.username,
    this.bio,
    this.image,
    this.backgroundImage,
    required this.points,
    this.shrtflyApiKey,
    required this.token,
    required this.socialMediaLinks,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      roles: List<String>.from(json['roles']),
      email: json['email'],
      username: json['username'],
      bio: json['bio'],
      image: json['image'],
      backgroundImage: json['backgroundImage'],
      points: json['points'],
      shrtflyApiKey: json['shrtflyApiKey'],
      token: json['token'],
      socialMediaLinks: (json['socialMediaLinks'] as List? ?? [])
          .map((e) => SocialMediaLink.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles,
      'email': email,
      'username': username,
      'bio': bio,
      'image': image,
      'backgroundImage': backgroundImage,
      'points': points,
      'shrtflyApiKey': shrtflyApiKey,
      'token': token,
      'socialMediaLinks': socialMediaLinks.map((e) => e.toJson()).toList(),
    };
  }

  User copyWith({
    List<String>? roles,
    String? email,
    String? username,
    String? bio,
    String? image,
    String? backgroundImage,
    int? points,
    String? shrtflyApiKey,
    String? token,
    List<SocialMediaLink>? socialMediaLinks,
  }) {
    return User(
      roles: roles ?? this.roles,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      image: image ?? this.image,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      points: points ?? this.points,
      shrtflyApiKey: shrtflyApiKey ?? this.shrtflyApiKey,
      token: token ?? this.token,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
    );
  }
}

class Profile {
  final String username;
  final dynamic bio;
  final dynamic image;
  final dynamic backgroundImage;
  final bool following;
  final List<SocialMediaLink> socialMediaLinks;

  Profile({
    required this.username,
    this.bio,
    this.image,
    this.backgroundImage,
    required this.following,
    required this.socialMediaLinks,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      username: json['username'],
      bio: json['bio'],
      image: json['image'],
      backgroundImage: json['backgroundImage'],
      following: json['following'],
      socialMediaLinks: (json['socialMediaLinks'] as List? ?? [])
          .map((e) => SocialMediaLink.fromJson(e))
          .toList(),
    );
  }
}

class SocialMediaLink {
  final String platform;
  final String url;

  SocialMediaLink({required this.platform, required this.url});

  factory SocialMediaLink.fromJson(Map<String, dynamic> json) {
    return SocialMediaLink(
      platform: json['platform'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'url': url,
    };
  }
}

class UserResponse {
  final User user;

  UserResponse({required this.user});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(user: User.fromJson(json['user']));
  }
}

class ProfileResponse {
  final Profile profile;

  ProfileResponse({required this.profile});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(profile: Profile.fromJson(json['profile']));
  }
}
