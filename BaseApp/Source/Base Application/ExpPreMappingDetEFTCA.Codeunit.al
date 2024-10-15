codeunit 10338 "Exp. Pre-Mapping Det EFT CA"
{
    Permissions = TableData "EFT Export" = rimd;
    TableNo = "EFT Export Workset";

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure PrepareEFTDetails(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; DataExchangeEntryNo: Integer; LineNo: Integer; var DetailArray: array[100] of Integer; var ExportEFTRB: Codeunit "Export EFT (RB)"; DataExchLineDefCode: Code[20]; var EFTValues: Codeunit "EFT Values")
    var
        BankAccount: Record "Bank Account";
        GenerateEFT: Codeunit "Generate EFT";
        DetailCount: Integer;
    begin
        DetailCount := 0;
        DetailCount := DetailCount + 1;
        DetailArray[DetailCount] := DataExchangeEntryNo;
        LineNo += 1;
        PrepareEFTDetail(DataExchangeEntryNo, DataExchLineDefCode);
        BankAccount.Get(TempEFTExportWorkset."Bank Account No.");
        EFTValues.GetParentBoolean;
        EFTValues.GetTotalFileCredit;

        ExportEFTRB.ExportElectronicPayment(
          TempEFTExportWorkset, EFTValues.GetPaymentAmt(TempEFTExportWorkset),
          TempEFTExportWorkset.UserSettleDate, DataExchangeEntryNo, DataExchLineDefCode, EFTValues);
        GenerateEFT.UpdateEFTExport(TempEFTExportWorkset);
        DataExchangeEntryNo := DataExchangeEntryNo + 1;
    end;

    local procedure PrepareEFTDetail(DataExchangeEntryNo: Integer; DataExchLineDefCode: Code[20])
    var
        ACHRBDetail: Record "ACH RB Detail";
    begin
        with ACHRBDetail do begin
            Init;
            "Data Exch. Entry No." := DataExchangeEntryNo;
            "Data Exch. Line Def Code" := DataExchLineDefCode;
            Insert(true);
        end;
    end;
}

