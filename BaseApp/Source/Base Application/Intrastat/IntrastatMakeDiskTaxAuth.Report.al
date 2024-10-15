report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
    ProcessingOnly = true;

    dataset
    {
        dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = Type, "Journal Template Name", "Journal Batch Name";

            trigger OnAfterGetRecord()
            begin
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);

                CheckLine(IntrastatJnlLine);
                IntrastatJnlLineTemp := IntrastatJnlLine;
                IntrastatJnlLineTemp.Insert();
            end;

            trigger OnPostDataItem()
            var
                NilReturn: Boolean;
            begin
#if CLEAN19
                IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
#else
                if IntrastatSetup."Use Advanced Checklist" then
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
#endif
                NoOfRecords := LineCount + 1;
                LineCount := 1;

                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));

                NilReturn := not IntrastatJnlLineTemp.Find('-');
                WriteHeader(NilReturn, Type = Type::Shipment);

                if not NilReturn then
                    WriteFile();

                if NilReturn then
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

                Window.Open(
                  '#1############################################\\' +
                  Text1040015 +
                  Text1040016);

                IntrastatFileWriter.InitializeNextFile(IntrastatFileWriter.GetDefaultFileName());
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
            FilterSourceLinesByIntrastatSetupExportTypes();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        IntrastatFileWriter.Initialize(false, false, 0);

        if ExportFormatIsSpecified then
            ExportFormat := SpecifiedExportFormat;
    end;

    trigger OnPostReport()
    begin
        IntrastatFileWriter.AddCurrFileToResultFile();
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    var
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatJnlLineTemp: Record "Intrastat Jnl. Line" temporary;
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;
        Text1040013: Label 'must be either Receipt or Shipment';
        Text1040015: Label 'Checking lines        #2######################\';
        Text1040016: Label 'Writing lines to file #3###### @4@@@@@@@@@@@@@';
        Text1040018: Label 'There were no records for %1 %2.';
        Text1040021: Label '<Day,2><Month,2><Year,2>', Locked = true;

    local procedure FilterSourceLinesByIntrastatSetupExportTypes()
    begin
        if not IntrastatSetup.Get() then
            exit;

        if IntrastatJnlLine.GetFilter(Type) <> '' then
            exit;

        if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
            exit;

        if IntrastatSetup."Report Receipts" then
            IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt)
        else
            if IntrastatSetup."Report Shipments" then
                IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment)
    end;

    local procedure CheckLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
#if CLEAN19
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false);
#else
        if IntrastatSetup."Use Advanced Checklist" then
            IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false)
        else begin
            IntrastatJnlLine.TestField("Tariff No.");
            IntrastatJnlLine.TestField("Country/Region Code");
            IntrastatJnlLine.TestField("Transaction Type");
            if not IntrastatJnlLine."Supplementary Units" then
                IntrastatJnlLine.TestField("Total Weight");
            if IntrastatJnlLine."Supplementary Units" then
                IntrastatJnlLine.TestField(Quantity);
        end;
#endif
    end;

    [Scope('OnPrem')]
    procedure WriteFile()
    begin
        with IntrastatJnlLineTemp do begin
            repeat
                LineCount := LineCount + 1;
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                WriteGroupTotalsToFile(IntrastatJnlLineTemp);
            until Next() = 0;
        end;
    end;

#if not CLEAN20
    [Scope('OnPrem')]
    procedure CloseFile()
    begin
    end;

    procedure InitializeRequest(newServerFileName: Text)
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
    end;

    procedure InitializeRequestWithExportFormat(newServerFileName: Text; NewExportFormat: Enum "Intrastat Export Format")
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
        SpecifiedExportFormat := NewExportFormat;
        ExportFormatIsSpecified := true;
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream; NewExportFormat: Enum "Intrastat Export Format")
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
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
        IntrastatFileWriter.WriteLine(
            'T' + ',' +
            IntraJnlManagement.GetCompanyVATRegNo + ',' +
            ',' +
            CopyStr(CompanyInfo.Name, 1, 30) + ',' +
            NilReturnCode + ',' +
            JournalType + ',' +
            Format(WorkDate, 0, Text1040021) + ',' +
            IntrastatJnlBatch."Statistics Period" + ',' +
            'CSV02');
    end;

    local procedure WriteGroupTotalsToFile(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        Quantity: Text[11];
    begin
        IntrastatJnlLine."Total Weight" := IntraJnlManagement.RoundTotalWeight(IntrastatJnlLine."Total Weight");

        if IntrastatJnlLine."Supplementary Units" then
            Quantity := Format(IntrastatJnlLine.Quantity, 0, 1)
        else
            Quantity := '';

        if ExportFormat = ExportFormat::"2021" then
            WriteGroupTotalsToFile2021(IntrastatJnlLine, Quantity)
        else
            WriteGroupTotalsToFile2022(IntrastatJnlLine, Quantity);
    end;

    local procedure WriteGroupTotalsToFile2021(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Quantity: Text[11])
    begin
        IntrastatFileWriter.WriteLine(
            DelChr(IntrastatJnlLine."Tariff No.") + ',' +
            Format(IntrastatJnlLine."Statistical Value", 0, 1) + ',' +
            IntrastatJnlLine."Shpt. Method Code" + ',' +
            IntrastatJnlLine."Transaction Type" + ',' +
            Format(IntrastatJnlLine."Total Weight", 0, 1) + ',' +
            Quantity + ',' +
            IntrastatJnlLine."Country/Region Code" + ',' +
            IntrastatJnlLine."Document No.");
    end;

    local procedure WriteGroupTotalsToFile2022(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Quantity: Text[11])
    var
        CountryRegion: Record "Country/Region";
        CountryOfOriginCode: Code[10];
        SupplementaryUnits: Text[11];
        Line: Text;
    begin
        if IntrastatJnlLineTemp."Supplementary Units" then
            SupplementaryUnits := Format(IntrastatJnlLineTemp.Quantity, 0, 1)
        else
            SupplementaryUnits := '';

        if IntrastatJnlLine.Type = IntrastatJnlLine.Type::Shipment then begin
            CountryOfOriginCode := IntrastatJnlLine."Country/Region of Origin Code";
            if CountryRegion.Get(CountryOfOriginCode) then
                if CountryRegion."Intrastat Code" <> '' then
                    CountryOfOriginCode := CountryRegion."Intrastat Code";
        end;

        Line :=
            DelChr(IntrastatJnlLine."Tariff No.") + ',' +
            Format(IntrastatJnlLine."Statistical Value", 0, 1) + ',' +
            IntrastatJnlLine."Shpt. Method Code" + ',' +
            IntrastatJnlLine."Transaction Type" + ',' +
            Format(IntrastatJnlLine."Total Weight", 0, 1) + ',' +
            SupplementaryUnits + ',' +
            IntrastatJnlLine."Country/Region Code";

        if IntrastatJnlLine.Type = IntrastatJnlLine.Type::Shipment then
            Line += ',' + IntrastatJnlLine."Partner VAT ID" + ',' + CountryOfOriginCode;
        Line += ',' + IntrastatJnlLine."Document No.";

        IntrastatFileWriter.WriteLine(Line);
    end;
}

