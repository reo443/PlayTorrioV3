import 'package:flutter_test/flutter_test.dart';
import 'package:playtorrio/models/movie/tmdb_person.dart';
import 'package:playtorrio/services/metadata/tmdb_service.dart';

Map<String, dynamic> _credit({
  required int id,
  String? title,
  String? name,
  String mediaType = 'movie',
  String? releaseDate,
  String? firstAirDate,
  double popularity = 1,
  String? posterPath = '/poster.jpg',
}) => {
  'id': id,
  'media_type': mediaType,
  if (title != null) 'title': title,
  if (name != null) 'name': name,
  if (releaseDate != null) 'release_date': releaseDate,
  if (firstAirDate != null) 'first_air_date': firstAirDate,
  'popularity': popularity,
  if (posterPath != null) 'poster_path': posterPath,
  'vote_average': 7.5,
};

Map<String, dynamic> _person({
  int? id = 2524,
  String? name = 'Tom Hardy',
  String? profilePath = '/tom.jpg',
  String department = 'Acting',
  String biography = 'Edward Thomas Hardy is an English actor.',
  List<Map<String, dynamic>>? cast,
}) => {
  if (id != null) 'id': id,
  if (name != null) 'name': name,
  if (profilePath != null) 'profile_path': profilePath,
  'known_for_department': department,
  'biography': biography,
  'combined_credits': {
    'cast': cast ?? const <Map<String, dynamic>>[],
  },
};

void main() {
  group('personFromJson', () {
    test('reads the identity fields and builds the profile url', () {
      final person = TmdbService.personFromJson(_person());

      expect(person, isNotNull);
      expect(person!.id, 2524);
      expect(person.name, 'Tom Hardy');
      expect(person.department, 'Acting');
      expect(person.biography, startsWith('Edward Thomas Hardy'));
      expect(
        person.profileUrl,
        'https://image.tmdb.org/t/p/w185/tom.jpg',
      );
    });

    test('leaves the profile url null when the person has no photo', () {
      final person = TmdbService.personFromJson(_person(profilePath: null));

      expect(person!.profileUrl, isNull);
    });

    test('returns null when the payload has no usable id', () {
      expect(TmdbService.personFromJson(_person(id: null)), isNull);
      expect(TmdbService.personFromJson(_person(name: null)), isNull);
      expect(TmdbService.personFromJson(const {}), isNull);
    });

    test('keeps only movie and tv cast credits', () {
      final payload = _person(cast: [
        _credit(id: 1, title: 'Movie credit'),
        _credit(id: 2, name: 'TV credit', mediaType: 'tv', firstAirDate: '2019-01-01'),
        {'id': 4, 'title': 'No media type'},
      ]);
      (payload['combined_credits'] as Map<String, dynamic>)['crew'] = [
        _credit(id: 3, title: 'Crew credit'),
      ];

      final person = TmdbService.personFromJson(payload);

      expect(person!.credits.map((m) => m.name), ['TV credit', 'Movie credit']);
    });

    test('collapses the same title appearing in several roles', () {
      final person = TmdbService.personFromJson(_person(cast: [
        _credit(id: 10, title: 'Inception', releaseDate: '2010-07-16', popularity: 3),
        _credit(id: 10, title: 'Inception', releaseDate: '2010-07-16', popularity: 8),
      ]));

      expect(person!.credits, hasLength(1));
      expect(person.credits.single.popularity, 8);
    });

    test('does not merge a movie and a series that share a numeric id', () {
      final person = TmdbService.personFromJson(_person(cast: [
        _credit(id: 77, title: 'Film 77', releaseDate: '2001-01-01'),
        _credit(id: 77, name: 'Show 77', mediaType: 'tv', firstAirDate: '2002-01-01'),
      ]));

      expect(person!.credits, hasLength(2));
      expect(person.credits.map((m) => m.type), containsAll(['movie', 'series']));
    });

    test('orders credits by year descending, then popularity descending', () {
      final person = TmdbService.personFromJson(_person(cast: [
        _credit(id: 1, title: 'Old', releaseDate: '2015-01-01', popularity: 10),
        _credit(id: 2, title: 'New but quieter', releaseDate: '2020-05-01', popularity: 5),
        _credit(id: 3, name: 'New and loud', mediaType: 'tv', firstAirDate: '2020-09-01', popularity: 9),
        _credit(id: 4, title: 'Undated'),
      ]));

      expect(
        person!.credits.map((m) => m.name),
        ['New and loud', 'New but quieter', 'Old', 'Undated'],
      );
    });

    test('returns the person with no credits when combined_credits is missing', () {
      final payload = _person()..remove('combined_credits');

      final person = TmdbService.personFromJson(payload);

      expect(person, isNotNull);
      expect(person!.credits, isEmpty);
    });
  });

  group('personIdFromSearchJson', () {
    Map<String, dynamic> search(List<Map<String, dynamic>> results) =>
        {'results': results};

    test('prefers an exact name match over the first result', () {
      final id = TmdbService.personIdFromSearchJson(
        search([
          {'id': 1, 'name': 'Tom Hardy Jr.'},
          {'id': 2, 'name': 'tom hardy'},
        ]),
        name: 'Tom Hardy',
      );

      expect(id, 2);
    });

    test('falls back to the first result with an id', () {
      final id = TmdbService.personIdFromSearchJson(
        search([
          {'name': 'No id here'},
          {'id': 9, 'name': 'Someone Else'},
        ]),
      );

      expect(id, 9);
    });

    test('returns null when there are no results', () {
      expect(TmdbService.personIdFromSearchJson(const {}), isNull);
      expect(TmdbService.personIdFromSearchJson(search(const [])), isNull);
    });
  });

  group('TmdbPerson', () {
    test('exposes the credits as plain movies', () {
      final person = TmdbService.personFromJson(_person(cast: [
        _credit(id: 5, title: 'Fury', releaseDate: '2014-10-15'),
      ]));

      final TmdbPerson value = person!;
      expect(value.credits.single.id, '${TmdbService.kSentinel}:5');
      expect(value.credits.single.addonBaseUrl, TmdbService.kSentinel);
    });
  });
}
