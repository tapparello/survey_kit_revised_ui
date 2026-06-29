import 'package:flutter/material.dart';

class SelectionListTile extends StatelessWidget {
  final String text;
  final Function() onTap;
  final bool isSelected;

  const SelectionListTile({
    Key? key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Theme(
            // ADO #961: disable the row ink so taps show no ripple; selection
            // is conveyed by the blue title + trailing check only.
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            child: ListTile(
              title: Text(
                text,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isSelected
                          ? Theme.of(context).listTileTheme.selectedColor
                          : Theme.of(context).textTheme.headlineSmall?.color,
                    ),
              ),
              contentPadding: EdgeInsets.zero,
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).listTileTheme.selectedColor
                          : Colors.black,
                    )
                  : Container(
                      width: 32,
                      height: 32,
                    ),
              onTap: onTap,
            ),
          ),
        ),
        const Divider(
          color: Colors.grey,
        ),
      ],
    );
  }
}
