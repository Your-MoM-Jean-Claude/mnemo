import Foundation

enum BundledLists {

    static func all() -> [WordList] {
        [
            makeList(name: "CZ → EN · Greetings",  raw: raw_CZ_Greetings),
            makeList(name: "CZ → EN · Verbs",       raw: raw_CZ_Verbs),
            makeList(name: "CZ → EN · Adjectives",  raw: raw_CZ_Adjectives),
            makeList(name: "CZ → EN · Nouns",       raw: raw_CZ_Nouns),
            makeList(name: "CZ → EN · Phrases",     raw: raw_CZ_Phrases),
            makeList(name: "DE → EN · Greetings",   raw: raw_DE_Greetings),
            makeList(name: "DE → EN · Verbs",       raw: raw_DE_Verbs),
            makeList(name: "DE → EN · Adjectives",  raw: raw_DE_Adjectives),
            makeList(name: "DE → EN · Nouns",       raw: raw_DE_Nouns),
            makeList(name: "DE → EN · Phrases",     raw: raw_DE_Phrases),
            makeList(name: "ES → EN · Greetings",   raw: raw_ES_Greetings),
            makeList(name: "ES → EN · Verbs",       raw: raw_ES_Verbs),
            makeList(name: "ES → EN · Adjectives",  raw: raw_ES_Adjectives),
            makeList(name: "ES → EN · Nouns",       raw: raw_ES_Nouns),
            makeList(name: "ES → EN · Phrases",     raw: raw_ES_Phrases),
            makeList(name: "FR → EN · Greetings",   raw: raw_FR_Greetings),
            makeList(name: "FR → EN · Verbs",       raw: raw_FR_Verbs),
            makeList(name: "FR → EN · Adjectives",  raw: raw_FR_Adjectives),
            makeList(name: "FR → EN · Nouns",       raw: raw_FR_Nouns),
            makeList(name: "FR → EN · Phrases",     raw: raw_FR_Phrases),
        ]
    }

