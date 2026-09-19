# CODEX IMPLEMENTATIEOPDRACHT --- VERSTOBBERTJE V1

## Opdracht

Werk in de bestaande Flutter-repository `JanStobbe1/hide-and-seek-app`
en bouw de huidige prototype-app door tot een consistente, testbare
V1-demo van **Verstobbertje**.

Dit Markdown-bestand is de **volledige functionele source of truth voor
deze implementatie**. Er hoeven geen Word-documenten te worden gelezen
of geüpload.

De bestaande code is alleen het technische uitgangspunt. Wanneer
bestaande code afwijkt van de specificatie hieronder, is deze
specificatie leidend.

## Prioriteitsvolgorde

Bij een tegenstrijdigheid geldt:

1.  Genummerde business rules, acceptatiecriteria en testcases in dit
    bestand.
2.  Functioneel Ontwerp V3.3 in dit bestand.
3.  Bestaande applicatie/code.

Verzin bij een echte tegenstrijdigheid of ontbrekende normatieve
spelregel **geen eigen functionele oplossing**. Noteer het als blokkade
of open punt in het eindrapport. Technische implementatiekeuzes die het
functionele gedrag niet veranderen mag je zelfstandig maken.

## Scope V1

V1 werkt uitsluitend met **punten**.

Niet implementeren als echte V1-functionaliteit:

-   echt geld;
-   wallet;
-   betaalprovider;
-   iDEAL/Tikkie;
-   bankgegevens;
-   echte uitbetalingen;
-   oude Gratis/Betaald niveau 1/2/3-abonnementen;
-   andere expliciete backlogitems die niet in de V1-business rules of
    acceptatiecriteria staan.

Implementeer geen backlogfunctionaliteit alleen omdat daarvoor al
gedeeltelijke code bestaat.

## Werkwijze --- eerst inventariseren

Voordat je functionele code wijzigt:

1.  Analyseer de huidige repository.
2.  Maak voor iedere BR en ieder AC intern de status:
    `correct aanwezig`, `gedeeltelijk`, `afwijkend` of `ontbreekt`.
3.  Hergebruik correcte bestaande code.
4.  Refactor of vervang gedrag dat conflicteert met deze specificatie.
5.  Houd domeinlogica buiten UI-widgets en maak spelregels afzonderlijk
    testbaar.
6.  Gebruik één centrale configuratielaag voor spelparameters en voorkom
    verspreide magic numbers.

Ga daarna zelfstandig door met implementeren.

## Kritieke verduidelijkingen

### Vondstpunten

Wanneer een hider wordt gevonden:

-   de **vinder** ontvangt 80% van de actuele puntenwaarde van de
    gevonden hider;
-   **iedere overige zoeker afzonderlijk** ontvangt 20% van de actuele
    puntenwaarde van de gevonden hider;
-   iedere nog actieve/niet gevonden hider krijgt **+10 punten**;
-   dit is bewust **niet zero-sum**;
-   dezelfde vondst mag nooit tweemaal worden verwerkt.

`20%` betekent dus nadrukkelijk **20% per overige zoeker**, niet een
gezamenlijke 20%-pot.

### Tijdsafbouw zoeker

Voor startwaarde `S` en totale spelduur `T` in minuten:

-   kwartfactoren: `1`, `1.5`, `2.25`, `3.375`;
-   som factoren: `8.125`;
-   basissnelheid: `r = S / ((T / 4) * 8.125)`;
-   verlies per minuut in kwartaal `q`: `r * 1.5^(q-1)`;
-   puntenwaarde wordt begrensd op minimaal `0`.

Voor `S=50`, `T=60`:

-   Q1: `0.4102564103` punt/minuut;
-   Q2: `0.6153846154`;
-   Q3: `0.9230769231`;
-   Q4: `1.3846153846`;
-   na 60 minuten zonder vondst: exact 0 binnen de afgesproken numerieke
    tolerantie.

Bereken dit op basis van **elapsed game time**, niet op het aantal
UI-timer-ticks. Backgrounding, vertraagde timers of dubbele ticks mogen
geen extra verlies veroorzaken.

### Krimpend speelveld

Krimp start op 25%, 50% en 75% van de spelduur en duurt telkens 5
minuten.

`5% krimp` betekent **5% van de actuele oppervlakte**, niet 5% van de
straal:

-   `A_nieuw = A_huidig * 0.95`;
-   bij een cirkel: `r_nieuw = r_huidig * sqrt(0.95)`;
-   na drie krimpen resteert circa `85.7375%` van de oorspronkelijke
    oppervlakte.

Het centrum mag verschuiven, maar de nieuwe zone moet volledig binnen de
huidige zone liggen. De uiteindelijke veilige zone mag dus niet vooraf
voorspelbaar zijn.

### GPS-terugkeertijd

Gebruik de afstand van de speler tot de **dichtstbijzijnde grens van de
nieuwe zone**.

`terugkeertijd = geschatte reistijd * 1.5`, begrensd op:

-   minimaal 2 minuten;
-   maximaal 10% van de totale spelduur.

De veronderstelde verplaatsingssnelheid is centraal configureerbaar op
basis van de schaal van het oorspronkelijke speelgebied.

Eén afwijkende GPS-meting mag geen eliminatie veroorzaken. Meerdere
opeenvolgende geldige metingen moeten de buiten-zone-status bevestigen.
Betrouwbare terugkeer binnen de zone stopt de countdown onmiddellijk.

### Private vragen

Alleen voor private games.

-   organisator maakt vijf persoonlijke vragen zelf of laat AI vijf
    geschikte vragen genereren;
-   iedere deelnemer beantwoordt vooraf die vijf vragen over zichzelf;
-   voor iedere deelnemer bestaat een vraagtekenlocatie;
-   eigen vraagteken is nooit zichtbaar;
-   binnen range verschijnt vraagteken met avatar + in-game naam;
-   tikken start alle vijf vragen in één sessie;
-   range verlaten na start geeft 5 seconden om terug te keren;
-   terug binnen 5 seconden: verder waar gebleven;
-   niet terug binnen 5 seconden: poging definitief mislukt voor die
    speler bij die deelnemer en vraagteken verdwijnt voor die speler;
-   status is dus per `speler × deelnemer/vraagteken`.

Punten:

-   0 goed = 0;
-   1 goed = 10;
-   2 goed = 20;
-   3 goed = 40;
-   4 goed = 60;
-   5 goed = 100.

Als een speler **alle andere deelnemers** heeft bezocht én bij iedereen
5/5 heeft, krijgt hij eenmaal **+500 punten**. Nooit dubbel toekennen.

## Architectuurverwachting

Maak minimaal afzonderlijk testbare domeincomponenten/services voor:

-   game lifecycle;
-   scoring;
-   seeker time decay;
-   finding;
-   hints;
-   private questions;
-   shrinking zone;
-   GPS/out-of-zone state;
-   location hierarchy;
-   intro invalidation/generation;
-   result calculation;
-   profile/name validation.

Timerlogica moet lifecycle-safe zijn. Voorkom dubbele
subscriptions/timers en updates na `dispose`.

## Teststrategie

De testcases verderop zijn verplicht. Voeg waar nodig extra
regressietests toe.

Minimaal aantoonbaar testen:

-   alle vier kwartalen van de puntenafbouw;
-   60-minutenvoorbeeld en minimum 0;
-   80% voor vinder;
-   20% **per** overige zoeker;
-   +10 per resterende hider;
-   dubbele vondst onmogelijk;
-   vraagpuntenstaffel;
-   +500 perfect-bonus exact eenmaal;
-   5-secondenregel bij vraagteken;
-   eigen vraagteken onzichtbaar;
-   5% oppervlaktekrimp;
-   nieuwe zone volledig binnen oude zone;
-   GPS false spike;
-   min/max terugkeertijd;
-   join op 5:00 versus 5:01;
-   afhankelijke locatiekeuze;
-   wijziging provincie reset ongeldige stad/buurt;
-   stale AI-intro regression;
-   eerder gemelde clipping van `Naam van het spel` en `Land(en)`.

Gebruik unit tests voor domeinregels en widget/integration tests waar
UI-gedrag anders niet betrouwbaar bewezen kan worden.

## Verplichte kwaliteitsgate

Voordat je meldt dat de implementatie klaar is:

1.  format alle gewijzigde Dart-bestanden;
2.  voer `flutter analyze` uit;
3.  voer `flutter test` uit;
4.  voer `flutter build web` uit;
5.  voer alle nieuw toegevoegde relevante tests uit;
6.  controleer dat geen P0-acceptatiecriterium onbehandeld is.

Een succesvolle build alleen is geen bewijs dat de functionaliteit
correct werkt.

Meld de taak niet als voltooid wanneer analyze, tests of build falen.

## Git / PR / deployment

-   Werk op een aparte branch.
-   Maak een reviewbare PR.
-   Merge **niet** zelfstandig naar `main`.
-   Deploy **niet** zelfstandig naar productie.
-   Laat de PR eerst beoordelen.

## Verplicht eindrapport

Rapporteer na implementatie:

