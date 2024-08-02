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
  bool isVotingPeriod = false;

  @override
  void initState() {
    super.initState();
    checkVotingPeriod();
  }

  void checkVotingPeriod() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfVoting = startOfMonth.add(const Duration(days: 7));
    setState(() {
      isVotingPeriod = now.isAfter(startOfMonth) && now.isBefore(endOfVoting);
    });
  }

  Future<Map<String, List<String>>> fetchLocations() async {
    // Fetch all unique locations from Firebase
    final snapshot =
        await FirebaseFirestore.instance.collection('userPlaceInfo').get();
    final locations = <String, Set<String>>{};
    for (var doc in snapshot.docs) {
      final country = doc.data()['country'] as String?;
      final city = doc.data()['city'] as String?;
      if (country != null && city != null) {
        locations.putIfAbsent(country, () => {}).add(city);
      }
    }
    return locations.map((key, value) => MapEntry(key, value.toList()));
  }

  Future<void> showLocationSelector() async {
    final locations = await fetchLocations();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: selectedCountry,
              hint: const Text('Select Country'),
              items: locations.keys.map((country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                  selectedCity = null;
                });
              },
            ),
            if (selectedCountry != null)
              DropdownButton<String>(
                value: selectedCity,
                hint: const Text('Select City'),
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
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              if (selectedCity != null && selectedCountry != null) {
                fetchTopSupporters();
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> fetchTopSupporters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('city', isEqualTo: selectedCity)
        .where('country', isEqualTo: selectedCountry)
        .get();

    final supporters = snapshot.docs.map((doc) {
      final data = doc.data();
      final totalHearts = (data['receivedCommentsHearts'] ?? 0) +
          (data['receivedPostHearts'] ?? 0);
      return {
        'id': doc.id,
        'nickname': data['nickname'],
        'totalHearts': totalHearts,
      };
    }).toList();

    supporters.sort((a, b) => b['totalHearts'].compareTo(a['totalHearts']));
    setState(() {
      topSupporters = supporters.take(5).toList();
      votes = {for (var supporter in topSupporters) supporter['id']: 0};
    });
  }

  // fetchLocations, fetchTopSupporters, voteForSupporter, endVoting 메서드는 그대로 유지

  void endVoting() {
    if (!isVotingPeriod) return;

    final sortedVotes = votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final winners = sortedVotes.take(3).map((e) => e.key).toList();

    // Save winners to Firebase
    FirebaseFirestore.instance.collection('supportersVoting').add({
      'city': selectedCity,
      'country': selectedCountry,
      'winners': winners,
      'votingEndDate': DateTime.now(),
    });

    setState(() {
      isVotingPeriod = false;
    });
  }

  void voteForSupporter(String supporterId) {
    if (isVotingPeriod) {
      setState(() {
        votes[supporterId] = (votes[supporterId] ?? 0) + 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voting period has ended')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vote Your Supporters'),
        actions: [
          if (isVotingPeriod)
            IconButton(
              icon: const Icon(Icons.how_to_vote),
              onPressed: endVoting,
              tooltip: 'End Voting',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: showLocationSelector,
                icon: const Icon(Icons.location_on),
                label: Text(selectedCity != null && selectedCountry != null
                    ? '$selectedCity, $selectedCountry'
                    : 'Select Location'),
              ),
              const SizedBox(height: 20),
              if (topSupporters.isNotEmpty) ...[
                Text(
                  'Top Supporters in $selectedCity, $selectedCountry',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                ...topSupporters.map((supporter) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(supporter['nickname'][0]),
                        ),
                        title: Text(supporter['nickname']),
                        subtitle:
                            Text('Total Hearts: ${supporter['totalHearts']}'),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.thumb_up),
                          label: const Text('Vote'),
                          onPressed: isVotingPeriod
                              ? () => voteForSupporter(supporter['id'])
                              : null,
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
                Text(
                  'Current Votes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ...votes.entries.map((entry) => ListTile(
                      title: Text(topSupporters
                          .firstWhere((s) => s['id'] == entry.key)['nickname']),
                      trailing: Text('${entry.value} votes'),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