    private static func makeList(name: String, raw: String) -> WordList {
        let pairs: [WordPair] = raw
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                let s = line.trimmingCharacters(in: .whitespaces)
                guard !s.isEmpty, !s.hasPrefix("#") else { return nil }
                guard let range = s.range(of: " - ") else { return nil }
                return WordPair(
                    front: String(s[s.startIndex..<range.lowerBound]),
                    back:  String(s[range.upperBound...])
                )
            }
        return WordList(name: name, pairs: pairs)
    }

    // MARK: - CZ → EN

    private static let raw_CZ_Greetings = """
ahoj / čau - hi / hello
nazdar / zdar - hey
sbohem / čau - bye / goodbye
měj se - take care
díky / děkuji - thanks / thank you
na zdraví - cheers
prosím - please
promiň - sorry
promiňte / s dovolením - excuse me
žádný problém - no problem
není zač - you're welcome
jo / jep - yeah / yep
ne / nene - nope / nah
jasně - sure
dobře / okay - okay
v pohodě - alright
samozřejmě - of course
absolutně - absolutely
přesně - exactly
totálně - totally
určitě - definitely
možná - maybe
pravděpodobně - probably
myslím, že jo - I think so
nevím - I don't know
myslím tím - I mean
víš co - you know
jako (výplňkové slovo) - like (filler)
no - well
takže - so
každopádně - anyway
vlastně - actually
v podstatě - basically
upřímně - honestly
vážně - seriously
doslova - literally
že jo? - right?
nějak - kind of
tak nějak - sort of
trochu - a bit
hodně - a lot
opravdu - really
velmi - very
docela - pretty / quite
celkem - quite
jen / prostě - just
dokonce - even
hej - hey (exclamation)
fakt? - really? (question)
super - cool / great
"""

    private static let raw_CZ_Verbs = """
dostat / sehnat - get
jít - go
přijít / přijet - come
chtít - want
potřebovat - need
vědět / znát - know
myslet / přemýšlet - think
vidět - see
koukat / dívat se - look
říct / říkat - say
říct / sdělit - tell
zeptat se - ask
dát / dávat - give
vzít / brát - take
udělat / dělat - make / do
mít - have
pracovat - work
cítit - feel
zkusit / snažit se - try
používat - use
najít - find
zavolat / volat - call
mluvit / povídat - talk
čekat - wait
pomoci / pomáhat - help
nechat / dovolit - let
zachovat / udržet - keep
začít - start
skončit / zastavit - stop
běžet - run
otočit - turn
pohnout se / přesunout - move
poflakovat se / trávit čas - hang out
relaxovat / odpočívat - chill
chytit / vzít - grab
chytit - catch
chybět / zmeškat - miss
ukázat - show
zkontrolovat - check
opravit - fix
rozbít - break
ztratit - lose
zapomenout - forget
vzpomenout si - remember
pochopit / rozumět - understand
stát se - happen
záležet - matter
starat se - care
znamenat - mean
hádat / odhadnout - guess
"""

    private static let raw_CZ_Adjectives = """
dobrý / fajn - good
špatný / blbý - bad
velký - big
malý / malinký - small / little
horký - hot
studený / chladný - cold
nový - new
starý - old
snadný / lehký - easy
těžký / obtížný - hard / difficult
rychlý - fast / quick
pomalý - slow
super / hustý - cool
úžasný / bomba - awesome
skvělý / výborný - great
fajn / pěkný - nice
fajn / v pořádku - fine
okay / dobré - okay
unavený - tired
zaneprázdněný / vytíženej - busy
volný - free
připravený - ready
špatně / blbě - wrong
správně / správný - right
vtipný / legrační - funny
divný / podivný - weird
bláznivý / šílený - crazy
nudný / otravný - boring
zajímavý - interesting
neuvěřitelný / úžasný - amazing
hrozný / příšerný - terrible
nemocný - sick
bez peněz / na mizině - broke
hlasitý - loud
tichý / potichu - quiet
opilý / namol - drunk
šťastný / radostný - happy
smutný - sad
naštvaný / rozzlobený - angry
nervózní - nervous
nadšený / vzrušený - excited
znuděný / otrávený - bored
hladový - hungry
sytý / najedený - full (after eating)
pozdě - late
brzy / předčasně - early
stejný - same
jiný / odlišný - different
otevřený - open
zavřený - closed
"""

    private static let raw_CZ_Nouns = """
věci / krámy - stuff
věc - thing
chlap / typ - guy
holka / slečna - girl
dítě / děti - kid / kids
kamarád / přítel - friend
kámoš / brácha - buddy / mate
šéf / nadřízený - boss
práce / zaměstnání - job / work
peníze / prachy - money
telefon / mobil - phone
auto / vůz - car
dům / domov - house / home
místo - place
čas - time
den - day
noc - night
způsob / cesta - way
jídlo - food
pití / nápoj - drink
párty / mejdan - party
zábava / sranda - fun
vtip / žert - joke
problém - problem
plán - plan
nápad / myšlenka - idea
smysl / bod - point
dohoda / deal - deal
bordel / nepořádek - mess
šance / příležitost - chance
novinky / zprávy - news
život - life
svět - world
lidi / lidé - people
hlava - head
mysl / myšlenky - mind
srdce - heart
ruka - hand
oko - eye
obličej / tvář - face
slovo - word
příběh - story
chvíle / moment - moment
výlet / cesta - trip
hra - game
tým - team
skóre / výsledek - score
tah / krok - move (a move)
atmosféra / vibe - vibe
nálada - mood
"""

    private static let raw_CZ_Phrases = """
Co je? / Co nového? - what's up?
Co se děje? - what's going on?
Jak se máš? / Jak to jde? - how's it going?
Dlouho jsme se neviděli - long time no see
Nevadí / to nic - never mind
Nějak ne! / Ty jo! - no way!
Fakt? / Vážně? - for real?
Panebože / Ježíšmarjá - oh my god / OMG
No tak! / Prosím tě! - come on!
Počkej chvíli / Moment - hang on / hold on
To je v pohodě - that's fine
To je super / To je hustý - that's cool
To je na nic / To nasává - that sucks
No jo / Budiž - fair enough
Moje chyba / Sorry - my bad
Abych byl upřímný - to be honest
Aspoň - at least
Taky / Také - as well / too
Jsem fajn / Je mi dobře - I'm good
Mám hotovo / Skončil jsem - I'm done
Jdeme! / Jdem! - let's go
Jen do toho / Směle - go ahead
Mimochodem - by the way
Cestou / Na cestě - on the way
Hned teď / Okamžitě - right away
Celý den - all day
Nic extra / Maličkost - no big deal
Velká věc - a big deal
Co k sakru? - what the hell?
Co to má být? / Co blbneš? - what the heck?
Seryózně? / Ty vole! - shut up! (surprise)
Ty brečíš? / Vážně? - no kidding!
To myslíš vážně? / Žertuješ? - are you kidding?
Dej mi pokoj / Nech toho - give me a break
Za chvilku / Za minutku - in a minute
Hned jsem zpátky - back in a sec
Uvidíme se / Čau pak - catch you later
Měj se / Klid - take it easy
Tak dál / Nevzdávej to - keep it up
Dobrá práce / Výborně - good job / well done
Abych byl fér - to be fair
Abych to upřesnil - to be clear
Vyřízeno / Jasně - you got it
Jdu tam / Jsem na cestě - on my way
Řeším to / Starám se o to - I'm on it
Udělej mi laskavost - do me a favor
Určitě / Stoprocentně - for sure
Zatím je to dobré - so far so good
Záleží na situaci - it depends
Dej mi vědět / Ozvi se - let me know
"""

    // MARK: - DE → EN

    private static let raw_DE_Greetings = """
hallo / hi - hi / hello
hey - hey
tschüss / ciao - bye / goodbye
pass auf dich auf - take care
danke / danke schön - thanks / thank you
prost / zum Wohl - cheers
bitte - please
Entschuldigung / sorry - sorry / excuse me
macht nichts - no problem
bitte sehr / gern geschehen - you're welcome
ja / jup - yeah / yep
nein / nö - nope / nah
klar / sicher - sure
okay - okay
alles gut / alles klar - alright
natürlich - of course
absolut - absolutely
genau - exactly
total - totally
definitiv / auf jeden Fall - definitely
vielleicht - maybe
wahrscheinlich - probably
ich glaube schon - I think so
keine Ahnung / weiß nicht - I don't know
ich meine - I mean
weißt du - you know
halt (Füllwort) - like (filler)
naja - well
also - so
jedenfalls - anyway
eigentlich - actually
im Grunde - basically
ehrlich gesagt - honestly
ernsthaft - seriously
buchstäblich - literally
oder? - right?
irgendwie - kind of
so halbwegs - sort of
ein bisschen - a bit
viel - a lot
wirklich - really
sehr - very
ziemlich - pretty / quite
recht - quite
nur / einfach - just
sogar - even
hey! - hey (exclamation)
echt? - really? (question)
super - cool / great
krass - crazy / wow
"""

    private static let raw_DE_Verbs = """
kriegen / bekommen - get
gehen - go
kommen - come
wollen - want
brauchen - need
wissen / kennen - know
denken / überlegen - think
sehen - see
schauen / gucken - look
sagen - say
erzählen / sagen - tell
fragen - ask
geben - give
nehmen - take
machen - make / do
haben - have
arbeiten - work
fühlen - feel
versuchen - try
benutzen / verwenden - use
finden - find
anrufen / rufen - call
reden / sprechen - talk
warten - wait
helfen - help
lassen - let
behalten - keep
anfangen / starten - start
aufhören / stoppen - stop
rennen / laufen - run
drehen / umdrehen - turn
bewegen / verschieben - move
abhängen / rumhängen - hang out
chillen - chill
schnappen / greifen - grab
fangen - catch
verpassen / fehlen - miss
zeigen - show
checken / prüfen - check
reparieren / fixen - fix
kaputt machen / brechen - break
verlieren - lose
vergessen - forget
sich erinnern - remember
verstehen - understand
passieren / geschehen - happen
ausmachen / wichtig sein - matter
sich kümmern - care
meinen / bedeuten - mean
raten / schätzen - guess
"""

    private static let raw_DE_Adjectives = """
gut / toll - good
schlecht / mies - bad
groß - big
klein / winzig - small / little
heiß - hot
kalt - cold
neu - new
alt - old
einfach / leicht - easy
schwer / schwierig - hard / difficult
schnell - fast / quick
langsam - slow
cool / geil - cool
krass / hammer - awesome
super / klasse - great
nett / schön - nice
okay / in Ordnung - fine
okay - okay
müde - tired
beschäftigt - busy
frei - free
bereit / fertig - ready
falsch - wrong
richtig - right
witzig / lustig - funny
komisch / seltsam - weird
verrückt / irre - crazy
langweilig - boring
interessant - interesting
unglaublich / fantastisch - amazing
schrecklich / furchtbar - terrible
krank - sick
pleite / blank - broke
laut - loud
leise / ruhig - quiet
betrunken / besoffen - drunk
glücklich / froh - happy
traurig - sad
wütend / sauer - angry
nervös - nervous
aufgeregt - excited
gelangweilt - bored
hungrig - hungry
satt - full (after eating)
spät - late
früh - early
gleich / selbe - same
anders / verschieden - different
offen / auf - open
geschlossen / zu - closed
"""

    private static let raw_DE_Nouns = """
Zeug / Kram - stuff
Ding / Sache - thing
Typ / Kerl - guy
Mädchen / Mädel - girl
Kind / Kinder - kid / kids
Freund / Kumpel - friend
Kumpel / Alter - buddy / mate
Chef / Boss - boss
Job / Arbeit - job / work
Kohle / Geld - money
Handy / Telefon - phone
Auto / Wagen - car
Haus / Zuhause - house / home
Ort / Platz - place
Zeit - time
Tag - day
Nacht - night
Weg / Art - way
Essen / Futter - food
Getränk / Drink - drink
Party / Feier - party
Spaß / Gaudi - fun
Witz - joke
Problem / Probleme - problem
Plan - plan
Idee - idea
Sinn / Punkt - point
Deal / Abmachung - deal
Chaos / Durcheinander - mess
Chance / Gelegenheit - chance
Neuigkeiten / News - news
Leben - life
Welt - world
Leute / Menschen - people
Kopf - head
Verstand / Gedanken - mind
Herz - heart
Hand - hand
Auge - eye
Gesicht - face
Wort - word
Geschichte - story
Moment / Augenblick - moment
Ausflug / Reise - trip
Spiel - game
Team - team
Punktestand / Score - score
Zug / Move - move (a move)
Vibe / Stimmung - vibe
Stimmung / Laune - mood
"""

    private static let raw_DE_Phrases = """
Was geht ab? / Na, wie läuft's? - what's up?
Was ist los? / Was geht? - what's going on?
Wie läuft's? / Wie geht's? - how's it going?
Lange nicht gesehen - long time no see
Vergiss es / Schon gut - never mind
Auf keinen Fall! / Nie! - no way!
Echt? / Wirklich? - for real?
Oh mein Gott / OMG - oh my god / OMG
Komm schon! / Los! - come on!
Warte mal / Moment - hang on / hold on
Das ist okay / Ist gut - that's fine
Das ist cool / Das ist geil - that's cool
Das ist ätzend / Das nervt - that sucks
Naja, okay / Schon gut - fair enough
Mein Fehler / Sorry - my bad
Ehrlich gesagt - to be honest
Wenigstens / Zumindest - at least
Auch / Ebenfalls - as well / too
Mir geht's gut - I'm good
Ich bin fertig - I'm done
Los geht's! / Auf geht's! - let's go
Nur zu / Mach schon - go ahead
Übrigens / Ach ja - by the way
Auf dem Weg - on the way
Sofort / Gleich - right away
Den ganzen Tag - all day
Kein großes Ding / Halb so wild - no big deal
Eine große Sache - a big deal
Was zum Teufel? / Was soll das? - what the hell?
Was zur Hölle? / Ey! - what the heck?
Hör auf! / Quatsch! (Überraschung) - shut up! (surprise)
Nicht dein Ernst! / Ehrlich? - no kidding!
Machst du Witze? / Verarschst du mich? - are you kidding?
Lass mich in Ruhe / Hör auf - give me a break
In einer Minute - in a minute
Bin gleich zurück - back in a sec
Bis später / Tschüss erstmal - catch you later
Chill mal / Entspann dich - take it easy
Weiter so! / Mach weiter! - keep it up
Gute Arbeit / Toll gemacht - good job / well done
Fairerweise gesagt - to be fair
Um es klar zu stellen - to be clear
Verstanden / Wird gemacht - you got it
Ich bin auf dem Weg - on my way
Ich kümmere mich drum - I'm on it
Tu mir einen Gefallen - do me a favor
Auf jeden Fall / Sicher - for sure
Bisher läuft's gut - so far so good
Kommt drauf an - it depends
Sag mir Bescheid / Meld dich - let me know
"""

    // MARK: - ES → EN

    private static let raw_ES_Greetings = """
hola / buenas - hi / hello
hey / oye - hey
adiós / chao - bye / goodbye
cuídate - take care
gracias / muchas gracias - thanks / thank you
salud - cheers
por favor - please
lo siento / perdón - sorry / excuse me
no hay problema - no problem
de nada - you're welcome
sí / ajá - yeah / yep
no / nel - nope / nah
claro / seguro - sure
okay / bueno - okay
está bien - alright
por supuesto - of course
absolutamente - absolutely
exactamente - exactly
totalmente - totally
definitivamente - definitely
quizás / tal vez - maybe
probablemente - probably
creo que sí - I think so
no sé / ni idea - I don't know
o sea / quiero decir - I mean
ya sabes - you know
como (muletilla) - like (filler)
bueno - well
entonces - so
de todas formas - anyway
en realidad - actually
básicamente - basically
honestamente - honestly
en serio - seriously
literalmente - literally
¿verdad? / ¿no? - right?
algo así - kind of
más o menos - sort of
un poco - a bit
mucho - a lot
de verdad / realmente - really
muy - very
bastante - pretty / quite
solo - just
incluso - even
¡oye! - hey (exclamation)
¿en serio? - really? (question)
guay / chévere - cool / great
loco / genial - crazy / awesome
"""

    private static let raw_ES_Verbs = """
conseguir / obtener - get
ir - go
venir - come
querer - want
necesitar - need
saber / conocer - know
pensar / creer - think
ver - see
mirar / ver - look
decir - say
contar / decir - tell
preguntar - ask
dar - give
tomar / coger - take
hacer - make / do
tener - have
trabajar - work
sentir / sentirse - feel
intentar / tratar - try
usar / utilizar - use
encontrar - find
llamar - call
hablar / platicar - talk
esperar - wait
ayudar - help
dejar / permitir - let
mantener / guardar - keep
empezar / comenzar - start
parar / detener - stop
correr - run
voltear / girar - turn
mover / moverse - move
salir / juntarse - hang out
relajarse - chill
agarrar / tomar - grab
atrapar / coger - catch
extrañar / perder - miss
mostrar / enseñar - show
revisar / checar - check
arreglar / reparar - fix
romper - break
perder - lose
olvidar - forget
recordar - remember
entender / comprender - understand
pasar / ocurrir - happen
importar - matter
significar / querer decir - mean
adivinar - guess
"""

    private static let raw_ES_Adjectives = """
bueno / bien - good
malo / mal - bad
grande - big
pequeño / chico - small / little
caliente / caluroso - hot
frío - cold
nuevo - new
viejo / antiguo - old
fácil - easy
difícil / duro - hard / difficult
rápido - fast / quick
lento - slow
chido / cool / guay - cool
increíble / alucinante - awesome
genial / estupendo - great
lindo / chulo - nice
bien / okay - fine
okay - okay
cansado - tired
ocupado - busy
libre - free
listo / preparado - ready
equivocado / mal - wrong
correcto / bien - right
chistoso / gracioso - funny
raro / extraño - weird
loco / demente - crazy
aburrido - boring
interesante - interesting
increíble / alucinante - amazing
terrible / horrible - terrible
enfermo / malito - sick
sin dinero / pelado - broke
ruidoso / escandaloso - loud
callado / tranquilo - quiet
borracho / tomado - drunk
feliz / contento - happy
triste - sad
enojado / molesto - angry
nervioso - nervous
emocionado - excited
aburrido - bored
hambriento / con hambre - hungry
lleno / satisfecho - full (after eating)
tarde - late
temprano - early
mismo / igual - same
diferente / distinto - different
abierto - open
cerrado - closed
"""

    private static let raw_ES_Nouns = """
cosas / chivas - stuff
cosa / cosita - thing
tipo / chavo - guy
chica / chava - girl
niño / niños - kid / kids
amigo / cuate - friend
cuate / mano - buddy / mate
jefe / patrón - boss
trabajo / chamba - job / work
dinero / lana - money
celular / móvil - phone
carro / coche - car
casa / hogar - house / home
lugar / sitio - place
tiempo / rato - time
día - day
noche - night
forma / manera - way
comida / manjar - food
bebida / trago - drink
fiesta / reventón - party
diversión / relajo - fun
chiste / broma - joke
problema / lío - problem
plan - plan
idea / ocurrencia - idea
punto / sentido - point
trato / deal - deal
desmadre / desastre - mess
oportunidad / chance - chance
noticias / novedades - news
vida - life
mundo - world
gente / personas - people
cabeza - head
mente / cabeza - mind
corazón - heart
mano - hand
ojo - eye
cara / rostro - face
palabra - word
historia / cuento - story
momento / rato - moment
viaje / trip - trip
juego - game
equipo - team
marcador / score - score
movida / movimiento - move (a move)
vibra / onda - vibe
humor / ánimo - mood
"""

    private static let raw_ES_Phrases = """
¿Qué onda? / ¿Qué pasa? - what's up?
¿Qué está pasando? - what's going on?
¿Cómo va? / ¿Cómo andas? - how's it going?
Cuánto tiempo sin verte - long time no see
No importa / Olvídalo - never mind
¡Para nada! / ¡De ninguna manera! - no way!
¿De verdad? / ¿En serio? - for real?
Dios mío / OMG - oh my god / OMG
¡Vamos! / ¡Ándale! - come on!
Espera / Momento - hang on / hold on
Está bien / No hay problema - that's fine
Qué chido / Qué cool - that's cool
Qué malo / Qué feo - that sucks
Está bien / Justo - fair enough
Fue mi culpa / Sorry - my bad
Para ser honesto / Siendo sincero - to be honest
Al menos / Por lo menos - at least
También / Igualmente - as well / too
Estoy bien / Todo bien - I'm good
Ya terminé - I'm done
¡Vámonos! / ¡Vamos! - let's go
Adelante / Dale - go ahead
Por cierto / A propósito - by the way
En camino / De paso - on the way
Ahora mismo / De inmediato - right away
Todo el día - all day
No es para tanto - no big deal
Es un asunto importante - a big deal
¿Qué carajos? / ¿Qué demonios? - what the hell?
¿Qué rayos? / ¿Pero qué? - what the heck?
¡Cállate! (sorpresa) / ¡No me digas! - shut up! (surprise)
¡No puede ser! / ¡En serio! - no kidding!
¿Estás bromeando? / ¿Me tomas el pelo? - are you kidding?
Dame un respiro / Déjame - give me a break
En un minuto - in a minute
Ahorita vuelvo - back in a sec
Nos vemos / Hasta luego - catch you later
Tómatelo con calma - take it easy
Sigue así / Adelante - keep it up
Buen trabajo / Bien hecho - good job / well done
Para ser justo / Siendo objetivos - to be fair
Para ser claro - to be clear
Entendido / Trato hecho - you got it
Voy en camino - on my way
Ya lo tengo / Me encargo - I'm on it
Hazme un favor - do me a favor
Claro que sí / Sin duda - for sure
Hasta ahora bien - so far so good
Depende - it depends
Avísame / Dime - let me know
"""

    // MARK: - FR → EN

    private static let raw_FR_Greetings = """
salut / bonjour - hi / hello
hé / coucou - hey
au revoir / salut - bye / goodbye
prends soin de toi - take care
merci / merci beaucoup - thanks / thank you
santé / tchin - cheers
s'il te plaît / s'il vous plaît - please
désolé / pardon - sorry / excuse me
pas de problème - no problem
de rien / je vous en prie - you're welcome
ouais / ouep - yeah / yep
non / nan - nope / nah
bien sûr - sure
d'accord / okay - okay
ça va - alright
évidemment - of course
absolument - absolutely
exactement - exactly
totalement - totally
définitivement / carrément - definitely
peut-être - maybe
probablement - probably
je crois que oui - I think so
je sais pas / aucune idée - I don't know
je veux dire - I mean
tu vois - you know
genre (filler) - like (filler)
ben - well
donc / alors - so
de toute façon - anyway
en fait - actually
en gros / fondamentalement - basically
honnêtement - honestly
sérieusement / franchement - seriously
littéralement - literally
n'est-ce pas? / hein? - right?
un peu - kind of
à peu près / plutôt - sort of
un peu - a bit
beaucoup - a lot
vraiment - really
très - very
assez / plutôt - pretty / quite
juste - just
même - even
hé! - hey (exclamation)
vraiment? - really? (question)
super / génial - cool / great
dingue / ouf - crazy / awesome
"""

    private static let raw_FR_Verbs = """
obtenir / avoir - get
aller - go
venir - come
vouloir - want
avoir besoin - need
savoir / connaître - know
penser / réfléchir - think
voir - see
regarder / voir - look
dire - say
dire / raconter - tell
demander - ask
donner - give
prendre - take
faire - make / do
avoir - have
travailler / bosser - work
sentir / ressentir - feel
essayer - try
utiliser / user - use
trouver - find
appeler - call
parler / causer - talk
attendre - wait
aider - help
laisser - let
garder - keep
commencer / démarrer - start
arrêter / stopper - stop
courir - run
tourner - turn
bouger / déplacer - move
traîner / sortir - hang out
se détendre / kiffer - chill
attraper / saisir - grab
attraper - catch
manquer - miss
montrer - show
vérifier / checker - check
réparer / arranger - fix
casser - break
perdre - lose
oublier - forget
se souvenir / rappeler - remember
comprendre - understand
se passer / arriver - happen
importer / compter - matter
s'en ficher / tenir à - care
vouloir dire / signifier - mean
deviner - guess
"""

    private static let raw_FR_Adjectives = """
bon / bien - good
mauvais / nul - bad
grand / gros - big
petit - small / little
chaud - hot
froid - cold
nouveau / neuf - new
vieux / ancien - old
facile / simple - easy
difficile / dur - hard / difficult
rapide / vite - fast / quick
lent - slow
cool / sympa - cool
incroyable / ouf - awesome
super / génial - great
sympa / joli - nice
bien / ça va - fine
okay - okay
fatigué / crevé - tired
occupé - busy
libre - free
prêt - ready
faux / mauvais - wrong
correct / juste - right
drôle / rigolo - funny
bizarre / chelou - weird
fou / dingue - crazy
ennuyeux / barbant - boring
intéressant - interesting
incroyable / fou - amazing
terrible / horrible - terrible
malade - sick
fauché / sans un rond - broke
bruyant / fort - loud
calme / silencieux - quiet
saoul / bourré - drunk
heureux / content - happy
triste - sad
en colère / énervé - angry
nerveux / stressé - nervous
excité / enthousiaste - excited
ennuyé / blasé - bored
affamé / j'ai faim - hungry
plein / repu - full (after eating)
en retard - late
tôt - early
pareil / même - same
différent - different
ouvert - open
fermé - closed
"""

    private static let raw_FR_Nouns = """
trucs / affaires - stuff
truc / chose - thing
mec / gars - guy
fille / meuf - girl
gosse / enfants - kid / kids
ami / pote - friend
pote / copain - buddy / mate
patron / boss - boss
boulot / travail - job / work
fric / argent - money
téléphone / portable - phone
voiture / bagnole - car
maison / chez soi - house / home
endroit / place - place
temps - time
jour - day
nuit - night
façon / chemin - way
nourriture / bouffe - food
boisson / verre - drink
soirée / fête - party
rigolade / fun - fun
blague / vanne - joke
problème / souci - problem
plan - plan
idée - idea
sens / intérêt - point
deal / accord - deal
bazar / foutoir - mess
chance / occasion - chance
nouvelles / infos - news
vie - life
monde - world
gens / personnes - people
tête - head
esprit / tête - mind
cœur - heart
main - hand
œil / yeux - eye
visage / tête - face
mot - word
histoire - story
moment - moment
voyage / trip - trip
jeu - game
équipe - team
score / résultat - score
move / coup - move (a move)
vibe / ambiance - vibe
humeur / mood - mood
"""

    private static let raw_FR_Phrases = """
Quoi de neuf? / Ça roule? - what's up?
Qu'est-ce qui se passe? - what's going on?
Ça va? / Comment ça va? - how's it going?
Ça fait longtemps - long time no see
Laisse tomber / Peu importe - never mind
Pas question! / Jamais! - no way!
Vraiment? / Sérieux? - for real?
Oh mon Dieu / OMG - oh my god / OMG
Allez! / Vas-y! - come on!
Attends / Une seconde - hang on / hold on
C'est bon / Pas de souci - that's fine
C'est cool / C'est sympa - that's cool
C'est nul / Ça craint - that sucks
C'est juste / Bon d'accord - fair enough
C'est ma faute / Désolé - my bad
Pour être honnête / Sincèrement - to be honest
Au moins - at least
Aussi / Également - as well / too
Je vais bien / Ça va - I'm good
J'ai fini / C'est fait - I'm done
Allons-y! / On y va! - let's go
Vas-y / Je t'en prie - go ahead
Au fait / En passant - by the way
En chemin / Sur le chemin - on the way
Tout de suite / Immédiatement - right away
Toute la journée - all day
C'est pas grave / Rien de grave - no big deal
C'est important / C'est sérieux - a big deal
Mais qu'est-ce que c'est? - what the hell?
Mais enfin! / C'est quoi ça? - what the heck?
Ta gueule! (surprise) / N'importe quoi! - shut up! (surprise)
Sans blague! / Sérieusement? - no kidding!
Tu rigoles? / Tu te fous de moi? - are you kidding?
Laisse-moi tranquille / Arrête - give me a break
Dans une minute - in a minute
Je reviens dans une seconde - back in a sec
À plus tard / Ciao - catch you later
Vas-y doucement / Détends-toi - take it easy
Continue comme ça / Bravo - keep it up
Bon boulot / Bien joué - good job / well done
Pour être juste / Honnêtement - to be fair
Pour être clair / Clairement - to be clear
C'est noté / Bien compris - you got it
Je suis en chemin - on my way
Je m'en occupe - I'm on it
Fais-moi une faveur - do me a favor
Absolument / Bien sûr - for sure
Jusqu'ici tout va bien - so far so good
Ça dépend - it depends
Tiens-moi au courant / Dis-moi - let me know
"""
}
