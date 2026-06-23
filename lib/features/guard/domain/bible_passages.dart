import 'dart:math';

/// Scripture passages shown on the uninstall-protection lock screen.
///
/// Each is at least ~820 characters (the lock requires copying 800) and themed
/// on the two things the user
/// asked for: **fleeing lust / sexual immorality** and **being strong / standing
/// firm**. They are paraphrased from the ESV/KJV. Copying one out by hand is the
/// deliberate friction that stands between a moment of weakness and uninstalling.
class BiblePassages {
  const BiblePassages._();

  static final Random _random = Random();

  static const List<String> all = <String>[
    // Flee immorality — your body is a temple (1 Cor 6 / Rom 12 / 1 Cor 10).
    'Flee from sexual immorality. Every other sin a person commits is outside the '
        'body, but the sexually immoral person sins against his own body. Or do you '
        'not know that your body is a temple of the Holy Spirit within you, whom you '
        'have from God? You are not your own, for you were bought with a price. So '
        'glorify God in your body. I appeal to you therefore, brothers, by the mercies '
        'of God, to present your bodies as a living sacrifice, holy and acceptable to '
        'God, which is your spiritual worship. Do not be conformed to this world, but '
        'be transformed by the renewal of your mind, that by testing you may discern '
        'what is the will of God, what is good and acceptable and perfect. No '
        'temptation has overtaken you that is not common to man. God is faithful, and '
        'he will not let you be tempted beyond your ability, but with the temptation '
        'he will also provide the way of escape, that you may be able to endure it.',

    // Be strong and courageous (Joshua 1 / 1 Cor 16 / Eph 6 / Phil 4 / Isaiah 40).
    'Be watchful, stand firm in the faith, act like men, be strong. Let all that you '
        'do be done in love. Have I not commanded you? Be strong and courageous. Do '
        'not be frightened, and do not be dismayed, for the Lord your God is with you '
        'wherever you go. Finally, be strong in the Lord and in the strength of his '
        'might. Put on the whole armor of God, that you may be able to stand against '
        'the schemes of the devil. Therefore take up the whole armor of God, that you '
        'may be able to withstand in the evil day, and having done all, to stand firm. '
        'The Lord is my strength and my shield; in him my heart trusts, and I am '
        'helped. I can do all things through him who strengthens me. But they who wait '
        'for the Lord shall renew their strength; they shall mount up with wings like '
        'eagles; they shall run and not be weary; they shall walk and not faint.',

    // A covenant with my eyes (Job 31 / Matthew 5 / 2 Tim 2 / Psalm 119).
    'I have made a covenant with my eyes; how then could I gaze at a virgin? You have '
        'heard that it was said, You shall not commit adultery. But I say to you that '
        'everyone who looks at a woman with lustful intent has already committed '
        'adultery with her in his heart. If your right eye causes you to sin, tear it '
        'out and throw it away. For it is better that you lose one of your members than '
        'that your whole body be thrown into hell. So flee youthful passions and pursue '
        'righteousness, faith, love, and peace, along with those who call on the Lord '
        'from a pure heart. Let marriage be held in honor among all, and let the '
        'marriage bed be undefiled, for God will judge the sexually immoral. Let your '
        'eyes look directly forward, and your gaze be straight before you. Turn my eyes '
        'from looking at worthless things; and give me life in your ways.',

    // Walk by the Spirit (Galatians 5 / Romans 13 / Colossians 3 / 1 Thess 4).
    'But I say, walk by the Spirit, and you will not gratify the desires of the flesh. '
        'For the desires of the flesh are against the Spirit, and the desires of the '
        'Spirit are against the flesh, for these are opposed to each other. Let us walk '
        'properly as in the daytime, not in sexual immorality and sensuality, not in '
        'quarreling and jealousy. But put on the Lord Jesus Christ, and make no '
        'provision for the flesh, to gratify its desires. Put to death therefore what '
        'is earthly in you: sexual immorality, impurity, passion, evil desire, and '
        'covetousness, which is idolatry. For this is the will of God, your '
        'sanctification: that you abstain from sexual immorality; that each one of you '
        'know how to control his own body in holiness and honor. He who is in you is '
        'greater than he who is in the world. So make no provision for the flesh to '
        'gratify its desires, but cast off the works of darkness and put on the armor '
        'of light, and walk in it as children of the day.',

    // Steadfast under trial — a clean heart (James 1 / Psalm 119 / Psalm 51).
    'Blessed is the man who remains steadfast under trial, for when he has stood the '
        'test he will receive the crown of life. Let no one say when he is tempted, I '
        'am being tempted by God, for God cannot be tempted with evil, and he himself '
        'tempts no one. But each person is tempted when he is lured and enticed by his '
        'own desire. Then desire when it has conceived gives birth to sin, and sin when '
        'it is fully grown brings forth death. How can a young man keep his way pure? By '
        'guarding it according to your word. With my whole heart I seek you; let me not '
        'wander from your commandments. I have stored up your word in my heart, that I '
        'might not sin against you. Create in me a clean heart, O God, and renew a right '
        'spirit within me. Restore to me the joy of your salvation, and uphold me with '
        'a willing spirit.',
  ];

  /// A random passage, different from [previous] when possible so a fresh attempt
  /// is not the same wall of text the user just failed.
  static String random({String? previous}) {
    if (all.length == 1) return all.first;
    String pick;
    do {
      pick = all[_random.nextInt(all.length)];
    } while (pick == previous);
    return pick;
  }
}
