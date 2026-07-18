// Christian prayer content in three languages (English, Spanish, Portuguese)
// shown on the prayer gate. Pure data — no Flutter, no I/O — so it's trivially
// editable and testable. Guides are BUILT for a given language (and, for the
// Rosary, a set of mysteries) by the builders at the bottom.

/// The three supported languages.
enum Lang { en, es, pt }

Lang langFromCode(String? code) => switch (code) {
      'en' => Lang.en,
      'pt' => Lang.pt,
      _ => Lang.es,
    };

/// A localized string: the text in each language.
typedef L10n = Map<Lang, String>;

String tr(L10n m, Lang lang) => m[lang] ?? m[Lang.es] ?? m.values.first;

/// A single block of the guided prayer: a short heading and the words to pray.
class PrayerStep {
  const PrayerStep(this.heading, this.body);
  final String heading;
  final String body;
}

/// A named prayer guide (a sequence of steps to pray through), already resolved
/// to one language.
class PrayerGuide {
  const PrayerGuide(
      this.type, this.title, this.minutes, this.minMinutes, this.steps);

  /// Stored on each PrayerLog row: 'rosary' | 'thanksgiving'.
  final String type;
  final String title;

  /// Full session length, in minutes (the countdown).
  final int minutes;

  /// Minimum minutes prayed before the finish button unlocks. Equal to
  /// [minutes] for the Rosary (no early exit — you pray the whole thing).
  final int minMinutes;

  final List<PrayerStep> steps;
}

/// The Rosary's session lengths are fixed regardless of language/mysteries.
int fullMinutesFor(String type) => type == 'thanksgiving' ? 5 : 20;
int minMinutesFor(String type) => type == 'thanksgiving' ? 2 : 20;

// --- Core prayers ---------------------------------------------------------

const _signOfCross = {
  Lang.es: 'En el nombre del Padre, y del Hijo, y del Espíritu Santo. Amén.',
  Lang.en: 'In the name of the Father, and of the Son, and of the Holy '
      'Spirit. Amen.',
  Lang.pt: 'Em nome do Pai, e do Filho, e do Espírito Santo. Amém.',
};

const _ourFather = {
  Lang.es: 'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; '
      'venga a nosotros tu reino; hágase tu voluntad en la tierra como en el '
      'cielo. Danos hoy nuestro pan de cada día; perdona nuestras ofensas, como '
      'también nosotros perdonamos a los que nos ofenden; no nos dejes caer en '
      'la tentación, y líbranos del mal. Amén.',
  Lang.en: 'Our Father, who art in heaven, hallowed be thy name; thy kingdom '
      'come; thy will be done on earth as it is in heaven. Give us this day our '
      'daily bread, and forgive us our trespasses, as we forgive those who '
      'trespass against us; and lead us not into temptation, but deliver us '
      'from evil. Amen.',
  Lang.pt: 'Pai nosso que estais nos céus, santificado seja o vosso nome; '
      'venha a nós o vosso reino; seja feita a vossa vontade, assim na terra '
      'como no céu. O pão nosso de cada dia nos dai hoje; perdoai-nos as nossas '
      'ofensas, assim como nós perdoamos a quem nos tem ofendido; e não nos '
      'deixeis cair em tentação, mas livrai-nos do mal. Amém.',
};

const _hailMary = {
  Lang.es: 'Dios te salve, María, llena eres de gracia, el Señor es contigo. '
      'Bendita tú eres entre todas las mujeres, y bendito es el fruto de tu '
      'vientre, Jesús. Santa María, Madre de Dios, ruega por nosotros, '
      'pecadores, ahora y en la hora de nuestra muerte. Amén.',
  Lang.en: 'Hail Mary, full of grace, the Lord is with thee. Blessed art thou '
      'among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, '
      'Mother of God, pray for us sinners, now and at the hour of our death. '
      'Amen.',
  Lang.pt: 'Ave Maria, cheia de graça, o Senhor é convosco. Bendita sois vós '
      'entre as mulheres, e bendito é o fruto do vosso ventre, Jesus. Santa '
      'Maria, Mãe de Deus, rogai por nós pecadores, agora e na hora da nossa '
      'morte. Amém.',
};

const _gloryBe = {
  Lang.es: 'Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el '
      'principio, ahora y siempre, por los siglos de los siglos. Amén.',
  Lang.en: 'Glory be to the Father, and to the Son, and to the Holy Spirit. As '
      'it was in the beginning, is now, and ever shall be, world without end. '
      'Amen.',
  Lang.pt: 'Glória ao Pai, e ao Filho, e ao Espírito Santo. Como era no '
      'princípio, agora e sempre, pelos séculos dos séculos. Amém.',
};

