import 'dart:async';
import 'package:chopper/chopper.dart';

part 'user_api_service.chopper.dart';

@ChopperApi(baseUrl: '')
abstract class UserApiService extends ChopperService {
  static UserApiService create([ChopperClient? client]) =>
      _$UserApiService(client);

  // User and Authentication

  @Get(path: '/user')
  Future<Response> getCurrentUser();

  @Put(path: '/user')
  Future<Response> updateCurrentUser(@Body() Map<String, dynamic> body);

  @Post(path: '/user/tokens')
  Future<Response> createPermanentToken(@Body() Map<String, dynamic> body);

  @Get(path: '/user/tokens')
  Future<Response> listTokens();

  @Delete(path: '/user/tokens/{id}')
  Future<Response> revokeToken(@Path('id') String id);

  @Post(path: '/users')
  Future<Response> registerUser(@Body() Map<String, dynamic> body);

  @Post(path: '/users/login')
  Future<Response> login(@Body() Map<String, dynamic> body);

  @Post(path: '/users/sso')
  Future<Response> loginWithSSO(@Body() Map<String, dynamic> body);

  // Profile

  @Get(path: '/profiles/{username}')
  Future<Response> getProfileByUsername(@Path('username') String username);

  @Post(path: '/profiles/{username}/follow')
  Future<Response> followUserByUsername(@Path('username') String username);

  @Delete(path: '/profiles/{username}/follow')
  Future<Response> unfollowUserByUsername(@Path('username') String username);
}
