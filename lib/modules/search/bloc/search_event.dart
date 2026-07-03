import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class LoadSearchPage extends SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class AddRecentSearch extends SearchEvent {
  final String query;
  const AddRecentSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class RemoveRecentSearch extends SearchEvent {
  final String query;
  const RemoveRecentSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearRecentSearches extends SearchEvent {}

class SelectFilter extends SearchEvent {
  final String filterType; // 'cuisine', 'diet', 'time'
  final String? value;
  const SelectFilter(this.filterType, this.value);

  @override
  List<Object?> get props => [filterType, value];
}
