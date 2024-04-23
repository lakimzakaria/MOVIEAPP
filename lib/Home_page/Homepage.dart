import 'package:flutter/material.dart';
import 'package:movieapp/Movie_details_page/MovieDetailsPage.dart';
import 'package:movieapp/api_data/movie_model.dart';
import 'package:movieapp/api_data/movie_data_source.dart';
import 'package:movieapp/Home_page/list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MovieModel> futureMovies = [];
  final searchController = TextEditingController();
  int pageNumber = 1;

  // Add a ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMoreMovies();
    // Add a listener to the ScrollController
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        loadMoreMovies();
      }
    });
  }

  @override
  void dispose() {
    // Dispose the ScrollController
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void searchMovies() async {
    List<MovieModel> fetchedMovies;
    if (searchController.text.isEmpty) {
      // If the search query is null or empty, load the initial movies
      fetchedMovies = await OmdbApiClient().getMovies();
    } else {
      fetchedMovies =
          await OmdbApiClient().getMovies(query: searchController.text);
    }
    // Filter out movies without a poster
    fetchedMovies = fetchedMovies
        .where((movie) => movie.poster != null && movie.poster!.isNotEmpty)
        .toList();
    setState(() {
      futureMovies = fetchedMovies;
    });
  }

  void loadMoreMovies() {
    String query =
        searchController.text.isEmpty ? "movie" : searchController.text;
    OmdbApiClient().getMoreMovies(pageNumber, query: query).then((newMovies) {
      // Filter out movies without a poster
      newMovies = newMovies
          .where((movie) => movie.poster != null && movie.poster!.isNotEmpty)
          .toList();
      setState(() {
        pageNumber++;
        futureMovies.addAll(newMovies);
      });
    });
  }

  void onMovieCardTap(MovieModel movie) {
    if (movie.imdbID != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailsPage(imdbID: movie.imdbID!),
        ),
      );
    } else {
      print('Error: Movie imdbID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'MOVIEAPP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search a movie",
                fillColor: Colors.black,
                filled: true,
                suffixIcon: IconButton(
                  onPressed: searchMovies,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              // Add the ScrollController to the GridView
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
              ),
              itemCount:
                  futureMovies.length + 1, // Add 1 for the loading spinner
              itemBuilder: (context, index) {
                if (index == futureMovies.length) {
                  // Return a loading spinner for the last item if more movies are being loaded
                  return Center(child: CircularProgressIndicator());
                } else {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Card(
                      color: Colors.black,
                      child: InkWell(
                        onTap: () => onMovieCardTap(futureMovies[index]),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              futureMovies[index].poster ??
                                  'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 10, // Move to the bottom
                              left: 10,
                              child: Container(
                                color: Colors.black.withOpacity(
                                    0.6), // Semi-transparent background
                                padding: EdgeInsets.all(8.0), // Some padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      futureMovies[index].title ?? 'No Title',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    Text(
                                      futureMovies[index].year ?? 'No Year',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
