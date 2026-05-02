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
    id: 2,
    nama: 'Rizky',
    username: 'rizky',
    password:
        '8d969eef6ecad3c29a3a629280e686cff8fabf5d7e7a3a0655e768f8b1d1e6f3',
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
    nama: 'Aril',
    username: 'aril',
    password:
        '4e07408562bedb8b60ce05c1decfe3ad16b7223091f0b9f7e2c5e5a4b7c8d6a1',
  ),
];
