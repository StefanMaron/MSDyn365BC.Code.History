#if not CLEAN22
codeunit 352 "Intrastat File Writer"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    var
        DataCompression: Codeunit "Data Compression";
        ResultFileTempBlob: Codeunit "Temp Blob";
        CurrFileTempBlob: Codeunit "Temp Blob";
        ResultFileOutStream: OutStream;
        CurrFileOutStream: OutStream;
        ResultFileOutStreamIsInitialized: Boolean;
        ZipResultFile: Boolean;
        ZipIsInitialized: Boolean;
        SplitShipmentAndReceiptFiles: Boolean;
        CurrFileLineCounter: Integer;
        FileLineCounterLimit: Integer;
        CurrFileName: Text;
        PrevFileName: Text;
        StatisticsPeriod: Code[10];
        DefaultXMLFilenameTxt: Label 'Intrastat-%1.xml', Comment = '%1 - statistics period YYMM';
        DefaultFilenameTxt: Label 'Intrastat-%1.txt', Comment = '%1 - statistics period YYMM';
        DefaultIndexedFilenameTxt: Label 'Intrastat-%1-1.txt', Comment = '%1 - statistics period YYMM, 1 - file start index';
        ShipmentFilenameTxt: Label 'Shipment-%1.txt', Comment = '%1 - statistics period YYMM';
        ReceiptFilenameTxt: Label 'Receipt-%1.txt', Comment = '%1 - statistics period YYMM';
        ZipFilenameTxt: Label 'Intrastat-%1.zip', Comment = '%1 - statistics period YYMM';
#if not CLEAN20
        ServerFileName: Text;
#endif

    procedure Initialize(newZipResultFile: Boolean; newSplitShipmentAndReceiptFiles: Boolean; newFileLineCounterLimit: Integer)
    begin
        ZipResultFile := newZipResultFile;
        SplitShipmentAndReceiptFiles := newSplitShipmentAndReceiptFiles;
        FileLineCounterLimit := newFileLineCounterLimit;

        ZipResultFile := ZipResultFile or SplitShipmentAndReceiptFiles or (newFileLineCounterLimit > 0);

        if not ResultFileOutStreamIsInitialized then
            ResultFileTempBlob.CreateOutStream(ResultFileOutStream);
    end;

    procedure InitializeNextFile(newFileName: Text)
    begin
        CurrFileName := newFileName;
        CurrFileLineCounter := 0;
        Clear(CurrFileTempBlob);
        CurrFileTempBlob.CreateOutStream(CurrFileOutStream);
    end;

    procedure SetResultFileOutStream(var newResultFileOutStream: OutStream)
    begin
        ResultFileOutStream := newResultFileOutStream;
        ResultFileOutStreamIsInitialized := true;
    end;

    procedure SetStatisticsPeriod(newStatisticsPeriod: Code[10])
    begin
        StatisticsPeriod := newStatisticsPeriod;
    end;

#if not CLEAN20
    procedure SetServerFileName(newServerFileName: Text)
    begin
        ServerFileName := newServerFileName;
    end;
#endif

    procedure GetDefaultXMLFileName(): Text
    begin
        exit(DefaultXMLFilenameTxt);
    end;

    procedure GetDefaultFileName(): Text
    begin
        exit(DefaultFilenameTxt);
    end;

    procedure GetDefaultIndexedFileName(): Text
    begin
        exit(DefaultIndexedFilenameTxt);
    end;

    procedure GetDefaultShipmentFileName(): Text
    begin
        exit(ShipmentFilenameTxt);
    end;

    procedure GetDefaultReceiptFileName(): Text
    begin
        exit(ReceiptFilenameTxt);
    end;

    procedure GetDefaultOrReceiptFileName(): Text
    begin
        if SplitShipmentAndReceiptFiles then
            exit(ReceiptFilenameTxt);
        exit(DefaultFilenameTxt);
    end;

    procedure GetCurrFileOutStream(): OutStream
    begin
        exit(CurrFileOutStream);
    end;

    procedure IsSplitShipmentAndReceiptFiles(): Boolean
    begin
        exit(SplitShipmentAndReceiptFiles);
    end;

    procedure CloseAndDownloadResultFile()
    var
        FileManagement: Codeunit "File Management";
        ResultFileName: Text;
    begin
        if ZipResultFile then begin
            DataCompression.SaveZipArchive(ResultFileOutStream);
            DataCompression.CloseZipArchive();
        end;

        if ResultFileOutStreamIsInitialized then
            exit;

        if ZipResultFile then
            ResultFileName := ZipFilenameTxt
        else
            ResultFileName := CurrFileName;
        ResultFileName := StrSubstNo(ResultFileName, StatisticsPeriod);

#if not CLEAN20
        if ServerFileName = '' then
            FileManagement.BLOBExport(ResultFileTempBlob, ResultFileName, true)
        else
            FileManagement.BLOBExportToServerFile(ResultFileTempBlob, ServerFileName);
#else
        FileManagement.BLOBExport(ResultFileTempBlob, ResultFileName, true)
#endif
    end;

    procedure AddCurrFileToResultFile()
    var
        CurrFileInStream: InStream;
    begin
        if not ZipIsInitialized and ZipResultFile then begin
            ZipIsInitialized := true;
            DataCompression.CreateZipArchive();
        end;

        if PrevFileName = CurrFileName then
            CurrFileName := IncFileName(CurrFileName);
        CurrFileName := StrSubstNo(CurrFileName, StatisticsPeriod);

        CurrFileTempBlob.CreateInStream(CurrFileInStream);
        if ZipResultFile then
            DataCompression.AddEntry(CurrFileInStream, CurrFileName)
        else
            CopyStream(ResultFileOutStream, CurrFileInStream);

        PrevFileName := CurrFileName;
        InitializeNextFile(CurrFileName);
    end;

    local procedure IncFileName(FileName: Text) NewFileName: Text
    begin
        NewFileName := IncStr(FileName);
        if NewFileName = '' then
            exit(IncStr(DefaultIndexedFilenameTxt));
    end;

    procedure WriteLine(Line: Text)
    begin
        CheckFileLineCounterAndAddToResultFile();

        if CurrFileLineCounter > 0 then
            WriteLineBreak();
        CurrFileOutStream.WriteText(Line);
        CurrFileLineCounter += 1;
    end;

    procedure Write(Line: Text)
    begin
        CurrFileOutStream.WriteText(Line);
    end;

    procedure WriteLineBreak()
    begin
        CurrFileOutStream.WriteText();
    end;

    local procedure CheckFileLineCounterAndAddToResultFile()
    begin
        if (CurrFileLineCounter >= FileLineCounterLimit) and (FileLineCounterLimit > 0) then begin
            ZipResultFile := true;
            AddCurrFileToResultFile();
        end;
    end;
}
#endif