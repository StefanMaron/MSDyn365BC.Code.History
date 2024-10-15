namespace Microsoft.Bank.PositivePay;

using System.IO;

codeunit 1703 "Exp. Mapping Head Pos. Pay"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        PositivePayHeader: Record "Positive Pay Header";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        PositivePayExportMgt: Codeunit "Positive Pay Export Mgt";
        RecordRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        Window.Open(ProgressMsg);

        // Range through the Header record
        LineNo := 1;
        DataExchLineDef.Init();
        DataExchLineDef.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchLineDef.SetRange("Line Type", DataExchLineDef."Line Type"::Header);
        if DataExchLineDef.FindFirst() then begin
            DataExch.SetRange("Entry No.", Rec."Entry No.");
            if DataExch.FindFirst() then begin
                PositivePayHeader.Init();
                PositivePayHeader.SetRange("Data Exch. Entry No.", Rec."Entry No.");
                if PositivePayHeader.FindFirst() then begin
                    Window.Update(1, LineNo);
                    RecordRef.GetTable(PositivePayHeader);
                    PositivePayExportMgt.InsertDataExchLineForFlatFile(
                      DataExch,
                      LineNo,
                      RecordRef);
                end;
            end;
        end;
        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
#pragma warning restore AA0470
}

