import 'package:flutter/material.dart';
import 'package:third/kakao_login.dart';
import 'package:third/main_view_model.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'survey_screen.dart';  // SurveyScreen 클래스를 포함하는 파일 임포트

void main() async {
  kakao.KakaoSdk.init(nativeAppKey: '008e71896ceeac90f9ca92aabd609f32');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'EZPill'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final viewModel = MainViewModel(KakaoLogin());

  void showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('프로필 정보'),
        content: Text('이름: ${viewModel.user?.kakaoAccount?.profile?.nickname}\n'
                      '이메일: ${viewModel.user?.kakaoAccount?.email}'),
        actions: <Widget>[
          TextButton(
            child: Text('닫기'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () async {
        await viewModel.login();
        setState(() {});
      },
      child: const Text('Login'),
    );
  }

  Widget _buildUserButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (viewModel.user?.kakaoAccount?.profile?.profileImageUrl != null)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(viewModel.user!.kakaoAccount!.profile!.profileImageUrl!),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurveyScreen(kakaoUid: viewModel.user?.id.toString() ?? ''),
            ),
          );
        },
        child: const Text('시작하기'),
      ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            await viewModel.logout();
            setState(() {});
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: viewModel.user == null ? null : showProfileDialog,
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildLoginButton();
            }
            return _buildUserButtons();
          },
        ),
      ),
    );
  }
}
