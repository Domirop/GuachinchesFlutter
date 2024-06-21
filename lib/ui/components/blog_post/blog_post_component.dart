import 'package:flutter/material.dart';
import 'package:guachinches/data/model/blog_post.dart';
import 'package:guachinches/ui/pages/BlogPostDetail/blogPostDetail.dart';

class BlogPostComponent extends StatelessWidget {
  final BlogPost blogPost;

  BlogPostComponent({required this.blogPost});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlogPostDetail(blogPost: blogPost),
              ),
            );
          },
          child: Center(
            child: Container(
              width: 600,
              height: blogPost.size =='big' ? 400:200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    Image.network(
                      blogPost.photoUrl!,
                      width: 600,
                      height: 400,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.4),
                      colorBlendMode: BlendMode.darken,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.6,
                            child: Text(
                              blogPost.title!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            blogPost.restaurants!.length.toString() +
                                ' Restaurantes',
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo_gmt.png'),
              radius: 20,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@GuachinchesModernosTenerife',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Influencer Gastronomico - Tenerife',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
