namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.Check;
using System.IO;

codeunit 1705 "Exp. Mapping Det Pos. Pay"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        PositivePayDetail: Record "Positive Pay Detail";
        DataExch: Record "Data Exch.";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        RecordRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        if NoDataExchLineDef(Rec."Data Exch. Def Code") then
            exit;

        Window.Open(ProgressMsg);

        // Range through the line types, Look at details...
        LineNo := 1;

        PositivePayDetail.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        if PositivePayDetail.FindSet() then
            repeat
                Window.Update(1, LineNo);
                if HandlePositivePayDetails(PositivePayDetail) then begin
                    DataExch.SetRange("Entry No.", Rec."Entry No.");
                    if DataExch.FindFirst() then begin
                        RecordRef.GetTable(PositivePayDetail);
                        PositivePayExportMgt.InsertDataExchLineForFlatFile(
                          DataExch,
                          LineNo,
                          RecordRef);
                        LineNo := LineNo + 1;
                    end;
                end;
            until PositivePayDetail.Next() = 0;
        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
#pragma warning restore AA0470

    local procedure HandlePositivePayDetails(PositivePayDetail: Record "Positive Pay Detail"): Boolean
    var
        CheckLedgEntry: Record "Check Ledger Entry";
    begin
        if PositivePayDetail.Payee = '' then begin
            CheckLedgEntry.SetRange("Positive Pay Exported", false);
            CheckLedgEntry.SetRange("Data Exch. Voided Entry No.", PositivePayDetail."Data Exch. Entry No.");
            CheckLedgEntry.SetRange("Check No.", PositivePayDetail."Check Number");
            if CheckLedgEntry.FindLast() then
                exit(CheckLedgEntry."Entry Status" <> CheckLedgEntry."Entry Status"::"Test Print");
        end;

        exit(true);
    end;

    local procedure NoDataExchLineDef(DataExchDefCode: Code[20]): Boolean
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.Init();
        DataExchLineDef.SetRange(DataExchLineDef."Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange(DataExchLineDef."Line Type", DataExchLineDef."Line Type"::Detail);
        exit(DataExchLineDef.IsEmpty());
    end;
}

