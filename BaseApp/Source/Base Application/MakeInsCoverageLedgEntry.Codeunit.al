codeunit 5657 "Make Ins. Coverage Ledg. Entry"
{
    Permissions = TableData "Ins. Coverage Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    procedure CopyFromJnlLine(var InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
        with InsCoverageLedgEntry do begin
            "User ID" := UserId;
            "Insurance No." := InsuranceJnlLine."Insurance No.";
            "FA No." := InsuranceJnlLine."FA No.";
            "FA Description" := InsuranceJnlLine."FA Description";
            "Posting Date" := InsuranceJnlLine."Posting Date";
            "Document Type" := InsuranceJnlLine."Document Type";
            "Document Date" := InsuranceJnlLine."Document Date";
            if "Document Date" = 0D then
                "Document Date" := "Posting Date";
            "Document No." := InsuranceJnlLine."Document No.";
            "External Document No." := InsuranceJnlLine."External Document No.";
            Amount := InsuranceJnlLine.Amount;
            Description := InsuranceJnlLine.Description;
            "Index Entry" := InsuranceJnlLine."Index Entry";
            "Global Dimension 1 Code" := InsuranceJnlLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := InsuranceJnlLine."Shortcut Dimension 2 Code";
            "Source Code" := InsuranceJnlLine."Source Code";
            "Journal Batch Name" := InsuranceJnlLine."Journal Batch Name";
            "Reason Code" := InsuranceJnlLine."Reason Code";
            "Disposed FA" := SetDisposedFA("FA No.");
            "No. Series" := InsuranceJnlLine."Posting No. Series";
        end;

        OnAfterCopyFromJnlLine(InsCoverageLedgEntry, InsuranceJnlLine);
    end;

    procedure CopyFromInsuranceCard(var InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry"; var Insurance: Record Insurance)
    begin
        with InsCoverageLedgEntry do begin
            "FA Class Code" := Insurance."FA Class Code";
            "FA Subclass Code" := Insurance."FA Subclass Code";
            "FA Location Code" := Insurance."FA Location Code";
            "Location Code" := Insurance."Location Code";
        end;
    end;

    procedure SetDisposedFA(FANo: Code[20]): Boolean
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        if FADeprBook.Get(FANo, FASetup."Insurance Depr. Book") then
            exit(FADeprBook."Disposal Date" > 0D);

        exit(false);
    end;

    procedure UpdateInsCoverageLedgerEntryFromFASetup(InsDeprBookCode: Code[10])
    var
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FADeprBook: Record "FA Depreciation Book";
    begin
        with InsCoverageLedgEntry do begin
            if IsEmpty then
                exit;

            SetRange("Disposed FA", true);
            ModifyAll("Disposed FA", false);
            if InsDeprBookCode <> '' then begin
                Reset;
                FADeprBook.SetRange("Depreciation Book Code", InsDeprBookCode);
                FADeprBook.SetFilter("Disposal Date", '<>%1', 0D);
                if FADeprBook.FindSet then
                    repeat
                        SetRange("FA No.", FADeprBook."FA No.");
                        ModifyAll("Disposed FA", true)
                    until FADeprBook.Next = 0;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromJnlLine(var InsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry"; InsuranceJournalLine: Record "Insurance Journal Line")
    begin
    end;
}

