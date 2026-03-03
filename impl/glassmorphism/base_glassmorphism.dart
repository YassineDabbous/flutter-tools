// import 'package:concrete/concrete.dart';
// import 'package:concrete/ui/glassmorphism.dart';
// import 'package:core/core.dart';
// import 'package:flutter/material.dart';

// class GlassmorphicScreen extends StatelessWidget {
//   final Widget child;
//   final bool withBackBtn;
//   final String? title;
//   final FloatingActionButton? floatingAction;
//   const GlassmorphicScreen({Key? key, required this.child, this.withBackBtn = true, this.title, this.floatingAction}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Stack(
//       children: [
//         Img.network(
//           "https://github.com/RitickSaha/glassmophism/blob/master/example/assets/bg.png?raw=true",
//           fit: BoxFit.cover,
//           height: double.infinity,
//           width: double.infinity,
//           scale: 1,
//         ),
//         SafeArea(
//           child: Center(
//             child: GlassmorphicContainer(
//               width: size.width - 10,
//               height: size.height - 10,
//               borderRadius: 20,
//               blur: 1,
//               alignment: Alignment.bottomCenter,
//               border: 0,
//               linearGradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [const Color(0xFFffffff).withOpacity(0.1), const Color(0xFFFFFFFF).withOpacity(0.05)],
//                 stops: const [0.1, 1],
//               ),
//               borderGradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [const Color(0xFFffffff).withOpacity(0.5), const Color((0xFFFFFFFF)).withOpacity(0.5)],
//               ),
//               child: Scaffold(
//                 floatingActionButton: floatingAction,
//                 appBar: AppBar(
//                   title: title != null ? Text(title!) : null,
//                   leading: !withBackBtn ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
//                   actions: [
//                     IconButton(icon: const Icon(Icons.account_box), onPressed: () => Core.nav.pushReplacement(Core.get<R>().authRootRoute)),
//                     IconButton(icon: const Icon(Icons.chat), onPressed: () => Core.nav.pushReplacement(Core.get<R>().contentRootRoute)),
//                     IconButton(icon: const Icon(Icons.settings), onPressed: () => Core.nav.pushReplacement(Core.get<R>().settingsRootRoute)),
//                   ],
//                 ),
//                 body: Container(margin: const EdgeInsets.symmetric(horizontal: 8.0), child: child),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
