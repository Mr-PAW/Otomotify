class Question {
  final int id;
  final String question;
  final List<String> options; // A, B, C, D
  final int correctAnswer; // 0=A, 1=B, 2=C, 3=D

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizData {
  static final List<Question> questions = [
    Question(
      id: 1,
      question: 'Berapa banyak silinder yang dimiliki mesin V8?',
      options: ['4 silinder', '6 silinder', '8 silinder', '12 silinder'],
      correctAnswer: 2,
    ),
    Question(
      id: 2,
      question: 'Merek mobil BMW berasal dari negara mana?',
      options: ['Jepang', 'Jerman', 'Italia', 'Inggris'],
      correctAnswer: 1,
    ),
    Question(
      id: 3,
      question: 'Apa kepanjangan dari "SUV"?',
      options: [
        'Sport Utility Vehicle',
        'Super Urban Van',
        'Speed Universal Vehicle',
        'Standard Use Vehicle',
      ],
      correctAnswer: 0,
    ),
    Question(
      id: 4,
      question: 'Toyota Supra generasi terbaru diluncurkan tahun berapa?',
      options: ['2015', '2018', '2019', '2021'],
      correctAnswer: 2,
    ),
    Question(
      id: 5,
      question: 'Merek mobil "Lamborghini" terkenal dengan apa?',
      options: [
        'Mobil keluarga ekonomis',
        'Mobil mewah sport berkecepatan tinggi',
        'Mobil listrik ramah lingkungan',
        'Mobil off-road tangguh',
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 6,
      question: 'Apa fungsi utama dari "turbocharger" pada mesin?',
      options: [
        'Menurunkan emisi',
        'Meningkatkan performa dan tenaga mesin',
        'Mendinginkan mesin',
        'Mengisi bahan bakar',
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 7,
      question: 'Berapa kapasitas silinder (cc) pada motor standar Yamaha R15?',
      options: ['110cc', '150cc', '155cc', '200cc'],
      correctAnswer: 2,
    ),
    Question(
      id: 8,
      question: 'Porsche 911 pertama kali diproduksi pada tahun?',
      options: ['1950', '1963', '1970', '1985'],
      correctAnswer: 1,
    ),
    Question(
      id: 9,
      question: 'Apa fungsi dari "anti-lock braking system" (ABS)?',
      options: [
        'Mempercepat putaran roda',
        'Mencegah roda terkunci saat pengereman',
        'Menghemat bahan bakar',
        'Menambah daya dorong mesin',
      ],
      correctAnswer: 1,
    ),
    Question(
      id: 10,
      question:
          'Honda Civic terbaru (generasi 11) diluncurkan di Indonesia tahun?',
      options: ['2020', '2021', '2022', '2023'],
      correctAnswer: 3,
    ),
  ];
}