// Said at the end of each mystery, BEFORE the Fátima prayer.
const _oMaria = {
  Lang.es: 'Oh María, concebida sin pecado, ruega por nosotros que recurrimos '
      'a Ti.',
  Lang.en: 'O Mary, conceived without sin, pray for us who have recourse to '
      'thee.',
  Lang.pt: 'Ó Maria, concebida sem pecado, rogai por nós que recorremos a Vós.',
};

const _fatima = {
  Lang.es: 'Oh Jesús mío, perdónanos nuestros pecados, líbranos del fuego del '
      'infierno, lleva al cielo a todas las almas, especialmente a las más '
      'necesitadas de tu misericordia.',
  Lang.en: 'O my Jesus, forgive us our sins, save us from the fires of hell; '
      'lead all souls to Heaven, especially those in most need of Thy mercy.',
  Lang.pt: 'Ó meu Jesus, perdoai-nos, livrai-nos do fogo do inferno; levai as '
      'almas todas para o Céu, principalmente as que mais precisarem da vossa '
      'misericórdia.',
};

const _creed = {
  Lang.es: 'Creo en Dios, Padre todopoderoso, Creador del cielo y de la '
      'tierra. Creo en Jesucristo, su único Hijo, nuestro Señor, que fue '
      'concebido por obra del Espíritu Santo, nació de Santa María Virgen, '
      'padeció bajo el poder de Poncio Pilato, fue crucificado, muerto y '
      'sepultado, descendió a los infiernos, al tercer día resucitó de entre '
      'los muertos, subió a los cielos y está sentado a la derecha de Dios, '
      'Padre todopoderoso. Creo en el Espíritu Santo, la santa Iglesia '
      'católica, la comunión de los santos, el perdón de los pecados, la '
      'resurrección de la carne y la vida eterna. Amén.',
  Lang.en: 'I believe in God, the Father almighty, Creator of heaven and '
      'earth, and in Jesus Christ, his only Son, our Lord, who was conceived by '
      'the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, '
      'was crucified, died and was buried; he descended into hell; on the third '
      'day he rose again from the dead; he ascended into heaven and is seated '
      'at the right hand of God the Father almighty. I believe in the Holy '
      'Spirit, the holy catholic Church, the communion of saints, the '
      'forgiveness of sins, the resurrection of the body, and life everlasting. '
      'Amen.',
  Lang.pt: 'Creio em Deus Pai todo-poderoso, criador do céu e da terra; e em '
      'Jesus Cristo, seu único Filho, nosso Senhor, que foi concebido pelo '
      'poder do Espírito Santo, nasceu da Virgem Maria, padeceu sob Pôncio '
      'Pilatos, foi crucificado, morto e sepultado; desceu à mansão dos '
      'mortos; ressuscitou ao terceiro dia; subiu aos céus e está sentado à '
      'direita de Deus Pai todo-poderoso. Creio no Espírito Santo, na santa '
      'Igreja Católica, na comunhão dos santos, na remissão dos pecados, na '
      'ressurreição da carne e na vida eterna. Amém.',
};

const _hailHolyQueen = {
  Lang.es: 'Dios te salve, Reina y Madre de misericordia, vida, dulzura y '
      'esperanza nuestra; Dios te salve. A ti clamamos los desterrados hijos '
      'de Eva; a ti suspiramos, gimiendo y llorando, en este valle de '
      'lágrimas. Ea, pues, Señora, abogada nuestra, vuelve a nosotros esos tus '
      'ojos misericordiosos. Amén.',
  Lang.en: 'Hail, holy Queen, Mother of mercy, our life, our sweetness and our '
      'hope. To thee do we cry, poor banished children of Eve; to thee do we '
      'send up our sighs, mourning and weeping in this valley of tears. Turn '
      'then, most gracious advocate, thine eyes of mercy toward us. Amen.',
  Lang.pt: 'Salve, Rainha, Mãe de misericórdia, vida, doçura e esperança '
      'nossa, salve! A vós bradamos os degredados filhos de Eva; a vós '
      'suspiramos, gemendo e chorando neste vale de lágrimas. Eia, pois, '
      'advogada nossa, esses vossos olhos misericordiosos a nós volvei. Amém.',
};

// --- Section headings -----------------------------------------------------