-   branchnaam;
-   commit SHA;
-   PR;
-   gewijzigde bestanden;
-   geïmplementeerde BR-nummers;
-   AC-nummers die aantoonbaar slagen;
-   toegevoegde tests;
-   resultaten van format/analyze/test/build;
-   resterende bekende beperkingen;
-   requirements die technisch niet volledig uitvoerbaar bleken;
-   expliciete bevestiging dat geen backlogfunctionaliteit onbedoeld is
    meegenomen.

Maak geen claims over geslaagde functionaliteit zonder test- of
verificatiebasis.

------------------------------------------------------------------------

# DEEL A --- FUNCTIONEEL ONTWERP V3.3

# Verstobbertje - Functioneel Ontwerp V3.3

Werk-FO voor de eerste speelbare puntenversie

Gebaseerd op het eerdere prijzenblad, de verbeterdocumenten, de
ingevulde vragenlijst, Puntenblad(1) en de daaropvolgende functionele
keuzes.

## 1. Doel en scope

Verstobbertje is een locatiegebaseerd verstop- en zoekspel. Spelers
nemen deel als zoeker of hider binnen een vooraf bepaald speelgebied en
een vaste speeltijd. Tijd, locatie, het vinden van hiders, persoonlijke
opdrachten en het krimpende speelveld zorgen ervoor dat deelnemers
actief moeten blijven bewegen en keuzes moeten maken.

V3 maakt één belangrijke productkeuze expliciet: de eerste speelbare
versie werkt uitsluitend met punten. Financiële functionaliteit valt
buiten de scope van V1 en wordt beheerd op de afzonderlijke backlog.
Hints kosten in V1 punten en spelresultaten leveren punten op.

| Onderdeel \| Regel V1 \| Status / opmerking \|

| --- \| --- \| --- \|

| V1 \| Punten, spelmechaniek, private vragen, hints, krimpend
  speelveld, profiel/onboarding, vrienden, locatie en uitslag. \|
  Leidend voor demo. \|

## 2. Speltypen

### 2.1 Openbaar spel

Een openbaar spel is bedoeld voor deelnemers die elkaar niet
noodzakelijk kennen. Persoonlijke vragen over deelnemers maken geen deel
uit van dit speltype.

### 2.2 Privéspel

Een privéspel is bedoeld voor bijvoorbeeld vrienden, familie of
collega's. Naast de normale spelmechaniek kan de organisator de
persoonlijke vragenfunctie activeren. De organisator stelt vijf vragen
op of laat AI vijf geschikte vragen genereren. Deelnemers beantwoorden
vóór de start de vijf vragen over zichzelf; deze antwoorden vormen de
waarheid voor het spel.

## 3. Spel aanmaken en locatie

-   De velden 'Naam van het spel' en 'Land(en)' moeten volledig
    zichtbaar zijn en mogen niet worden afgesneden.

-   Locatiekeuze volgt Land → Provincie → Stad → Wijk en ondersteunt
    meerdere keuzes per niveau.

-   Bij land bestaat geen optie 'Alle'. Bij provincie betekent 'Alle'
    alle provincies binnen het gekozen land; bij stad alle steden binnen
    de gekozen provincie(s); bij wijk alle wijken binnen de gekozen
    stad/steden.

-   Een onderliggend niveau kan pas worden gekozen als het bovenliggende
    niveau geldig is gekozen.

-   Bij wijziging van provincie worden bestaande stad- en wijkkeuzes
    gereset; ongeldige combinaties mogen nooit blijven bestaan.

-   Keuzelijsten zijn doorzoekbaar en filteren tijdens het typen.

## 4. Introductie en AI

-   De introductie gebruikt minimaal de naam van het spel, de regio en
    de opzetter van het spel.

-   Er zijn minimaal tien inhoudelijk verschillende AI-varianten voordat
    herhaling acceptabel is.

-   Wanneer een eerdere spelinstelling wordt gewijzigd, verdwijnt een
    eerder door AI gegenereerde intro zodat de organisator bewust
    opnieuw genereert of zelf tekst schrijft.

-   Een handmatig geschreven introductie blijft bij zo'n wijziging
    staan.

-   Oude locatiegegevens of andere verouderde spelinstellingen mogen
    niet terugkomen in een nieuwe AI-intro.

## 5. Deelname en spelstatus

-   Een aangemaakt spel verschijnt direct bij beschikbare spellen.

-   Deelname blijft mogelijk tot en met exact 5:00 minuten na de start.
    Vanaf 5:01 is deelname gesloten.

-   Een gestart spel waaraan iemand niet heeft deelgenomen wordt voor
    die persoon onzichtbaar en komt niet in diens afgeronde spellen.

-   Onder 'Ik speel al mee met' staan actieve spellen én spellen
    waarvoor de gebruiker zich heeft aangemeld maar die nog niet zijn
    gestart.

-   Een spel eindigt zodra de speeltijd 0 bereikt, alle hiders zijn
    gevonden, of alle zoekers zijn uitgeschakeld.

-   Bij einde spel verandert de status in alle relevante schermen naar
    afgerond.

-   De persoonlijke uitslag verschijnt automatisch één keer per sessie
    en blijft daarna vanuit het afgeronde spel opvraagbaar via
    bijvoorbeeld Uitslag.

## 6. Informatie tijdens het spel

-   Compacte spelinformatie toont resterende uren/minuten; een live
    seconde-countdown is daar niet nodig.

-   Voor hiders wordt gevonden weergegeven als: aantal gevonden hiders /
    totaal aantal hiders.

-   Voor een zoeker wordt daarnaast persoonlijk weergegeven: aantal door
    mij gevonden hiders / totaal aantal gevonden hiders.

-   De speler ziet zijn actuele punten-/spelwaarde en of hij zich binnen
    het actuele speelgebied bevindt.

-   Waar relevant worden ook het aantal zoekers en het aantal hiders
    afzonderlijk getoond.

## 7. Krimpend speelveld

Het krimpende speelveld is een kernmechaniek om passief deelnemen te
voorkomen en de spanning gedurende het spel op te voeren.

-   Het oorspronkelijke maximale speelgebied is vooraf bekend. De
    uiteindelijke eindzone is vooraf niet bekend, maar blijft altijd
    binnen deze oorspronkelijke range.

-   Na ieder kwart van de totale speeltijd start een krimpfase.

-   Tijdens een krimpfase krimpt het actuele speelgebied in vijf minuten
    met 5%.

-   De toegestane tijd om weer binnen het nieuwe gebied te komen is
    dynamisch en houdt rekening met zowel de totale speelduur als de
    omvang van het oorspronkelijke speelgebied. De verplaatsing moet
    realistisch uitvoerbaar zijn.

-   Een groot gebied, bijvoorbeeld heel Nederland, vereist dus ruimere
    verplaatstijd dan een klein lokaal gebied. Tegelijk mag de
    toegestane tijd niet zo lang zijn dat bij een kort spel de spelduur
    feitelijk wordt opgeheven.

-   Een speler die langer dan de dynamisch bepaalde toegestane tijd
    buiten het actuele speelgebied blijft, wordt uitgeschakeld.

Het deel van het oorspronkelijke speelveld dat door de krimp niet meer
actief is, wordt op de kaart grijs weergegeven. Het actieve deel behoudt
zijn normale kleur.

Een speler die buiten het actuele speelgebied staat maar nog binnen de
terugkeertijd zit, krijgt een duidelijk alarmerend rood scherm met de
instructie dat hij buiten het speelveld staat en met de resterende
terugkeertijd. Als de app niet actief in beeld staat, wordt waar
technisch beschikbaar een waarschuwing/notificatie gebruikt.

-   Wanneer het speelgebied een nog vast te stellen kleine omvang
    bereikt, zijn hints en persoonlijke vragen niet meer beschikbaar.

-   Naarmate het speelveld kleiner wordt, wordt ook de afstand kleiner
    waarbinnen een zoeker een hider als gevonden kan registreren. Dit
    compenseert het voordeel dat een kleiner speelgebied de hider
    makkelijker lokaliseerbaar maakt.

Nog te parametriseren vóór implementatie: formule voor toegestane
terugkeertijd, exacte zonegeometrie/richting van de krimp, grens waarop
hints/vragen stoppen en de vindafstand per fase.

## 8. Hints

-   Iedere speler krijgt bij aanvang één gratis hint.

-   Daarna kost een hint 5 punten. Daarnaast wordt na afronding van het
    spel 1 punt per gekochte hint op het resultaat verrekend.

-   Na gebruik geldt een cooldown van 10 minuten voordat dezelfde speler
    opnieuw een hint kan gebruiken.

-   Een hint toont ongeveer één minuut een zoekcirkel. Vanaf 30 seconden
    wordt de cirkel steeds sneller kleiner; het einde is zeer kort
    zichtbaar.

-   Voor een zoeker toont de cirkel hoeveel hiders zich in het gebied
    bevinden. Voor een hider toont de cirkel hoeveel zoekers én hiders
    zich in het gebied bevinden.

