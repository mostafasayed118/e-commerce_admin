/// The tashkeel (diacritics) to strip from search text. Hoisted so
/// [normalizeSearchText] — which runs per record field per recompute — does
/// not recompile it on every call.
final RegExp _tashkeelRegExp = RegExp('[\u064B-\u0652\u0670]');

/// Search text normalized for matching. Arabic shoppers routinely omit
/// hamza and tashkeel, so BOTH the query and the stored text pass through
/// this before `contains` — otherwise 'ايما' would never match 'إيما' and
/// vocalized text ('كِتاب') would dodge an unvocalized query ('كتاب').
/// English text is unaffected beyond the existing lowercase.
///
/// Shared by the catalog (product name/description search) and the admin
/// orders screen (order number / customer search).
///
/// Normalizations (deliberately conservative — no ة/ه collapse, which can
/// change meaning):
///   * hamza forms أ إ آ → plain alef ا (three fixed `replaceAll`s — no regex)
///   * alef maqsura ى  → ya ي
///   * tashkeel (U+064B..U+0652, U+0670) stripped
String normalizeSearchText(String input) {
  return input
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll(_tashkeelRegExp, '');
}
