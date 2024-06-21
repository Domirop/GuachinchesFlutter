import 'package:flutter/material.dart';
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/ui/components/cards/restaurantMainCard.dart';

class BlogPostDetail extends StatelessWidget {
  final BlogPost blogPost;

  BlogPostDetail({required this.blogPost});
  Color bgColor = Color.fromRGBO(25, 27, 32, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color.fromRGBO(25, 27, 32, 1)],
                      stops: [0.5, 1.0],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                  },
                  blendMode: BlendMode.darken,
                  child: Image.network(
                    blogPost.photoUrl ?? '',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.black.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blogPost.title ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(

                height: 0.1,
                width: double.infinity,
                color: Color.fromRGBO(208, 221, 255, 1),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                child: Text(
                  blogPost.subTitle ?? '',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: blogPost.restaurants?.map((restaurant) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: RestaurantMainCard(restaurant: restaurant, size: 'big'),
                  );
                }).toList() ?? [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

