// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Bank.Payment;

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
        if VendorBillLine.FindSet() then begin
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
        if VendorBillLine.FindSet() then
            repeat
                VendorBillLine.TestField("Document Type", VendorBillLine."Document Type"::Invoice);
                InsertTempGenJnlLine(TempGenJnlLine, VendorBillHeader, VendorBillLine, VendorBillLine."Amount to Pay", 1);
            until VendorBillLine.Next() = 0;

        OnAfterCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine);
    end;

    local procedure InsertTempGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; AmountToPay: Decimal; CumulativeCnt: Integer)
    begin
        TempGenJnlLine.Init();
        TempGenJnlLine."Journal Template Name" := '';
        TempGenJnlLine."Journal Batch Name" := '';
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
        TempGenJnlLine."Document No." := VendorBillLine."Vendor Bill List No.";
        TempGenJnlLine."Line No." := VendorBillLine."Line No.";
        TempGenJnlLine."Account No." := VendorBillLine."Vendor No.";
        TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Vendor;
        TempGenJnlLine."Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
        TempGenJnlLine."Bal. Account No." := VendorBillHeader."Bank Account No.";
        TempGenJnlLine.Amount := AmountToPay;
        TempGenJnlLine."Applies-to Doc. Type" := VendorBillLine."Document Type";
        TempGenJnlLine."Applies-to Doc. No." := VendorBillLine."Document No.";
        TempGenJnlLine."Currency Code" := VendorBillHeader."Currency Code";
        TempGenJnlLine."Due Date" := VendorBillLine."Due Date";
        TempGenJnlLine."Posting Date" := VendorBillHeader."Posting Date";
        TempGenJnlLine."Recipient Bank Account" := VendorBillLine."Vendor Bank Acc. No.";
        if CumulativeCnt > 1 then begin
            TempGenJnlLine."Applies-to Ext. Doc. No." := '';
            TempGenJnlLine.Description := CumulativeInvoiceTxt;
        end else begin
            TempGenJnlLine."Applies-to Ext. Doc. No." := VendorBillLine."External Document No.";
            TempGenJnlLine.Description := VendorBillLine.Description;
        end;
        TempGenJnlLine."Message to Recipient" := VendorBillLine."Description 2";
        OnInsertTempGenJnlLineOnBeforeInsert(TempGenJnlLine, VendorBillLine);
        TempGenJnlLine.Insert();
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

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempGenJnlLineOnBeforeInsert(var TempGenJnlLine: Record "Gen. Journal Line" temporary; VendorBillLine: Record "Vendor Bill Line")
    begin
    end;
}

