"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Locale = exports.TransactionType = exports.LogLevel = exports.InfractionCategory = exports.InfractionSeverity = exports.EvidenceType = exports.ReportStatus = void 0;
var ReportStatus;
(function (ReportStatus) {
    ReportStatus["Draft"] = "draft";
    ReportStatus["Submitted"] = "submitted";
    ReportStatus["UnderReview"] = "under_review";
    ReportStatus["Verified"] = "verified";
    ReportStatus["Rejected"] = "rejected";
    ReportStatus["Resolved"] = "resolved";
})(ReportStatus || (exports.ReportStatus = ReportStatus = {}));
var EvidenceType;
(function (EvidenceType) {
    EvidenceType["Photo"] = "photo";
    EvidenceType["Video"] = "video";
    EvidenceType["Document"] = "document";
})(EvidenceType || (exports.EvidenceType = EvidenceType = {}));
var InfractionSeverity;
(function (InfractionSeverity) {
    InfractionSeverity["Low"] = "low";
    InfractionSeverity["Medium"] = "medium";
    InfractionSeverity["High"] = "high";
    InfractionSeverity["Critical"] = "critical";
})(InfractionSeverity || (exports.InfractionSeverity = InfractionSeverity = {}));
var InfractionCategory;
(function (InfractionCategory) {
    InfractionCategory["Parking"] = "parking";
    InfractionCategory["Traffic"] = "traffic";
    InfractionCategory["Safety"] = "safety";
    InfractionCategory["Environmental"] = "environmental";
    InfractionCategory["Documentation"] = "documentation";
    InfractionCategory["Other"] = "other";
})(InfractionCategory || (exports.InfractionCategory = InfractionCategory = {}));
var LogLevel;
(function (LogLevel) {
    LogLevel["None"] = "none";
    LogLevel["Error"] = "error";
    LogLevel["Warn"] = "warn";
    LogLevel["Info"] = "info";
    LogLevel["Debug"] = "debug";
})(LogLevel || (exports.LogLevel = LogLevel = {}));
var TransactionType;
(function (TransactionType) {
    TransactionType["Stake"] = "stake";
    TransactionType["Unstake"] = "unstake";
    TransactionType["Reward"] = "reward";
    TransactionType["Transfer"] = "transfer";
})(TransactionType || (exports.TransactionType = TransactionType = {}));
var Locale;
(function (Locale) {
    Locale["En"] = "en";
    Locale["Es"] = "es";
})(Locale || (exports.Locale = Locale = {}));
//# sourceMappingURL=enums.js.map