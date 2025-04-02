// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;

codeunit 1232 "SEPA DD-Prepare Source"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.CopyFilters(Rec);
        CopyLines(DirectDebitCollectionEntry, Rec);
    end;

    local procedure CopyLines(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
        if not FromDirectDebitCollectionEntry.IsEmpty() then begin
            FromDirectDebitCollectionEntry.SetFilter(Status, '%1|%2',
              FromDirectDebitCollectionEntry.Status::New, FromDirectDebitCollectionEntry.Status::"File Created");
            if FromDirectDebitCollectionEntry.FindSet() then
                repeat
                    ToDirectDebitCollectionEntry := FromDirectDebitCollectionEntry;
                    ToDirectDebitCollectionEntry.Insert();
                until FromDirectDebitCollectionEntry.Next() = 0
        end else
            CreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    local procedure CreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        LSVJnl: Record "LSV Journal";
        LSVJnlLine: Record "LSV Journal Line";
        DirectDebitCollectionNo: Integer;
        LSVJnlNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        DirectDebitCollectionNo := FromDirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No.");
        DirectDebitCollection.Get(DirectDebitCollectionNo);
        Evaluate(LSVJnlNo, DirectDebitCollection.Identifier);

        if LSVJnl.Get(LSVJnlNo) then begin
            ToDirectDebitCollectionEntry.Reset();
            LSVJnlLine.SetRange("LSV Journal No.", LSVJnlNo);
            if LSVJnlLine.FindSet() then
                repeat
                    ToDirectDebitCollectionEntry.Init();
                    ToDirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollectionNo;
                    ToDirectDebitCollectionEntry."Entry No." := LSVJnlLine."Line No.";
                    ToDirectDebitCollectionEntry.Validate("Customer No.", LSVJnlLine."Customer No.");
                    ToDirectDebitCollectionEntry.Validate("Applies-to Entry No.", LSVJnlLine."Cust. Ledg. Entry No.");
                    if LSVJnlLine."Direct Debit Mandate ID" <> '' then
                        ToDirectDebitCollectionEntry.Validate("Mandate ID", LSVJnlLine."Direct Debit Mandate ID");
                    ToDirectDebitCollectionEntry.Validate("Transfer Amount", LSVJnlLine."Collection Amount");
                    ToDirectDebitCollectionEntry.Insert(true);
                until LSVJnlLine.Next() = 0;
        end;

        OnAfterCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var isHandled: Boolean)
    begin
    end;
}

