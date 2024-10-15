namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

codeunit 1230 "SEPA DD-Export File"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        BankAccount: Record "Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        DirectDebitCollectionEntry.Copy(Rec);
        GetDirectDebitCollection(Rec, DirectDebitCollection);
        DirectDebitCollection.TestField("To Bank Account No.");
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."SEPA Export w/o Bank Acc. Data" then
            BankAccount.TestField(IBAN)
        else
            if (BankAccount."Bank Account No." = '') or (BankAccount."Bank Branch No." = '') then
                if BankAccount.IBAN = '' then
                    Error(ExportWithoutIBANErr, BankAccount.TableCaption(), BankAccount."No.");

        DirectDebitCollection.LockTable();
        DirectDebitCollection.DeletePaymentFileErrors();
        Commit();
        if not Export(Rec, BankAccount.GetDDExportXMLPortID(), DirectDebitCollection.Identifier) then
            Error('');

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.ModifyAll(Status, DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollection.Status := DirectDebitCollection.Status::"File Created";
        DirectDebitCollection.Modify();
    end;

    var
        ExportToServerFile: Boolean;
        ExportWithoutIBANErr: Label 'Either the Bank Account No. and Bank Branch No. fields or the IBAN field must be filled in for %1 %2.', Comment = '%1= table name, %2=key field value. Example: Either the Bank Account No. and Bank Branch No. fields or the IBAN field must be filled in for Bank Account WWB-OPERATING.';

    local procedure Export(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; XMLPortID: Integer; FileName: Text) Result: Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExport(DirectDebitCollectionEntry, XMLPortID, FileName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, DirectDebitCollectionEntry);

        IsHandled := false;
        OnExportOnAfterXMLPortExport(TempBlob, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', FileName), not ExportToServerFile) <> '');
    end;

    local procedure GetDirectDebitCollection(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var DirectDebitCollection: Record "Direct Debit Collection")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDirectDebitCollection(DirectDebitCollectionEntry, DirectDebitCollection, IsHandled);
        if IsHandled then
            exit;

        DirectDebitCollection.Get(DirectDebitCollectionEntry.GetRangeMin("Direct Debit Collection No."));
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectDebitCollection(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var DirectDebitCollection: Record "Direct Debit Collection"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; XMLPortID: Integer; FileName: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportOnAfterXMLPortExport(var TempBlob: Codeunit "Temp Blob"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

