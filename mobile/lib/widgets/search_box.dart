import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () {},
      decoration: const InputDecoration(
        hintText: 'Search courses, tasks or lessons',
        prefixIcon: Icon(Icons.search_rounded),
        suffixIcon: Icon(Icons.tune_rounded),
      ),
    );
  }
}
