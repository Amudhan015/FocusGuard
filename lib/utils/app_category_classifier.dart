import '../models/enums.dart';

/// Classifies an app into one of the six FocusGuard categories using
/// package-name heuristics, per the spec's "package name
/// heuristics/known category lists" requirement.
///
/// This is a best-effort guess, not a guarantee - the whole point of
/// `AppMeta.categoryOverride` is to let the user correct it.
///
/// KNOWN GAP (flagged during Stage 3 device testing, not yet fixed):
/// sports/simulation games like eFootball/PES don't contain "game" in
/// their package name and aren't in the curated map, so they currently
/// fall through to Other. Needs curated entries (e.g. com.konami.pesam)
/// or a broader substring rule ("efootball", "pes", "cricket",
/// "football") before this ships.
class AppCategoryClassifier {
  AppCategoryClassifier._();

  static const Map<String, AppCategory> _knownPackages = {
    'com.instagram.android': AppCategory.socialMedia,
    'com.facebook.katana': AppCategory.socialMedia,
    'com.facebook.orca': AppCategory.socialMedia,
    'com.facebook.lite': AppCategory.socialMedia,
    'com.twitter.android': AppCategory.socialMedia,
    'com.zhiliaoapp.musically': AppCategory.socialMedia,
    'com.ss.android.ugc.trill': AppCategory.socialMedia,
    'com.snapchat.android': AppCategory.socialMedia,
    'com.reddit.frontpage': AppCategory.socialMedia,
    'com.linkedin.android': AppCategory.socialMedia,
    'com.pinterest': AppCategory.socialMedia,
    'com.whatsapp': AppCategory.socialMedia,
    'com.whatsapp.w4b': AppCategory.socialMedia,
    'org.telegram.messenger': AppCategory.socialMedia,
    'com.discord': AppCategory.socialMedia,
    'com.tumblr': AppCategory.socialMedia,
    'com.bereal.ft': AppCategory.socialMedia,
    'com.google.android.apps.dynamite': AppCategory.socialMedia,

    'com.king.candycrushsaga': AppCategory.games,
    'com.supercell.clashofclans': AppCategory.games,
    'com.supercell.clashroyale': AppCategory.games,
    'com.mojang.minecraftpe': AppCategory.games,
    'com.roblox.client': AppCategory.games,
    'com.miniclip.eightballpool': AppCategory.games,
    'com.dts.freefireth': AppCategory.games,
    'com.pubg.krmobile': AppCategory.games,
    'com.tencent.ig': AppCategory.games,
    'com.activision.callofduty.shooter': AppCategory.games,
    'com.epicgames.fortnite': AppCategory.games,
    'com.gameloft.android.ANMP': AppCategory.games,
    'com.ea.gp.fifamobile': AppCategory.games,
    'com.nianticlabs.pokemongo': AppCategory.games,
    'com.konami.pesam': AppCategory.games,
    'com.konami.efootball': AppCategory.games,

    'com.netflix.mediaclient': AppCategory.entertainment,
    'com.google.android.youtube': AppCategory.entertainment,
    'com.spotify.music': AppCategory.entertainment,
    'com.amazon.avod.thirdpartyclient': AppCategory.entertainment,
    'in.startv.hotstar': AppCategory.entertainment,
    'com.jio.media.jiobeats': AppCategory.entertainment,
    'com.gaana': AppCategory.entertainment,
    'com.google.android.apps.youtube.music': AppCategory.entertainment,
    'com.twitch.android.app': AppCategory.entertainment,
    'tv.twitch.android.app': AppCategory.entertainment,

    'com.google.android.apps.docs': AppCategory.studyProductivity,
    'com.google.android.apps.docs.editors.docs': AppCategory.studyProductivity,
    'com.google.android.apps.docs.editors.sheets': AppCategory.studyProductivity,
    'com.google.android.apps.docs.editors.slides': AppCategory.studyProductivity,
    'com.microsoft.office.word': AppCategory.studyProductivity,
    'com.microsoft.office.excel': AppCategory.studyProductivity,
    'com.microsoft.office.powerpoint': AppCategory.studyProductivity,
    'com.microsoft.office.officehubrow': AppCategory.studyProductivity,
    'com.microsoft.onenote': AppCategory.studyProductivity,
    'us.zoom.videomeetings': AppCategory.studyProductivity,
    'com.google.android.apps.classroom': AppCategory.studyProductivity,
    'com.google.android.apps.meetings': AppCategory.studyProductivity,
    'com.evernote': AppCategory.studyProductivity,
    'notion.id': AppCategory.studyProductivity,
    'com.khanacademy.android': AppCategory.studyProductivity,
    'org.geogebra.android': AppCategory.studyProductivity,
    'com.desmos.calculator': AppCategory.studyProductivity,
    'com.wolfram.android.alpha': AppCategory.studyProductivity,
    'com.anki.android': AppCategory.studyProductivity,
    'com.ichi2.anki': AppCategory.studyProductivity,

    'com.android.settings': AppCategory.utilities,
    'com.android.dialer': AppCategory.utilities,
    'com.google.android.dialer': AppCategory.utilities,
    'com.android.mms': AppCategory.utilities,
    'com.google.android.apps.messaging': AppCategory.utilities,
    'com.android.calculator2': AppCategory.utilities,
    'com.google.android.calculator': AppCategory.utilities,
    'com.android.calendar': AppCategory.utilities,
    'com.google.android.calendar': AppCategory.utilities,
    'com.android.camera2': AppCategory.utilities,
    'com.google.android.gallery3d': AppCategory.utilities,
    'com.google.android.apps.maps': AppCategory.utilities,
    'com.android.chrome': AppCategory.utilities,
    'com.google.android.gm': AppCategory.utilities,
    'com.google.android.apps.photos': AppCategory.utilities,
  };

