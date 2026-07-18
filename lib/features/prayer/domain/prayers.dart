// Christian prayer content (Spanish) shown on the prayer gate while the
// 20-minute timer runs. Pure data — no Flutter, no I/O — so it's trivially
// editable and testable.

/// A single block of the guided prayer: a short heading and the words to pray.
class PrayerStep {
  const PrayerStep(this.heading, this.body);
  final String heading;
  final String body;
}

/// A named prayer guide (a sequence of steps to pray through).
class PrayerGuide {
  const PrayerGuide(this.type, this.title, this.minutes, this.steps);

  /// Stored on each PrayerLog row: 'rosary' | 'thanksgiving'.
  final String type;
  final String title;

  /// How long the gate's countdown runs for this prayer, in minutes. The
  /// Rosary is a full session; thanksgiving is meant to be short.
  final int minutes;

  final List<PrayerStep> steps;
}

// --- Core prayers ---------------------------------------------------------

const _signOfCross =
    'Por la señal de la Santa Cruz, de nuestros enemigos líbranos, Señor, '
    'Dios nuestro. En el nombre del Padre, y del Hijo, y del Espíritu Santo. '
    'Amén.';

const _ourFather =
    'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a '
    'nosotros tu reino; hágase tu voluntad en la tierra como en el cielo. '
    'Danos hoy nuestro pan de cada día; perdona nuestras ofensas, como también '
    'nosotros perdonamos a los que nos ofenden; no nos dejes caer en la '
    'tentación, y líbranos del mal. Amén.';

const _hailMary =
    'Dios te salve, María, llena eres de gracia, el Señor es contigo. Bendita '
    'tú eres entre todas las mujeres, y bendito es el fruto de tu vientre, '
    'Jesús. Santa María, Madre de Dios, ruega por nosotros, pecadores, ahora y '
    'en la hora de nuestra muerte. Amén. (Reza diez Avemarías en este misterio.)';

const _gloryBe =
    'Gloria al Padre, y al Hijo, y al Espíritu Santo. Como era en el principio, '
    'ahora y siempre, por los siglos de los siglos. Amén.';

const _creed =
    'Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra. Creo '
    'en Jesucristo, su único Hijo, nuestro Señor... que fue concebido por obra '
    'del Espíritu Santo, nació de Santa María Virgen, padeció bajo el poder de '
    'Poncio Pilato, fue crucificado, muerto y sepultado, descendió a los '
    'infiernos, al tercer día resucitó de entre los muertos... Creo en el '
    'Espíritu Santo, la santa Iglesia católica, la comunión de los santos, el '
    'perdón de los pecados, la resurrección de la carne y la vida eterna. Amén.';

const _fatima =
    'Oh Jesús mío, perdónanos nuestros pecados, líbranos del fuego del '
    'infierno, lleva al cielo a todas las almas, especialmente a las más '
    'necesitadas de tu misericordia.';

const _hailHolyQueen =
    'Dios te salve, Reina y Madre de misericordia, vida, dulzura y esperanza '
    'nuestra; Dios te salve. A ti clamamos los desterrados hijos de Eva; a ti '
    'suspiramos, gimiendo y llorando, en este valle de lágrimas. Ea, pues, '
    'Señora, abogada nuestra, vuelve a nosotros esos tus ojos misericordiosos. '
    'Amén.';

// --- The Holy Rosary ------------------------------------------------------

/// The Santo Rosario: opening prayers, then five decades, then the closing.
/// Praying it attentively fills roughly the twenty minutes of the gate.
const rosaryGuide = PrayerGuide('rosary', 'Santo Rosario', 20, [
  PrayerStep('Señal de la Cruz', _signOfCross),
  PrayerStep('Credo', _creed),
  PrayerStep('Padre Nuestro', _ourFather),
  PrayerStep('Tres Avemarías (fe, esperanza y caridad)', _hailMary),
  PrayerStep('Gloria', _gloryBe),
  PrayerStep('Primer misterio — Padre Nuestro', _ourFather),
  PrayerStep('Primer misterio — diez Avemarías', _hailMary),
  PrayerStep('Primer misterio — Gloria y jaculatoria', '$_gloryBe\n\n$_fatima'),
  PrayerStep('Segundo misterio — Padre Nuestro', _ourFather),
  PrayerStep('Segundo misterio — diez Avemarías', _hailMary),
  PrayerStep('Segundo misterio — Gloria y jaculatoria', '$_gloryBe\n\n$_fatima'),
  PrayerStep('Tercer misterio — Padre Nuestro', _ourFather),
  PrayerStep('Tercer misterio — diez Avemarías', _hailMary),
  PrayerStep('Tercer misterio — Gloria y jaculatoria', '$_gloryBe\n\n$_fatima'),
  PrayerStep('Cuarto misterio — Padre Nuestro', _ourFather),
  PrayerStep('Cuarto misterio — diez Avemarías', _hailMary),
  PrayerStep('Cuarto misterio — Gloria y jaculatoria', '$_gloryBe\n\n$_fatima'),
  PrayerStep('Quinto misterio — Padre Nuestro', _ourFather),
  PrayerStep('Quinto misterio — diez Avemarías', _hailMary),
  PrayerStep('Quinto misterio — Gloria y jaculatoria', '$_gloryBe\n\n$_fatima'),
  PrayerStep('Salve', _hailHolyQueen),
  PrayerStep('Acción de gracias',
      'Gracias, Señor, por este tiempo de oración. Dad gracias en todo, porque '
      'esta es la voluntad de Dios para con vosotros en Cristo Jesús. Amén.'),
]);

/// A shorter guide of thanksgiving — psalms and words of gratitude to God.
const thanksgivingGuide = PrayerGuide('thanksgiving', 'Acción de Gracias', 5, [
  PrayerStep('Señal de la Cruz', _signOfCross),
  PrayerStep('Salmo 100',
      'Aclamad a Dios con alegría, habitantes de toda la tierra; servid al '
      'Señor con gozo, entrad en su presencia con cánticos. Reconoced que el '
      'Señor es Dios: Él nos hizo y somos suyos, su pueblo y ovejas de su '
      'rebaño. Entrad por sus puertas con acción de gracias, por sus atrios con '
      'himnos, dadle gracias, bendecid su nombre. Porque el Señor es bueno, su '
      'misericordia es eterna, su fidelidad por todas las edades.'),
  PrayerStep('Padre Nuestro', _ourFather),
  PrayerStep('Salmo 23',
      'El Señor es mi pastor, nada me falta: en verdes praderas me hace '
      'recostar; me conduce hacia fuentes tranquilas y repara mis fuerzas. Aunque '
      'camine por cañadas oscuras, nada temo, porque tú vas conmigo. Tu bondad y '
      'tu misericordia me acompañan todos los días de mi vida.'),
  PrayerStep('Acción de gracias',
      'Gracias te doy, Dios mío, por tu amor y tu fidelidad. Gracias por la vida, '
      'por este día, por los que amo. En todo momento, gracias a Dios. Amén.'),
  PrayerStep('Gloria', _gloryBe),
]);

/// Look up a guide by its stored type; defaults to the Rosary.
PrayerGuide guideFor(String type) =>
    type == 'thanksgiving' ? thanksgivingGuide : rosaryGuide;
