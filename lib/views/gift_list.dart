import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gift_app/constants/routes.dart';
import 'package:gift_app/models/ModelProvider.dart';

class GiftListView extends StatefulWidget {
  final Person person;
  const GiftListView({super.key, required this.person});

  @override
  State<GiftListView> createState() => _GiftListViewState();
}

class _GiftListViewState extends State<GiftListView> {
  late final Person _person = widget.person;
  List<Gift> _presents = [];
  late StreamSubscription<QuerySnapshot<Gift>> _subscription;
  String _url = "";

  Future<void> changeIsSelected(id) async {
    try {
      final giftWithId = await Amplify.DataStore.query(
        Gift.classType,
        where: Gift.ID.eq(id),
      );
      final oldGift = giftWithId.first;
      final newGift = oldGift.copyWith(isSelected: !oldGift.isSelected);
      await Amplify.DataStore.save(newGift);
    } catch (e) {
      safePrint(e);
    }
  }

  Future<void> getUrl(Person person) async {
    final key = person.pictureKey;
    if (key != null) {
      _url = (await Amplify.Storage.getUrl(key: key)).url;
    }
  }

  @override
  void initState() {
    _subscription = Amplify.DataStore.observeQuery(
      Gift.classType,
      where: Gift.RECEIVER.eq(_person.id),
    ).listen((QuerySnapshot<Gift> snapshot) {
      setState(() {
        _presents = snapshot.items;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_person.name),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(newGiftRoute, arguments: _person);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              _profilePic(),
              const SizedBox(
                height: 20,
              ),
              _giftList(),
            ],
          );
        },
        future: getUrl(_person),
      ),
    );
  }

  Widget _giftList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _presents.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            title: Text(_presents[index].name),
            value: _presents[index].isSelected,
            onChanged: (val) {
              setState(() {
                changeIsSelected(_presents[index].id);
              });
            },
          );
        },
      ),
    );
  }

  Widget _profilePic() {
    if (_url == "") {
      return const CircleAvatar(
        radius: 60,
        backgroundImage: AssetImage('lib/assets/present.png'),
      );
    }
    return CircleAvatar(
      radius: 60,
      backgroundImage: NetworkImage(
        _url,
      ),
    );
  }
}
