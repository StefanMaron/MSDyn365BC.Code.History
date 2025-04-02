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
        RefPmtExp: Record "Ref. Payment - Exported";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJnlLines(FromGenJnlLine, TempGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        RefPmtExp.SetRange(Transferred, false);
        RefPmtExp.SetRange("Applied Payments", false);
        RefPmtExp.SetRange("SEPA Payment", true);

        if RefPmtExp.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := '';
                TempGenJnlLine."Journal Batch Name" := '';
                case RefPmtExp."Document Type" of
                    RefPmtExp."Document Type"::Invoice:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    else
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::" ";
                end;
                TempGenJnlLine."Document No." := RefPmtExp."Document No.";
                TempGenJnlLine."Line No." := RefPmtExp."No.";
                TempGenJnlLine."Account No." := RefPmtExp."Vendor No.";
                TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Vendor;
                TempGenJnlLine."Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
                TempGenJnlLine."Bal. Account No." := RefPmtExp."Payment Account";
                TempGenJnlLine."External Document No." := RefPmtExp."External Document No.";
                TempGenJnlLine.Amount := RefPmtExp.Amount;
                TempGenJnlLine."Applies-to Doc. Type" := Enum::"Gen. Journal Document Type".FromInteger(RefPmtExp."Document Type");
                TempGenJnlLine."Applies-to Doc. No." := RefPmtExp."Document No.";
                TempGenJnlLine."Currency Code" := RefPmtExp."Currency Code";
                TempGenJnlLine."Due Date" := RefPmtExp."Due Date";
                TempGenJnlLine."Posting Date" := RefPmtExp."Payment Date";
                TempGenJnlLine."Recipient Bank Account" := RefPmtExp."Vendor Account";
                TempGenJnlLine.Description := CopyStr(RefPmtExp."Description 2", 1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine."Message to Recipient" := RefPmtExp."External Document No.";

                TempGenJnlLine.Insert();
            until RefPmtExp.Next() = 0;

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

