import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ParentsActivityPost extends StatefulWidget {
  const ParentsActivityPost({super.key});

  @override
  State<ParentsActivityPost> createState() => _ParentsActivityPostState();
}

class _ParentsActivityPostState extends State<ParentsActivityPost> {
  bool skeletonLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        skeletonLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Activity Post')),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Skeletonizer(
          enabled: skeletonLoading,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LargeListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/icons/profile.png'),
                  ),
                  title: Text(
                    'Company Name',
                    style: textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. "',
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        DateTime.now().toString(),
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  bottom: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.asset('assets/images/login.png'),
                  ),
                  alignLeadingOnTop: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LargeListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/icons/profile.png'),
                  ),
                  title: Text(
                    'Company Name',
                    style: textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. "',
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        DateTime.now().toString(),
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  bottom: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.asset('assets/images/login.png'),
                  ),
                  alignLeadingOnTop: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LargeListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/icons/profile.png'),
                  ),
                  title: Text(
                    'Company Name',
                    style: textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. "',
                        style: textTheme.bodyMedium,
                      ),
                      Text(
                        DateTime.now().toString(),
                        style: textTheme.bodyMedium!.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  bottom: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.asset('assets/images/login.png'),
                  ),
                  alignLeadingOnTop: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
