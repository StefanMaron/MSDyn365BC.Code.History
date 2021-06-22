codeunit 1230 "SEPA DD-Export File"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        BankAccount: Record "Bank Account";
    begin
        DirectDebitCollectionEntry.Copy(Rec);
        TestField("Direct Debit Collection No.");
        DirectDebitCollection.Get("Direct Debit Collection No.");
        DirectDebitCollection.TestField("To Bank Account No.");
        BankAccount.Get(DirectDebitCollection."To Bank Account No.");
        BankAccount.TestField(IBAN);
        DirectDebitCollection.LockTable;
        DirectDebitCollection.DeletePaymentFileErrors;
        Commit;
        if not Export(Rec, BankAccount.GetDDExportXMLPortID, DirectDebitCollection.Identifier) then
            Error('');

        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DirectDebitCollectionEntry.ModifyAll(Status, DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollection.Status := DirectDebitCollection.Status::"File Created";
        DirectDebitCollection.Modify;
    end;

    var
        ExportToServerFile: Boolean;

    local procedure Export(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; XMLPortID: Integer; FileName: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, DirectDebitCollectionEntry);
        exit(FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', FileName), not ExportToServerFile) <> '');
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}

