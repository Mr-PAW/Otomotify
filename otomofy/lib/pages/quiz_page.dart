import 'package:flutter/material.dart';
import 'dart:async';
import '../models/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool isStarted = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswer;
  Timer? _timer;
  int timeLeft = 10;
  bool isFinished = false;
  List<int?> answers = List.filled(10, null);
  int? lastScore;
  String? lastGelar;
  bool showLastResult = false;

  void _startQuiz() {
    setState(() {
      isStarted = true;
      score = 0;
      currentQuestionIndex = 0;
      selectedAnswer = null;
      timeLeft = 10;
      answers = List.filled(10, null);
      isFinished = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    _timer?.cancel();

    if (currentQuestionIndex < 9) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        timeLeft = 10;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();

    int finalScore = 0;
    for (int i = 0; i < QuizData.questions.length; i++) {
      if (answers[i] == QuizData.questions[i].correctAnswer) {
        finalScore++;
      }
    }

    setState(() {
      score = finalScore;
      isFinished = true;
    });
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswer = index;
      answers[currentQuestionIndex] = index;
    });
  }

  String _getGelar() {
    if (score == 10) return '🏆 Raja Otomotif';
    if (score == 9) return '⭐ Sepuh Otomotif';
    if (score == 8) return '🔥 Gila Otomotif';
    if (score == 7) return '📚 Berpengetahuan Otomotif';
    if (score == 6) return '👍 Lumayan Lah';
    if (score == 5) return '😅 Cupu Otomotif';
    return '💀 Pekok Tenan Ndes';
  }

  void _goToGelarPage() {
    final savedScore = score;
    final savedGelar = _getGelar();

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (c) => GelarPage(score: savedScore, gelar: savedGelar),
          ),
        )
        .then((_) {
          if (!mounted) return;
          setState(() {
            lastScore = savedScore;
            lastGelar = savedGelar;
            showLastResult = true;

            // Reset for next attempt
            score = 0;
            currentQuestionIndex = 0;
            selectedAnswer = null;
            timeLeft = 10;
            answers = List.filled(10, null);
            isStarted = false;
            isFinished = false;
          });
        });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isStarted) return _buildStartScreen();
    if (isFinished) return _buildResultScreen();
    return _buildQuizScreen();
  }

  // ─── START SCREEN ────────────────────────────────────────────
  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        title: const Text('Kuis Otomotif'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Kuis Otomotif',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                '10 Soal • 10 Detik Per Soal\nPilih Jawaban Terbaik Anda!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3C72).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E3C72).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Informasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3C72),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jawaban benar akan ditampilkan setelah mengerjakan semua soal. '
                      'Waktu tidak bisa dihentikan, jadi siapkan diri Anda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Last result card
              if (showLastResult && lastScore != null && lastGelar != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Terakhir',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastGelar!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Skor: ${lastScore ?? 0} / 10',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Mulai Quiz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── QUIZ SCREEN ──────────────────────────────────────────────
  Widget _buildQuizScreen() {
    final question = QuizData.questions[currentQuestionIndex];
    final options = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        title: Text('Soal ${currentQuestionIndex + 1} / 10'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: timeLeft <= 3
                    ? Colors.red.shade50
                    : const Color(0xFF1E3C72).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: timeLeft <= 3
                      ? Colors.red
                      : const Color(0xFF1E3C72).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Text(
                'Waktu: ${timeLeft}s',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: timeLeft <= 3 ? Colors.red : const Color(0xFF1E3C72),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Question
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView.separated(
                itemCount: 4,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  bool isSelected = selectedAnswer == index;

                  return GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E3C72).withOpacity(0.1)
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1E3C72)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF1E3C72)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1E3C72)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                options[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFF1E3C72)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Next / Selesai Button
            ElevatedButton(
              onPressed: selectedAnswer != null ? _nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                currentQuestionIndex == 9 ? 'Selesai' : 'Lanjut →',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── RESULT SCREEN ────────────────────────────────────────────
  Widget _buildResultScreen() {
    final percentage = (score / 10) * 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        title: const Text('Hasil Quiz'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on result screen
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Score Circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3C72).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score/10',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status
            Text(
              score >= 7
                  ? 'Luar Biasa! 🎉'
                  : score >= 5
                  ? 'Bagus! 👍'
                  : 'Coba Lagi! 💪',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getGelar(),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Review Answers
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Jawaban:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(10, (index) {
                    final question = QuizData.questions[index];
                    final userAnswer = answers[index];
                    final isSkipped = userAnswer == null;
                    final isCorrect =
                        !isSkipped && userAnswer == question.correctAnswer;
                    final optionLabels = ['A', 'B', 'C', 'D'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSkipped
                                  ? Colors.grey.shade200
                                  : isCorrect
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              border: Border.all(
                                color: isSkipped
                                    ? Colors.grey
                                    : isCorrect
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                isSkipped ? '-' : (isCorrect ? '✓' : '✗'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSkipped
                                      ? Colors.grey
                                      : isCorrect
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. ${question.question}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (isSkipped)
                                  Text(
                                    'Tidak dijawab (waktu habis)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  Text(
                                    'Jawab: ${optionLabels[userAnswer!]} - ${question.options[userAnswer]}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCorrect
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (!isCorrect)
                                  Text(
                                    'Benar: ${optionLabels[question.correctAnswer]} - ${question.options[question.correctAnswer]}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Lihat Gelar button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToGelarPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Lihat Gelar Saya 🏅',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── GELAR PAGE ───────────────────────────────────────────────────────────────
class GelarPage extends StatelessWidget {
  final int score;
  final String gelar;

  const GelarPage({super.key, required this.score, required this.gelar});

  Color _getGelarColor() {
    if (score >= 9) return const Color(0xFFFFD700); // gold
    if (score >= 7) return const Color(0xFF1E3C72); // dark blue
    if (score >= 5) return Colors.green;
    return Colors.redAccent;
  }

  IconData _getGelarIcon() {
    if (score == 10) return Icons.workspace_premium;
    if (score >= 8) return Icons.emoji_events;
    if (score >= 6) return Icons.thumb_up_alt;
    return Icons.sentiment_dissatisfied;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGelarColor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        title: const Text('Gelar Anda'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color, width: 3),
                ),
                child: Icon(_getGelarIcon(), size: 60, color: color),
              ),
              const SizedBox(height: 32),

              // Gelar text
              Text(
                gelar,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),

              // Score
              Text(
                'Skor Anda: $score / 10',
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 10,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 48),

              // Back button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kembali ke Quiz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
