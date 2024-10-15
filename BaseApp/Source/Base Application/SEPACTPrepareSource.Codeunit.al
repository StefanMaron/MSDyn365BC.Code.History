codeunit 1222 "SEPA CT-Prepare Source"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.CopyFilters(Rec);
        CopyJnlLines(GenJnlLine, Rec);
    end;

    var
        CumulativeInvoiceTxt: Label 'Sundry Invoices';

    local procedure CopyJnlLines(var FromGenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if FromGenJnlLine.FindSet then begin
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
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        PrevVendorBillLine: Record "Vendor Bill Line";
        PaymentDocNo: Code[20];
        CumulativeAmount: Decimal;
        CumulativeCnt: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PaymentDocNo := FromGenJnlLine.GetFilter("Document No.");
        VendorBillHeader.Get(PaymentDocNo);
        VendorBillLine.Reset();
        VendorBillLine.SetCurrentKey("Vendor Bill List No.", "Vendor No.", "Due Date", "Vendor Bank Acc. No.", "Cumulative Transfers");
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");

        VendorBillLine.SetRange("Cumulative Transfers", true);
        if VendorBillLine.FindSet then begin
            CumulativeAmount := 0;
            CumulativeCnt := 0;
            PrevVendorBillLine := VendorBillLine;
            repeat
                VendorBillLine.TestField("Document Type", VendorBillLine."Document Type"::Invoice);
                if ((VendorBillLine."Vendor No." <> PrevVendorBillLine."Vendor No.") or (VendorBillLine."Vendor Bank Acc. No." <> PrevVendorBillLine."Vendor Bank Acc. No.")) then begin
                    InsertTempGenJnlLine(TempGenJnlLine, VendorBillHeader, PrevVendorBillLine, CumulativeAmount, CumulativeCnt);
                    CumulativeAmount := VendorBillLine."Amount to Pay";
                    CumulativeCnt := 1;
                end else begin
                    CumulativeAmount += VendorBillLine."Amount to Pay";
                    CumulativeCnt += 1;
                end;
                PrevVendorBillLine := VendorBillLine;
            until VendorBillLine.Next() = 0;
            InsertTempGenJnlLine(TempGenJnlLine, VendorBillHeader, PrevVendorBillLine, CumulativeAmount, CumulativeCnt);
        end;

        VendorBillLine.SetRange("Cumulative Transfers", false);
        if VendorBillLine.FindSet then
            repeat
                VendorBillLine.TestField("Document Type", VendorBillLine."Document Type"::Invoice);
                InsertTempGenJnlLine(TempGenJnlLine, VendorBillHeader, VendorBillLine, VendorBillLine."Amount to Pay", 1);
            until VendorBillLine.Next() = 0;

        OnAfterCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    local procedure InsertTempGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; AmountToPay: Decimal; CumulativeCnt: Integer)
    begin
        with TempGenJnlLine do begin
            Init;
            "Journal Template Name" := '';
            "Journal Batch Name" := '';
            "Document Type" := "Document Type"::Payment;
            "Document No." := VendorBillLine."Vendor Bill List No.";
            "Line No." := VendorBillLine."Line No.";
            "Account No." := VendorBillLine."Vendor No.";
            "Account Type" := TempGenJnlLine."Account Type"::Vendor;
            "Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
            "Bal. Account No." := VendorBillHeader."Bank Account No.";
            Amount := AmountToPay;
            "Applies-to Doc. Type" := VendorBillLine."Document Type";
            "Applies-to Doc. No." := VendorBillLine."Document No.";
            "Currency Code" := VendorBillHeader."Currency Code";
            "Due Date" := VendorBillLine."Due Date";
            "Posting Date" := VendorBillHeader."Posting Date";
            "Recipient Bank Account" := VendorBillLine."Vendor Bank Acc. No.";
            if CumulativeCnt > 1 then begin
                "Applies-to Ext. Doc. No." := '';
                Description := CumulativeInvoiceTxt;
            end else begin
                "Applies-to Ext. Doc. No." := VendorBillLine."External Document No.";
                Description := VendorBillLine.Description;
            end;
            "Message to Recipient" := VendorBillLine."Description 2";
            Insert;
        end;
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