-   De hint toont niet letterlijk de locatie van één specifieke speler.
    Als relevante spelers dicht bij elkaar staan, kan de uiteindelijke
    cirkel vanzelf zeer klein worden.

-   Bij onvoldoende punten kan geen betaalde hint worden gebruikt.

-   In het laatste kwart van het spel kunnen geen nieuwe hints meer
    worden gekocht. Daarnaast kunnen hints worden uitgeschakeld zodra de
    geconfigureerde minimale speelveldomvang is bereikt.

De puntenprijs van een hint stijgt bij ieder nieuw kwart met 20% ten
opzichte van de dan geldende prijs. De implementatie moet vooraf één
afrondingsregel voor niet-gehele punten toepassen.

## 9. Persoonlijke vragen - alleen privéspel

### 9.1 Voorbereiding

-   De organisator bedenkt vijf persoonlijke vragen of laat AI vijf
    vragen genereren.

-   Voorbeelden zijn: "Ben ik boven de 30 jaar?", "Heb ik drie kinderen
    of meer?", "Werk ik al meer dan 10 jaar bij hetzelfde bedrijf?" en
    "Ben ik geboren in Haarlem?".

-   Iedere deelnemer beantwoordt vóór het spel alle vijf vragen over
    zichzelf.

-   De vragenfunctie is niet beschikbaar in openbare spellen.

### 9.2 Vraagtekens tijdens het spel

-   Voor iedere deelnemer bestaat een vraagteken op een locatie binnen
    het speelveld. Een speler ziet zijn eigen vraagteken nooit.

-   Wanneer een speler binnen de vereiste range van het vraagteken van
    een andere deelnemer komt, verschijnt het vraagteken met de avatar
    en in-game naam van die deelnemer.

-   Door op het vraagteken te drukken start één vragenronde waarin alle
    vijf vragen over die deelnemer worden beantwoord.

-   Na de start moet de speler binnen de range blijven. Bij het verlaten
    van de range verschijnt direct een waarschuwing en een countdown van
    vijf seconden.

-   Keert de speler binnen vijf seconden terug, dan gaat de vragenronde
    verder waar hij gebleven was.

-   Keert hij niet binnen vijf seconden terug, dan wordt de ronde
    definitief afgebroken. Voor die deelnemer krijgt deze speler geen
    tweede poging en het vraagteken verschijnt voor hem niet meer.

-   De status van een vraagteken is dus individueel per speler:
    eigen/onzichtbaar, beschikbaar, afgerond of mislukt/geblokkeerd.

-   Vanaf de later te bepalen minimale speelveldomvang worden vragen
    uitgeschakeld.

### 9.3 Punten voor vragen

| Goed van 5 \| Punten \|

| --- \| --- \|

| 0 \| 0 \|

| 1 \| 10 \|

| 2 \| 20 \|

| 3 \| 40 \|

| 4 \| 60 \|

| 5 \| 100 \|

Perfecte ronde over het hele spel: wanneer een speler de vraagtekens van
alle andere deelnemers heeft bezocht én bij iedere deelnemer 5/5 vragen
goed heeft beantwoord, ontvangt hij 500 bonuspunten. Eén score lager dan
5/5 bij één deelnemer betekent dat deze bonus niet wordt toegekend.

## 10. Punten en spelwaarde V1

V1 gebruikt punten als enige spelvaluta. Het puntensysteem is bewust
niet zero-sum: spelgebeurtenissen mogen nieuwe punten creëren.

Een zoeker start in het 60-minuten rekenvoorbeeld met 50 punten. De
concrete startwaarde moet als spelparameter worden vastgelegd zodat
andere spelduur/rangconfiguraties reproduceerbaar blijven.

Zolang geen hider wordt gevonden, daalt de waarde van een zoeker per
minuut. De daling wordt per kwart van het spel zwaarder. Puntenblad(1)
is leidend voor de gewenste richting; de exacte formule en afronding
worden als configureerbare rekenregel vastgelegd vóór implementatie.

Per rang krijgt een speler vanaf de start 5 punten extra spelwaarde.

Wanneer een hider wordt gevonden, ontvangt de zoeker die de hider vindt
80% van de actuele puntenwaarde van die hider.

Iedere andere actieve zoeker ontvangt afzonderlijk 20% van de actuele
puntenwaarde van de gevonden hider. Dit percentage wordt dus niet over
de overige zoekers verdeeld.

Exacte afbouwformule zoeker: laat S de startwaarde van de zoeker zijn en
T de totale spelduur in minuten. De vier kwartalen duren T/4 minuten en
gebruiken factoren 1, 1,5, 2,25 en 3,375. De basissnelheid r = S /
((T/4) × 8,125). In kwart q is het puntenverlies per minuut r ×
1,5\^(q-1). De waarde wordt begrensd op minimaal 0 punten.

Voorbeeld bij S = 50 en T = 60 minuten: r = 0,410256 punt/minuut. De
afbouw per minuut is achtereenvolgens 0,410256; 0,615385; 0,923077;
1,384615. Per kwart verdwijnt circa 6,1538; 9,2308; 13,8462; 20,7692
punten, samen exact 50 punten.

Iedere hider die na de vondst nog actief en niet gevonden is, krijgt +10
punten spelwaarde.

De gevonden hider wordt uit het actieve spel verwijderd. De hiervoor
toegekende punten hoeven niet op te tellen tot de waarde van de gevonden
hider; het systeem mag punten creëren.

Hints volgen de puntenregels uit hoofdstuk 8. Persoonlijke vragen volgen
de vaste staffel uit hoofdstuk 9.

Bij gelijke relevante prestatie wordt een eventuele prestatiegebonden
bonus gelijk behandeld volgens dezelfde spelregel; er wordt geen
willekeurige winnaar gekozen.

## 11. Eindresultaat en feedback

### 11.1 Zoekers

-   50% of meer van de hiders gevonden betekent winst voor het
    zoekersteam.

-   Een individuele zoeker krijgt een extra positief bericht als hij
    zelf 50% of meer van alle gevonden hiders heeft gevonden; bij 100%
    is het bericht het meest positief.

-   Als het zoekersteam wint maar de individuele zoeker maximaal 10%
    aandeel in de vondsten had, is het persoonlijke bericht neutraal.

-   Minder dan 50% gevonden is negatief; minder dan 10% zeer negatief;
    niemand gevonden is het meest negatieve resultaat.

### 11.2 Hiders

-   Niet gevonden worden is zeer positief; als enige hider overblijven
    is het meest positieve resultaat.

-   Gevonden worden in het laatste kwart kan nog steeds een positief
    persoonlijk resultaat opleveren.

-   Gevonden vóór de helft van de speeltijd is negatief; gevonden in het
    eerste kwart is het meest negatief.

### 11.3 Popup en media

-   Voor een hider toont de eindpopup minimaal hoe lang hij uit handen
    van de zoekers bleef en hoeveel hiders samen met hem overbleven.

-   Voor een zoeker toont de popup minimaal hoeveel hiders hij
    persoonlijk vond en welk percentage dat is.

-   De popup bevat de mogelijkheid deelnemers als vriend toe te voegen.

-   Bij winst: confetti en juichend geluid. Bij verlies: een origineel,
    overdreven teleurstellend effect; geen beschermde Pokémon-beelden of
    -audio kopiëren.

-   Spelgeluid staat standaard aan en respecteert de geluidsinstellingen
    van het apparaat/de app. Pushmeldingsrechten worden afzonderlijk
    behandeld.

-   Bij de islamitische profielvariant: 'as-salāmu ʿalaykum' bij
    start/startscherm, 'bismillāh' bij het starten van een nieuw spel,
    'Allāhumma bārik' bij winst en 'alḥamdulillāh' bij verlies.

## 12. Vrienden en uitnodigingen

-   Na afloop verschijnt in de resultaatpopup de mogelijkheid
    medespelers als vriend toe te voegen; standaard zijn alle spelers
    geselecteerd.

-   Als beide spelers elkaar kiezen ontstaat direct een vriendschap. Bij
    een eenzijdige keuze ontvangt de ander een verzoek.

-   Een vriendverzoek blijft twee dagen open. De verzender kan het niet
    intrekken; de ontvanger kan weigeren of blokkeren.

-   Wie via een uitnodigingslink binnenkomt wordt automatisch vriend van
    de uitnodiger. Heeft de genodigde al een account, dan wordt het
    bestaande account gebruikt.

-   Vrienden zien: gewonnen spellen/totaal spellen, badges, dagelijkse
    speelstreak, rang en spellen waarvoor iemand zich heeft aangemeld
    maar die nog niet zijn gestart.

-   Niet zichtbaar voor vrienden: actuele speldeelname,
    bedrag/financiële waarde en hoeveel nog nodig is voor de volgende
    rang.

## 13. Profiel, onboarding en naammoderatie

### 13.1 Eerste onboardingconcept

De onboarding wordt in V1 als korte, herkenbare route opgezet rond de
Verstobbertje-mascotte: een geanimeerde boomstronk/detective met
zonnebril, bolhoed en vergrootglas. Het notitieblok met afvinkbare
avatars kan terugkomen als visueel motief voor voortgang en opdrachten.

