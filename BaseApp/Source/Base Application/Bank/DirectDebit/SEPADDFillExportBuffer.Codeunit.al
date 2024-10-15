namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;

codeunit 1231 "SEPA DD-Fill Export Buffer"
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Payment Export Data";

    trigger OnRun()
    begin
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';

    procedure FillExportBuffer(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var PaymentExportData: Record "Payment Export Data")
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        GLSetup: Record "General Ledger Setup";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary;
    begin
        TempDirectDebitCollectionEntry.CopyFilters(DirectDebitCollectionEntry);
        CODEUNIT.Run(CODEUNIT::"SEPA DD-Prepare Source", TempDirectDebitCollectionEntry);

        TempDirectDebitCollectionEntry.SetAutoCalcFields("Applies-to Entry Document No.", "Applies-to Entry Description");

        if not TempDirectDebitCollectionEntry.FindSet() then
            exit;

        DirectDebitCollection.Get(TempDirectDebitCollectionEntry."Direct Debit Collection No.");
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");
        GetDDExportImportSetup(BankAccount, BankExportImportSetup);
        BankExportImportSetup.TestField("Check Export Codeunit");
        repeat
            CODEUNIT.Run(BankExportImportSetup."Check Export Codeunit", TempDirectDebitCollectionEntry);
        until TempDirectDebitCollectionEntry.Next() = 0;

        if DirectDebitCollection.HasPaymentFileErrors() then begin
            Commit();
            Error(HasErrorsErr);
        end;

        GLSetup.Get();
        GLSetup.TestField("LCY Code");

        TempDirectDebitCollectionEntry.FindSet();
        PaymentExportData.Reset();
        if PaymentExportData.FindLast() then;
        repeat
            PaymentExportData.Init();
            PaymentExportData."Entry No." += 1;
            PaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");
            PaymentExportData.SetBankAsSenderBank(BankAccount);
            PaymentExportData.SetCreditorIdentifier(BankAccount);
            PaymentExportData."SEPA Direct Debit Mandate ID" := TempDirectDebitCollectionEntry."Mandate ID";
            SEPADirectDebitMandate.Get(TempDirectDebitCollectionEntry."Mandate ID");
            PaymentExportData."SEPA DD Mandate Signed Date" := SEPADirectDebitMandate."Date of Signature";

            TempDirectDebitCollectionEntry."Sequence Type" :=
              UpdateSourceEntrySequenceType(TempDirectDebitCollectionEntry);

            PaymentExportData.Validate(PaymentExportData."SEPA Direct Debit Seq. Type", TempDirectDebitCollectionEntry."Sequence Type");
            PaymentExportData."Transfer Date" := TempDirectDebitCollectionEntry."Transfer Date";
            PaymentExportData."Document No." := TempDirectDebitCollectionEntry."Applies-to Entry Document No.";
            PaymentExportData.Amount := TempDirectDebitCollectionEntry."Transfer Amount";
            PaymentExportData."Currency Code" := GLSetup.GetCurrencyCode(TempDirectDebitCollectionEntry."Currency Code");

            Customer.Get(TempDirectDebitCollectionEntry."Customer No.");
            CustomerBankAccount.Get(Customer."No.", SEPADirectDebitMandate."Customer Bank Account Code");
            PaymentExportData.SetCustomerAsRecipient(Customer, CustomerBankAccount);

            PaymentExportData.Validate(PaymentExportData."SEPA Partner Type", Customer."Partner Type");
            PaymentExportData.Validate(PaymentExportData."SEPA Instruction Priority", PaymentExportData."SEPA Instruction Priority"::NORMAL);
            PaymentExportData.Validate(PaymentExportData."SEPA Payment Method", PaymentExportData."SEPA Payment Method"::TRF);
            PaymentExportData.Validate(PaymentExportData."SEPA Charge Bearer", PaymentExportData."SEPA Charge Bearer"::SLEV);

            PaymentExportData."SEPA Batch Booking" := false;
            PaymentExportData."Message ID" := DirectDebitCollection."Message ID";
            PaymentExportData."Payment Information ID" := TempDirectDebitCollectionEntry."Transaction ID";
            PaymentExportData."End-to-End ID" := TempDirectDebitCollectionEntry."Transaction ID";
            PaymentExportData."Message to Recipient 1" := TempDirectDebitCollectionEntry."Applies-to Entry Description";
            PaymentExportData."Message to Recipient 2" := TempDirectDebitCollectionEntry."Message to Recipient";

            OnBeforeInsertPaymentExportData(PaymentExportData, TempDirectDebitCollectionEntry);
            PaymentExportData.Insert(true);
        until TempDirectDebitCollectionEntry.Next() = 0;
    end;

    local procedure GetDDExportImportSetup(BankAccount: Record "Bank Account"; var BankExportImportSetup: Record "Bank Export/Import Setup")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDDExportImportSetup(BankAccount, BankExportImportSetup, IsHandled);
        if IsHandled then
            exit;

        BankAccount.GetDDExportImportSetup(BankExportImportSetup);
    end;

    local procedure UpdateSourceEntrySequenceType(TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary) SequenceType: Integer
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        if TempDirectDebitCollectionEntry.Status <> TempDirectDebitCollectionEntry.Status::New then
            exit(TempDirectDebitCollectionEntry."Sequence Type");

        SEPADirectDebitMandate.Get(TempDirectDebitCollectionEntry."Mandate ID");
        SequenceType := SEPADirectDebitMandate.GetSequenceType();
        SEPADirectDebitMandate.UpdateCounter();

        DirectDebitCollectionEntry := TempDirectDebitCollectionEntry;
        if DirectDebitCollectionEntry.Find() then begin
            DirectDebitCollectionEntry."Sequence Type" := SequenceType;
            DirectDebitCollectionEntry.Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDDExportImportSetup(BankAccount: Record "Bank Account"; var BankExportImportSetup: Record "Bank Export/Import Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPaymentExportData(var PaymentExportData: Record "Payment Export Data"; var TempDirectDebitCollectionEntry: Record "Direct Debit Collection Entry" temporary)
    begin
    end;
}

