enum ReportStatus {
  draft('draft'),
  submitted('submitted'),
  underReview('under_review'),
  verified('verified'),
  rejected('rejected'),
  appealed('appealed'),
  resolved('resolved');

  const ReportStatus(this.value);
  final String value;
}

enum ReportSource {
  mobileApp('mobile_app'),
  web('web'),
  sdk('sdk'),
  api('api');

  const ReportSource(this.value);
  final String value;
}

enum VehicleCategory {
  car('car'),
  motorcycle('motorcycle'),
  truck('truck'),
  bus('bus'),
  van('van'),
  bicycle('bicycle'),
  other('other');

  const VehicleCategory(this.value);
  final String value;
}

enum EvidenceType {
  photo('photo'),
  video('video'),
  audio('audio'),
  document('document');

  const EvidenceType(this.value);
  final String value;
}

enum InfractionCategory {
  parking('parking'),
  speeding('speeding'),
  redLight('red_light'),
  illegalTurn('illegal_turn'),
  wrongWay('wrong_way'),
  noSeatbelt('no_seatbelt'),
  phoneUse('phone_use'),
  recklessDriving('reckless_driving'),
  dui('dui'),
  other('other');

  const InfractionCategory(this.value);
  final String value;
}

enum InfractionSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const InfractionSeverity(this.value);
  final String value;
}

enum TokenTxType {
  reward('reward'),
  stake('stake'),
  unstake('unstake'),
  transferIn('transfer_in'),
  transferOut('transfer_out'),
  claim('claim'),
  penalty('penalty');

  const TokenTxType(this.value);
  final String value;
}
