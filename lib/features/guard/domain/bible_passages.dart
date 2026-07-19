import 'dart:math';

import 'package:unchained/features/prayer/domain/prayers.dart';

/// Scripture passages shown on the uninstall-protection lock screen.
///
/// Each is at least ~820 characters (the lock requires copying 800) and themed
/// on the two things the user asked for: **fleeing lust / sexual immorality**
/// and **being strong / standing firm**. They are paraphrased from the ESV/KJV
/// (English), Reina-Valera (Spanish) and Almeida (Portuguese). Copying one out
/// by hand is the deliberate friction that stands between a moment of weakness
/// and uninstalling.
///
/// The three languages hold the **same five passages in the same order**, so
/// switching language mid-challenge keeps the same passage — just in a language
/// the user can actually read and pronounce.
class BiblePassages {
  const BiblePassages._();

  static final Random _random = Random();

  // Flee immorality — your body is a temple (1 Cor 6 / Rom 12 / 1 Cor 10).
  // Be strong and courageous (Joshua 1 / 1 Cor 16 / Eph 6 / Phil 4 / Isaiah 40).
  // A covenant with my eyes (Job 31 / Matthew 5 / 2 Tim 2 / Psalm 119).
  // Walk by the Spirit (Galatians 5 / Romans 13 / Colossians 3 / 1 Thess 4).
  // Steadfast under trial — a clean heart (James 1 / Psalm 119 / Psalm 51).