-   1.  Welkom: mascotte, korte uitleg "verstop, zoek, beweeg en scoor
        punten".
-   2.  Profiel: kies in-game naam; avatar/logo en kleur zijn al
        standaard ingevuld maar kunnen worden aangepast.
-   3.  Spelvoorkeur: keuze voor de islamitische profielvariant; deze
        voorkeur bepaalt passende begroetingen/teksten.
-   4.  Korte uitleg van rollen: zoeker en hider, speelgebied, timer en
        krimpende zone.

Geometrie krimp: 5% betekent 5% van de huidige oppervlakte, niet 5% van
de straal. Nieuwe oppervlakte = huidige oppervlakte × 0,95. Bij een
cirkel geldt nieuwe straal = oude straal × √0,95 ≈ 0,974679 × oude
straal. Na drie krimpmomenten op 25%, 50% en 75% resteert circa 85,74%
van de oorspronkelijke oppervlakte.

Richting van de krimp: het centrum van de nieuwe zone mag bij ieder
krimpmoment verschuiven. De nieuwe zone moet volledig binnen de huidige
zone liggen. De uiteindelijke veilige zone is daardoor vooraf niet
bekend. Tijdens de vijf minuten durende overgang wordt de nieuwe zone
zichtbaar en wordt het vervallende gebied visueel grijs.

GPS-terugkeertijd: voor een speler buiten de nieuwe zone wordt de
afstand tot de dichtstbijzijnde grens van de nieuwe zone bepaald. De
geschatte benodigde reistijd wordt vermenigvuldigd met veiligheidsfactor
1,5. De toegestane terugkeertijd is minimaal 2 minuten en maximaal 10%
van de totale spelduur. De veronderstelde verplaatsingssnelheid wordt
als centrale configuratieparameter gekoppeld aan de schaal van het
oorspronkelijke speelgebied. Eliminatie mag niet op één afwijkende
GPS-meting berusten; meerdere opeenvolgende geldige metingen moeten
bevestigen dat de speler buiten de zone is. Zodra betrouwbare
GPS-metingen bevestigen dat de speler weer binnen is, stopt de
eliminatiecountdown onmiddellijk.

-   5.  Korte uitleg van punten, hints en - bij privéspellen -
        persoonlijke vragen.
-   6.  Daarna naar het startscherm met beschikbare spellen, eigen
        spellen en "Nieuw spel".

### 13.2 Profielregels

-   Een profielfoto is niet verplicht; een avatar/logo is toegestaan en
    standaard beschikbaar.

-   In-game naam: maximaal 30 tekens; niet uitsluitend hoofdletters of
    speciale tekens. Cijfers en letters mogen worden gecombineerd.

-   Aanstootgevende namen worden niet geaccepteerd. Melding: "Deze naam
    is aanstootgevend, kies een andere naam."

-   Moderatie moet minimaal rekening houden met Nederlands, Duits,
    Frans, Spaans, Engels en Arabisch.

-   De islamitische variant is een profielinstelling, niet een
    instelling per spel.

## 14. Privacy en deelnemersinformatie

-   Vóór de start zien deelnemers van anderen minimaal naam en rang.

-   Voor vrienden kunnen naam, leeftijd, rang en foto zichtbaar zijn,
    waarbij de foto alleen zichtbaar is als de gebruiker deze deelt.

-   De gekozen deelinstellingen gelden profielbreed en niet afzonderlijk
    per spel.

-   Screenshots van deelnemersinformatie worden waar technisch haalbaar
    ontmoedigd of beperkt. Als een platform een betrouwbare
    blur/beveiliging ondersteunt kan die worden toegepast. Volledige
    screenshotpreventie wordt niet als gegarandeerde functionaliteit
    gepresenteerd.

## 15. Nog te parametriseren vóór acceptatiecriteria

De functionele richting is nu voldoende bepaald. De onderstaande punten
zijn geen fundamentele productvragen meer, maar parameters/formules die
we vóór of tijdens het opstellen van de acceptatiecriteria expliciet
moeten vastleggen:

-   Exacte tijdsafbouwformule voor de zoeker per kwart, inclusief
    ondergrens (bijvoorbeeld nooit lager dan 0) en afrondingsregel.

-   Afrondingsregel voor de 20%-stijging van hintkosten wanneer een
    niet-geheel puntenaantal ontstaat.

-   Formule voor de maximaal toegestane tijd buiten een gekrompen zone
    op basis van spelduur en oorspronkelijke gebiedsgrootte.

-   Exacte geometrie/richting van iedere krimpfase en hoe spelers de
    nieuwe grens zien.

-   De grensgrootte waaronder hints en vragen worden uitgeschakeld.

-   Vindafstand per krimpfase.

-   Eventuele aanvullende rang-/prestatiebonussen buiten de reeds
    vastgelegde +5 startwaarde per rang en vragenbonus.

## 16. Volgende stap

Na akkoord op dit FO wordt per functioneel onderdeel een set
acceptatiecriteria opgesteld. Daarna worden daar concrete testcases aan
gekoppeld. Pas wanneer requirement → acceptatiecriterium → testcase
sluitend is, wordt de implementatieopdracht voor Codex opgesteld.
Daarmee wordt voorkomen dat Codex open spelregels zelf moet invullen.

------------------------------------------------------------------------

# DEEL B --- BUSINESS RULES, ACCEPTATIECRITERIA EN TESTCASES V1.1

# Verstobbertje - Business rules, acceptatiecriteria en testcases

V1 - puntenversie \| Uitwerking voor Codex

Bronbasis: Functioneel Ontwerp V3.3 + Puntenblad(1) + vastgelegde
verduidelijkingen

## 1. Gebruik van dit pakket

Dit document vertaalt het FO naar toetsbare regels. Business rules (BR)
zijn normatief. Acceptatiecriteria (AC) beschrijven wanneer de
functionaliteit geaccepteerd wordt. Testcases (TC) bevatten zowel
positieve als negatieve scenario's. Codex mag geen open parameter zelf
inhoudelijk invullen; daarvoor worden benoemde configuratieparameters
gebruikt.

-   Prioriteit P0 = blokkerend voor een speelbare V1; P1 = belangrijk
    voor V1; P2 = polish/ondersteunend.

-   Waar een exacte waarde nog als parameter is gemarkeerd, moet de code
    die waarde centraal configureerbaar maken en mogen er geen
    verspreide magic numbers ontstaan.

-   Financiële functionaliteit staat niet in dit pakket; V1 gebruikt
    uitsluitend punten.

## 2. Centrale configuratieparameters

| ID \| Parameter \| Waarde \| Regel \|

| --- \| --- \| --- \| --- \|

| CFG-01 \| join_grace_minutes \| 5:00 \| Deelname toegestaan t/m exact
  5:00 na start; vanaf 5:01 gesloten. \|

| CFG-02 \| shrink_duration_minutes \| 5 \| Duur van iedere krimpfase.
  \|

| CFG-03 \| shrink_percent \| 5% \| Krimp per fase; definitie of dit
  oppervlakte/radius betreft moet vóór GPS-implementatie worden
  vastgezet. \|

| CFG-04 \| question_range_meters \| TBD \| Range waarbinnen vraagteken
  activeerbaar is. \|

| CFG-05 \| question_return_seconds \| 5 \| Terugkeertijd na verlaten
  range tijdens vragen. \|

| CFG-06 \| hint_duration_seconds \| 60 \| Totale zichtduur hintcirkel.
  \|

| CFG-07 \| hint_shrink_start_seconds \| 30 \| Vanaf dit moment versneld
  krimpen. \|

| CFG-08 \| hint_cooldown_minutes \| 10 \| Cooldown per speler. \|

| CFG-09 \| hint_base_cost_points \| 5 \| Basiskosten eerste betaalde
  hint. \|

| CFG-10 \| hint_result_penalty_points \| 1 \| Extra verrekening per
  gekochte hint na spel. \|

| CFG-11 \| hint_quarter_increase \| 20% \| Kostenstijging per kwart;
  afrondingsregel TBD. \|

| CFG-12 \| rank_start_value_increment \| 5 \| Extra startwaarde per
  rang. \|

| CFG-13 \| finder_reward_percent \| 80% \| Beloning vinder op actuele
  hiderwaarde. \|

| CFG-14 \| other_seeker_reward_percent \| 20% per zoeker \| Iedere
  overige actieve zoeker afzonderlijk. \|

| CFG-15 \| surviving_hider_bonus \| 10 \| Bonus aan iedere nog actieve
  hider na een vondst. \|

| CFG-16 \| seeker_decay_formula \| TBD \| Tijdsafbouw per kwart;
  Puntenblad(1) geeft richting/voorbeeld maar formule en ondergrens
  moeten centraal worden vastgelegd. \|

| CFG-17 \| zone_return_formula \| TBD \| Dynamische terugkeertijd
  o.b.v. spelduur en oorspronkelijke gebiedsgrootte. \|

| CFG-18 \| find_distance_by_phase \| TBD \| Vindafstand wordt kleiner
  bij kleiner speelveld. \|

