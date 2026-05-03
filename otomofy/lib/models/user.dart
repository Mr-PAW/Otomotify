class User {
  int id; // ID unik tiap user
  String nama;
  String username;
  String password; // Langsung nyimpen string yang lu kasih

  // Constructor
  User({
    required this.id,
    required this.nama,
    required this.username,
    required this.password,
  });
}

// Ini array/list user kelompok lu
List<User> dummyUsers = [
  User(
    id: 1,
    nama: 'Dito',
    username: 'dito',
    password:
        '86fcb2dca4158cf259a85669f0a621a30eeff280e3e06e4c47e853e9b941b43b',
  ),
  User(
    id: 3,
    nama: 'Ardi',
    username: 'ardi',
    password:
        '52c9d53b73f8a8b61152ca671557a2c4dd8fe5a4425a5a4a47306e2aacc28fd5',
  ),
  User(
    id: 4,
    nama: 'Raffy',
    username: 'raffy',
    password:
        'bfccfeb7726160d74f8a18407853846aab2ebd57db1dc32409acd6aefc7c4b33',
  ),
  User(
    id: 5,
    nama: 'Ual imitasi',
    username: 'ual',
    password:
        'ace4a5cc7a5a2923894f0d703b95a7649102ca86b7ef5013d50d05f107d660fc',
  ),
];
