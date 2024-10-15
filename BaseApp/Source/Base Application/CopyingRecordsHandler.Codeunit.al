codeunit 11770 "Copying Records Handler"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, 5222, 'OnAfterCopyEmployeeLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyEmployeeLedgerEntryFromGenJnlLine(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        with EmployeeLedgerEntry do begin
            "Specific Symbol" := GenJournalLine."Specific Symbol";
            "Variable Symbol" := GenJournalLine."Variable Symbol";
            "Constant Symbol" := GenJournalLine."Constant Symbol";
        end;
    end;
}