| CFG-19 \| min_zone_for_hints_questions \| TBD \| Onder deze grootte
  hints/vragen uit. \|

## 3. Genummerde business rules

| ID \| Domein \| Business rule \| Prioriteit \|

| --- \| --- \| --- \| --- \|

| BR-GAME-001 \| Spelstatus \| Een spel is na aanmaken direct
  beschikbaar voor bevoegde gebruikers. \| P0 \|

| BR-GAME-002 \| Deelname \| Deelname is toegestaan t/m exact 5:00 na
  start en niet meer vanaf 5:01. \| P0 \|

| BR-GAME-003 \| Zichtbaarheid \| Een gestart spel waaraan de gebruiker
  niet deelnam verdwijnt voor die gebruiker uit beschikbare spellen en
  komt niet in afgeronde spellen. \| P0 \|

| BR-GAME-004 \| Mijn spellen \| Ik speel al mee met bevat actieve
  spellen en toekomstige spellen waarvoor de gebruiker is aangemeld. \|
  P1 \|

| BR-GAME-005 \| Einde spel \| Een spel eindigt bij timer 0, wanneer
  alle hiders gevonden zijn, of wanneer alle zoekers uitgeschakeld zijn.
  \| P0 \|

| BR-GAME-006 \| Einde spel \| Na einde wordt de status overal direct
  afgerond; de persoonlijke uitslag opent automatisch maximaal één keer
  per sessie en blijft handmatig opvraagbaar. \| P0 \|

| BR-LOC-001 \| Locatie \| Locatiehiërarchie is Land \> Provincie \>
  Stad \> Wijk; onderliggende keuzes zijn afhankelijk van bovenliggende
  geldige keuzes. \| P0 \|

| BR-LOC-002 \| Locatie \| Meerdere keuzes zijn toegestaan. Land kent
  geen Alle; provincie/stad/wijk kennen contextafhankelijk Alle. \| P1
  \|

| BR-LOC-003 \| Locatie \| Wijziging van provincie reset ongeldige stad-
  en wijkkeuzes; een stad buiten de gekozen provincie kan nooit
  geselecteerd blijven. \| P0 \|

| BR-LOC-004 \| Locatie \| Dropdowns zijn doorzoekbaar en filteren
  tijdens typen. Labels Naam van het spel en Land(en) worden volledig
  weergegeven. \| P1 \|

| BR-AI-001 \| Intro \| AI-intro gebruikt actuele spelnaam, regio en
  organisator en nooit verouderde waarden. \| P0 \|

| BR-AI-002 \| Intro \| Minimaal tien inhoudelijk verschillende
  varianten zijn beschikbaar vóór herhaling acceptabel is. \| P1 \|

| BR-AI-003 \| Intro \| Na wijziging van een broninstelling wordt een
  AI-intro gewist; handmatige intro blijft staan. \| P0 \|

| BR-ZONE-001 \| Speelveld \| Krimp start na ieder verstreken kwart
  waarop het spel nog actief is; praktisch dus na 25%, 50% en 75%. \| P0
  \|

| BR-ZONE-002 \| Speelveld \| Elke krimpfase duurt 5 minuten en
  reduceert het actieve speelgebied met 5% volgens centraal vastgelegde
  geometrie. \| P0 \|

| BR-ZONE-003 \| Speelveld \| Niet-actief gebied wordt grijs; actief
  gebied behoudt normale kleur. \| P1 \|

| BR-ZONE-004 \| Speelveld \| Buiten het gebied start een dynamische
  terugkeertijd. Tijdens deze tijd toont de app een rood alarmscherm,
  instructie en resterende tijd. \| P0 \|

| BR-ZONE-005 \| Speelveld \| Na overschrijden van de terugkeertijd
  wordt de speler uitgeschakeld. Terugkeer vóór het verstrijken stopt de
  uitschakeling. \| P0 \|

| BR-ZONE-006 \| Speelveld \| De eindzone blijft binnen het
  oorspronkelijke speelgebied en is vooraf niet bekend. \| P0 \|

| BR-ZONE-007 \| Speelveld \| Vindafstand neemt af naarmate het
  speelveld kleiner wordt. \| P0 \|

| BR-ZONE-008 \| Speelveld \| Hints en vragen worden uitgeschakeld bij
  de geconfigureerde minimale zonegrootte; hints zijn in elk geval niet
  koopbaar in het laatste kwart. \| P0 \|

| BR-PTS-001 \| Punten \| V1 gebruikt uitsluitend punten en het systeem
  is niet zero-sum. \| P0 \|

| BR-PTS-002 \| Punten \| Per rang krijgt een speler +5 startwaarde per
  rangstap volgens de centraal vastgelegde rangbasis. \| P0 \|

| BR-PTS-003 \| Punten \| Zolang niemand gevonden wordt daalt de
  zoekerwaarde per minuut volgens CFG-16; de afbouw wordt per kwart
  zwaarder. \| P0 \|

| BR-PTS-004 \| Punten \| Bij vondst ontvangt de vinder 80% van de
  actuele hiderwaarde. \| P0 \|

| BR-PTS-005 \| Punten \| Iedere andere actieve zoeker ontvangt
  afzonderlijk 20% van de actuele hiderwaarde. \| P0 \|

| BR-PTS-006 \| Punten \| Iedere nog actieve, niet gevonden hider
  ontvangt bij iedere vondst +10 punten spelwaarde. \| P0 \|

| BR-PTS-007 \| Punten \| De gevonden hider wordt uit het actieve spel
  verwijderd en kan niet opnieuw gevonden/beloond worden. \| P0 \|

| BR-PTS-008 \| Punten \| Percentagebeloningen worden volgens één
  centrale afrondingsregel verwerkt; dezelfde gebeurtenis mag niet
  dubbel worden geboekt. \| P0 \|

| BR-HINT-001 \| Hints \| Iedere speler krijgt bij start één gratis
  hint. \| P0 \|

| BR-HINT-002 \| Hints \| Daarna kost een hint 5 punten, met +20% kosten
  per nieuw kwart volgens één afrondingsregel. \| P0 \|

| BR-HINT-003 \| Hints \| Iedere gekochte hint veroorzaakt daarnaast 1
  punt resultaatcorrectie na afloop. \| P1 \|

| BR-HINT-004 \| Hints \| Na gebruik geldt 10 minuten cooldown per
  speler. \| P0 \|

| BR-HINT-005 \| Hints \| Hintcirkel is circa 60 seconden zichtbaar en
  krimpt vanaf 30 seconden versneld. \| P1 \|

| BR-HINT-006 \| Hints \| Zoekerhint toont aantal hiders; hiderhint
  toont aantal zoekers én hiders binnen de cirkel, zonder specifieke
  spelerlocatie prijs te geven. \| P0 \|

| BR-HINT-007 \| Hints \| Bij onvoldoende punten, actieve cooldown,
  laatste kwart of te kleine zone kan geen betaalde hint starten en
  worden geen punten afgeschreven. \| P0 \|

| BR-Q-001 \| Vragen \| Persoonlijke vragen bestaan alleen in
  privéspellen en alleen wanneer de organisator de functie activeert. \|
  P0 \|

| BR-Q-002 \| Vragen \| De organisator levert exact vijf vragen zelf of
  laat AI vijf geschikte persoonlijke vragen genereren; iedere deelnemer
  beantwoordt ze vóór start over zichzelf. \| P0 \|

| BR-Q-003 \| Vragen \| Iedere deelnemer heeft een vraagtekenlocatie; de
  eigenaar ziet zijn eigen vraagteken nooit. \| P0 \|

| BR-Q-004 \| Vragen \| Binnen range ziet een andere speler vraagteken +
  avatar + in-game naam en kan met één druk alle vijf vragen in één
  ronde starten. \| P0 \|

| BR-Q-005 \| Vragen \| Na start moet de speler binnen range blijven.
  Buiten range start 5 seconden waarschuwing; terugkeer binnen 5 sec
  hervat dezelfde ronde. \| P0 \|

| BR-Q-006 \| Vragen \| Niet terug binnen 5 sec maakt de ronde voor die
  speler/deelnemer definitief mislukt; geen tweede poging en marker
  verdwijnt voor die speler. \| P0 \|

| BR-Q-007 \| Vragen \| Vraagtekenstatus is per speler onafhankelijk:
  eigen/onzichtbaar, beschikbaar, afgerond of mislukt/geblokkeerd. \| P0
  \|

| BR-Q-008 \| Vragen \| Score per ronde: 0=0, 1=10, 2=20, 3=40, 4=60,
  5=100 punten. \| P0 \|

| BR-Q-009 \| Vragen \| Wie alle andere deelnemers bezoekt en bij
  iedereen 5/5 scoort krijgt eenmaal 500 bonuspunten. \| P0 \|

| BR-Q-010 \| Vragen \| De 500-bonus vervalt zodra bij minimaal één
  andere deelnemer minder dan 5/5 is gescoord of een ronde definitief
  mislukt. \| P0 \|

