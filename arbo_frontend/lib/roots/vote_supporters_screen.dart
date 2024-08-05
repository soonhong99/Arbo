import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/widgets/login_widgets/login_popup_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VoteSupportersScreen extends StatefulWidget {
  const VoteSupportersScreen({super.key});

  @override
  _VoteSupportersScreenState createState() => _VoteSupportersScreenState();
}

class _VoteSupportersScreenState extends State<VoteSupportersScreen> {
  String? selectedCity;
  String? selectedCountry;
  List<Map<String, dynamic>> topSupporters = [];
  Map<String, int> votes = {};
  Map<String, List<String>> locations = {};
  bool isLoading = true;
  String? userVotedId;
  String? userVotedNickname;
  bool isMaster = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });
    await fetchLocations();
    if (locations.isNotEmpty) {
      selectedCountry = locations.keys.first;
      if (locations[selectedCountry]!.isNotEmpty) {
        selectedCity = locations[selectedCountry]!.first;
        await fetchTopSupporters();
        await fetchUserVote();
      }
    }
    checkIfMaster();

    setState(() {
      isLoading = false;
    });
  }

  checkIfMaster() {
    if (currentLoginUser != null) {
      if (nickname == 'master') {
        setState(() {
          isMaster = true;
        });
      }
    }
  }

  Future<void> endVoting() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 모든 지역의 투표 데이터 가져오기
      QuerySnapshot votesSnapshot =
          await FirebaseFirestore.instance.collection('votes').get();

      // 각 지역별 상위 3명의 서포터즈 ID를 저장할 맵
      Map<String, List<String>> topSupportersByRegion = {};

      // 각 지역별로 상위 3명의 서포터즈 선정
      for (var voteDoc in votesSnapshot.docs) {
        String region = voteDoc.id;
        Map<String, dynamic> voteData = voteDoc.data() as Map<String, dynamic>;

        // 투표 데이터를 리스트로 변환하고 정렬
        List<MapEntry<String, dynamic>> sortedVotes = voteData.entries.toList()
          ..sort((a, b) => (b.value as int).compareTo(a.value as int));

        // 상위 3명의 서포터즈 ID 선택
        List<String> topSupportersIds =
            sortedVotes.take(3).map((e) => e.key).toList();
        topSupportersByRegion[region] = topSupportersIds;
      }

      // 모든 사용자의 상태 업데이트
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        String userRegion = '${userDoc['country']}-${userDoc['city']}';

        bool isNewSupporter =
            topSupportersByRegion[userRegion]?.contains(userId) ?? false;

        await userDoc.reference.update({
          'nowSupporters': isNewSupporter,
          'receivedCommentsHearts': 0,
          'receivedPostHearts': 0,
          'voteUserId': FieldValue.delete(),
          'voteUserNickname': FieldValue.delete(),
        });
      }

      // 모든 투표 데이터 삭제
      for (var voteDoc in votesSnapshot.docs) {
        await voteDoc.reference.delete();
      }

      // 현재 화면의 데이터 새로고침
      await fetchTopSupporters();
      await fetchUserVote();

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Voting has ended and supporters have been selected for all regions.')),
      );
    } catch (e) {
      print('Error in endVoting: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'An error occurred while ending the voting. Please try again.')),
      );
    }
  }

  Future<void> fetchLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('userPlaceInfo').get();
    final locationsMap = <String, Set<String>>{};
    for (var doc in snapshot.docs) {
      final country = doc.data()['country'] as String?;
      final city = doc.data()['city'] as String?;
      if (country != null && city != null) {
        locationsMap.putIfAbsent(country, () => {}).add(city);
      }
    }
    setState(() {
      locations =
          locationsMap.map((key, value) => MapEntry(key, value.toList()));
    });
  }

  Future<void> fetchTopSupporters() async {
    if (selectedCity == null || selectedCountry == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('city', isEqualTo: selectedCity)
        .where('country', isEqualTo: selectedCountry)
        .get();

    final supporters = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final totalHearts = (data['receivedCommentsHearts'] ?? 0) +
              (data['receivedPostHearts'] ?? 0);
          return {
            'id': doc.id,
            '닉네임': data['닉네임'],
            'totalHearts': totalHearts,
          };
        })
        .where((supporter) => supporter['totalHearts'] > 0)
        .toList();

    supporters.sort((a, b) => b['totalHearts'].compareTo(a['totalHearts']));

    final voteSnapshot = await FirebaseFirestore.instance
        .collection('votes')
        .doc('$selectedCountry-$selectedCity')
        .get();

    final voteData = voteSnapshot.data() ?? {};

    setState(() {
      topSupporters = supporters.take(5).toList();
      votes = {
        for (var supporter in topSupporters)
          supporter['id']: voteData[supporter['id']] ?? 0
      };
    });
  }

  Future<void> fetchUserVote() async {
    if (currentLoginUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentLoginUser!.uid)
          .get();
      final userData = userDoc.data();
      if (userData != null) {
        setState(() {
          userVotedId = userData['voteUserId'];
          userVotedNickname = userData['voteUserNickname'];
        });
      }
    }
  }

  Future<void> voteForSupporter(
      String supporterId, String supporterNickname) async {
    if (currentLoginUser == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return LoginPopupWidget(
            onLoginSuccess: () {
              voteForSupporter(supporterId, supporterNickname);
            },
          );
        },
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentLoginUser!.uid)
        .get();
    final userData = userDoc.data();

    if (userData == null || userData['country'] != selectedCountry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only vote in your own country.')),
      );
      return;
    }

    if (userVotedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You have already voted for $userVotedNickname!')),
      );
      return;
    }

    // Update user's vote
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentLoginUser!.uid)
        .update({
      'voteUserId': supporterId,
      'voteUserNickname': supporterNickname,
    });

    // Update vote count
    await FirebaseFirestore.instance
        .collection('votes')
        .doc('$selectedCountry-$selectedCity')
        .set({supporterId: FieldValue.increment(1)}, SetOptions(merge: true));

    // Refresh data
    await fetchTopSupporters();
    await fetchUserVote();
  }

  Future<void> cancelVote() async {
    if (currentLoginUser == null || userVotedId == null) return;

    // Remove user's vote
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentLoginUser!.uid)
        .update({
      'voteUserId': FieldValue.delete(),
      'voteUserNickname': FieldValue.delete(),
    });

    // Update vote count
    await FirebaseFirestore.instance
        .collection('votes')
        .doc('$selectedCountry-$selectedCity')
        .set({userVotedId!: FieldValue.increment(-1)}, SetOptions(merge: true));

    // Refresh data
    await fetchTopSupporters();
    await fetchUserVote();
  }

  Widget _buildSupportersTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Supporters in $selectedCity, $selectedCountry',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: const Text(
            'The top 5 users in this region with at least 1 heart from comments or posts are competing here! Please cast your valuable vote!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSupportersList() {
    return topSupporters.asMap().entries.map((entry) {
      final index = entry.key;
      final supporter = entry.value;
      final isFirstPlace = index == 0;
      final isTopThree = index < 3;

      return Padding(
        padding: EdgeInsets.only(bottom: isFirstPlace ? 24 : 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: isFirstPlace
                    ? Colors.yellow.withOpacity(0.5)
                    : (isTopThree
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3)),
                spreadRadius: isFirstPlace ? 4 : 2,
                blurRadius: isFirstPlace ? 10 : 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: isTopThree
                ? Border.all(
                    color: isFirstPlace ? Colors.yellow : Colors.blue,
                    width: isFirstPlace ? 3 : 2,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: isFirstPlace
                            ? Colors.yellow[100]
                            : Colors.blue[100],
                        radius: isFirstPlace ? 30 : 25,
                        child: Text(
                          supporter['닉네임'][0],
                          style: TextStyle(
                            color: isFirstPlace
                                ? Colors.orange[800]
                                : Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: isFirstPlace ? 24 : 20,
                          ),
                        ),
                      ),
                      if (isTopThree)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isFirstPlace ? 70 : 60,
                          height: isFirstPlace ? 70 : 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFirstPlace ? Colors.yellow : Colors.blue,
                              width: isFirstPlace ? 3 : 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    supporter['닉네임'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isFirstPlace ? 18 : 16,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[300], size: 16),
                      const SizedBox(width: 4),
                      Text('Total Hearts: ${supporter['totalHearts']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Votes: ${votes[supporter['id']]}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFirstPlace
                            ? Colors.orange[700]
                            : Colors.blue[700],
                        fontSize: isFirstPlace ? 16 : 14,
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(
                        userVotedId == supporter['id']
                            ? Icons.check_circle
                            : Icons.how_to_vote,
                        color: Colors.white,
                      ),
                      label: Text(
                        userVotedId == supporter['id'] ? 'Voted' : 'Vote',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userVotedId == supporter['id']
                            ? Colors.green
                            : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: userVotedId == supporter['id']
                          ? cancelVote
                          : () => voteForSupporter(
                              supporter['id'], supporter['닉네임']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUserVoteInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have voted for: $userVotedNickname',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedCountry,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.flag, color: Colors.blue),
              labelText: 'Select Country',
              border: OutlineInputBorder(),
            ),
            items: locations.keys.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCountry = value;
                selectedCity = locations[value]?.isNotEmpty == true
                    ? locations[value]!.first
                    : null;
              });
              fetchTopSupporters();
            },
          ),
          const SizedBox(height: 16),
          if (selectedCountry != null &&
              locations[selectedCountry]?.isNotEmpty == true)
            DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_city, color: Colors.blue),
                labelText: 'Select City',
                border: OutlineInputBorder(),
              ),
              items: locations[selectedCountry]!.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
                fetchTopSupporters();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vote Your Supporters'),
        backgroundColor: Colors.blue,
        actions: [
          if (isMaster)
            ElevatedButton(
              onPressed: endVoting,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('vote 종료!'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationSelectors(),
                    const SizedBox(height: 20),
                    if (topSupporters.isNotEmpty) ...[
                      _buildSupportersTitle(),
                      const SizedBox(height: 16),
                      ..._buildSupportersList(),
                    ],
                    if (userVotedNickname != null) _buildUserVoteInfo(),
                  ],
                ),
              ),
            ),
    );
  }
}
