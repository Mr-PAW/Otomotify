import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// HALAMAN UTAMA FORUM KESAN & PESAN
// =========================================================
class KesanPesanPage extends StatefulWidget {
  final String userId;
  final String userName;

  const KesanPesanPage({Key? key, required this.userId, required this.userName})
    : super(key: key);

  @override
  _KesanPesanPageState createState() => _KesanPesanPageState();
}

class _KesanPesanPageState extends State<KesanPesanPage> {
  final TextEditingController _postController = TextEditingController();

  String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Baru saja";
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} thn lalu";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} bln lalu";
    if (diff.inDays > 0) return "${diff.inDays} hr lalu";
    if (diff.inHours > 0) return "${diff.inHours} jam lalu";
    if (diff.inMinutes > 0) return "${diff.inMinutes} mnt lalu";
    return "Baru saja";
  }

  // REQ 3: Gedein space buat input kesan pesan
  void _tambahKesanPesan() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            "Tulis Kesan & Pesan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: _postController,
              minLines: 5, // Bikin box-nya langsung lega dari awal
              maxLines: 8,
              maxLength: 300,
              decoration: InputDecoration(
                hintText:
                    "Apa pesan dan kesan anda terhadap Otomotify? Anda juga dapat menulis pesan dan kesan anda terhadap Mata Kuliah Teknologi Pemrograman Mobile",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _postController.clear();
                Navigator.pop(context);
              },
              child: Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_postController.text.trim().isEmpty) return;

                await FirebaseFirestore.instance.collection('forum').add({
                  'id_user': widget.userId,
                  'nama': widget.userName,
                  'teks': _postController.text.trim(),
                  'upvoters': [],
                  'downvoters': [],
                  'createdAt': FieldValue.serverTimestamp(),
                });

                _postController.clear();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E3C72),
              ),
              child: Text("Posting", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // REQ 2: Hapus Postingan & Seluruh Komentar di dalamnya
  void _hapusPostingan(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Hapus Postingan", style: TextStyle(color: Colors.red)),
        content: Text(
          "Yakin mau hapus postingan ini? Semua komentar di dalamnya juga bakal musnah permanen lho.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // 1. Eksekusi mati semua komentar di sub-collection
              var komenSnp = await FirebaseFirestore.instance
                  .collection('forum')
                  .doc(postId)
                  .collection('komentar')
                  .get();
              for (var doc in komenSnp.docs) {
                await doc.reference.delete();
              }

              // 2. Eksekusi mati postingannya
              await FirebaseFirestore.instance
                  .collection('forum')
                  .doc(postId)
                  .delete();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Postingan berhasil dihapus!"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleVote(
    String docId,
    List upvoters,
    List downvoters,
    bool isUpvote,
  ) {
    var ref = FirebaseFirestore.instance.collection('forum').doc(docId);
    if (isUpvote) {
      if (upvoters.contains(widget.userId)) {
        ref.update({
          'upvoters': FieldValue.arrayRemove([widget.userId]),
        });
      } else {
        ref.update({
          'upvoters': FieldValue.arrayUnion([widget.userId]),
          'downvoters': FieldValue.arrayRemove([widget.userId]),
        });
      }
    } else {
      if (downvoters.contains(widget.userId)) {
        ref.update({
          'downvoters': FieldValue.arrayRemove([widget.userId]),
        });
      } else {
        ref.update({
          'downvoters': FieldValue.arrayUnion([widget.userId]),
          'upvoters': FieldValue.arrayRemove([widget.userId]),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Kesan & Pesan"),
        backgroundColor: Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('forum')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text("Jadilah yang pertama memberi kesan!"));

          var allDocs = snapshot.data!.docs;
          var myPost = allDocs
              .where((doc) => doc['id_user'] == widget.userId)
              .toList();
          var otherPosts = allDocs
              .where((doc) => doc['id_user'] != widget.userId)
              .toList();
          var sortedDocs = [...myPost, ...otherPosts];

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              var post = sortedDocs[index];
              List upvoters = post['upvoters'] ?? [];
              List downvoters = post['downvoters'] ?? [];
              int score = upvoters.length - downvoters.length;
              bool isMyPost = post['id_user'] == widget.userId;

              return Card(
                margin: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: index == sortedDocs.length - 1 ? 80 : 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isMyPost
                      ? BorderSide(color: Colors.orange, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isMyPost
                                ? Colors.orange
                                : Color(0xFF1E3C72),
                            child: Text(
                              post['nama'].toString()[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMyPost
                                      ? "${post['nama']} (Anda)"
                                      : post['nama'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  timeAgo(post['createdAt'] as Timestamp?),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // REQ 2: Tombol Hapus Postingan
                          if (isMyPost)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                              ),
                              onPressed: () => _hapusPostingan(post.id),
                            )
                          else if (myPost.isNotEmpty && post.id == myPost[0].id)
                            Icon(
                              Icons.push_pin,
                              color: Colors.orange,
                              size: 20,
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        post['teks'],
                        style: TextStyle(fontSize: 15, height: 1.4),
                      ),
                      SizedBox(height: 16),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_upward,
                                  color: upvoters.contains(widget.userId)
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                                onPressed: () => _handleVote(
                                  post.id,
                                  upvoters,
                                  downvoters,
                                  true,
                                ),
                              ),
                              Text(
                                score.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_downward,
                                  color: downvoters.contains(widget.userId)
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () => _handleVote(
                                  post.id,
                                  upvoters,
                                  downvoters,
                                  false,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.grey[600],
                            ),
                            label: Text(
                              "Komentar",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => KomentarBottomSheet(
                                  postId: post.id,
                                  currentUserId: widget.userId,
                                  currentUserName: widget.userName,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('forum')
            .where('id_user', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
            return FloatingActionButton.extended(
              onPressed: _tambahKesanPesan,
              backgroundColor: Colors.orange,
              icon: Icon(Icons.edit, color: Colors.white),
              label: Text(
                "Beri Kesan",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          return SizedBox();
        },
      ),
    );
  }
}

// =========================================================
// BOTTOM SHEET KHUSUS KOMENTAR (IG Style: Thread & Mention)
// =========================================================
class KomentarBottomSheet extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;

  const KomentarBottomSheet({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  _KomentarBottomSheetState createState() => _KomentarBottomSheetState();
}

class _KomentarBottomSheetState extends State<KomentarBottomSheet> {
  final TextEditingController _komenController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _activeParentId; // Nampung ID parent kalo lagi reply
  String? _replyTargetName; // Nampung nama yg di-reply
  Set<String> _expandedComments =
      {}; // Nampung ID parent yg lagi dibuka balasannya

  String timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Baru aja";
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) return "${diff.inDays}h";
    if (diff.inHours > 0) return "${diff.inHours}j";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Baru";
  }

  void _kirimKomentar() async {
    if (_komenController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('forum')
        .doc(widget.postId)
        .collection('komentar')
        .add({
          'id_user': widget.currentUserId,
          'nama': widget.currentUserName,
          'teks': _komenController.text.trim(),
          'parentId': _activeParentId, // Kalo null berarti dia komen utama
          'createdAt': FieldValue.serverTimestamp(),
        });

    _komenController.clear();
    setState(() {
      // Kalo abis kirim reply, otomatis expand balasannya biar langsung keliatan
      if (_activeParentId != null) _expandedComments.add(_activeParentId!);
      _activeParentId = null;
      _replyTargetName = null;
    });
    FocusScope.of(context).unfocus();
  }

  // Siap-siap reply
  void _setReply(String namaTarget, String parentId) {
    setState(() {
      _replyTargetName = namaTarget;
      _activeParentId = parentId;
    });
    _komenController.text = "@$namaTarget ";
    _focusNode.requestFocus();
  }

  // REQ 2: Hapus Komentar (kalo parent, anak-anaknya ikut kehapus)
  void _hapusKomen(String idKomen, bool isParent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Hapus Komentar"),
        content: Text("Yakin mau hapus komentar ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              var col = FirebaseFirestore.instance
                  .collection('forum')
                  .doc(widget.postId)
                  .collection('komentar');

              if (isParent) {
                // Hapus semua child yg numpang di parent ini
                var children = await col
                    .where('parentId', isEqualTo: idKomen)
                    .get();
                for (var child in children.docs) await child.reference.delete();
              }
              // Hapus komentar itu sendiri
              await col.doc(idKomen).delete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Builder buat UI tiap item komentar
  Widget _buildKomenItem(
    DocumentSnapshot komen,
    bool isReply,
    String parentIdForReply,
  ) {
    var data = komen.data() as Map<String, dynamic>;
    bool isMyKomen = data['id_user'] == widget.currentUserId;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 40 : 0,
        bottom: 8,
        top: 4,
      ), // Di-tab 40px kalo reply
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 12 : 16, // Lingkaran lebih kecil buat reply
            backgroundColor: isMyKomen ? Colors.orange : Colors.grey[400],
            child: Text(
              data['nama'].toString()[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isReply ? 10 : 12,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['nama'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      timeAgo(data['createdAt'] as Timestamp?),
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  data['teks'],
                  style: TextStyle(color: Colors.black87, fontSize: 13),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      // IG Style: Kalo bales ke parent, id-nya si parent. Kalo bales ke child, id-nya tetep si parent!
                      onTap: () => _setReply(data['nama'], parentIdForReply),
                      child: Text(
                        "Balas",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isMyKomen) ...[
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _hapusKomen(komen.id, !isReply),
                        child: Text(
                          "Hapus",
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height:
            MediaQuery.of(context).size.height *
            0.7, // Ditinggiin dikit 70% biar leluasa
        padding: EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Komentar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Divider(),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('forum')
                    .doc(widget.postId)
                    .collection('komentar')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return Center(child: Text("Belum ada komentar."));

                  var allKomen = snapshot.data!.docs;

                  // Pisahin mana yang parent (utama), mana yang balasan
                  var parentKomen = allKomen
                      .where(
                        (k) =>
                            !(k.data() as Map).containsKey('parentId') ||
                            k['parentId'] == null,
                      )
                      .toList();
                  var childKomen = allKomen
                      .where(
                        (k) =>
                            (k.data() as Map).containsKey('parentId') &&
                            k['parentId'] != null,
                      )
                      .toList();

                  return ListView.builder(
                    itemCount: parentKomen.length,
                    itemBuilder: (context, index) {
                      var parent = parentKomen[index];
                      // Cari anak-anak yang nginduk ke parent ini
                      var replies = childKomen
                          .where((c) => c['parentId'] == parent.id)
                          .toList();
                      bool isExpanded = _expandedComments.contains(parent.id);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKomenItem(
                            parent,
                            false,
                            parent.id,
                          ), // Render si Induk
                          // Kalau ada balasannya, munculin tombol "Lihat balasan"
                          if (replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 40,
                                bottom: 8,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded)
                                      _expandedComments.remove(parent.id);
                                    else
                                      _expandedComments.add(parent.id);
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 1,
                                      color: Colors.grey[400],
                                    ), // Garis sambung
                                    SizedBox(width: 8),
                                    Text(
                                      isExpanded
                                          ? "Sembunyikan balasan"
                                          : "Lihat balasan (${replies.length})",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Kalau lagi expanded, tampilin semua anaknya
                          if (isExpanded)
                            ...replies
                                .map(
                                  (reply) =>
                                      _buildKomenItem(reply, true, parent.id),
                                )
                                .toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // BAR INFO LAGI REPLY SIAPA
            if (_replyTargetName != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Membalas $_replyTargetName",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyTargetName = null;
                          _activeParentId = null;
                        });
                        _komenController.clear();
                      },
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

            // KOLOM INPUT KOMENTAR
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: _replyTargetName != null
                    ? BorderRadius.vertical(bottom: Radius.circular(25))
                    : BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _komenController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: "Tambahkan komentar...",
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Color(0xFF1E3C72)),
                    onPressed: _kirimKomentar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
