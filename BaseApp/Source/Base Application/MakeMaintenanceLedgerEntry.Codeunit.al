codeunit 5647 "Make Maintenance Ledger Entry"
{

    trigger OnRun()
    begin
    end;

    procedure CopyFromFAJnlLine(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; FAJnlLine: Record "FA Journal Line")
    begin
        with MaintenanceLedgEntry do begin
            Init;
            "User ID" := UserId;
            "G/L Entry No." := 0;
            "Depreciation Book Code" := FAJnlLine."Depreciation Book Code";
            "FA No." := FAJnlLine."FA No.";
            "FA Posting Date" := FAJnlLine."FA Posting Date";
            "Posting Date" := FAJnlLine."Posting Date";
            "Document Date" := FAJnlLine."Document Date";
            if "Document Date" = 0D then
                "Document Date" := "Posting Date";
            "Document Type" := FAJnlLine."Document Type";
            "Document No." := FAJnlLine."Document No.";
            "External Document No." := FAJnlLine."External Document No.";
            Description := FAJnlLine.Description;
            Amount := FAJnlLine.Amount;
            Quantity := FAJnlLine.Quantity;
            "Index Entry" := FAJnlLine."Index Entry";
            "FA Posting Group" := FAJnlLine."FA Posting Group";
            "Global Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FAJnlLine."Dimension Set ID";
            "Reason Code" := FAJnlLine."Reason Code";
            "Source Code" := FAJnlLine."Source Code";
            "Journal Batch Name" := FAJnlLine."Journal Batch Name";
            "Maintenance Code" := FAJnlLine."Maintenance Code";
            Correction := FAJnlLine.Correction;
            "No. Series" := FAJnlLine."Posting No. Series";
        end;

        OnAfterCopyFromFAJnlLine(MaintenanceLedgEntry, FAJnlLine);
    end;

    procedure CopyFromGenJnlLine(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        with MaintenanceLedgEntry do begin
            Init;
            "User ID" := UserId;
            "Entry No." := GenJnlLine."FA Error Entry No.";
            "G/L Entry No." := 1;
            "Depreciation Book Code" := GenJnlLine."Depreciation Book Code";
            "FA No." := GenJnlLine."Account No.";
            "FA Posting Date" := GenJnlLine."FA Posting Date";
            "Posting Date" := GenJnlLine."Posting Date";
            "Document Date" := GenJnlLine."Document Date";
            if "Document Date" = 0D then
                "Document Date" := "Posting Date";
            "Document Type" := GenJnlLine."Document Type";
            "Document No." := GenJnlLine."Document No.";
            "External Document No." := GenJnlLine."External Document No.";
            Description := GenJnlLine.Description;
            Quantity := GenJnlLine.Quantity;
            Correction := GenJnlLine.Correction;
            "Index Entry" := GenJnlLine."Index Entry";
            "FA Posting Group" := GenJnlLine."Posting Group";
            "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := GenJnlLine."Dimension Set ID";
            "Maintenance Code" := GenJnlLine."Maintenance Code";
            "Reason Code" := GenJnlLine."Reason Code";
            "Source Code" := GenJnlLine."Source Code";
            "Journal Batch Name" := GenJnlLine."Journal Batch Name";
            "Bal. Account Type" := GenJnlLine."Bal. Account Type";
            "Bal. Account No." := GenJnlLine."Bal. Account No.";
            "Gen. Posting Type" := GenJnlLine."Gen. Posting Type";
            "Gen. Bus. Posting Group" := GenJnlLine."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GenJnlLine."Gen. Prod. Posting Group";
            "VAT Bus. Posting Group" := GenJnlLine."VAT Bus. Posting Group";
            "VAT Prod. Posting Group" := GenJnlLine."VAT Prod. Posting Group";
            "Tax Area Code" := GenJnlLine."Tax Area Code";
            "Tax Liable" := GenJnlLine."Tax Liable";
            "Tax Group Code" := GenJnlLine."Tax Group Code";
            "Use Tax" := GenJnlLine."Use Tax";
            Correction := GenJnlLine.Correction;
            "No. Series" := GenJnlLine."Posting No. Series";
        end;

        OnAfterCopyFromGenJnlLine(MaintenanceLedgEntry, GenJnlLine);
    end;

    procedure CopyFromFACard(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var FA: Record "Fixed Asset"; var FADeprBook: Record "FA Depreciation Book")
    begin
        with MaintenanceLedgEntry do begin
            "FA Class Code" := FA."FA Class Code";
            "FA Subclass Code" := FA."FA Subclass Code";
            "FA Location Code" := FA."FA Location Code";
            "Location Code" := FA."Location Code";
            "FA Exchange Rate" := FADeprBook.GetExchangeRate;
        end;

        OnAfterCopyFromFACard(MaintenanceLedgEntry, FA, FADeprBook);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFAJnlLine(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFACard(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

