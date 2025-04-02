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

    var
        NoDomJnlErr: Label 'There are no domiciliation records.';

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
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        DirectDebitCollection.Get(FromDirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No."));
        DomiciliationJournalLine.SetRange("Journal Template Name", DirectDebitCollection.Identifier);
        DomiciliationJournalLine.SetRange("Journal Batch Name", DirectDebitCollection."Domiciliation Batch Name");
        DomiciliationJournalLine.SetRange(Status, DomiciliationJournalLine.Status::Marked);
        if DomiciliationJournalLine.FindSet() then
            repeat
                ToDirectDebitCollectionEntry.Init();
                ToDirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
                ToDirectDebitCollectionEntry."Entry No." := DomiciliationJournalLine."Line No.";
                ToDirectDebitCollectionEntry.Validate("Customer No.", DomiciliationJournalLine."Customer No.");
                ToDirectDebitCollectionEntry.Validate("Applies-to Entry No.", DomiciliationJournalLine."Applies-to Entry No.");
                ToDirectDebitCollectionEntry."Transfer Date" := DomiciliationJournalLine."Posting Date";
                ToDirectDebitCollectionEntry.Validate("Transfer Amount", -DomiciliationJournalLine.Amount);
                ToDirectDebitCollectionEntry.Validate("Mandate ID", DomiciliationJournalLine."Direct Debit Mandate ID");
                ToDirectDebitCollectionEntry."Message to Recipient" := DomiciliationJournalLine."Message 1";
                if DomiciliationJournalLine."Message 2" <> '' then begin
                    if ToDirectDebitCollectionEntry."Message to Recipient" <> '' then
                        ToDirectDebitCollectionEntry."Message to Recipient" += ', ';
                    ToDirectDebitCollectionEntry."Message to Recipient" += DomiciliationJournalLine."Message 2";
                end;
                ToDirectDebitCollectionEntry.Insert(true);
            until DomiciliationJournalLine.Next() = 0
        else
            Error(NoDomJnlErr);

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

