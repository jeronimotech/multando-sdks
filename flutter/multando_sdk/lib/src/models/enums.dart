import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum ReportStatus {
  @JsonValue('draft')
  draft('draft'),
  @JsonValue('submitted')
  submitted('submitted'),
  @JsonValue('under_review')
  underReview('under_review'),
  @JsonValue('verified')
  verified('verified'),
  @JsonValue('rejected')
  rejected('rejected'),
  @JsonValue('appealed')
  appealed('appealed'),
  @JsonValue('resolved')
  resolved('resolved');

  const ReportStatus(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum ReportSource {
  @JsonValue('mobile_app')
  mobileApp('mobile_app'),
  @JsonValue('web')
  web('web'),
  @JsonValue('sdk')
  sdk('sdk'),
  @JsonValue('api')
  api('api');

  const ReportSource(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum VehicleCategory {
  @JsonValue('car')
  car('car'),
  @JsonValue('motorcycle')
  motorcycle('motorcycle'),
  @JsonValue('truck')
  truck('truck'),
  @JsonValue('bus')
  bus('bus'),
  @JsonValue('van')
  van('van'),
  @JsonValue('bicycle')
  bicycle('bicycle'),
  @JsonValue('other')
  other('other');

  const VehicleCategory(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum EvidenceType {
  @JsonValue('photo')
  photo('photo'),
  @JsonValue('video')
  video('video'),
  @JsonValue('audio')
  audio('audio'),
  @JsonValue('document')
  document('document');

  const EvidenceType(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum InfractionCategory {
  @JsonValue('parking')
  parking('parking'),
  @JsonValue('speeding')
  speeding('speeding'),
  @JsonValue('red_light')
  redLight('red_light'),
  @JsonValue('illegal_turn')
  illegalTurn('illegal_turn'),
  @JsonValue('wrong_way')
  wrongWay('wrong_way'),
  @JsonValue('no_seatbelt')
  noSeatbelt('no_seatbelt'),
  @JsonValue('phone_use')
  phoneUse('phone_use'),
  @JsonValue('reckless_driving')
  recklessDriving('reckless_driving'),
  @JsonValue('dui')
  dui('dui'),
  @JsonValue('other')
  other('other');

  const InfractionCategory(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum InfractionSeverity {
  @JsonValue('low')
  low('low'),
  @JsonValue('medium')
  medium('medium'),
  @JsonValue('high')
  high('high'),
  @JsonValue('critical')
  critical('critical');

  const InfractionSeverity(this.value);
  final String value;
}

@JsonEnum(valueField: 'value')
enum TokenTxType {
  @JsonValue('reward')
  reward('reward'),
  @JsonValue('stake')
  stake('stake'),
  @JsonValue('unstake')
  unstake('unstake'),
  @JsonValue('transfer_in')
  transferIn('transfer_in'),
  @JsonValue('transfer_out')
  transferOut('transfer_out'),
  @JsonValue('claim')
  claim('claim'),
  @JsonValue('penalty')
  penalty('penalty');

  const TokenTxType(this.value);
  final String value;
}
