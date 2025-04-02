// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

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
        PmtJnlLineToExport: Record "Payment Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        PmtJnlLineToExport.SetFilter("Journal Template Name", FromGenJnlLine.GetFilter("Journal Template Name"));
        PmtJnlLineToExport.SetFilter("Journal Batch Name", FromGenJnlLine.GetFilter("Journal Batch Name"));
        PmtJnlLineToExport.SetFilter("Line No.", FromGenJnlLine.GetFilter("Line No."));
        if PmtJnlLineToExport.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := PmtJnlLineToExport."Journal Template Name";
                TempGenJnlLine."Journal Batch Name" := PmtJnlLineToExport."Journal Batch Name";
                TempGenJnlLine."Document No." := PmtJnlLineToExport."Applies-to Doc. No.";
                TempGenJnlLine."Line No." := PmtJnlLineToExport."Line No.";
                TempGenJnlLine."Account No." := PmtJnlLineToExport."Account No.";
                if PmtJnlLineToExport."Account Type" = PmtJnlLineToExport."Account Type"::Customer then begin
                    TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Customer;
                    TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Refund;
                end else begin
                    TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Vendor;
                    TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                end;
                TempGenJnlLine.Amount := PmtJnlLineToExport.Amount;
                TempGenJnlLine."Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
                TempGenJnlLine."Bal. Account No." := PmtJnlLineToExport."Bank Account";
                TempGenJnlLine."Currency Code" := PmtJnlLineToExport."Currency Code";
                TempGenJnlLine."Posting Date" := PmtJnlLineToExport."Posting Date";
                TempGenJnlLine."Recipient Bank Account" := PmtJnlLineToExport."Beneficiary Bank Account";
                TempGenJnlLine."Message to Recipient" := PmtJnlLineToExport."Payment Message";
                TempGenJnlLine.Insert();
            until PmtJnlLineToExport.Next() = 0;

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

