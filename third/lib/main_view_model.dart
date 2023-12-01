import 'package:firebase_auth/firebase_auth.dart';
import 'package:third/firebase_auth_remote_data_source.dart';
import 'package:third/social_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainViewModel {
  final _firebaseAuthDataSource = FirebaseAuthRemoteDataSource();
  final SocialLogin _socialLogin;
  bool isLogined = false;
  kakao.User? user;

  MainViewModel(this._socialLogin);

  Future login() async {
    isLogined = await _socialLogin.login();
    if (isLogined) {
      user = await kakao.UserApi.instance.me();

      final token = await _firebaseAuthDataSource.createCustomToken({
        'uid': user!.id.toString(),
        'displayName': user!.kakaoAccount!.profile!.nickname,
        'email': user!.kakaoAccount!.email!,
        'photoURL': user!.kakaoAccount!.profile!.profileImageUrl!,
      });

      await FirebaseAuth.instance.signInWithCustomToken(token);

      // Django 백엔드로 사용자 정보를 전송
      await sendUserDataToDjango();
    }
  }

  Future logout() async {
    await _socialLogin.logout();
    await FirebaseAuth.instance.signOut();
    isLogined = false;
    user = null;
  }
Future<void> sendUserDataToDjango() async {
  if (user != null && user!.kakaoAccount != null && user!.kakaoAccount!.profile != null) {
    String nickname = user!.kakaoAccount!.profile!.nickname ?? 'Unknown'; // 'Unknown'이라는 기본값을 제공
    String email = user!.kakaoAccount!.email ?? ''; // 이메일이 null일 경우 빈 문자열을 사용

    var response = await http.post(
      Uri.parse('http://ec2-13-209-244-84.ap-northeast-2.compute.amazonaws.com/users/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'name': nickname,
        // 여기에 필요한 다른 사용자 필드를 추가할 수 있습니다.
      }),
    );

    if (response.statusCode == 200) {
      print("User data sent successfully");
    } else {
      print("Failed to send user data");
    }
  }
}
}