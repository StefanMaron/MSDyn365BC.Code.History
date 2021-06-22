table 747 "VAT Report Archive"
{
    Caption = 'VAT Report Archive';
    Permissions = TableData "VAT Report Archive" = rimd;

    fields
    {
        field(1; "VAT Report Type"; Option)
        {
            Caption = 'VAT Report Type';
            OptionCaption = 'EC Sales List,VAT Return';
            OptionMembers = "EC Sales List","VAT Return";
        }
        field(2; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            TableRelation = "VAT Report Header"."No.";
        }
        field(4; "Submitted By"; Code[50])
        {
            Caption = 'Submitted By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(5; "Submission Message BLOB"; BLOB)
        {
            Caption = 'Submission Message BLOB';
        }
        field(6; "Submittion Date"; Date)
        {
            Caption = 'Submittion Date';
        }
        field(7; "Response Message BLOB"; BLOB)
        {
            Caption = 'Response Message BLOB';
        }
        field(8; "Response Received Date"; DateTime)
        {
            Caption = 'Response Received Date';
        }
    }

    keys
    {
        key(Key1; "VAT Report Type", "VAT Report No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        NoResponseMessageAvailableErr: Label 'The response message of the report is not available.';
        DataCompression: Codeunit "Data Compression";

    procedure ArchiveSubmissionMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20]; TempBlobSubmissionMessage: Codeunit "Temp Blob"): Boolean
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        if VATReportNoValue = '' then
            exit(false);
        if not TempBlobSubmissionMessage.HasValue then
            exit(false);
        if VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            exit(false);

        VATReportArchive.Init();
        VATReportArchive."VAT Report No." := VATReportNoValue;
        VATReportArchive."VAT Report Type" := VATReportTypeValue;
        VATReportArchive."Submitted By" := UserId;
        VATReportArchive."Submittion Date" := Today;
        VATReportArchive.SetSubmissionMessageBLOBFromBlob(TempBlobSubmissionMessage);
        VATReportArchive.Insert(true);
        exit(true);
    end;

    procedure ArchiveResponseMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20]; TempBlobResponseMessage: Codeunit "Temp Blob"): Boolean
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            exit(false);
        if not TempBlobResponseMessage.HasValue then
            exit(false);

        VATReportArchive."Response Received Date" := CurrentDateTime;
        VATReportArchive.SetResponseMessageBLOBFromBlob(TempBlobResponseMessage);
        VATReportArchive.Modify(true);

        exit(true);
    end;

    procedure DownloadSubmissionMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        VATReportArchive: Record "VAT Report Archive";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text[250];
    begin
        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            Error(NoSubmissionMessageAvailableErr);

        if not VATReportArchive."Submission Message BLOB".HasValue then
            Error(NoSubmissionMessageAvailableErr);

        VATReportArchive.CalcFields("Submission Message BLOB");
        TempBlob.FromRecord(VATReportArchive, VATReportArchive.FieldNo("Submission Message BLOB"));

        ZipFileName := VATReportNoValue + '_Submission.txt';
        DownloadZipFile(ZipFileName, TempBlob);
    end;

    procedure DownloadResponseMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        VATReportArchive: Record "VAT Report Archive";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text[250];
    begin
        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            Error(NoResponseMessageAvailableErr);

        if not VATReportArchive."Response Message BLOB".HasValue then
            Error(NoResponseMessageAvailableErr);

        VATReportArchive.CalcFields("Response Message BLOB");
        TempBlob.FromRecord(VATReportArchive, VATReportArchive.FieldNo("Response Message BLOB"));

        ZipFileName := VATReportNoValue + '_Response.txt';
        DownloadZipFile(ZipFileName, TempBlob);
    end;

    local procedure DownloadZipFile(ZipFileName: Text[250]; TempBlob: Codeunit "Temp Blob")
    var
        ZipTempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        DataCompression.CreateZipArchive;
        TempBlob.CreateInStream(ServerFileInStream);
        DataCompression.AddEntry(ServerFileInStream, ZipFileName);
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        ToFile := ZipFileName + '.zip';
        DownloadFromStream(ZipInStream, '', '', '', ToFile);
    end;

    procedure SetSubmissionMessageBLOBFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Submission Message BLOB"));
        RecordRef.SetTable(Rec);
    end;

    procedure SetResponseMessageBLOBFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Response Message BLOB"));
        RecordRef.SetTable(Rec);
    end;
}

