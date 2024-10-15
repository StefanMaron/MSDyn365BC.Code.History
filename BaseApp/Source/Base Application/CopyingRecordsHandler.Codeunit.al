#if not CLEAN18
codeunit 11770 "Copying Records Handler"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Employee Ledger Entry", 'OnAfterCopyEmployeeLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyEmployeeLedgerEntryFromGenJnlLine(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        with EmployeeLedgerEntry do begin
            "Specific Symbol" := GenJournalLine."Specific Symbol";
            "Variable Symbol" := GenJournalLine."Variable Symbol";
            "Constant Symbol" := GenJournalLine."Constant Symbol";
        end;
    end;
}
#endif