report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = Type, "Journal Template Name", "Journal Batch Name";

            trigger OnAfterGetRecord()
            begin
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
#if CLEAN19
                IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Make Disk Tax Auth", false);
#else
                if IntrastatSetup."Use Advanced Checklist" then
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Make Disk Tax Auth", false)
                else begin
                    TestField("Tariff No.");
                    TestField("Country/Region Code");
                    TestField("Transaction Type");
                    TestField("Total Weight");
                    TestField("Shpt. Method Code");
                    if "Supplementary Units" then
                        TestField(Quantity);
                end;
#endif
                IntrastatJnlLineTemp := "Intrastat Jnl. Line";
                IntrastatJnlLineTemp.Insert();
            end;

            trigger OnPostDataItem()
            var
                ToFile: Text[1024];
                NilReturn: Boolean;
            begin
#if CLEAN19
                IntraJnlManagement.CheckForJournalBatchError("Intrastat Jnl. Line", true);
#else
                if IntrastatSetup."Use Advanced Checklist" then
                    IntraJnlManagement.CheckForJournalBatchError("Intrastat Jnl. Line", true);
#endif
                NoOfRecords := LineCount + 1;
                LineCount := 1;

                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));

                NilReturn := not IntrastatJnlLineTemp.Find('-');
                WriteHeader(NilReturn, Type = Type::Shipment);

                if not NilReturn then
                    WriteFile;

                CloseFile;

                if ServerFileName <> '' then
                    FileMgt.CopyServerFile(FileName, ServerFileName, true)
                else
                    if not FileMgt.DownloadHandler(FileName, '', '', FileMgt.GetToFilterText('', DefaultFilenameTxt), DefaultFilenameTxt) and NilReturn then
                        Message(Text1040018, FieldName(Type), GetFilter(Type));
            end;

            trigger OnPreDataItem()
            begin
                if not (GetRangeMin(Type) = GetRangeMax(Type)) then
                    FieldError(Type, Text1040013);

                LockTable();
                IntrastatJnlBatch.Get(
                  GetFilter("Journal Template Name"),
                  GetFilter("Journal Batch Name"));
                IntrastatJnlBatch.TestField(Reported, false);
                Type := Type::Receipt;
                if GetFilter(Type) = Format(Type) then begin
                    IntrastatJnlBatch.TestField("Arrivals Reported", false);
                    IntrastatJnlBatch.Validate("Arrivals Reported", true);
                end else begin
                    IntrastatJnlBatch.TestField("Dispatches Reported", false);
                    IntrastatJnlBatch.Validate("Dispatches Reported", true);
                end;
                IntrastatJnlBatch.Modify();
                IntraJnlManagement.ChecklistClearBatchErrors(IntrastatJnlBatch);

                CompanyInfo.Get();
                if FileName = '' then
                    Error(Text1040014);
                Clear(CurrFile);
                CurrFile.TextMode := true;
                CurrFile.WriteMode := true;
                CurrFile.Create(FileName);

                Window.Open(
                  '#1############################################\\' +
                  Text1040015 +
                  Text1040016);

                Window.Update(1, Text1040017 + FileName);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ExportFormatField; ExportFormat)
                    {
                        Caption = 'Export Format';
                        ToolTip = 'Specifies the year for which to report Intrastat. This ensures that the report has the correct format for that year.';
                        ApplicationArea = BasicEU;
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

    trigger OnPreReport()
    begin
        FileName := FileMgt.ServerTempFileName('');

        if ExportFormatIsSpecified then
            ExportFormat := SpecifiedExportFormat;
    end;

    var
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        FileMgt: Codeunit "File Management";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLineTemp: Record "Intrastat Jnl. Line" temporary;
        FileName: Text;
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
        EndPos: Integer;
        CurrFile: File;
        ServerFileName: Text;
        DefaultFilenameTxt: Label 'Default.txt', Locked = true;
        GroupTotal: Boolean;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;
        Text1040013: Label 'must be either Receipt or Shipment';
        Text1040014: Label 'You must specify a filename.';
        Text1040015: Label 'Checking lines        #2######################\';
        Text1040016: Label 'Writing lines to file #3###### @4@@@@@@@@@@@@@';
        Text1040017: Label 'Creating file ';
        Text1040018: Label 'There were no records for %1 %2.';
        Text1040021: Label '<Day,2><Month,2><Year,2>', Locked = true;

    [Scope('OnPrem')]
    procedure WriteFile()
    begin
        with IntrastatJnlLineTemp do begin
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                WriteGrTotalsToFile(IntrastatJnlLineTemp);
            until Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CloseFile()
    begin
        EndPos := CurrFile.Pos;
        CurrFile.Close;
        CurrFile.Open(FileName);
        CurrFile.Seek(EndPos - 2);
        CurrFile.Trunc;
        CurrFile.Close;
    end;

    procedure InitializeRequest(newServerFileName: Text)
    begin
        ServerFileName := newServerFileName;
    end;

    procedure InitializeRequestWithExportFormat(newServerFileName: Text; NewExportFormat: Enum "Intrastat Export Format")
    begin
        ServerFileName := newServerFileName;
        SpecifiedExportFormat := NewExportFormat;
        ExportFormatIsSpecified := true;
    end;

    local procedure WriteHeader(NilReturn: Boolean; IsShipment: Boolean)
    var
        JournalType: Text[1];
        NilReturnCode: Code[10];
    begin
        if NilReturn then
            NilReturnCode := 'N'
        else
            NilReturnCode := 'X';

        if IsShipment then
            JournalType := 'D'
        else
            JournalType := 'A';
        CurrFile.Write(
            'T' + ',' +
            DelChr(CompanyInfo."VAT Registration No.", '=', DelChr(CompanyInfo."VAT Registration No.", '=', '0123456789')) + ',' +
            ',' +
            CopyStr(CompanyInfo.Name, 1, 30) + ',' +
            NilReturnCode + ',' +
            JournalType + ',' +
            Format(WorkDate, 0, Text1040021) + ',' +
            IntrastatJnlBatch."Statistics Period" + ',' +
            'CSV02');
    end;

    local procedure WriteGrTotalsToFile(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        SupplementaryUnits: Text[11];
    begin
        IntrastatJnlLine."Total Weight" := IntraJnlManagement.RoundTotalWeight(IntrastatJnlLine."Total Weight");

        if ExportFormat = ExportFormat::"2022" then begin
            WriteGrTotalsToFile2022(IntrastatJnlLine);
            exit;
        end;

        if IntrastatJnlLine."Supplementary Units" then
            SupplementaryUnits := Format(IntrastatJnlLine.Quantity, 0, 1)
        else
            SupplementaryUnits := '';

        CurrFile.Write(
            DelChr(IntrastatJnlLine."Tariff No.") + ',' +
            Format(IntrastatJnlLine."Statistical Value", 0, 1) + ',' +
            IntrastatJnlLine."Shpt. Method Code" + ',' +
            IntrastatJnlLine."Transaction Type" + ',' +
            Format(IntrastatJnlLine."Total Weight", 0, 1) + ',' +
            SupplementaryUnits + ',' +
            IntrastatJnlLine."Country/Region Code" + ',' +
            IntrastatJnlLine."Document No.");
    end;

    local procedure WriteGrTotalsToFile2022(IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        CountryRegion: Record "Country/Region";
        CountryOfOriginCode: Code[10];
        SupplementaryUnits: Text[11];
    begin
        if IntrastatJnlLineTemp."Supplementary Units" then
            SupplementaryUnits := Format(IntrastatJnlLineTemp.Quantity, 0, 1)
        else
            SupplementaryUnits := '';

        if IntrastatJnlLine.Type = IntrastatJnlLine.Type::Shipment then
            CountryOfOriginCode := ''
        else begin
            CountryOfOriginCode := IntrastatJnlLine."Country/Region of Origin Code";
            if CountryRegion.Get(CountryOfOriginCode) then
                if CountryRegion."Intrastat Code" <> '' then
                    CountryOfOriginCode := CountryRegion."Intrastat Code";
        end;

        CurrFile.Write(
            DelChr(IntrastatJnlLine."Tariff No.") + ',' +
            Format(IntrastatJnlLine."Statistical Value", 0, 1) + ',' +
            IntrastatJnlLine."Shpt. Method Code" + ',' +
            IntrastatJnlLine."Transaction Type" + ',' +
            Format(IntrastatJnlLine."Total Weight", 0, 1) + ',' +
            SupplementaryUnits + ',' +
            IntrastatJnlLine."Country/Region Code" + ',' +
            IntrastatJnlLine."Partner VAT ID" + ',' +
            CountryOfOriginCode + ',' +
            IntrastatJnlLine."Document No.");
    end;
}

