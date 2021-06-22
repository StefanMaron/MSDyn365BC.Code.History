codeunit 5604 "Make FA Ledger Entry"
{

    trigger OnRun()
    begin
    end;

    procedure CopyFromFAJnlLine(var FALedgEntry: Record "FA Ledger Entry"; FAJnlLine: Record "FA Journal Line")
    begin
        with FALedgEntry do begin
            Init;
            "User ID" := UserId;
            "Entry No." := FAJnlLine."FA Error Entry No.";
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
            Correction := FAJnlLine.Correction;
            "Reclassification Entry" := FAJnlLine."FA Reclassification Entry";
            "Index Entry" := FAJnlLine."Index Entry";
            "No. of Depreciation Days" := FAJnlLine."No. of Depreciation Days";
            "FA Posting Group" := FAJnlLine."FA Posting Group";
            "Global Dimension 1 Code" := FAJnlLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := FAJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := FAJnlLine."Dimension Set ID";
            "Reason Code" := FAJnlLine."Reason Code";
            "Source Code" := FAJnlLine."Source Code";
            "Journal Batch Name" := FAJnlLine."Journal Batch Name";
            "FA Posting Type" := FAJnlLine.ConvertToLedgEntry(FAJnlLine);
            "No. Series" := FAJnlLine."Posting No. Series";
        end;

        OnAfterCopyFromFAJnlLine(FALedgEntry, FAJnlLine);
    end;

    procedure CopyFromGenJnlLine(var FALedgEntry: Record "FA Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    var
        FAJnlLine: Record "FA Journal Line";
    begin
        with FALedgEntry do begin
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
            "Reclassification Entry" := GenJnlLine."FA Reclassification Entry";
            "No. of Depreciation Days" := GenJnlLine."No. of Depreciation Days";
            "FA Posting Group" := GenJnlLine."Posting Group";
            "Global Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
            "Global Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
            "Dimension Set ID" := GenJnlLine."Dimension Set ID";
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
            "No. Series" := GenJnlLine."Posting No. Series";
            FAJnlLine."FA Posting Type" := GenJnlLine."FA Posting Type" - 1;
            "FA Posting Type" := FAJnlLine.ConvertToLedgEntry(FAJnlLine);
        end;

        OnAfterCopyFromGenJnlLine(FALedgEntry, GenJnlLine);
    end;

    procedure CopyFromFACard(var FALedgEntry: Record "FA Ledger Entry"; var FA: Record "Fixed Asset"; var FADeprBook: Record "FA Depreciation Book")
    var
        xFALedgerEntry: Record "FA Ledger Entry";
    begin
        OnBeforeCopyFromFACard(FALedgEntry, FA, FADeprBook, xFALedgerEntry);

        with FALedgEntry do begin
            "FA Class Code" := FA."FA Class Code";
            "FA Subclass Code" := FA."FA Subclass Code";
            "FA Location Code" := FA."FA Location Code";
            "Location Code" := FA."Location Code";
            "FA Exchange Rate" := FADeprBook.GetExchangeRate;
            "Depreciation Method" := FADeprBook."Depreciation Method";
            "Depreciation Starting Date" := FADeprBook."Depreciation Starting Date";
            "Depreciation Ending Date" := FADeprBook."Depreciation Ending Date";
            "Straight-Line %" := FADeprBook."Straight-Line %";
            "No. of Depreciation Years" := FADeprBook."No. of Depreciation Years";
            "Fixed Depr. Amount" := FADeprBook."Fixed Depr. Amount";
            "Declining-Balance %" := FADeprBook."Declining-Balance %";
            "Depreciation Table Code" := FADeprBook."Depreciation Table Code";
            "Use FA Ledger Check" := FADeprBook."Use FA Ledger Check";
            "Depr. Starting Date (Custom 1)" := FADeprBook."Depr. Starting Date (Custom 1)";
            "Depr. Ending Date (Custom 1)" := FADeprBook."Depr. Ending Date (Custom 1)";
            "Accum. Depr. % (Custom 1)" := FADeprBook."Accum. Depr. % (Custom 1)";
            "Depr. % this year (Custom 1)" := FADeprBook."Depr. This Year % (Custom 1)";
            "Property Class (Custom 1)" := FADeprBook."Property Class (Custom 1)";
        end;

        OnAfterCopyFromFACard(FALedgEntry, FA, FADeprBook, xFALedgerEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFAJnlLine(var FALedgerEntry: Record "FA Ledger Entry"; FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGenJnlLine(var FALedgerEntry: Record "FA Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFACard(var FALedgerEntry: Record "FA Ledger Entry"; var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var xFALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromFACard(var FALedgerEntry: Record "FA Ledger Entry"; var FixedAsset: Record "Fixed Asset"; var FADepreciationBook: Record "FA Depreciation Book"; var xFALedgerEntry: Record "FA Ledger Entry")
    begin
    end;
}