const _hSign = {Lang.es: 'Señal de la Cruz', Lang.en: 'Sign of the Cross', Lang.pt: 'Sinal da Cruz'};
const _hCreed = {Lang.es: 'Credo', Lang.en: "Apostles' Creed", Lang.pt: 'Credo'};
const _hOurFather = {Lang.es: 'Padre Nuestro', Lang.en: 'Our Father', Lang.pt: 'Pai Nosso'};
const _hThreeHail = {Lang.es: 'Tres Avemarías (fe, esperanza y caridad)', Lang.en: 'Three Hail Marys (faith, hope, charity)', Lang.pt: 'Três Ave-Marias (fé, esperança e caridade)'};
const _hTenHail = {Lang.es: 'Diez Avemarías', Lang.en: 'Ten Hail Marys', Lang.pt: 'Dez Ave-Marias'};
const _hGloryFatima = {Lang.es: 'Gloria y jaculatoria', Lang.en: 'Glory Be and Fátima Prayer', Lang.pt: 'Glória e jaculatória'};
const _hSalve = {Lang.es: 'Salve', Lang.en: 'Hail, Holy Queen', Lang.pt: 'Salve Rainha'};
const _hThanks = {Lang.es: 'Acción de gracias', Lang.en: 'Thanksgiving', Lang.pt: 'Ação de graças'};
const _mysteryWord = {Lang.es: 'misterio', Lang.en: 'mystery', Lang.pt: 'mistério'};
const _decadeHint = {
  Lang.es: 'Contempla este misterio mientras rezas un Padre Nuestro, diez '
      'Avemarías y un Gloria.',
  Lang.en: 'Contemplate this mystery while you pray one Our Father, ten Hail '
      'Marys and a Glory Be.',
  Lang.pt: 'Contempla este mistério enquanto rezas um Pai Nosso, dez '
      'Ave-Marias e um Glória.',
};

// --- The four sets of mysteries -------------------------------------------

/// One set of mysteries (Joyful / Sorrowful / Glorious / Luminous), each with
/// its localized set name and five localized mystery titles.
class MysterySet {
  const MysterySet(this.type, this.name, this.mysteries);
  final String type;
  final L10n name;
  final List<L10n> mysteries;
}

const gozosos = MysterySet(
  'gozosos',
  {Lang.es: 'Misterios Gozosos', Lang.en: 'Joyful Mysteries', Lang.pt: 'Mistérios Gozosos'},
  [
    {Lang.es: 'La anunciación del ángel a la Virgen Nuestra Señora', Lang.en: 'The Annunciation of the angel to the Virgin Mary', Lang.pt: 'A anunciação do anjo à Virgem Nossa Senhora'},
    {Lang.es: 'La visitación de Nuestra Señora a su prima santa Isabel', Lang.en: 'The Visitation of Our Lady to her cousin Saint Elizabeth', Lang.pt: 'A visitação de Nossa Senhora à sua prima santa Isabel'},
    {Lang.es: 'El nacimiento del Hijo de Dios en Belén', Lang.en: 'The Nativity of the Son of God in Bethlehem', Lang.pt: 'O nascimento do Filho de Deus em Belém'},
    {Lang.es: 'La presentación de Jesús en el Templo', Lang.en: 'The Presentation of Jesus in the Temple', Lang.pt: 'A apresentação de Jesus no Templo'},
    {Lang.es: 'El Niño Dios perdido y hallado en el Templo', Lang.en: 'The Child Jesus lost and found in the Temple', Lang.pt: 'O Menino Deus perdido e achado no Templo'},
  ],
);

const dolorosos = MysterySet(
  'dolorosos',
  {Lang.es: 'Misterios Dolorosos', Lang.en: 'Sorrowful Mysteries', Lang.pt: 'Mistérios Dolorosos'},
  [
    {Lang.es: 'La oración de Jesús en el Huerto', Lang.en: 'The Agony of Jesus in the Garden', Lang.pt: 'A oração de Jesus no Horto'},
    {Lang.es: 'La flagelación del Señor', Lang.en: 'The Scourging at the Pillar', Lang.pt: 'A flagelação'},
    {Lang.es: 'La coronación de espinas', Lang.en: 'The Crowning with Thorns', Lang.pt: 'A coroação de espinhos'},
    {Lang.es: 'Jesús con la cruz a cuestas', Lang.en: 'Jesus carrying the Cross', Lang.pt: 'Jesus com a cruz às costas'},
    {Lang.es: 'Jesús muere en la cruz', Lang.en: 'Jesus dies on the Cross', Lang.pt: 'Jesus morre na cruz'},
  ],
);

