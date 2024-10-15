namespace Microsoft.Bank.PositivePay;

using System.IO;

codeunit 1708 "Exp. Writing Pos. Pay"
{
    Permissions = TableData "Data Exch." = rimd;

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure ExportPositivePay(DataExchEntryCodeDetail: Integer; DataExchEntryCodeFooter: Integer; Filename: Text; DataExchEntryCodeFooterArray: array[100] of Integer)
    var
        DataExchFooter: Record "Data Exch.";
        DataExchDetail: Record "Data Exch.";
        ExportFile: File;
        OutStream: OutStream;
        InStream: InStream;
        Filename2: Text[250];
        RecordCount: Integer;
        ArrayLength: Integer;
    begin
        // Need to copy the File Name and File from the footer to the Detail record.
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Open(Filename);

        // Copy current file contents to TempBlob
        Filename2 := CopyStr(Filename, 1, 250);

        DataExchDetail.SetRange("Entry No.", DataExchEntryCodeDetail);
        if DataExchDetail.FindFirst() then begin
            DataExchDetail."File Name" := Filename2;
            ExportFile.CreateInStream(InStream);
            DataExchDetail."File Content".CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            DataExchDetail.Modify();
        end;
        ExportFile.Close();

        // Need to clear out the File Name and blob (File Content) for the footer record(s)
        DataExchFooter.SetRange("Entry No.", DataExchEntryCodeFooter);
        if DataExchFooter.FindFirst() then begin
            ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
            RecordCount := 1;
            while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
                DataExchFooter."Entry No." := DataExchEntryCodeFooterArray[RecordCount];
                DataExchFooter."File Name" := '';
                Clear(DataExchFooter."File Content");
                DataExchFooter.Modify();
                RecordCount := RecordCount + 1;
            end;
        end;
    end;

    procedure CleanUpPositivePayWorkTables(DataExchEntryCodeHeaderArray: array[100] of Integer; DataExchEntryCodeDetailArray: array[100] of Integer; DataExchEntryCodeFooterArray: array[100] of Integer)
    var
        PositivePayHeader: Record "Positive Pay Header";
        PositivePayDetail: Record "Positive Pay Detail";
        PositivePayFooter: Record "Positive Pay Footer";
        RecordCount: Integer;
        ArrayLength: Integer;
    begin
        ArrayLength := ArrayLen(DataExchEntryCodeHeaderArray);
        RecordCount := 1;
        while (DataExchEntryCodeHeaderArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayHeader.SetRange("Data Exch. Entry No.", DataExchEntryCodeHeaderArray[RecordCount]);
            PositivePayHeader.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeDetailArray);
        RecordCount := 1;
        while (DataExchEntryCodeDetailArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayDetail.SetRange("Data Exch. Entry No.", DataExchEntryCodeDetailArray[RecordCount]);
            PositivePayDetail.DeleteAll();
            RecordCount := RecordCount + 1;
        end;

        ArrayLength := ArrayLen(DataExchEntryCodeFooterArray);
        RecordCount := 1;
        while (DataExchEntryCodeFooterArray[RecordCount] > 0) and (RecordCount < ArrayLength) do begin
            PositivePayFooter.SetRange("Data Exch. Entry No.", DataExchEntryCodeFooterArray[RecordCount]);
            PositivePayFooter.DeleteAll();
            RecordCount := RecordCount + 1;
        end;
    end;
}

