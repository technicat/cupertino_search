library cupertino_search;

import 'dart:async';

import 'package:flutter/cupertino.dart';

typedef String FormFieldFormatter<T>(T v);
typedef bool CupertinoSearchFilter<T>(T v, String c);
typedef int CupertinoSearchSort<T>(T a, T b, String c);
typedef Future<List<CupertinoSearchResult>> CupertinoResultsFinder(String c);
typedef void OnSubmit(String value);

class CupertinoSearchResult<T> extends StatelessWidget {
  const CupertinoSearchResult({
    Key? key,
    required this.value,
    required this.text,
    this.icon,
  }) : super(key: key);

  final T value;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          Container(width: 70.0, child: Icon(icon)),
          Expanded(
              child: Text(
                  text)), //style: CupertinoTheme.of(context).textTheme.navTitleTextStyle)),
        ],
      ),
      height: 56.0,
    );
  }
}

class CupertinoSearch<T> extends StatefulWidget {
  CupertinoSearch({
    Key? key,
    this.placeholder,
    this.results,
    this.getResults,
    this.filter,
    this.sort,
    this.limit: 10,
    this.onSelect,
    this.onSubmit,
    this.barBackgroundColor = CupertinoColors.white,
    this.iconColor = CupertinoColors.black,
    this.leading,
  })  : assert(() {
          if (results == null && getResults == null ||
              results != null && getResults != null) {
            throw AssertionError(
                'Either provide a function to get the results, or the results.');
          }

          return true;
        }()),
        super(key: key);

  final String? placeholder;

  final List<CupertinoSearchResult<T>>? results;
  final CupertinoResultsFinder? getResults;
  final CupertinoSearchFilter<T>? filter;
  final CupertinoSearchSort<T>? sort;
  final int limit;
  final ValueChanged<T>? onSelect;
  final OnSubmit? onSubmit;
  final Color barBackgroundColor;
  final Color iconColor;
  final Widget? leading;

  @override
  _CupertinoSearchState<T> createState() => _CupertinoSearchState<T>();
}

class _CupertinoSearchState<T> extends State<CupertinoSearch> {
  bool _loading = false;
  List<CupertinoSearchResult<T>> _results = [];

  String _criteria = '';
  TextEditingController _controller = TextEditingController();

  _filter(dynamic v, String c) {
    return v
        .toString()
        .toLowerCase()
        .trim()
        .contains(RegExp(r'' + c.toLowerCase().trim() + ''));
  }

  @override
  void initState() {
    super.initState();

    if (widget.getResults != null) {
      _getResultsDebounced();
    }

    _controller.addListener(() {
      setState(() {
        _criteria = _controller.value.text;
        if (widget.getResults != null) {
          _getResultsDebounced();
        }
      });
    });
  }

  Timer? _resultsTimer;
  Future _getResultsDebounced() async {
    if (_results.length == 0) {
      setState(() {
        _loading = true;
      });
    }

    if (_resultsTimer != null && _resultsTimer!.isActive) {
      _resultsTimer!.cancel();
    }

    _resultsTimer = Timer(Duration(milliseconds: 400), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = true;
      });

      //TODO: debounce widget.results too
      var results = await widget.getResults!(_criteria);

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _results = results as List<CupertinoSearchResult<T>>;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _resultsTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var results =
        (widget.results ?? _results).where((CupertinoSearchResult result) {
      if (widget.filter != null) {
        return widget.filter!(result.value, _criteria);
      }
      //only apply default filter if used the `results` option
      //because getResults may already have applied some filter if `filter` option was omited.
      else if (widget.results != null) {
        return _filter(result.value, _criteria);
      }

      return true;
    }).toList();

    if (widget.sort != null) {
      results.sort((a, b) => widget.sort!(a.value, b.value, _criteria));
    }

    results = results.take(widget.limit).toList();

