codeunit 1222 "SEPA CT-Prepare Source"
{
    TableNo = "Gen. Journal Line";

    var
        DescriptionTxt: Label '%1; %2', Comment = '%1=Vendor Invoice No., %2=Bill No.';

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.CopyFilters(Rec);
        CopyJnlLines(GenJnlLine, Rec);
    end;

    local procedure CopyJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if FromGenJnlLine.FindSet() then begin
            GenJnlBatch.Get(FromGenJnlLine."Journal Template Name", FromGenJnlLine."Journal Batch Name");

            repeat
                TempGenJnlLine := FromGenJnlLine;
                OnCopyJnlLinesOnBeforeTempGenJnlLineInsert(FromGenJnlLine, TempGenJnlLine, GenJnlBatch);
                TempGenJnlLine.Insert();
            until FromGenJnlLine.Next() = 0
        end else
            CreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    local procedure CreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        PaymentOrder: Record "Payment Order";
        PurchInvHeader: Record "Purch. Inv. Header";
        CarteraDoc: Record "Cartera Doc.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempGenJnlLine.Reset();
        PaymentOrder.Get(FromGenJnlLine.GetFilter("Document No."));
        CarteraDoc.Reset();
        CarteraDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.");
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrder."No.");
        if CarteraDoc.FindSet() then
            repeat
                with TempGenJnlLine do begin
                    Init;
                    "Journal Template Name" := '';
                    "Journal Batch Name" := '';
                    "Line No." := CarteraDoc."Entry No.";
                    "Posting Date" := CarteraDoc."Due Date";
                    "Due Date" := CarteraDoc."Due Date";
                    "Document Type" := "Document Type"::Payment;
                    "Account Type" := "Account Type"::Vendor;
                    "Account No." := CarteraDoc."Account No.";
                    "Recipient Bank Account" := CarteraDoc."Cust./Vendor Bank Acc. Code";
                    "Bal. Account Type" := "Bal. Account Type"::"Bank Account";
                    "Bal. Account No." := PaymentOrder."Bank Account No.";
                    "Bill No." := CarteraDoc."Document No.";
                    "Document No." := PaymentOrder."No.";
                    if PurchInvHeader.Get(CarteraDoc."Document No.") then
                        Description := StrSubstNo(DescriptionTxt, PurchInvHeader."Vendor Invoice No.", CarteraDoc.Description);
                    "External Document No." := CarteraDoc."Original Document No.";
                    "Currency Code" := CarteraDoc."Currency Code";
                    Amount := CarteraDoc."Remaining Amount";
                    Insert;
                end;
            until CarteraDoc.Next() = 0;

        OnAfterCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJnlLinesOnBeforeTempGenJnlLineInsert(var FromGenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;
}