const gloriosos = MysterySet(
  'gloriosos',
  {Lang.es: 'Misterios Gloriosos', Lang.en: 'Glorious Mysteries', Lang.pt: 'Mistérios Gloriosos'},
  [
    {Lang.es: 'La resurrección del Señor', Lang.en: 'The Resurrection of the Lord', Lang.pt: 'A ressurreição do Senhor'},
    {Lang.es: 'La ascensión de Jesús al cielo', Lang.en: 'The Ascension of Jesus into Heaven', Lang.pt: 'A ascensão de Jesus ao céu'},
    {Lang.es: 'La venida del Espíritu Santo', Lang.en: 'The Descent of the Holy Spirit', Lang.pt: 'A vinda do Espírito Santo'},
    {Lang.es: 'La asunción de Nuestra Señora', Lang.en: 'The Assumption of Our Lady', Lang.pt: 'A assunção de Nossa Senhora'},
    {Lang.es: 'La coronación de María Santísima', Lang.en: 'The Coronation of Mary Most Holy', Lang.pt: 'A coroação de Maria Santíssima'},
  ],
);

const luminosos = MysterySet(
  'luminosos',
  {Lang.es: 'Misterios Luminosos', Lang.en: 'Luminous Mysteries', Lang.pt: 'Mistérios Luminosos'},
  [
    {Lang.es: 'El bautismo en el Jordán', Lang.en: 'The Baptism in the Jordan', Lang.pt: 'O batismo no Jordão'},
    {Lang.es: 'La autorrevelación en las bodas de Caná', Lang.en: 'The self-revelation at the wedding of Cana', Lang.pt: 'A autorrevelação nas bodas de Caná'},
    {Lang.es: 'El anuncio del reino de Dios con invitación a la conversión', Lang.en: 'The proclamation of the Kingdom of God with the call to conversion', Lang.pt: 'O anúncio do reino de Deus com convite à conversão'},
    {Lang.es: 'La transfiguración', Lang.en: 'The Transfiguration', Lang.pt: 'A transfiguração'},
    {Lang.es: 'La institución de la Eucaristía', Lang.en: 'The Institution of the Eucharist', Lang.pt: 'A instituição da Eucaristia'},
  ],
);

const allMysterySets = [gozosos, dolorosos, gloriosos, luminosos];

/// The mysteries traditionally prayed on a given weekday (DateTime.weekday:
/// Mon=1 … Sun=7): Joyful Mon/Sat, Sorrowful Tue/Fri, Glorious Wed/Sun,
/// Luminous Thu.
MysterySet mysterySetForWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
    case DateTime.saturday:
      return gozosos;
    case DateTime.tuesday:
    case DateTime.friday:
      return dolorosos;
    case DateTime.thursday:
      return luminosos;
    default: // Wednesday, Sunday
      return gloriosos;
  }
}

MysterySet mysterySetByType(String type) =>
    allMysterySets.firstWhere((s) => s.type == type, orElse: () => gozosos);

// --- Guide builders -------------------------------------------------------

const _rosaryTitle = {Lang.es: 'Santo Rosario', Lang.en: 'Holy Rosary', Lang.pt: 'Santo Rosário'};
const _thanksTitle = {Lang.es: 'Acción de Gracias', Lang.en: 'Thanksgiving', Lang.pt: 'Ação de Graças'};

const _ordinals = {
  Lang.es: ['Primer', 'Segundo', 'Tercer', 'Cuarto', 'Quinto'],
  Lang.en: ['First', 'Second', 'Third', 'Fourth', 'Fifth'],
  Lang.pt: ['Primeiro', 'Segundo', 'Terceiro', 'Quarto', 'Quinto'],
};

/// Build the Rosary for [lang], meditating on [set]'s five mysteries.
PrayerGuide buildRosary(Lang lang, MysterySet set) {
  final steps = <PrayerStep>[
    PrayerStep(tr(_hSign, lang), tr(_signOfCross, lang)),
    PrayerStep(tr(_hCreed, lang), tr(_creed, lang)),
    PrayerStep(tr(_hOurFather, lang), tr(_ourFather, lang)),
    PrayerStep(tr(_hThreeHail, lang), tr(_hailMary, lang)),
    PrayerStep(tr(_hGloryFatima, lang), tr(_gloryBe, lang)),
  ];
  for (var i = 0; i < 5; i++) {
    final ord = _ordinals[lang]![i];
    final mystery = tr(set.mysteries[i], lang);
    steps.add(PrayerStep(
      '$ord ${tr(_mysteryWord, lang)}: $mystery',
      tr(_decadeHint, lang),
    ));
    steps.add(PrayerStep(tr(_hOurFather, lang), tr(_ourFather, lang)));
    steps.add(PrayerStep(tr(_hTenHail, lang), tr(_hailMary, lang)));
    steps.add(PrayerStep(
      tr(_hGloryFatima, lang),
      '${tr(_gloryBe, lang)}\n\n${tr(_oMaria, lang)}\n\n${tr(_fatima, lang)}',
    ));
  }
  steps.add(PrayerStep(tr(_hSalve, lang), tr(_hailHolyQueen, lang)));
  return PrayerGuide('rosary', tr(_rosaryTitle, lang), 20, 20, steps);
}