    // IconThemeData iconTheme = CupertinoTheme.of(context).iconTheme.copyWith(color: widget.iconColor);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: widget.leading,
        backgroundColor: widget.barBackgroundColor,
        //  iconTheme: iconTheme,
        middle: CupertinoTextField(
          controller: _controller,
          autofocus: true,
          // decoration: new InputDecoration.collapsed(hintText: widget.placeholder),
          style: CupertinoTheme.of(context).textTheme.textStyle,
          onSubmitted: (String value) {
            if (widget.onSubmit != null) {
              widget.onSubmit!(value);
            }
          },
        ),
        trailing: _criteria.length == 0
            ? null
            : CupertinoButton(
                child: Icon(CupertinoIcons.clear),
                onPressed: () {
                  setState(() {
                    _controller.text = _criteria = '';
                  });
                }),
      ),
      child: _loading
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: CupertinoActivityIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                children: results.map((CupertinoSearchResult result) {
                  return CupertinoButton(
                    onPressed: () => widget.onSelect!(result.value),
                    child: result,
                  );
                }).toList(),
              ),
            ),
    );
  }
}

class _CupertinoSearchPageRoute<T> extends CupertinoPageRoute<T> {
  _CupertinoSearchPageRoute({
    required WidgetBuilder builder,
    RouteSettings settings: const RouteSettings(),
    maintainState: true,
    bool fullscreenDialog: false,
  }) : super(
            builder: builder,
            settings: settings,
            maintainState: maintainState,
            fullscreenDialog: fullscreenDialog);
}

class CupertinoSearchInput<T> extends StatefulWidget {
  CupertinoSearchInput({
    Key? key,
    required this.onSaved,
    required this.validator,
    required this.placeholder,
    required this.formatter,
    required this.results,
    required this.getResults,
    required this.filter,
    required this.sort,
    required this.onSelect,
  });

  final FormFieldSetter<T> onSaved;
  final FormFieldValidator<T> validator;
  final String placeholder;
  final FormFieldFormatter<T> formatter;

  final List<CupertinoSearchResult<T>> results;
  final CupertinoResultsFinder getResults;
  final CupertinoSearchFilter<T> filter;
  final CupertinoSearchSort<T> sort;
  final ValueChanged<T> onSelect;

  @override
  _CupertinoSearchInputState<T> createState() =>
      new _CupertinoSearchInputState<T>();
}

class _CupertinoSearchInputState<T> extends State<CupertinoSearchInput<T>> {
  GlobalKey<FormFieldState<T>> _formFieldKey =
      new GlobalKey<FormFieldState<T>>();

  _buildCupertinoSearchPage(BuildContext context) {
    return _CupertinoSearchPageRoute<T>(
        settings: RouteSettings(
          name: 'cupertino_search',
        ),
        builder: (BuildContext context) {
          return CupertinoSearch<T>(
            placeholder: widget.placeholder,
            results: widget.results,
            getResults: widget.getResults,
            filter: widget.filter,
            sort: widget.sort,
            onSelect: (dynamic value) => Navigator.of(context).pop(value),
          );
        });
  }

  _showCupertinoSearch(BuildContext context) {
    Navigator.of(context)
        .push(_buildCupertinoSearchPage(context))
        .then((dynamic value) {
      if (value != null) {
        _formFieldKey.currentState?.didChange(value);
        widget.onSelect(value);
      }
    });
  }

  bool _isEmpty(field) {
    return field.value == null;
  }

  Widget build(BuildContext context) {
    final TextStyle valueStyle =
        CupertinoTheme.of(context).textTheme.actionTextStyle; //.subhead;

    return CupertinoButton(
      onPressed: () => _showCupertinoSearch(context),
      child: FormField<T>(
        key: _formFieldKey,
        validator: widget.validator,
        onSaved: widget.onSaved,
        autovalidateMode: AutovalidateMode.always,
        builder: (FormFieldState<T> field) {
          return Container(
            /* baseStyle: valueStyle,
            isEmpty: _isEmpty(field),
            decoration: new Container(
              labelStyle: _isEmpty(field) ? null : valueStyle,
              labelText: widget.placeholder,
              errorText: field.errorText,
            ), */
            child: _isEmpty(field)
                ? null
                : Text(
                    widget.formatter != null
                        ? widget.formatter(field.value!)
                        : field.value.toString(),
                    style: valueStyle),
          );
        },
      ),
    );
  }
}
