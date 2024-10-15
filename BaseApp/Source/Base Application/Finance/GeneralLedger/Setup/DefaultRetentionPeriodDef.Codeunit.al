namespace Microsoft.Finance.GeneralLedger.Setup;

codeunit 800 "Default Retention Period Def." implements "Documents - Retention Period"
{
    procedure GetDeletionBlockedAfterDate(): Date
    begin
        exit(0D);
    end;

    procedure GetDeletionBlockedBeforeDate(): Date
    begin
        exit(0D);
    end;

    procedure IsDocumentDeletionAllowedByLaw(PostingDate: Date): Boolean
    begin
        exit(true);
    end;

    procedure CheckDocumentDeletionAllowedByLaw(PostingDate: Date)
    begin
    end;
}