const _psalm100 = {
  Lang.es: 'Aclamad a Dios con alegría, habitantes de toda la tierra; servid al '
      'Señor con gozo, entrad en su presencia con cánticos. Reconoced que el '
      'Señor es Dios: Él nos hizo y somos suyos. Entrad por sus puertas con '
      'acción de gracias. Porque el Señor es bueno, su misericordia es eterna.',
  Lang.en: 'Shout for joy to the Lord, all the earth. Worship the Lord with '
      'gladness; come before him with joyful songs. Know that the Lord is God. '
      'It is he who made us, and we are his. Enter his gates with thanksgiving. '
      'For the Lord is good and his love endures forever.',
  Lang.pt: 'Aclamai o Senhor, ó terra inteira; servi ao Senhor com alegria, '
      'entrai na sua presença com cânticos. Reconhecei que o Senhor é Deus: Ele '
      'nos fez e somos dele. Entrai por suas portas com ação de graças. Porque '
      'o Senhor é bom, eterna é a sua misericórdia.',
};

const _psalm23 = {
  Lang.es: 'El Señor es mi pastor, nada me falta: en verdes praderas me hace '
      'recostar; me conduce hacia fuentes tranquilas y repara mis fuerzas. '
      'Aunque camine por cañadas oscuras, nada temo, porque tú vas conmigo.',
  Lang.en: 'The Lord is my shepherd, I lack nothing. He makes me lie down in '
      'green pastures, he leads me beside quiet waters, he refreshes my soul. '
      'Even though I walk through the darkest valley, I will fear no evil, for '
      'you are with me.',
  Lang.pt: 'O Senhor é meu pastor, nada me faltará. Em verdes pastagens me faz '
      'repousar; para as águas tranquilas me conduz e restaura as minhas '
      'forças. Ainda que eu ande por vales tenebrosos, nada temerei, pois estás '
      'comigo.',
};

const _thanksClosing = {
  Lang.es: 'Gracias te doy, Dios mío, por tu amor y tu fidelidad. Gracias por '
      'la vida, por este día, por los que amo. En todo momento, gracias a Dios. '
      'Amén.',
  Lang.en: 'I thank you, my God, for your love and faithfulness. Thank you for '
      'life, for this day, for those I love. In all things, thanks be to God. '
      'Amen.',
  Lang.pt: 'Eu te dou graças, meu Deus, pelo teu amor e tua fidelidade. '
      'Obrigado pela vida, por este dia, por aqueles que amo. Em tudo, graças a '
      'Deus. Amém.',
};

const _psalm100Head = {Lang.es: 'Salmo 100', Lang.en: 'Psalm 100', Lang.pt: 'Salmo 100'};
const _psalm23Head = {Lang.es: 'Salmo 23', Lang.en: 'Psalm 23', Lang.pt: 'Salmo 23'};

/// Build the short thanksgiving guide for [lang].
PrayerGuide buildThanksgiving(Lang lang) {
  final steps = <PrayerStep>[
    PrayerStep(tr(_hSign, lang), tr(_signOfCross, lang)),
    PrayerStep(tr(_psalm100Head, lang), tr(_psalm100, lang)),
    PrayerStep(tr(_hOurFather, lang), tr(_ourFather, lang)),
    PrayerStep(tr(_psalm23Head, lang), tr(_psalm23, lang)),
    PrayerStep(tr(_hThanks, lang), tr(_thanksClosing, lang)),
    PrayerStep(tr(_hGloryFatima, lang), tr(_gloryBe, lang)),
  ];
  return PrayerGuide('thanksgiving', tr(_thanksTitle, lang), 5, 2, steps);
}

/// Build a guide by type. [set] is used only for the Rosary; when null the
/// Rosary defaults to the Joyful mysteries.
PrayerGuide buildGuide(String type, Lang lang, {MysterySet? set}) {
  if (type == 'thanksgiving') return buildThanksgiving(lang);
  return buildRosary(lang, set ?? gozosos);
}