| BR-UI-001 \| Spelscherm \| Toon gevonden hiders / totaal hiders. Voor
  zoeker daarnaast door mij gevonden / totaal gevonden. \| P0 \|

| BR-UI-002 \| Spelscherm \| Compacte timer toont uren/minuten, actuele
  spelwaarde en binnen/buiten speelgebied. \| P1 \|

| BR-RES-001 \| Resultaat \| Zoekersteam wint bij \>=50% gevonden; \<50%
  is verlies. Persoonlijke toon volgt FO-grenzen 50%, 10% en 0%. \| P1
  \|

| BR-RES-002 \| Resultaat \| Hiderfeedback volgt overleving: niet
  gevonden zeer positief; enige survivor meest positief; laatste kwart
  positief; vóór helft negatief; eerste kwart meest negatief. \| P1 \|

| BR-RES-003 \| Resultaat \| Resultaatpopup toont rolrelevante
  statistiek en vriendoptie; winst gebruikt confetti/juichgeluid,
  verlies origineel teleurstellingseffect. \| P2 \|

| BR-FR-001 \| Vrienden \| Na afloop zijn medespelers standaard
  geselecteerd voor toevoegen; wederzijdse keuze = direct vriend,
  eenzijdig = verzoek. \| P1 \|

| BR-FR-002 \| Vrienden \| Vriendverzoek verloopt na 2 dagen; ontvanger
  kan weigeren/blokkeren; verzender kan niet intrekken. \| P1 \|

| BR-FR-003 \| Uitnodiging \| Via uitnodigingslink ontstaat automatisch
  vriendschap met uitnodiger; bestaand account wordt hergebruikt. \| P1
  \|

| BR-PROF-001 \| Profiel \| Naam max 30 tekens; niet uitsluitend
  hoofdletters/speciale tekens; aanstootgevende naam wordt geweigerd met
  afgesproken melding. \| P0 \|

| BR-PROF-002 \| Profiel \| Moderatie dekt minimaal NL/DE/FR/ES/EN/AR.
  \| P1 \|

| BR-PROF-003 \| Profiel \| Islamitische variant is profielbreed en
  stuurt de afgesproken teksten. \| P1 \|

| BR-PRIV-001 \| Privacy \| Voor start zien deelnemers minimaal naam en
  rang; vrienden zien alleen de afgesproken profielinformatie en geen
  actuele speldeelname of financiële informatie. \| P1 \|

## Aanvullende definitieve business rules - puntenafbouw, geometrie en GPS

BR-PNT-DECAY-01 - De puntenafbouw van een zoeker zonder vondst gebruikt
vier kwartalen met snelheidsfactoren 1, 1,5, 2,25 en 3,375.

BR-PNT-DECAY-02 - Voor startwaarde S en spelduur T minuten is de
basissnelheid r = S / ((T/4) × 8,125). In kwart q is het verlies per
minuut r × 1,5\^(q-1).

BR-PNT-DECAY-03 - Een zoeker die gedurende de volledige spelduur niemand
vindt, eindigt door tijdsafbouw exact op 0 punten; punten mogen nooit
negatief worden.

BR-ZONE-GEO-01 - Op 25%, 50% en 75% van de spelduur start een krimpfase
van 5 minuten. Iedere krimp reduceert de huidige oppervlakte met exact
5%.

BR-ZONE-GEO-02 - Bij een cirkel wordt de nieuwe straal berekend als oude
straal × √0,95. De nieuwe zone ligt volledig binnen de huidige zone.

BR-ZONE-GEO-03 - Het centrum van de nieuwe zone mag verschuiven, zodat
de uiteindelijke veilige zone vooraf niet bekend is. Tijdens de overgang
wordt de nieuwe zone zichtbaar en het vervallende gebied grijs.

BR-ZONE-GPS-01 - Voor een speler buiten de nieuwe zone wordt de afstand
tot de dichtstbijzijnde grens van de nieuwe zone gebruikt voor de
terugkeerberekening.

BR-ZONE-GPS-02 - Terugkeertijd = geschatte reistijd × 1,5, met minimum 2
minuten en maximum 10% van de totale spelduur.

BR-ZONE-GPS-03 - De veronderstelde verplaatsingssnelheid is een centrale
configuratieparameter die afhangt van de schaal van het oorspronkelijke
speelgebied; de waarde wordt niet hardcoded in domeinlogica.

BR-ZONE-GPS-04 - Een speler wordt niet op basis van één afwijkende
GPS-meting als buiten de zone bevestigd. Meerdere opeenvolgende geldige
metingen zijn vereist. Betrouwbare terugkeer binnen de zone stopt de
countdown onmiddellijk.

## 4. Acceptatiecriteria

| AC \| Business rules \| Acceptatiecriterium \|

| --- \| --- \| --- \|

| AC-001 \| BR-GAME-001..006 \| Spelstatus, deelnamevenster en drie
  eindcondities werken exact volgens de business rules en synchroniseren
  alle relevante schermen zonder refresh. \|

| AC-002 \| BR-LOC-001..004 \| Locatiekeuzes kunnen alleen geldige
  hiërarchische combinaties opleveren; parent-wijziging reset ongeldige
  children; labels clippen niet. \|

| AC-003 \| BR-AI-001..003 \| AI-intro gebruikt uitsluitend actuele
  bronwaarden; AI-tekst wordt bij bronwijziging ongeldig gemaakt,
  handmatige tekst niet; variantmechanisme ondersteunt minimaal 10
  varianten. \|

| AC-004 \| BR-ZONE-001..008 \| Krimpfasen worden op juiste
  kwartmomenten gestart, duren 5 minuten, tonen actieve/inactieve zone
  correct en handhaven terugkeer/uitschakeling deterministisch. \|

| AC-005 \| BR-PTS-001..008 \| Een vondst boekt exact één keer: 80% naar
  vinder, 20% naar iedere overige actieve zoeker, +10 naar iedere
  overige actieve hider; gevonden hider wordt inactief. \|

| AC-006 \| BR-PTS-002..003 \| Startwaarde/rang en tijdsafbouw worden
  uitsluitend via centrale configuratie berekend en kunnen niet onder de
  gekozen ondergrens komen zodra die parameter is vastgesteld. \|

| AC-007 \| BR-HINT-001..007 \| Gratis hint, puntenkosten,
  kwartstijging, resultaatcorrectie, cooldown, rolafhankelijke telling
  en blokkades werken zonder onterechte puntenmutatie. \|

| AC-008 \| BR-Q-001..007 \| Vraagtekens bestaan alleen in privéspel,
  zijn individueel zichtbaar/statusgestuurd en de 5-seconden range-regel
  is onomkeerbaar na mislukking. \|

| AC-009 \| BR-Q-008..010 \| Vragenscore volgt exact 0/10/20/40/60/100;
  500 bonus wordt precies eenmaal toegekend bij perfecte volledige reeks
  en anders nooit. \|

| AC-010 \| BR-UI-001..002 \| Spelscherm toont correcte globale en
  persoonlijke vondsttellers, uren/minuten, waarde en zone-status. \|

| AC-011 \| BR-RES-001..003 \| Eindresultaat gebruikt juiste rol,
  grenswaarden en statistieken; automatische popup verschijnt maximaal
  eenmaal per sessie en blijft handmatig beschikbaar. \|

| AC-012 \| BR-FR-001..003 \| Vriendschapslogica verwerkt
  wederzijds/eenzijdig/verlopen/geblokkeerd/invite-link zonder dubbele
  relaties. \|

| AC-013 \| BR-PROF-001..003 \| Profiel valideert naamregels,
  taalmoderatie en profielbrede islamitische variant; standaard
  avatar/kleur maken onboarding zonder foto mogelijk. \|

| AC-014 \| BR-PRIV-001 \| Niet-vrienden en vrienden zien uitsluitend de
  voor hun relatie toegestane gegevens; verboden velden worden niet in
  UI-payload weergegeven. \|

## 5. Testcases - positief en negatief

Testdata moet waar mogelijk deterministisch zijn. Voor GPS/range-gedrag
gebruikt de testlaag vaste coördinaten of een location-provider stub.
Voor tijd gebruikt de testlaag een fake clock; tests mogen niet
afhankelijk zijn van echte minuten wachten.

| TC \| Type \| BR \| Voorwaarde \| Stappen \| Verwacht resultaat \|
  Prio \|

| --- \| --- \| --- \| --- \| --- \| --- \| --- \|

| TC-GAME-01 \| Positief \| BR-GAME-002 \| Spel gestart om T0; gebruiker
  nog niet deelnemer. \| Probeer te joinen op T0+05:00. \| Join wordt
  geaccepteerd. \| P0 \|

| TC-GAME-02 \| Negatief \| BR-GAME-002 \| Zelfde. \| Probeer te joinen
  op T0+05:01. \| Join wordt geweigerd; geen deelname-record. \| P0 \|

| TC-GAME-03 \| Positief \| BR-GAME-005 \| Actief spel met resterende
  tijd. \| Laat fake clock timer 0 bereiken. \| Spel eindigt exact
  eenmaal en status = afgerond. \| P0 \|

