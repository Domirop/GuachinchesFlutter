import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_presenter.dart';
import 'package:http/http.dart';

class SurveyInAppPage extends StatefulWidget {
  final VoidCallback? onVoted;

  const SurveyInAppPage({Key? key, this.onVoted}) : super(key: key);

  @override
  State<SurveyInAppPage> createState() => _SurveyInAppPageState();
}

class _SurveyInAppPageState extends State<SurveyInAppPage>
    implements SurveyInAppView {
  late SurveyInAppPresenter _presenter;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<SurveyInAppChoice> _tradicionales = [];
  List<SurveyInAppChoice> _modernos = [];

  String? _selectedTradicional;
  String? _selectedModerno;

  // Previous votes (already voted)
  String? _previousTradicional;
  String? _previousModerno;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitted = false;

  // Search
  final TextEditingController _searchTradicionalCtrl = TextEditingController();
  final TextEditingController _searchModernoCtrl = TextEditingController();
  String _searchTradicional = '';
  String _searchModerno = '';

  static const Color _bgColor = Color.fromRGBO(25, 27, 32, 1);
  static const Color _cardColor = Color.fromRGBO(35, 37, 44, 1);
  static const Color _greenAccent = Color.fromRGBO(0, 255, 102, 1);
  static const Color _borderColor = Color.fromRGBO(208, 221, 255, 0.15);

  @override
  void initState() {
    super.initState();
    _presenter = SurveyInAppPresenter(HttpRemoteRepository(Client()), this);
    _presenter.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchTradicionalCtrl.dispose();
    _searchModernoCtrl.dispose();
    super.dispose();
  }

  // --- SurveyInAppView implementation ---

  @override
  void setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  @override
  void setSubmitting(bool submitting) {
    if (mounted) setState(() => _isSubmitting = submitting);
  }

  @override
  void setChoices({
    required List<SurveyInAppChoice> tradicionales,
    required List<SurveyInAppChoice> modernos,
  }) {
    if (mounted) {
      setState(() {
        _tradicionales = tradicionales;
        _modernos = modernos;
      });
    }
  }

  @override
  void setPreviousVotes({String? tradicional, String? moderno}) {
    if (mounted) {
      setState(() {
        _previousTradicional = tradicional;
        _previousModerno = moderno;
        _selectedTradicional = tradicional ?? _selectedTradicional;
        _selectedModerno = moderno ?? _selectedModerno;
      });
    }
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void onSubmitSuccess() {
    if (mounted) {
      setState(() => _submitted = true);
      widget.onVoted?.call();
    }
  }

  // --- Navigation ---

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  bool get _hasAlreadyVotedAll =>
      _previousTradicional != null && _previousModerno != null;

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Encuesta 2026',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_submitted && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / 2',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _submitted
              ? _buildSuccessScreen()
              : _hasAlreadyVotedAll
                  ? _buildAlreadyVotedScreen()
                  : _buildSurvey(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color.fromRGBO(0, 255, 102, 1)),
          SizedBox(height: 16),
          Text(
            'Cargando preguntas...',
            style: TextStyle(color: Colors.white54, fontFamily: 'SF Pro Display'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: _greenAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Gracias, por tus votos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu voto ha sido registrado correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyVotedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote, color: _greenAccent, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Ya has votado en esta encuesta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Muchas Gracias por participar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _greenAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Volver al inicio',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurvey() {
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _buildSurveyPage(
                title: 'Mejor Guachinche Tradicional',
                subtitle: 'Selecciona tu voto para GUACHINCHE TRADICIONAL',
                choices: _tradicionales,
                selectedValue: _selectedTradicional,
                alreadyVoted: _previousTradicional,
                searchController: _searchTradicionalCtrl,
                searchQuery: _searchTradicional,
                onSearchChanged: (v) =>
                    setState(() => _searchTradicional = v),
                onSelect: (value) =>
                    setState(() => _selectedTradicional = value),
              ),
              _buildSurveyPage(
                title: 'Mejor Guachinche Moderno',
                subtitle: 'Selecciona tu voto para mejor Guachinche Moderno',
                choices: _modernos,
                selectedValue: _selectedModerno,
                alreadyVoted: _previousModerno,
                searchController: _searchModernoCtrl,
                searchQuery: _searchModerno,
                onSearchChanged: (v) =>
                    setState(() => _searchModerno = v),
                onSelect: (value) =>
                    setState(() => _selectedModerno = value),
              ),
            ],
          ),
        ),
        _buildNavigation(),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(2, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i <= _currentPage ? _greenAccent : _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSurveyPage({
    required String title,
    required String subtitle,
    required List<SurveyInAppChoice> choices,
    required String? selectedValue,
    required String? alreadyVoted,
    required TextEditingController searchController,
    required String searchQuery,
    required ValueChanged<String> onSearchChanged,
    required ValueChanged<String> onSelect,
  }) {
    final bool isLocked = alreadyVoted != null;

    final filteredChoices = searchQuery.isEmpty
        ? choices
        : choices
            .where((c) =>
                c.text.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontFamily: 'SF Pro Display',
            ),
          ),
          if (isLocked) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 255, 102, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color.fromRGBO(0, 255, 102, 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: _greenAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Ya has votado en esta categoría',
                    style: TextStyle(
                      color: _greenAccent,
                      fontSize: 13,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Search bar
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            enabled: !isLocked,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SF Pro Display',
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar local...',
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontFamily: 'SF Pro Display',
              ),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      child: const Icon(Icons.close,
                          color: Colors.white38, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: const Color.fromRGBO(45, 48, 56, 1),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (choices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cargando opciones...',
                  style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'SF Pro Display'),
                ),
              ),
            )
          else if (filteredChoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No se encontraron resultados',
                  style: TextStyle(
                      color: Colors.white38,
                      fontFamily: 'SF Pro Display'),
                ),
              ),
            )
          else
            ...filteredChoices.map((choice) {
              final bool isSelected = selectedValue == choice.value;
              return GestureDetector(
                onTap: isLocked ? null : () => onSelect(choice.value),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromRGBO(0, 255, 102, 0.15)
                        : _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _greenAccent : _borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            color:
                                isSelected ? _greenAccent : Colors.white,
                            fontSize: 15,
                            fontFamily: 'SF Pro Display',
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: _greenAccent, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    final bool isLastPage = _currentPage == 1;

    // Página 1 → 2: requiere voto en Tradicional (nuevo o previo)
    final bool canGoNext =
        _selectedTradicional != null || _previousTradicional != null;

    // Enviar: requiere ambos votos (nuevos o previos)
    final bool canSubmit =
        (_selectedTradicional != null || _previousTradicional != null) &&
        (_selectedModerno != null || _previousModerno != null);

    final bool enabled = isLastPage ? canSubmit : canGoNext;

    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _goToPage(_currentPage - 1),
                child: const Text(
                  'Anterior',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? _greenAccent : Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting || !enabled
                  ? null
                  : isLastPage
                      ? _handleSubmit
                      : () => _goToPage(_currentPage + 1),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      isLastPage ? 'Enviar votos' : 'Siguiente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        color: enabled ? Colors.black : Colors.white38,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    _presenter.submitVotes(
      tradicionalValue: _selectedTradicional,
      modernoValue: _selectedModerno,
    );
  }
}
