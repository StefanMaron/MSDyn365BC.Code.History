report 593 "Intrastat - Make Declaration"
{
    Caption = 'Intrastat - Make Declaration';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                var
                    ServerFile: File;
                    ServerFileInStream: InStream;
                begin
                    if LineCounter >= 1000 then begin
                        LineCounter := 0;
                        IntraFile.Close;
                        Clear(IntraFile);
                        ClientFilename := IncStr(ClientFilename);
                        ServerFile.Open(FileName);
                        ServerFile.CreateInStream(ServerFileInStream);
                        DataCompression.AddEntry(ServerFileInStream, ClientFilename);
                        ServerFile.Close;
                        FileName := FileMgt.ServerTempFileName('');
                        IntraFile.TextMode := true;
                        IntraFile.WriteMode := true;
                        IntraFile.Create(FileName);
                        IntraFile.CreateOutStream(OutStreamObj);
                        Window.Update(1, StrSubstNo(Text1100001, FileName));
                    end;

                    RecNo := RecNo + 1;
                    LineCounter := LineCounter + 1;

                    Window.Update(2, Round(RecNo / TotalRecNo * 10000, 1));

                    JournalBatch.Get("Journal Template Name", "Journal Batch Name");
                    JournalBatch.TestField(Reported, false);

                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    "Tariff No." := DelChr("Tariff No.");
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Make Declaration", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        TestField("Total Weight");
                        TestField(Amount);
                    end;

                    if "Total Weight" > 9999999999999.0 then
                        Error(Text1100000, FieldCaption("Total Weight"), "Total Weight");

                    if Amount > 9999999999999.0 then
                        Error(Text1100000, FieldCaption(Amount), Amount);

                    if Quantity > 9999999999999.0 then
                        Error(Text1100000, FieldCaption(Quantity), Quantity);

                    if "Statistical Value" > 9999999999999.0 then
                        Error(Text1100000, FieldCaption("Statistical Value"), "Statistical Value");

                    if Country.Get("Country/Region Code") then
                        CountryCode := Country."EU Country/Region Code"
                    else
                        CountryCode := '';
                    if Country.Get("Country/Region of Origin Code") then
                        CountryOfOriginCode := Country."EU Country/Region Code"
                    else
                        CountryOfOriginCode := '';
                    case "Statistical System" of
                        0:
                            StatSystem := '';
                        "Statistical System"::"1-Final Destination":
                            StatSystem := '1';
                        "Statistical System"::"2-Temporary Destination":
                            StatSystem := '2';
                        "Statistical System"::"3-Temporary Destination+Transformation":
                            StatSystem := '3';
                        "Statistical System"::"4-Return":
                            StatSystem := '4';
                        "Statistical System"::"5-Return+Transformation":
                            StatSystem := '5';
                    end;

                    if LineCounter <> 1 then
                        OutStreamObj.WriteText; // This command is to move to next line

                    OutStreamObj.WriteText(
                      CopyStr(CountryCode, 1, 2) + ';' + // 1
                      CopyStr(Area, 1, 2) + ';' + // 2
                      CopyStr("Shpt. Method Code", 1, 3) + ';' + // 3
                      CopyStr("Transaction Type", 1, 2) + ';' + // 4
                      CopyStr("Transport Method", 1, 1) + ';' + // 5
                      CopyStr("Entry/Exit Point", 1, 4) + ';' + // 6
                      PadStr("Tariff No.", 8) + ';' + // 7
                      CopyStr(CountryOfOriginCode, 1, 2) + ';' + // 8
                      StatSystem + ';' + // 9
                      Format("Total Weight", 0, '<Precision,2:><Integer><Decimal>') + ';' + //10
                      Format(Quantity, 0, '<Precision,2:><Integer><Decimal>') + ';' + //11
                      Format(Amount, 0, '<Precision,2:><Integer><Decimal>') + ';' + //12
                      Format("Statistical Value", 0, '<Precision,2:><Integer><Decimal>') //13
                      );
                end;

                trigger OnPostDataItem()
                begin
                    "Intrastat Jnl. Batch".Reported := true;
                    "Intrastat Jnl. Batch".Modify();

                    // avoid I/O exception error
                    IntraFile.Close;
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(
                      '#1###################################################\\' +
                      '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\');
                    TotalRecNo := "Intrastat Jnl. Line".Count();

                    Window.Update(1, StrSubstNo(Text1100001, FileName));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                IntraReferenceNo := "Statistics Period" + '000000';
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
            end;

            trigger OnPreDataItem()
            begin
                IntrastatJnlLine4.CopyFilter("Journal Template Name", "Journal Template Name");
                IntrastatJnlLine4.CopyFilter("Journal Batch Name", Name);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Filename; ClientFilename)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intrastat File Name';
                        ToolTip = 'Specifies the Intrastat file.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if not IntrastatSetup.Get then
                exit;

            if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
                exit;

            if IntrastatSetup."Report Receipts" then
                "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Receipt)
            else
                if IntrastatSetup."Report Shipments" then
                    "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Shipment)
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClientFilename := DefaultFilenameTxt;
    end;

    trigger OnPostReport()
    var
        ServerFileTempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
        FileToDownload: Text;
    begin
        ClientFilename := IncStr(ClientFilename);
        FileMgt.BLOBImportFromServerFile(ServerFileTempBlob, FileName);
        ServerFileTempBlob.CreateInStream(ServerFileInStream);
        DataCompression.AddEntry(ServerFileInStream, ClientFilename);
        FileToDownload := ZipFilenameTxt;
        DataCompression.SaveZipArchive(TempZipFileOutStream);
        DataCompression.CloseZipArchive;
        TempZipFile.Close;

        if ServerFileName = '' then
            FileMgt.DownloadHandler(TempZipFileName, '', '', FileMgt.GetToFilterText('', ZipFilenameTxt), ZipFilenameTxt)
        else
            FileMgt.CopyServerFile(TempZipFileName, ServerFileName, true);
    end;

    trigger OnPreReport()
    begin
        TempZipFileName := FileMgt.ServerTempFileName('zip');
        TempZipFile.Create(TempZipFileName);
        TempZipFile.CreateOutStream(TempZipFileOutStream);
        DataCompression.CreateZipArchive;
        FileName := FileMgt.ServerTempFileName('');

        IntrastatJnlLine4.CopyFilters("Intrastat Jnl. Line");
        if FileName = '' then
            Error(Text000);
        IntraFile.TextMode := true;
        IntraFile.WriteMode := true;
        IntraFile.Create(FileName);
        IntraFile.CreateOutStream(OutStreamObj);
    end;

    var
        Text000: Label 'Enter the file name.';
        IntrastatJnlLine4: Record "Intrastat Jnl. Line";
        Country: Record "Country/Region";
        FileMgt: Codeunit "File Management";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        DataCompression: Codeunit "Data Compression";
        TempZipFile: File;
        IntraFile: File;
        OutStreamObj: OutStream;
        TempZipFileOutStream: OutStream;
        FileName: Text;
        IntraReferenceNo: Text[10];
        Text1100000: Label 'The value of %1 %2  is bigger than maximum value allowed (9.999.999.999.999).';
        ServerFileName: Text;
        LineCounter: Integer;
        StatSystem: Code[1];
        CountryCode: Code[3];
        CountryOfOriginCode: Code[3];
        JournalBatch: Record "Intrastat Jnl. Batch";
        Text1100001: Label 'Exporting to file %1';
        TotalRecNo: Integer;
        RecNo: Integer;
        Window: Dialog;
        DefaultFilenameTxt: Label 'Default_0.txt', Locked = true;
        ClientFilename: Text;
        TempZipFileName: Text;
        ZipFilenameTxt: Label 'Intrastat.zip', Locked = true;

    procedure InitializeRequest(newServerFileName: Text)
    begin
        ServerFileName := newServerFileName;
    end;

    [Scope('OnPrem')]
    procedure WriteGrTotalsToFile(TotalWeightAmt: Decimal; QuantityAmt: Decimal; StatisticalValueAmt: Decimal)
    begin
        // W1 code referenced DataItemVarName not present in ES; removed (as this function is not called in the ES localization)
    end;

    [Scope('OnPrem')]
    procedure FormatTextAmt(Amount: Decimal): Text[13]
    var
        AmtText: Text[13];
    begin
        AmtText := ConvertStr(Format(Amount), ' ', '0');
        AmtText := DelChr(AmtText, '=', ',');
        while StrLen(AmtText) < 13 do
            AmtText := '0' + AmtText;
        exit(AmtText);
    end;
}

