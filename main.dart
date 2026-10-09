import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FortuneApp());
}

class FortuneApp extends StatelessWidget {
  const FortuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '소원 카드 뽑기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 소원 목록 (4개)
  final List<String> wishes = ['건강운', '재물운', '연애운', '기타운'];
  int selectedWishIndex = 0;

  // 소원 입력 컨트롤러
  final TextEditingController _wishTextController = TextEditingController();

  // 카드 상태 관리 변수
  List<bool> isFlipped = List.generate(15, (_) => false);
  List<double> cardScales = List.generate(15, (_) => 1.0); // 각 카드의 확대 스케일
  List<String> assignedImages = []; // 각 카드에 배치될 무작위 이미지 파일명
  int selectedCount = 0;
  int? activeAnimatingIndex; // 현재 확대 애니메이션 중인 카드 인덱스

  @override
  void initState() {
    super.initState();
    _initializeCardImages();
  }

  // pic_01.jpg ~ pic_21.jpg 중 15개를 무작위 추출하여 배치
  void _initializeCardImages() {
    List<String> allImages = List.generate(
      21,
      (index) {
        String numStr = (index + 1).toString().padLeft(2, '0');
        return 'assets/images/pic_$numStr.jpg';
      },
    );
    allImages.shuffle(Random());
    assignedImages = allImages.sublist(0, 15);
  }

  // 카드 클릭 처리
  void _onCardTap(int index) async {
    // 이미 뒤집힌 카드거나 5장을 다 선택했으면 리턴
    if (isFlipped[index]) return;

    if (selectedCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드는 최대 5장까지 골라주세요.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 1. 카드 뒤집기 및 1.5배 확대
    setState(() {
      isFlipped[index] = true;
      cardScales[index] = 1.5;
      activeAnimatingIndex = index;
      selectedCount++;
    });

    // 2. 잠시 인식할 시간을 둔 뒤(1초) 원래 크기로 원복
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        cardScales[index] = 1.0;
        if (activeAnimatingIndex == index) {
          activeAnimatingIndex = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _wishTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '소원 카드 뽑기',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 소원 선택 버튼 (4개)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: wishes.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedWishIndex == index;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.indigo : Colors.white,
                      foregroundColor:
                          isSelected ? Colors.white : Colors.black87,
                      side: const BorderSide(color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        selectedWishIndex = index;
                      });
                    },
                    child: Text(
                      wishes[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),

              // 선택된 운세 안내
              Text(
                '선택된 운세 : ${wishes[selectedWishIndex]}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // 안내 문구
              const Text(
                '이루어지길 원하는 소원을 아래에 짧게 적고 카드를 5장 고르세요',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // 소원 입력 박스
              TextField(
                controller: _wishTextController,
                decoration: InputDecoration(
                  hintText: '여기에 소원을 적어주세요...',
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Colors.black87),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide:
                        const BorderSide(color: Colors.indigo, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 15장 카드 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none, // 확대 시 카드 잘림 방지
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemCount: 15,
                itemBuilder: (context, index) {
                  return CardWidget(
                    isFlipped: isFlipped[index],
                    imagePath: assignedImages[index],
                    scale: cardScales[index],
                    isAnimating: activeAnimatingIndex == index,
                    onTap: () => _onCardTap(index),
                  );
                },
              ),
              const SizedBox(height: 25),

              // 카드 5장이 모두 선택되었을 때 나타나는 '카드 분석하기' 붉은색 버튼
              if (selectedCount == 5)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // 붉은색 바탕
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('카드를 분석 중입니다...'),
                        ),
                      );
                    },
                    child: const Text(
                      '카드 분석하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 애니메이션이 적용된 카드 위젯
class CardWidget extends StatelessWidget {
  final bool isFlipped;
  final String imagePath;
  final double scale;
  final bool isAnimating;
  final VoidCallback onTap;

  const CardWidget({
    super.key,
    required this.isFlipped,
    required this.imagePath,
    required this.scale,
    required this.isAnimating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 300), // 확대/축소 속도
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isFlipped ? Colors.indigo : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isAnimating ? 0.3 : 0.12),
                blurRadius: isAnimating ? 8 : 3,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: isFlipped
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/card_back1.jpg',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }
}