| TC-GAME-04 \| Positief \| BR-GAME-005 \| Actief spel; één laatste
  hider. \| Registreer geldige vondst. \| Alle hiders gevonden -\> spel
  eindigt. \| P0 \|

| TC-GAME-05 \| Positief \| BR-GAME-005 \| Actief spel; één laatste
  zoeker. \| Schakel zoeker uit via zone-regel. \| Alle zoekers
  uitgeschakeld -\> spel eindigt. \| P0 \|

| TC-GAME-06 \| Negatief \| BR-GAME-006 \| Afgerond spel; popup al
  automatisch getoond in sessie. \| Navigeer weg en terug. \| Popup
  opent niet opnieuw automatisch; Uitslag-knop opent hem wel. \| P0 \|

| TC-LOC-01 \| Positief \| BR-LOC-001..003 \| Land NL, provincie
  Noord-Holland. \| Open stedenzoeker en zoek Haarlem. \| Haarlem is
  selecteerbaar; steden buiten gekozen provincies niet. \| P0 \|

| TC-LOC-02 \| Negatief \| BR-LOC-003 \| Stad Haarlem geselecteerd onder
  Noord-Holland. \| Wijzig provincie naar Utrecht. \| Haarlem en
  afhankelijke wijk worden gewist; ongeldige combinatie kan niet worden
  opgeslagen. \| P0 \|

| TC-LOC-03 \| Negatief \| BR-LOC-001 \| Geen provincie gekozen. \|
  Probeer stad te selecteren. \| Stadselectie is disabled/niet
  uitvoerbaar. \| P0 \|

| TC-LOC-04 \| Positief \| BR-LOC-004 \| Nieuw-spelscherm. \| Bekijk
  labels op ondersteunde viewportgroottes. \| Naam van het spel en
  Land(en) zijn volledig leesbaar zonder clipping. \| P1 \|

| TC-AI-01 \| Positief \| BR-AI-001 \| Spelnaam X, Utrecht, organisator
  Jan. \| Genereer intro. \| Intro bevat actuele X/Utrecht/Jan-context
  en geen oude locatie. \| P0 \|

| TC-AI-02 \| Negatief \| BR-AI-003 \| AI-intro gegenereerd voor
  Haarlem. \| Ga terug, wijzig stad naar Utrecht. \| AI-intro wordt
  verwijderd/ongeldig; oude Haarlemtekst kan niet als actuele intro
  blijven staan. \| P0 \|

| TC-AI-03 \| Positief \| BR-AI-003 \| Handmatige intro aanwezig. \|
  Wijzig stad. \| Handmatige intro blijft staan. \| P1 \|

| TC-ZONE-01 \| Positief \| BR-ZONE-001..003 \| Spelduur 60 min; fake
  clock. \| Ga naar 15:00 verstreken en doorloop 5 min krimp. \| Eerste
  krimp start op 25%, eindigt na 5 min; vervallen zone grijs, actief
  deel gekleurd. \| P0 \|

| TC-ZONE-02 \| Positief \| BR-ZONE-004..005 \| Speler buiten nieuwe
  zone; grace time actief. \| Keer terug vóór grace timer 0. \| Alarm
  verdwijnt; speler blijft actief. \| P0 \|

| TC-ZONE-03 \| Negatief \| BR-ZONE-005 \| Speler buiten zone. \| Laat
  grace timer verstrijken zonder terugkeer. \| Speler wordt exact
  eenmaal uitgeschakeld. \| P0 \|

| TC-ZONE-04 \| Negatief \| BR-ZONE-006 \| Origineel speelgebied bekend.
  \| Genereer alle krimpzones. \| Geen nieuwe zone bevat gebied buiten
  de oorspronkelijke grens. \| P0 \|

| TC-ZONE-05 \| Positief \| BR-ZONE-008 \| Spel bereikt laatste kwart.
  \| Probeer nieuwe betaalde hint te kopen. \| Hintkoop is
  disabled/geweigerd en punten blijven gelijk. \| P0 \|

| TC-PTS-01 \| Positief \| BR-PTS-004..006 \| Hiderwaarde 100; 3 actieve
  zoekers incl. vinder; 2 overige actieve hiders. \| Registreer vondst
  door zoeker A. \| A +80; zoekers B en C ieder +20; beide overgebleven
  hiders ieder +10. \| P0 \|

| TC-PTS-02 \| Negatief \| BR-PTS-007..008 \| Vondst uit TC-PTS-01 al
  verwerkt. \| Verwerk hetzelfde find-event opnieuw. \| Geen tweede
  puntenmutatie; idempotent gedrag. \| P0 \|

| TC-PTS-03 \| Positief \| BR-PTS-002 \| Twee spelers met rangverschil
  2. \| Start spel. \| Hogere rang heeft 10 punten meer startwaarde dan
  lagere rang, uitgaande van dezelfde basis. \| P0 \|

| TC-PTS-04 \| Negatief \| BR-PTS-003 \| Zoekerwaarde nabij ondergrens.
  \| Laat decay meerdere ticks uitvoeren. \| Waarde volgt centrale
  formule en overschrijdt de geconfigureerde ondergrens niet. \| P0 \|

| TC-HINT-01 \| Positief \| BR-HINT-001 \| Nieuwe speler; gratis hint
  ongebruikt. \| Gebruik hint. \| Hint start zonder puntenaftrek; gratis
  hint wordt verbruikt. \| P0 \|

| TC-HINT-02 \| Positief \| BR-HINT-002..003 \| Gratis hint gebruikt;
  voldoende punten; eerste kwart. \| Koop hint. \| 5 punten direct
  afgeschreven; 1 resultaatpunt geregistreerd voor eindverrekening. \|
  P0 \|

| TC-HINT-03 \| Negatief \| BR-HINT-007 \| Speler heeft minder punten
  dan actuele hintprijs. \| Probeer hint te kopen. \| Hint start niet;
  geen punten of penalty gewijzigd. \| P0 \|

| TC-HINT-04 \| Negatief \| BR-HINT-004 \| Hint zojuist gebruikt. \|
  Probeer opnieuw binnen 10 min. \| Geblokkeerd door cooldown; geen
  kosten. \| P0 \|

| TC-HINT-05 \| Positief \| BR-HINT-004 \| Cooldown exact verstreken. \|
  Gebruik hint. \| Hint is weer toegestaan indien overige voorwaarden
  kloppen. \| P0 \|

| TC-HINT-06 \| Positief \| BR-HINT-006 \| Zoeker gebruikt hint; 3
  hiders in cirkel. \| Activeer hint. \| UI toont 3 hiders, geen
  individuele locatie/identiteit. \| P0 \|

| TC-HINT-07 \| Negatief \| BR-HINT-007 \| Laatste kwart of zone onder
  minimum. \| Probeer hint te kopen. \| Geen hint, geen puntenaftrek,
  duidelijke blokkademelding. \| P0 \|

| TC-Q-01 \| Negatief \| BR-Q-001 \| Openbaar spel. \| Open spelscherm.
  \| Geen persoonlijke vraagtekens of vragenfunctie beschikbaar. \| P0
  \|

| TC-Q-02 \| Positief \| BR-Q-003..004 \| Privéspel; A nadert marker van
  B. \| Kom binnen range. \| A ziet marker met avatar + in-game naam B
  en kan ronde starten. \| P0 \|

| TC-Q-03 \| Negatief \| BR-Q-003 \| Privéspel; A staat bij eigen
  marker. \| Bekijk kaart. \| A ziet eigen marker nooit. \| P0 \|

| TC-Q-04 \| Positief \| BR-Q-005 \| A start B-vragen, verlaat range en
  keert na 4 sec terug. \| Beweeg buiten/binnen via location stub. \|
  Waarschuwing telt; ronde hervat op eerdere voortgang. \| P0 \|

| TC-Q-05 \| Negatief \| BR-Q-006 \| A start B-vragen en verlaat range.
  \| Blijf \>5 sec buiten range. \| Ronde mislukt definitief; B-marker
  verdwijnt voor A; opnieuw starten onmogelijk. \| P0 \|

| TC-Q-06 \| Positief \| BR-Q-007 \| A heeft B afgerond; C heeft B nog
  niet bezocht. \| Vergelijk spelersweergave. \| B-marker weg/afgerond
  voor A maar beschikbaar voor C. \| P0 \|

| TC-Q-07 \| Positief \| BR-Q-008 \| Vijf rondes met respectievelijk
  0,1,2,3,4,5 goede antwoorden. \| Bereken scores. \| Scores exact
  0,10,20,40,60,100. \| P0 \|

| TC-Q-08 \| Positief \| BR-Q-009 \| Speler heeft alle andere deelnemers
  bezocht en overal 5/5. \| Rond laatste perfecte ronde af. \| Eenmalig
  +500 bonus. \| P0 \|

| TC-Q-09 \| Negatief \| BR-Q-010 \| Alle deelnemers bezocht, één ronde
  4/5. \| Rond spel af. \| Geen 500 bonus. \| P0 \|