  static const List<MapEntry<String, AppCategory>> _substringRules = [
    MapEntry('game', AppCategory.games),
    MapEntry('casino', AppCategory.games),
    MapEntry('puzzle', AppCategory.games),
    MapEntry('poker', AppCategory.games),
    MapEntry('chess', AppCategory.games),
    MapEntry('efootball', AppCategory.games),
    MapEntry('pes', AppCategory.games),
    MapEntry('fifa', AppCategory.games),
    MapEntry('cricket', AppCategory.games),
    MapEntry('football', AppCategory.games),

    MapEntry('social', AppCategory.socialMedia),
    MapEntry('chat', AppCategory.socialMedia),
    MapEntry('messenger', AppCategory.socialMedia),
    MapEntry('dating', AppCategory.socialMedia),

    MapEntry('video', AppCategory.entertainment),
    MapEntry('music', AppCategory.entertainment),
    MapEntry('stream', AppCategory.entertainment),
    MapEntry('movie', AppCategory.entertainment),
    MapEntry('radio', AppCategory.entertainment),
    MapEntry('podcast', AppCategory.entertainment),

    MapEntry('office', AppCategory.studyProductivity),
    MapEntry('note', AppCategory.studyProductivity),
    MapEntry('pdf', AppCategory.studyProductivity),
    MapEntry('study', AppCategory.studyProductivity),
    MapEntry('school', AppCategory.studyProductivity),
    MapEntry('edu', AppCategory.studyProductivity),
    MapEntry('dictionary', AppCategory.studyProductivity),
    MapEntry('translat', AppCategory.studyProductivity),

    MapEntry('settings', AppCategory.utilities),
    MapEntry('launcher', AppCategory.utilities),
    MapEntry('fileexplorer', AppCategory.utilities),
    MapEntry('filemanager', AppCategory.utilities),
    MapEntry('camera', AppCategory.utilities),
    MapEntry('gallery', AppCategory.utilities),
    MapEntry('contacts', AppCategory.utilities),
    MapEntry('dialer', AppCategory.utilities),
    MapEntry('browser', AppCategory.utilities),
    MapEntry('weather', AppCategory.utilities),
    MapEntry('bank', AppCategory.utilities),
    MapEntry('wallet', AppCategory.utilities),
  ];

  static AppCategory classify(String packageName) {
    final knownMatch = _knownPackages[packageName];
    if (knownMatch != null) return knownMatch;

    final lowerPackage = packageName.toLowerCase();
    for (final rule in _substringRules) {
      if (lowerPackage.contains(rule.key)) return rule.value;
    }

    return AppCategory.other;
  }
}
