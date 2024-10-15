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
        HasErrorsErr: Label 'The file export has one or more errors. For each of the lines to be exported, resolve any errors that are displayed in the File Export Errors FactBox.';

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
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        SEPADDCheckLine: Codeunit "SEPA DD-Check Line";
        AppliesToEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        ToDirectDebitCollectionEntry.Reset();
        DirectDebitCollection.Get(FromDirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No."));
        PaymentHeader.Get(DirectDebitCollection.Identifier);
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        if PaymentLine.FindSet() then
            with ToDirectDebitCollectionEntry do
                repeat
                    Init;
                    "Entry No." := PaymentLine."Line No.";
                    "Direct Debit Collection No." := DirectDebitCollection."No.";
                    DeletePaymentFileErrors;
                    if SEPADDCheckLine.CheckPaymentLine(ToDirectDebitCollectionEntry, PaymentLine, AppliesToEntryNo) then begin
                        Validate("Customer No.", PaymentLine."Account No.");
                        Validate("Applies-to Entry No.", AppliesToEntryNo);
                        "Transfer Date" := PaymentHeader."Posting Date";
                        "Currency Code" := PaymentLine."Currency Code";
                        Validate("Transfer Amount", PaymentLine."Credit Amount");
                        Validate("Mandate ID", PaymentLine."Direct Debit Mandate ID");
                        OnCreateTempCollectionEntriesOnBeforeInsert(ToDirectDebitCollectionEntry, PaymentHeader, PaymentLine);
                        Insert;
                        SEPADDCheckLine.CheckCollectionEntry(ToDirectDebitCollectionEntry);
                    end;
                until PaymentLine.Next() = 0;

        if DirectDebitCollection.HasPaymentFileErrors then begin
            Commit();
            Error(HasErrorsErr);
        end;

        OnAfterCreateTempCollectionEntries(FromDirectDebitCollectionEntry, ToDirectDebitCollectionEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempCollectionEntries(var FromDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; isHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempCollectionEntriesOnBeforeInsert(var ToDirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; PaymentHeader: Record "Payment Header"; PaymentLine: Record "Payment Line")
    begin
    end;
}

