namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
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
        BankAccount: Record "Bank Account";
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
                with TempGenJnlLine do begin
                    Init();
                    "Journal Template Name" := '';
                    "Journal Batch Name" := '';
                    case RefPmtExp."Document Type" of
                        RefPmtExp."Document Type"::Invoice:
                            "Document Type" := "Document Type"::Payment;
                        else
                            "Document Type" := "Document Type"::" ";
                    end;
                    "Document No." := RefPmtExp."Document No.";
                    "Line No." := RefPmtExp."No.";
                    "Account No." := RefPmtExp."Vendor No.";
                    "Account Type" := TempGenJnlLine."Account Type"::Vendor;
                    "Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
                    "Bal. Account No." := RefPmtExp."Payment Account";
                    "External Document No." := RefPmtExp."External Document No.";
                    Amount := RefPmtExp.Amount;
                    "Applies-to Doc. Type" := Enum::"Gen. Journal Document Type".FromInteger(RefPmtExp."Document Type");
                    "Applies-to Doc. No." := RefPmtExp."Document No.";
                    "Currency Code" := RefPmtExp."Currency Code";
                    "Due Date" := RefPmtExp."Due Date";
                    "Posting Date" := RefPmtExp."Payment Date";
                    "Recipient Bank Account" := RefPmtExp."Vendor Account";
                    Description := CopyStr(RefPmtExp."Description 2", 1, MaxStrLen(Description));
                    "Message to Recipient" := RefPmtExp."External Document No.";

                    Insert();
                end;
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

