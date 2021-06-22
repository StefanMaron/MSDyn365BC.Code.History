codeunit 366 "Exchange Acc. G/L Journal Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        GenJnlLine2 := Rec;
        "Account Type" := GenJnlLine2."Bal. Account Type";
        "Account No." := GenJnlLine2."Bal. Account No.";
        "VAT %" := GenJnlLine2."Bal. VAT %";
        "VAT Amount" := GenJnlLine2."Bal. VAT Amount";
        "VAT Amount (LCY)" := GenJnlLine2."Bal. VAT Amount (LCY)";
        "VAT Difference" := GenJnlLine2."Bal. VAT Difference";
        "Gen. Posting Type" := GenJnlLine2."Bal. Gen. Posting Type";
        "Gen. Bus. Posting Group" := GenJnlLine2."Bal. Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := GenJnlLine2."Bal. Gen. Prod. Posting Group";
        "VAT Bus. Posting Group" := GenJnlLine2."Bal. VAT Bus. Posting Group";
        "VAT Prod. Posting Group" := GenJnlLine2."Bal. VAT Prod. Posting Group";
        "VAT Calculation Type" := GenJnlLine2."Bal. VAT Calculation Type";
        "VAT Base Amount" := GenJnlLine2."Bal. VAT Base Amount";
        "VAT Base Amount (LCY)" := GenJnlLine2."Bal. VAT Base Amount (LCY)";
        "Tax Area Code" := GenJnlLine2."Bal. Tax Area Code";
        "Tax Liable" := GenJnlLine2."Bal. Tax Liable";
        "Tax Group Code" := GenJnlLine2."Bal. Tax Group Code";
        "Use Tax" := GenJnlLine2."Bal. Use Tax";

        "Bal. Account Type" := GenJnlLine2."Account Type";
        "Bal. Account No." := GenJnlLine2."Account No.";
        "Bal. VAT %" := GenJnlLine2."VAT %";
        "Bal. VAT Amount" := GenJnlLine2."VAT Amount";
        "Bal. VAT Amount (LCY)" := GenJnlLine2."VAT Amount (LCY)";
        "Bal. VAT Difference" := GenJnlLine2."VAT Difference";
        "Bal. Gen. Posting Type" := GenJnlLine2."Gen. Posting Type";
        "Bal. Gen. Bus. Posting Group" := GenJnlLine2."Gen. Bus. Posting Group";
        "Bal. Gen. Prod. Posting Group" := GenJnlLine2."Gen. Prod. Posting Group";
        "Bal. VAT Bus. Posting Group" := GenJnlLine2."VAT Bus. Posting Group";
        "Bal. VAT Prod. Posting Group" := GenJnlLine2."VAT Prod. Posting Group";
        "Bal. VAT Calculation Type" := GenJnlLine2."VAT Calculation Type";
        "Bal. VAT Base Amount" := GenJnlLine2."VAT Base Amount";
        "Bal. VAT Base Amount (LCY)" := GenJnlLine2."VAT Base Amount (LCY)";
        "Bal. Tax Area Code" := GenJnlLine2."Tax Area Code";
        "Bal. Tax Liable" := GenJnlLine2."Tax Liable";
        "Bal. Tax Group Code" := GenJnlLine2."Tax Group Code";
        "Bal. Use Tax" := GenJnlLine2."Use Tax";

        Amount := -GenJnlLine2.Amount;
        "Debit Amount" := GenJnlLine2."Credit Amount";
        "Credit Amount" := GenJnlLine2."Debit Amount";
        "Amount (LCY)" := -GenJnlLine2."Amount (LCY)";
        "Balance (LCY)" := -GenJnlLine2."Balance (LCY)";
        "Source Currency Amount" := -GenJnlLine2."Source Currency Amount";
        if ("Currency Code" <> '') and not "System-Created Entry" then begin
            "Source Currency Amount" := Amount;
            "Source Curr. VAT Base Amount" := "VAT Base Amount";
            "Source Curr. VAT Amount" := "VAT Amount";
        end;

        OnAfterOnRun(Rec, GenJnlLine2);
    end;

    var
        GenJnlLine2: Record "Gen. Journal Line";

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

