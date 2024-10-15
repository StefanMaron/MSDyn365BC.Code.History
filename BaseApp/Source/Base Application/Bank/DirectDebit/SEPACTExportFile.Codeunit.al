namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using System.Utilities;

codeunit 1220 "SEPA CT-Export File"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        Rec.LockTable();
        BankAccount.Get(Rec."Bal. Account No.");
        if Export(Rec, BankAccount.GetPaymentExportXMLPortID()) then
            ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(Rec);
    end;

    var
        ExportToServerFile: Boolean;
        FeatureNameTxt: label 'SEPA Credit Transfer Export', locked = true;

    internal procedure FeatureName(): Text
    begin
        exit(FeatureNameTxt)
    end;

    procedure Export(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer) Result: Boolean
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        CHMgt: Codeunit CHMgt;
        OutStr: OutStream;
        UseCommonDialog: Boolean;
        FileCreated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExtport(GenJnlLine, XMLPortID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, GenJnlLine);

        if CHMgt.IsSwissSEPACTExport(GenJnlLine) then
            case XMLPortID of
               XMLPort::"SEPA CT pain.001.001.03":
                    CHMgt.ReplaceXMLNamespaceCaption(
                      TempBlob,
                      'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03',
                      'http://www.six-interbank-clearing.com/de/pain.001.001.03.ch.02.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.six-interbank-clearing.com/de/pain.001.001.03.ch.02.xsd  pain.001.001.03.ch.02.xsd');
               XMLPort::"SEPA CT pain.001.001.09":
                    CHMgt.ReplaceXMLNamespaceCaption(
                      TempBlob,
                      'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09',
                      'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09 pain.001.001.09.ch.03.xsd');
            end;
        CreditTransferRegister.FindLast();
        UseCommonDialog := not ExportToServerFile;
        OnBeforeBLOBExport(TempBlob, CreditTransferRegister, UseCommonDialog, FileCreated, IsHandled);
        if not IsHandled then
            FileCreated :=
              FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', CreditTransferRegister.Identifier), UseCommonDialog) <> '';
        if FileCreated then
            SetCreditTransferRegisterToFileCreated(CreditTransferRegister, TempBlob);

        exit(CreditTransferRegister.Status = CreditTransferRegister.Status::"File Created");
    end;

    local procedure SetCreditTransferRegisterToFileCreated(var CreditTransferRegister: Record "Credit Transfer Register"; var TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        CreditTransferRegister.Status := CreditTransferRegister.Status::"File Created";
        RecordRef.GetTable(CreditTransferRegister);
        TempBlob.ToRecordRef(RecordRef, CreditTransferRegister.FieldNo("Exported File"));
        RecordRef.SetTable(CreditTransferRegister);
        CreditTransferRegister.Modify();
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBLOBExport(var TempBlob: Codeunit "Temp Blob"; CreditTransferRegister: Record "Credit Transfer Register"; UseComonDialog: Boolean; var FieldCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExtport(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

