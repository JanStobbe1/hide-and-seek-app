class IntroductionRequest {
  const IntroductionRequest({required this.gameName, required this.region, required this.organizer, required this.durationMinutes, required this.maxParticipants, required this.hintsEnabled, required this.questionsEnabled});
  final String gameName, region, organizer; final int durationMinutes, maxParticipants; final bool hintsEnabled, questionsEnabled;
  String get fingerprint => [gameName, region, organizer, durationMinutes, maxParticipants, hintsEnabled, questionsEnabled].join('|');
}
abstract interface class IntroductionService { String generate(IntroductionRequest request,{required int variant}); }
class DemoIntroductionService implements IntroductionService {
  const DemoIntroductionService();
  static const openings = ['Welkom bij','Maak je klaar voor','Durf jij mee te doen aan','Het avontuur begint met','Ontdek','Speur mee tijdens','Verstop je slim bij','Tijd voor','Daag je vrienden uit met','Beleef samen'];
  @override String generate(IntroductionRequest r,{required int variant}) {
    final extras=[if(r.hintsEnabled)'hints',if(r.questionsEnabled)'vragen'];
    return '${openings[variant % openings.length]} ${r.gameName} in ${r.region}. ${r.organizer} organiseert ${r.durationMinutes} minuten verstopplezier voor maximaal ${r.maxParticipants} spelers${extras.isEmpty ? '' : ', met ${extras.join(' en ')}'}.';
  }
}
enum IntroductionOrigin { empty, manual, generated }
class IntroductionDraft {
  String text=''; IntroductionOrigin origin=IntroductionOrigin.empty; String? _fingerprint;
  void setManual(String value){text=value; origin=value.isEmpty?IntroductionOrigin.empty:IntroductionOrigin.manual; _fingerprint=null;}
  void setGenerated(String value,IntroductionRequest request){text=value;origin=IntroductionOrigin.generated;_fingerprint=request.fingerprint;}
  void sourcesChanged(IntroductionRequest request){if(origin==IntroductionOrigin.generated && _fingerprint!=request.fingerprint){text='';origin=IntroductionOrigin.empty;_fingerprint=null;}}
}