| TC-Q-10 \| Negatief \| BR-Q-009 \| Perfecte reeks al beloond. \|
  Trigger resultaatberekening opnieuw. \| Geen tweede +500 bonus. \| P0
  \|

| TC-UI-01 \| Positief \| BR-UI-001 \| 10 hiders, 4 totaal gevonden,
  huidige zoeker vond er 2. \| Open actief spelscherm. \| Toont 4/10
  gevonden en 2/4 door mij gevonden. \| P0 \|

| TC-UI-02 \| Negatief \| BR-UI-001 \| Nog geen hider gevonden. \| Open
  zoekerweergave. \| Toont 0/totaal en persoonlijke teller zonder
  delen-door-nul fout. \| P0 \|

| TC-RES-01 \| Positief \| BR-RES-001 \| 10 hiders, exact 5 gevonden. \|
  Beëindig spel. \| Zoekersteam wordt als winnaar behandeld (\>=50%). \|
  P1 \|

| TC-RES-02 \| Negatief \| BR-RES-001 \| 10 hiders, 4 gevonden. \|
  Beëindig spel. \| Zoekersteam krijgt verliesfeedback; geen
  win-confetti. \| P1 \|

| TC-FR-01 \| Positief \| BR-FR-001 \| A en B selecteren elkaar na spel.
  \| Verwerk beide keuzes. \| Eén wederzijdse vriendschap; geen dubbel
  verzoek. \| P1 \|

| TC-FR-02 \| Negatief \| BR-FR-002 \| A stuurt verzoek; \>2 dagen
  verstreken. \| B probeert te accepteren. \| Verzoek is verlopen en
  creëert geen vriendschap. \| P1 \|

| TC-PROF-01 \| Negatief \| BR-PROF-001 \| Onboarding. \| Voer naam \>30
  tekens in. \| Opslaan geweigerd met valideerfeedback. \| P0 \|

| TC-PROF-02 \| Negatief \| BR-PROF-001..002 \| Onboarding. \| Voer een
  door moderatie als aanstootgevend gemarkeerde naam in. \| Opslaan
  geweigerd met exacte afgesproken melding. \| P0 \|

| TC-PROF-03 \| Positief \| BR-PROF-001 \| Onboarding. \| Voer geldige
  letters+cijfers naam \<=30 in. \| Naam wordt geaccepteerd. \| P0 \|

| TC-PRIV-01 \| Negatief \| BR-PRIV-001 \| Gebruiker bekijkt niet-vriend
  vóór spel. \| Inspecteer UI/viewmodel payload. \| Alleen toegestane
  velden; geen financiële/current-game/progress-to-next-rank gegevens.
  \| P1 \|

## 6. Codex implementatie- en kwaliteitsgate

-   Implementeer business rules in domein-/servicelogica; UI mag de
    spelregels niet dupliceren.

-   Gebruik een injectable clock voor timer-, kwart-, cooldown- en
    5-secondenregels.

-   Gebruik een abstraheerbare location provider zodat range- en
    zonegedrag zonder echte GPS deterministisch getest kan worden.

-   Gebruik idempotente eventverwerking voor find-events, vraagbonus en
    eindresultaat zodat rebuilds/retries geen dubbele punten opleveren.

-   Alle configureerbare parameters staan centraal en hebben unit tests
    op grenswaarden.

-   Voor merge moeten formattering, static analysis, unit/widget tests
    en web build slagen.

-   Naast geautomatiseerde tests moet een korte browsermatige
    functionele smoke-test de eerder mislukte punten expliciet
    controleren: label clipping, provincie/stad-afhankelijkheid en
    AI-intro na teruggaan/wijzigen.

-   Geen financiële UI of geldlogica in V1 introduceren.

## 7. Nog te beslissen vóór volledige GPS/game-economie implementatie

Deze punten blokkeren niet het opzetten van architectuur, UI en tests
met configuratie/stubs, maar Codex mag de uiteindelijke waarde niet zelf
verzinnen:

-   Of 5% krimp betrekking heeft op oppervlakte, straal/diameter of een
    andere zonegeometrie; plus de methode waarmee de nieuwe zone wordt
    gekozen.

-   Formule voor dynamische terugkeertijd buiten de zone.

-   Exacte vindafstand per krimpfase en vraagtekenrange.

-   Minimale zonegrootte waaronder vragen/hints uitgaan (naast de vaste
    regel: geen nieuwe hints in laatste kwart).

-   Exacte tijdsafbouwformule voor zoekers. Puntenblad(1) bevat een
    60-minuten voorbeeld, maar de tekstuele regel "stapgrootte ieder
    kwart 50% aanpassen" en de voorbeeldstappen moeten nog tot één
    formule worden gemaakt.

-   Afrondingsregel voor percentages en de 20%-hintprijsstijging (hele
    punten, decimalen, floor/ceil/round).

## 8. Traceability-overzicht

| Onderdeel \| Business rules \| AC \| Testcases \|

| --- \| --- \| --- \| --- \|

| Spelstatus/deelname \| BR-GAME-001..006 \| AC-001 \| TC-GAME-01..06 \|

| Locatie \| BR-LOC-001..004 \| AC-002 \| TC-LOC-01..04 \|

| AI-intro \| BR-AI-001..003 \| AC-003 \| TC-AI-01..03 \|

| Krimpend veld \| BR-ZONE-001..008 \| AC-004 \| TC-ZONE-01..05 \|

| Punten \| BR-PTS-001..008 \| AC-005..006 \| TC-PTS-01..04 \|

| Hints \| BR-HINT-001..007 \| AC-007 \| TC-HINT-01..07 \|

| Private vragen \| BR-Q-001..010 \| AC-008..009 \| TC-Q-01..10 \|

| Spel-UI \| BR-UI-001..002 \| AC-010 \| TC-UI-01..02 \|

| Resultaat \| BR-RES-001..003 \| AC-011 \| TC-RES-01..02 \|

| Vrienden \| BR-FR-001..003 \| AC-012 \| TC-FR-01..02 \|

| Profiel \| BR-PROF-001..003 \| AC-013 \| TC-PROF-01..03 \|

| Privacy \| BR-PRIV-001 \| AC-014 \| TC-PRIV-01 \|

## Aanvullende acceptatiecriteria en testcases

| Acceptatiecriterium \| Verwacht gedrag \| Test \|

| --- \| --- \| --- \|

| AC-PNT-DECAY-01 \| Bij S=50 en T=60 resulteert geen enkele vondst na
  60 minuten in exact 0 punten (binnen afrondingstolerantie). \|
  TC-PNT-01 positief \|

| AC-PNT-DECAY-02 \| De afbouwsnelheid van elk volgend kwart is exact
  1,5× die van het vorige kwart. \| TC-PNT-02 positief \|

| AC-PNT-DECAY-03 \| Punten worden nooit negatief, ook niet bij
  vertraagde timers of dubbele ticks. \| TC-PNT-03 negatief \|

| AC-ZONE-01 \| Iedere krimp verlaagt de huidige oppervlakte met 5%,
  niet de straal met 5%. \| TC-ZONE-01 positief \|

| AC-ZONE-02 \| Na drie krimpen resteert circa 85,74% van de
  oorspronkelijke oppervlakte. \| TC-ZONE-02 positief \|

| AC-ZONE-03 \| Een gegenereerde nieuwe zone valt volledig binnen de
  voorgaande zone. \| TC-ZONE-03 positief / TC-ZONE-04 negatief \|

| AC-ZONE-04 \| Een zonevoorstel dat deels buiten de huidige zone valt
  wordt afgewezen en opnieuw bepaald. \| TC-ZONE-04 negatief \|

| AC-GPS-01 \| Terugkeertijd gebruikt afstand tot dichtstbijzijnde
  nieuwe zonegrens, factor 1,5, min. 2 min en max. 10% spelduur. \|
  TC-GPS-01 positief \|

| AC-GPS-02 \| Een enkele GPS-sprong buiten het gebied elimineert de
  speler niet en start niet onterecht een definitieve uitschakeling. \|
  TC-GPS-02 negatief \|

| AC-GPS-03 \| Bevestigde terugkeer binnen de zone stopt de countdown
  onmiddellijk. \| TC-GPS-03 positief \|

| AC-GPS-04 \| Een berekende terugkeertijd boven 10% van de spelduur
  wordt afgekapt op 10%; onder 2 minuten wordt opgehoogd naar 2 minuten.
  \| TC-GPS-04 grenswaarden \|

Rekenvoorbeeld TC-PNT-01: r = 50 / (15 × 8,125) = 0,4102564103.
Kwartverlies: 6,153846; 9,230769; 13,846154; 20,769231. Totaal = 50.

Negatieve GPS-test TC-GPS-02: simuleer één foutieve locatie buiten de
zone gevolgd door geldige locaties binnen de zone. Verwacht: geen
eliminatie en geen blijvende buiten-zone-status.

Negatieve geometrie-test TC-ZONE-04: forceer een kandidaat-zone die de
huidige grens kruist. Verwacht: kandidaat wordt niet geaccepteerd;
systeem genereert/berekent een geldige zone binnen de huidige grens.
