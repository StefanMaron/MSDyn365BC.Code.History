report 31072 "Sales Price Import/Export"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Price Import/Export';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Sales Price"; "Sales Price")
        {
            DataItemTableView = SORTING("Item No.");
            RequestFilterFields = "Item No.", "Sales Type", "Sales Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break;
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
                    field(ActionFormat; ActionFormat)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Type';
                        OptionCaption = 'TXT Format,XML Format,XLS Format';
                        ToolTip = 'Specifies format type of export/import file';

                        trigger OnValidate()
                        begin
                            SetRequestPage;
                        end;
                    }
                    field(RadioDataportExport; ActionDirection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Direction';
                        OptionCaption = 'Export,Import';
                        ToolTip = 'Specifies direction of report - export or import of file.';

                        trigger OnValidate()
                        begin
                            SetRequestPage;
                        end;
                    }
                    field(DoUpdateExistingWorksheet; DoUpdateExistingWorksheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Existing Worksheet';
                        Enabled = ExcelImportBoxEnable;
                        ToolTip = 'Specifies if the existing workshit will be updated';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            SetRequestPage;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        WorkFile;
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileManagement: Codeunit "File Management";
        XmlSalesPriceExport: XMLport "Sales Price Export";
        XmlSalesPriceImport: XMLport "Sales Price Import";
        ReadInStream: InStream;
        WorkLFile: File;
        ExpOutStream: OutStream;
        ActionFormat: Option TxtFile,"XMLPort",ExcelPort;
        ActionDirection: Option Export,Import;
        FieldCaptionExp: array[20] of Text[250];
        SheetName: Text[250];
        ClientFileName: Text;
        [InDataSet]
        ExcelImportBoxEnable: Boolean;
        ServerFileName: Text;
        ImportFinishedMsg: Label 'Import finished.';
        ExcelBuffEmptyErr: Label 'Excel Table is empty.';
        ConversionErr: Label 'Conversion failed.';
        ImpTxtFileTxt: Label 'Import from Text File';
        ImpXmlFileTxt: Label 'Import from XML File';
        ExpTxtFileTxt: Label 'Export to Text File';
        ExpXmlFileTxt: Label 'Export to XML File';
        ImpXSLFileTxt: Label 'Import from Excel File';
        FileNameErr: Label 'Enter the file name.';
        ToXMLFileNameTxt: Label 'Default.xml';
        ToTXTFileNameTxt: Label 'Default.txt';
        DoUpdateExistingWorksheet: Boolean;
        UpdateWorkbookTxt: Label 'Update Workbook';

    local procedure FExcelExport(var SalesPrice: Record "Sales Price")
    var
        i: Integer;
        j: Integer;
    begin
        with SalesPrice do begin
            FieldCaptionExp[1] := FieldCaption("Item No.");
            FieldCaptionExp[2] := FieldCaption("Sales Type");
            FieldCaptionExp[3] := FieldCaption("Sales Code");
            FieldCaptionExp[4] := FieldCaption("Starting Date");
            FieldCaptionExp[5] := FieldCaption("Currency Code");
            FieldCaptionExp[6] := FieldCaption("Variant Code");
            FieldCaptionExp[7] := FieldCaption("Unit of Measure Code");
            FieldCaptionExp[8] := FieldCaption("Minimum Quantity");
            FieldCaptionExp[9] := FieldCaption("Unit Price");
            FieldCaptionExp[10] := FieldCaption("Price Includes VAT");
            FieldCaptionExp[11] := FieldCaption("Allow Invoice Disc.");
            FieldCaptionExp[12] := FieldCaption("VAT Bus. Posting Gr. (Price)");
            FieldCaptionExp[13] := FieldCaption("Ending Date");
            FieldCaptionExp[14] := FieldCaption("Allow Line Disc.");
        end;
        for i := 1 to 14 do
            EnterCell(1, i, FieldCaptionExp[i], true, '@');

        j := 2; // @ means, that data have text property in Excel sheet. It is important during Import.
        with SalesPrice do
            if Find('-') then begin
                repeat
                    EnterCell(j, 1, Format("Item No."), false, '@');
                    EnterCell(j, 2, Format("Sales Type"), false, '@');
                    EnterCell(j, 3, Format("Sales Code"), false, '@');
                    EnterCell(j, 4, Format("Starting Date"), false, '');
                    EnterCell(j, 5, Format("Currency Code"), false, '@');
                    EnterCell(j, 6, Format("Variant Code"), false, '@');
                    EnterCell(j, 7, Format("Unit of Measure Code"), false, '@');
                    EnterCell(j, 8, Format("Minimum Quantity"), false, '');
                    EnterCell(j, 9, Format("Unit Price"), false, '');
                    EnterCell(j, 10, Format("Price Includes VAT"), false, '');
                    EnterCell(j, 11, Format("Allow Invoice Disc."), false, '');
                    EnterCell(j, 12, Format("VAT Bus. Posting Gr. (Price)"), false, '@');
                    EnterCell(j, 13, Format("Ending Date"), false, '');
                    EnterCell(j, 14, Format("Allow Line Disc."), false, '');
                    j := j + 1;
                until Next = 0;
            end;

        if DoUpdateExistingWorksheet then begin
            TempExcelBuffer.UpdateBook(ServerFileName, SheetName);
            TempExcelBuffer.WriteSheet('', CompanyName, UserId);
            TempExcelBuffer.CloseBook;
            TempExcelBuffer.DownloadAndOpenExcel;
        end else begin
            TempExcelBuffer.CreateBook('', "Sales Price".TableName);
            TempExcelBuffer.WriteSheet("Sales Price".TableName, CompanyName, UserId);
            TempExcelBuffer.CloseBook;
            TempExcelBuffer.OpenExcel;
        end;
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValueText: Text[250]; IsBold: Boolean; NumberFormatText: Text[30])
    begin
        with TempExcelBuffer do begin
            Init;
            Validate("Row No.", RowNo);
            Validate("Column No.", ColumnNo);
            "Cell Value as Text" := CellValueText;
            Comment := '';
            Formula := '';
            Italic := false;
            Bold := IsBold;
            Underline := false;
            NumberFormat := NumberFormatText;
            Insert;
        end;
    end;

    local procedure FExcelImport()
    var
        TempSalesPrice: Record "Sales Price" temporary;
        NoOfColumns: Integer;
        NoOfRows: Integer;
        i: Integer;
        j: Integer;
        StartingDate: Date;
        MinimumQuantity: Decimal;
        UnitPrice: Decimal;
        PriceIncVAT: Boolean;
        AllowInvDisc: Boolean;
        EndingDate: Date;
        IsAllowLD: Boolean;
    begin
        with TempExcelBuffer do begin
            OpenBook(ServerFileName, SheetName);
            ReadSheet;

            NoOfColumns := 14;
            if FindLast then
                NoOfRows := "Row No."
            else
                Error(ExcelBuffEmptyErr);

            for i := 2 to NoOfRows do begin
                TempSalesPrice.Init;
                TempSalesPrice."Item No." := '';
                TempSalesPrice."Sales Type" := TempSalesPrice."Sales Type"::Customer;
                TempSalesPrice."Sales Code" := '';
                TempSalesPrice."Starting Date" := 0D;
                TempSalesPrice."Currency Code" := '';
                TempSalesPrice."Variant Code" := '';
                TempSalesPrice."Unit of Measure Code" := '';
                TempSalesPrice."Minimum Quantity" := 0;

                for j := 1 to NoOfColumns do
                    if Get(i, j) then
                        case j of
                            1:
                                begin
                                    TempSalesPrice.Validate("Item No.", CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."Item No.")));
                                    TempSalesPrice."Unit of Measure Code" := '';
                                end;
                            2:
                                begin
                                    Evaluate(TempSalesPrice."Sales Type", "Cell Value as Text");
                                    TempSalesPrice.Validate("Sales Type");
                                end;
                            3:
                                TempSalesPrice.Validate("Sales Code", CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."Sales Code")));
                            4:
                                if Evaluate(StartingDate, "Cell Value as Text") then
                                    TempSalesPrice.Validate("Starting Date", StartingDate)
                                else
                                    Error(ConversionErr);
                            5:
                                TempSalesPrice.Validate("Currency Code", CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."Currency Code")));
                            6:
                                TempSalesPrice.Validate("Variant Code", CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."Variant Code")));
                            7:
                                TempSalesPrice.Validate(
                                  "Unit of Measure Code", CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."Unit of Measure Code")));
                            8:
                                if Evaluate(MinimumQuantity, "Cell Value as Text") then
                                    TempSalesPrice."Minimum Quantity" := MinimumQuantity
                                else
                                    Error(ConversionErr);
                            9:
                                if Evaluate(UnitPrice, "Cell Value as Text") then
                                    TempSalesPrice."Unit Price" := UnitPrice
                                else
                                    Error(ConversionErr);
                            10:
                                if Evaluate(PriceIncVAT, "Cell Value as Text") then
                                    TempSalesPrice."Price Includes VAT" := PriceIncVAT
                                else
                                    Error(ConversionErr);
                            11:
                                if Evaluate(AllowInvDisc, "Cell Value as Text") then
                                    TempSalesPrice."Allow Invoice Disc." := AllowInvDisc
                                else
                                    Error(ConversionErr);
                            12:
                                TempSalesPrice.Validate(
                                  "VAT Bus. Posting Gr. (Price)",
                                  CopyStr("Cell Value as Text", 1, MaxStrLen(TempSalesPrice."VAT Bus. Posting Gr. (Price)")));
                            13:
                                if Evaluate(EndingDate, "Cell Value as Text") then begin
                                    TempSalesPrice.Validate("Ending Date", EndingDate);
                                    TempSalesPrice."Ending Date" := EndingDate;
                                end else
                                    Error(ConversionErr);
                            14:
                                if Evaluate(IsAllowLD, "Cell Value as Text") then
                                    TempSalesPrice."Allow Line Disc." := IsAllowLD
                                else
                                    Error(ConversionErr);
                        end;
                TempSalesPrice.Insert;
            end;
        end;

        InsertSalesPriceLine(TempSalesPrice);
    end;

    local procedure SetRequestPage()
    begin
        ExcelImportBoxEnable := ((ActionFormat = ActionFormat::ExcelPort) and (ActionDirection = ActionDirection::Export));
    end;

    [Scope('OnPrem')]
    procedure WorkFile()
    var
        TempSalesPrice: Record "Sales Price" temporary;
        TempBlob: Codeunit "Temp Blob";
        TextLine: Text[1024];
    begin
        case ActionFormat of
            ActionFormat::XMLPort:
                case ActionDirection of
                    ActionDirection::Import:
                        begin
                            ClientFileName := ToXMLFileNameTxt;
                            ServerFileName := FileManagement.BLOBImportWithFilter(
                                TempBlob, ImpXmlFileTxt, ClientFileName, FileManagement.GetToFilterText('', '.xml'), '*.*');
                            if not Exists(ServerFileName) then
                                Error(FileNameErr);
                            TempBlob.CreateInStream(ReadInStream);
                            XmlSalesPriceImport.SetSource(ReadInStream);
                            XmlSalesPriceImport.Import;
                            Message(ImportFinishedMsg);
                        end;
                    ActionDirection::Export:
                        begin
                            ClientFileName := ToXMLFileNameTxt;
                            ServerFileName := FileManagement.ServerTempFileName('.xml');
                            WorkLFile.Create(ServerFileName);
                            WorkLFile.CreateOutStream(ExpOutStream);
                            XmlSalesPriceExport.SetDestination(ExpOutStream);
                            XmlSalesPriceExport.SetTableView("Sales Price");
                            XmlSalesPriceExport.Export;
                            WorkLFile.Close;
                            Download(ServerFileName, ExpXmlFileTxt, '', FileManagement.GetToFilterText('', '.xml'), ClientFileName);
                            Erase(ServerFileName);
                        end;
                end;
            ActionFormat::TxtFile:
                case ActionDirection of
                    ActionDirection::Import:
                        begin
                            ServerFileName := FileManagement.ServerTempFileName('.txt');
                            Upload(ImpTxtFileTxt, '', FileManagement.GetToFilterText('', '.txt'), ClientFileName, ServerFileName);
                            if not Exists(ServerFileName) then
                                Error(FileNameErr);
                            WorkLFile.TextMode := true;
                            WorkLFile.Open(ServerFileName);
                            while WorkLFile.Pos <> WorkLFile.Len do begin
                                WorkLFile.Read(TextLine);
                                ImpLine(TempSalesPrice, TextLine);
                            end;
                            InsertSalesPriceLine(TempSalesPrice);
                            WorkLFile.Close;
                            Erase(ServerFileName);
                            Message(ImportFinishedMsg);
                        end;
                    ActionDirection::Export:
                        begin
                            ClientFileName := ToTXTFileNameTxt;
                            ServerFileName := FileManagement.ServerTempFileName('.txt');
                            WorkLFile.TextMode(true);
                            WorkLFile.WriteMode(true);
                            WorkLFile.Create(ServerFileName);
                            if "Sales Price".FindSet then
                                repeat
                                    WorkLFile.Write(ExpLine("Sales Price"));
                                until "Sales Price".Next = 0;
                            WorkLFile.Close;
                            Download(ServerFileName, ExpTxtFileTxt, '', FileManagement.GetToFilterText('', '.txt'), ClientFileName);
                            Erase(ServerFileName);
                        end;
                end;
            ActionFormat::ExcelPort:
                case ActionDirection of
                    ActionDirection::Import:
                        begin
                            ServerFileName := FileManagement.UploadFile(ImpXSLFileTxt, '.xlsx');
                            if ServerFileName = '' then
                                exit;
                            SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
                            if SheetName = '' then
                                exit;
                            FExcelImport;
                            Message(ImportFinishedMsg);
                        end;
                    ActionDirection::Export:
                        begin
                            if DoUpdateExistingWorksheet then begin
                                ServerFileName := FileManagement.UploadFile(UpdateWorkbookTxt, '.xlsx');
                                if ServerFileName = '' then
                                    exit;
                                SheetName := TempExcelBuffer.SelectSheetsName(ServerFileName);
                                if SheetName = '' then
                                    exit;
                            end;
                            FExcelExport("Sales Price");
                        end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ImpLine(var SalesPrice: Record "Sales Price"; TextLine: Text)
    var
        i: Integer;
        j: Integer;
        TextField: array[20] of Text;
    begin
        while StrPos(TextLine, ';') <> 0 do begin
            i += 1;
            TextField[i] := CopyStr(TextLine, 1, StrPos(TextLine, ';') - 1);
            TextLine := CopyStr(TextLine, StrPos(TextLine, ';') + 1);
        end;
        i += 1;
        TextField[i] := TextLine;
        with SalesPrice do begin
            Clear(SalesPrice);
            for j := 1 to i do
                if TextField[j] <> '' then
                    case true of
                        j = 1:
                            if Evaluate("Item No.", CopyStr(TextField[j], 1, MaxStrLen("Item No."))) then
                                ;
                        j = 2:
                            if Evaluate("Sales Type", TextField[j]) then
                                ;
                        j = 3:
                            if Evaluate("Sales Code", CopyStr(TextField[j], 1, MaxStrLen("Sales Code"))) then
                                ;
                        j = 4:
                            if Evaluate("Starting Date", TextField[j]) then
                                ;
                        j = 5:
                            if Evaluate("Currency Code", CopyStr(TextField[j], 1, MaxStrLen("Currency Code"))) then
                                ;
                        j = 6:
                            if Evaluate("Variant Code", CopyStr(TextField[j], 1, MaxStrLen("Variant Code"))) then
                                ;
                        j = 7:
                            if Evaluate("Unit of Measure Code", CopyStr(TextField[j], 1, MaxStrLen("Unit of Measure Code"))) then
                                ;
                        j = 8:
                            if Evaluate("Minimum Quantity", TextField[j]) then
                                ;
                        j = 9:
                            if Evaluate("Unit Price", TextField[j]) then
                                ;
                        j = 10:
                            if Evaluate("Price Includes VAT", TextField[j]) then
                                ;
                        j = 11:
                            if Evaluate("Allow Invoice Disc.", TextField[j]) then
                                ;
                        j = 12:
                            if Evaluate("VAT Bus. Posting Gr. (Price)", CopyStr(TextField[j], 1, MaxStrLen("VAT Bus. Posting Gr. (Price)"))) then
                                ;
                        j = 13:
                            if Evaluate("Ending Date", TextField[j]) then
                                ;
                        j = 14:
                            if Evaluate("Allow Line Disc.", TextField[j]) then
                                ;
                    end;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure ExpLine(SalesPrice: Record "Sales Price") TextLine: Text[1024]
    begin
        Clear(TextLine);
        with SalesPrice do begin
            TextLine := StrSubstNo('%1;', Format("Item No."));
            TextLine += StrSubstNo('%1;', Format("Sales Type"));
            TextLine += StrSubstNo('%1;', Format("Sales Code"));
            TextLine += StrSubstNo('%1;', Format("Starting Date"));
            TextLine += StrSubstNo('%1;', Format("Currency Code"));
            TextLine += StrSubstNo('%1;', Format("Variant Code"));
            TextLine += StrSubstNo('%1;', Format("Unit of Measure Code"));
            TextLine += StrSubstNo('%1;', Format("Minimum Quantity"));
            TextLine += StrSubstNo('%1;', Format("Unit Price"));
            TextLine += StrSubstNo('%1;', Format("Price Includes VAT"));
            TextLine += StrSubstNo('%1;', Format("Allow Invoice Disc."));
            TextLine += StrSubstNo('%1;', Format("VAT Bus. Posting Gr. (Price)"));
            TextLine += StrSubstNo('%1;', Format("Ending Date"));
            TextLine += Format("Allow Line Disc.");
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertSalesPriceLine(var TempSalesPrice: Record "Sales Price" temporary)
    var
        SalesPrice: Record "Sales Price";
    begin
        with TempSalesPrice do begin
            if Find('-') then
                repeat
                    if SalesPrice.Get("Item No.", "Sales Type", "Sales Code", "Starting Date",
                         "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
                    then begin
                        SalesPrice."Unit Price" := "Unit Price";
                        SalesPrice."Price Includes VAT" := "Price Includes VAT";
                        SalesPrice."Allow Invoice Disc." := "Allow Invoice Disc.";
                        SalesPrice."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
                        SalesPrice."Ending Date" := "Ending Date";
                        SalesPrice."Allow Line Disc." := "Allow Line Disc.";
                        SalesPrice.Modify;
                    end else begin
                        SalesPrice."Item No." := "Item No.";
                        SalesPrice."Sales Type" := "Sales Type";
                        SalesPrice."Sales Code" := "Sales Code";
                        SalesPrice."Starting Date" := "Starting Date";
                        SalesPrice."Currency Code" := "Currency Code";
                        SalesPrice."Variant Code" := "Variant Code";
                        SalesPrice."Unit of Measure Code" := "Unit of Measure Code";
                        SalesPrice."Minimum Quantity" := "Minimum Quantity";
                        SalesPrice."Unit Price" := "Unit Price";
                        SalesPrice."Price Includes VAT" := "Price Includes VAT";
                        SalesPrice."Allow Invoice Disc." := "Allow Invoice Disc.";
                        SalesPrice."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";
                        SalesPrice."Ending Date" := "Ending Date";
                        SalesPrice."Allow Line Disc." := "Allow Line Disc.";
                        SalesPrice.Insert;
                    end;
                until Next = 0;
        end;
    end;
}

