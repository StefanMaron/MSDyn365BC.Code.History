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
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentDocNo: Code[20];
        AppliedDocNoList: Text;
        DescriptionLen: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PaymentDocNo := FromGenJnlLine.GetFilter("Document No.");
        PaymentHeader.Get(PaymentDocNo);
        PaymentLine.Reset();
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        if PaymentLine.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := '';
                TempGenJnlLine."Journal Batch Name" := Format(DATABASE::"Payment Header");
                TempGenJnlLine."Document No." := PaymentHeader."No.";
                TempGenJnlLine."Line No." := PaymentLine."Line No.";
                TempGenJnlLine."Account No." := PaymentLine."Account No.";
                TempGenJnlLine."Account Type" := PaymentLine."Account Type";
                case PaymentLine."Account Type" of
                    PaymentLine."Account Type"::Vendor:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    PaymentLine."Account Type"::Customer:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Refund;
                end;
                TempGenJnlLine.Amount := PaymentLine.Amount;
                TempGenJnlLine."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type";
                TempGenJnlLine."Applies-to Doc. No." := PaymentLine."Applies-to Doc. No.";
                TempGenJnlLine."Applies-to ID" := PaymentLine."Applies-to ID";
                TempGenJnlLine."Bal. Account Type" := PaymentHeader."Account Type";
                TempGenJnlLine."Bal. Account No." := PaymentHeader."Account No.";
                TempGenJnlLine."Currency Code" := PaymentLine."Currency Code";
                TempGenJnlLine."Posting Date" := PaymentLine."Posting Date";
                TempGenJnlLine."Recipient Bank Account" := PaymentLine."Bank Account Code";

                DescriptionLen := MaxStrLen(TempGenJnlLine.Description);
                AppliedDocNoList := PaymentLine.GetAppliedDocNoList(DescriptionLen);
                TempGenJnlLine.Description := CopyStr(AppliedDocNoList, 1, DescriptionLen);
                if StrLen(AppliedDocNoList) > DescriptionLen then
                    TempGenJnlLine."Message to Recipient" :=
                      CopyStr(AppliedDocNoList, DescriptionLen + 1, MaxStrLen(TempGenJnlLine."Message to Recipient"));
                OnCreateTempJnlLinesOnBeforeInsertTempGenJnlLine(TempGenJnlLine, PaymentLine);
                TempGenJnlLine.Insert();
            until PaymentLine.Next() = 0;

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

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJnlLinesOnBeforeInsertTempGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; var PaymentLine: Record "Payment Line")
    begin
    end;
}