  static const List<String> _en = <String>[
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

  static const List<String> _es = <String>[
    'Huid de la fornicación. Cualquier otro pecado que el hombre cometa, está fuera '
        'del cuerpo; mas el que fornica, contra su propio cuerpo peca. ¿O ignoráis que '
        'vuestro cuerpo es templo del Espíritu Santo, el cual está en vosotros, el cual '
        'tenéis de Dios, y que no sois vuestros? Porque habéis sido comprados por '
        'precio; glorificad, pues, a Dios en vuestro cuerpo. Así que, hermanos, os '
        'ruego por las misericordias de Dios, que presentéis vuestros cuerpos en '
        'sacrificio vivo, santo, agradable a Dios, que es vuestro culto racional. No os '
        'conforméis a este siglo, sino transformaos por medio de la renovación de '
        'vuestro entendimiento, para que comprobéis cuál sea la buena voluntad de Dios, '
        'agradable y perfecta. No os ha sobrevenido ninguna tentación que no sea '
        'humana; pero fiel es Dios, que no os dejará ser tentados más de lo que podéis '
        'resistir, sino que dará también juntamente con la tentación la salida, para '
        'que podáis soportar.',

    'Velad, estad firmes en la fe; portaos varonilmente, y esforzaos. Todas vuestras '
        'cosas sean hechas con amor. Mira que te mando que te esfuerces y seas valiente; '
        'no temas ni desmayes, porque Jehová tu Dios estará contigo dondequiera que '
        'vayas. Por lo demás, hermanos míos, fortaleceos en el Señor, y en el poder de '
        'su fuerza. Vestíos de toda la armadura de Dios, para que podáis estar firmes '
        'contra las asechanzas del diablo. Por tanto, tomad toda la armadura de Dios, '
        'para que podáis resistir en el día malo, y habiendo acabado todo, estar firmes. '
        'Jehová es mi fortaleza y mi escudo; en él confió mi corazón, y fui ayudado. '
        'Todo lo puedo en Cristo que me fortalece. Pero los que esperan a Jehová tendrán '
        'nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; '
        'caminarán, y no se fatigarán.',

    'Hice pacto con mis ojos; ¿cómo, pues, había yo de mirar a una virgen? Oísteis que '
        'fue dicho: No cometerás adulterio. Pero yo os digo que cualquiera que mira a '
        'una mujer para codiciarla, ya adulteró con ella en su corazón. Por tanto, si tu '
        'ojo derecho te es ocasión de caer, sácalo, y échalo de ti; pues mejor te es que '
        'se pierda uno de tus miembros, y no que todo tu cuerpo sea echado al infierno. '
        'Huye también de las pasiones juveniles, y sigue la justicia, la fe, el amor y '
        'la paz, con los que de corazón limpio invocan al Señor. Honroso sea en todos el '
        'matrimonio, y el lecho sin mancilla; pero a los fornicarios y a los adúlteros '
        'los juzgará Dios. Tus ojos miren lo recto, y diríjanse tus párpados hacia lo '
        'que tienes delante. Aparta mis ojos, que no vean la vanidad; avívame en tu '
        'camino. Ordena mis pasos con tu palabra, y ninguna iniquidad se enseñoree de '
        'mí.',

    'Digo, pues: Andad en el Espíritu, y no satisfagáis los deseos de la carne. Porque '
        'el deseo de la carne es contra el Espíritu, y el del Espíritu es contra la '
        'carne; y éstos se oponen entre sí. Andemos como de día, honestamente; no en '
        'glotonerías y borracheras, no en lujurias y lascivias, no en contiendas y '
        'envidia. Mas vestíos del Señor Jesucristo, y no proveáis para los deseos de la '
        'carne. Haced morir, pues, lo terrenal en vosotros: fornicación, impureza, '
        'pasiones desordenadas, malos deseos y avaricia, que es idolatría. Pues la '
        'voluntad de Dios es vuestra santificación; que os apartéis de fornicación; que '
        'cada uno de vosotros sepa tener su propio cuerpo en santidad y honor. Mayor es '
        'el que está en vosotros, que el que está en el mundo. Echemos, pues, las obras '
        'de las tinieblas, y vistámonos las armas de la luz, y andemos como de día.',

    'Bienaventurado el varón que soporta la tentación; porque cuando haya resistido la '
        'prueba, recibirá la corona de vida. Cuando alguno es tentado, no diga que es '
        'tentado de parte de Dios; porque Dios no puede ser tentado por el mal, ni él '
        'tienta a nadie. Sino que cada uno es tentado, cuando de su propia concupiscencia '
        'es atraído y seducido. Entonces la concupiscencia, después que ha concebido, da '
        'a luz el pecado; y el pecado, siendo consumado, da a luz la muerte. ¿Con qué '
        'limpiará el joven su camino? Con guardar tu palabra. Con todo mi corazón te he '
        'buscado; no me dejes desviarme de tus mandamientos. En mi corazón he guardado '
        'tus dichos, para no pecar contra ti. Crea en mí, oh Dios, un corazón limpio, y '
        'renueva un espíritu recto dentro de mí. Vuélveme el gozo de tu salvación, y '
        'espíritu noble me sustente.',
  ];

  static const List<String> _pt = <String>[
    'Fugi da prostituição. Todo pecado que o homem comete é fora do corpo; mas o que '
        'se prostitui peca contra o seu próprio corpo. Ou não sabeis que o vosso corpo é '
        'o templo do Espírito Santo, que habita em vós, o qual tendes de Deus, e que não '
        'sois de vós mesmos? Porque fostes comprados por bom preço; glorificai, pois, a '
        'Deus no vosso corpo. Rogo-vos, pois, irmãos, pela compaixão de Deus, que '
        'apresenteis os vossos corpos em sacrifício vivo, santo e agradável a Deus, que '
        'é o vosso culto racional. E não vos conformeis com este mundo, mas transformai-'
        'vos pela renovação do vosso entendimento, para que experimenteis qual seja a '
        'boa, agradável e perfeita vontade de Deus. Não veio sobre vós tentação, senão '
        'humana; mas fiel é Deus, que não vos deixará tentar acima do que podeis, antes '
        'com a tentação dará também o escape, para que a possais suportar.',

    'Vigiai, estai firmes na fé, portai-vos varonilmente e fortalecei-vos. Todas as '
        'vossas coisas sejam feitas com amor. Não to mandei eu? Esforça-te, e tem bom '
        'ânimo; não temas, nem te espantes, porque o Senhor teu Deus é contigo por onde '
        'quer que andares. No demais, irmãos meus, fortalecei-vos no Senhor e na força '
        'do seu poder. Revesti-vos de toda a armadura de Deus, para que possais estar '
        'firmes contra as astutas ciladas do diabo. Portanto, tomai toda a armadura de '
        'Deus, para que possais resistir no dia mau e, havendo feito tudo, ficar firmes. '
        'O Senhor é a minha força e o meu escudo; nele confiou o meu coração, e fui '
        'socorrido. Posso todas as coisas naquele que me fortalece. Mas os que esperam '
        'no Senhor renovarão as suas forças; subirão com asas como águias; correrão, e '
        'não se cansarão; caminharão, e não se fatigarão.',

    'Fiz aliança com os meus olhos; como, pois, os fixaria numa virgem? Ouvistes que '
        'foi dito: Não cometerás adultério. Eu, porém, vos digo que qualquer que atentar '
        'numa mulher para a cobiçar, já em seu coração cometeu adultério com ela. '
        'Portanto, se o teu olho direito te escandalizar, arranca-o e atira-o para longe '
        'de ti; pois melhor te é que se perca um dos teus membros do que seja todo o teu '
        'corpo lançado no inferno. Foge também das paixões da mocidade, e segue a '
        'justiça, a fé, o amor e a paz com os que, de coração puro, invocam o Senhor. '
        'Venerado seja entre todos o matrimônio, e o leito sem mácula; porém aos que se '
        'prostituem e aos adúlteros Deus os julgará. Os teus olhos olhem direitos, e as '
        'tuas pálpebras olhem diretamente diante de ti. Desvia os meus olhos de '
        'contemplarem a vaidade, e vivifica-me no teu caminho.',

    'Digo, porém: Andai em Espírito, e não cumprireis a concupiscência da carne. Porque '
        'a carne cobiça contra o Espírito, e o Espírito contra a carne; e estes opõem-se '
        'um ao outro. Andemos honestamente, como de dia; não em glutonarias, nem em '
        'bebedeiras, nem em desonestidades, nem em dissoluções, nem em contendas e '
        'inveja. Mas revesti-vos do Senhor Jesus Cristo, e não tenhais cuidado da carne '
        'em suas concupiscências. Mortificai, pois, os vossos membros que estão sobre a '
        'terra: a prostituição, a impureza, o apetite desordenado, a vil concupiscência '
        'e a avareza, que é idolatria. Porque esta é a vontade de Deus, a vossa '
        'santificação: que vos abstenhais da prostituição, que cada um de vós saiba '
        'possuir o seu vaso em santificação e honra. Maior é o que está em vós do que o '
        'que está no mundo. Rejeitemos, pois, as obras das trevas, e vistamo-nos das '
        'armas da luz, e andemos como de dia.',

    'Bem-aventurado o homem que suporta a tentação; porque, quando for provado, '
        'receberá a coroa da vida. Ninguém, sendo tentado, diga: De Deus sou tentado; '
        'porque Deus não pode ser tentado pelo mal, e a ninguém tenta. Mas cada um é '
        'tentado, quando atraído e engodado pela sua própria concupiscência. Depois, '
        'havendo a concupiscência concebido, dá à luz o pecado; e o pecado, sendo '
        'consumado, gera a morte. Com que purificará o jovem o seu caminho? Observando-o '
        'conforme a tua palavra. Com todo o meu coração te busquei; não me deixes '
        'desviar dos teus mandamentos. Escondi a tua palavra no meu coração, para não '
        'pecar contra ti. Cria em mim, ó Deus, um coração puro, e renova em mim um '
        'espírito reto. Torna a dar-me a alegria da tua salvação, e sustém-me com um '
        'espírito voluntário. Então ensinarei aos transgressores os teus caminhos, e os '
        'pecadores a ti se converterão.',
  ];

  static const Map<Lang, List<String>> _byLang = <Lang, List<String>>{
    Lang.en: _en,
    Lang.es: _es,
    Lang.pt: _pt,
  };

  /// How many distinct passages exist (same count in every language).
  static int get count => _en.length;

  /// The passages in [lang], falling back to English if a language is missing.
  static List<String> forLang(Lang lang) => _byLang[lang] ?? _en;

  /// The [index]-th passage in [lang]. Guards against a bad index by falling
  /// back to the first passage so the screen can never soft-lock.
  static String at(int index, Lang lang) {
    final list = forLang(lang);
    if (index < 0 || index >= list.length) return list.first;
    return list[index];
  }

  /// A random passage index, different from [previous] when possible so a fresh
  /// attempt is not the same wall of text the user just failed. Because every
  /// language holds the same passages in the same order, the index is
  /// language-independent.
  static int randomIndex({int? previous}) {
    if (count <= 1) return 0;
    int pick;
    do {
      pick = _random.nextInt(count);
    } while (pick == previous);
    return pick;
  }
}
