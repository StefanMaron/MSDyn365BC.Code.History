#if not CLEAN22
report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID");
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(IntrastatJnlLine) then
                        CurrReport.Skip();

                    CheckLine(IntrastatJnlLine);

                    CompoundField := GetCompound(IntrastatJnlLine);
                    if (PrevType <> Type) or (StrLen(PrevCompoundField) = 0) then begin
                        PrevType := Type;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + Format(Type, 1, 2) + '01001';
                    end else
                        if PrevCompoundField <> CompoundField then
                            if CopyStr(IntraReferenceNo, 8, 3) = '999' then
                                IntraReferenceNo := IncStr(CopyStr(IntraReferenceNo, 1, 7)) + '001'
                            else
                                IntraReferenceNo := IncStr(IntraReferenceNo);

                    "Internal Ref. No." := IntraReferenceNo;
                    Modify();
                    PrevCompoundField := CompoundField;

                    case Type of
                        Type::Receipt:
                            ReceiptExists := true;
                        Type::Shipment:
                            ShipmentExists := true;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
                end;
            }
            dataitem(ReceiptIntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") where(Type = const(Receipt));

                trigger OnAfterGetRecord()
                begin
                    ProcessNextLine(ReceiptIntrastatJnlLine);
                end;

                trigger OnPostDataItem()
                begin
                    if ReceiptExists then begin
                        WriteGroupTotalsToFile(TempIntrastatJnlLineGroupTotals);
                        if IntrastatFileWriter.IsSplitShipmentAndReceiptFiles() then
                            IntrastatFileWriter.AddCurrFileToResultFile();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    CompanyInfo.Get();
                    VATRegNo := ConvertStr(IntraJnlManagement.GetCompanyVATRegNo(), Text001, '    ');
                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');
                    PrevCompoundField := '';
                    IntrastatFileWriter.InitializeNextFile(IntrastatFileWriter.GetDefaultOrReceiptFileName());
                    WriteHeader();
                end;
            }
            dataitem(ShipmentIntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") where(Type = const(Shipment));

                trigger OnAfterGetRecord()
                begin
                    ProcessNextLine(ShipmentIntrastatJnlLine);
                end;

                trigger OnPostDataItem()
                begin
                    if ShipmentExists then
                        WriteGroupTotalsToFile(TempIntrastatJnlLineGroupTotals);
                    WriteFooter();
                    if not IntrastatFileWriter.IsSplitShipmentAndReceiptFiles() or ShipmentExists then
                        IntrastatFileWriter.AddCurrFileToResultFile();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');
                    PrevCompoundField := '';
                    if IntrastatFileWriter.IsSplitShipmentAndReceiptFiles() then
                        IntrastatFileWriter.InitializeNextFile(IntrastatFileWriter.GetDefaultShipmentFileName());
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                TestField("Statistics Period");
                IntraReferenceNo := "Statistics Period" + '000000';
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
                SetBatchIsExported("Intrastat Jnl. Batch");
                IntrastatFileWriter.SetStatisticsPeriod("Statistics Period");
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Journal Template Name", IntrastatJnlLine.GetFilter("Journal Template Name"));
                SetFilter(Name, IntrastatJnlLine.GetFilter("Journal Batch Name"));
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
            ExportFormat := ExportFormat::"2022";
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
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    var
        TempIntrastatJnlLineGroupTotals: Record "Intrastat Jnl. Line" temporary;
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        StatisticalValueTotalAmt: Decimal;
        IntraReferenceNo: Text[10];
        CompoundField: Text;
        PrevCompoundField: Text;
        PrevType: Integer;
        ReceiptExists: Boolean;
        ShipmentExists: Boolean;
        VATRegNo: Text;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;

        Text001: Label 'WwWw';
        Text002: Label 'INTRASTAT';
        Text003: Label 'It is not possible to display %1 in a field with a length of %2.';

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
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false);
    end;

    local procedure ProcessNextLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        if IsBlankedLine(IntrastatJnlLine) then
            CurrReport.Skip();

        CompoundField := GetCompound(IntrastatJnlLine);
        if (StrLen(PrevCompoundField) <> 0) and (CompoundField <> PrevCompoundField) then
            WriteGroupTotalsToFile(TempIntrastatJnlLineGroupTotals);

        UpdateGroupTotals(TempIntrastatJnlLineGroupTotals, IntrastatJnlLine, CompoundField <> PrevCompoundField);
        PrevCompoundField := CompoundField;
    end;

    local procedure UpdateGroupTotals(var GroupIntrastatJnlLine: Record "Intrastat Jnl. Line"; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; newGroup: Boolean)
    begin
        if not newGroup then begin
            GroupIntrastatJnlLine."Total Weight" += IntrastatJnlLine."Total Weight";
            GroupIntrastatJnlLine.Quantity += IntrastatJnlLine.Quantity;
            GroupIntrastatJnlLine."Statistical Value" += IntrastatJnlLine."Statistical Value";
        end else
            GroupIntrastatJnlLine := IntrastatJnlLine;

        StatisticalValueTotalAmt += IntrastatJnlLine."Statistical Value";
    end;

    local procedure IsBlankedLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    begin
        exit(
            (IntrastatJnlLine."Tariff No." = '') and
            (IntrastatJnlLine."Country/Region Code" = '') and
            (IntrastatJnlLine."Transaction Type" = '') and
            (IntrastatJnlLine."Transport Method" = '') and
            (IntrastatJnlLine."Total Weight" = 0));
    end;

    local procedure GetCompound(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Text
    begin
        exit(
            Format(IntrastatJnlLine."Country/Region Code", 10) + Format(DelChr(IntrastatJnlLine."Tariff No."), 20) +
            Format(IntrastatJnlLine."Transaction Type", 10) + Format(IntrastatJnlLine."Transport Method", 10) +
            Format(IntrastatJnlLine."Partner VAT ID", 50) + Format(IntrastatJnlLine."Country/Region of Origin Code", 10));
    end;

    local procedure SetBatchIsExported(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlBatch.Validate(Reported, true);
        IntrastatJnlBatch.Modify(true);
    end;

    local procedure DecimalNumeralZeroFormat(DecimalNumeral: Decimal; Length: Integer): Text[250]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumeral), 1, '<'), 0, 1)), Length));
    end;

    local procedure TextZeroFormat(Text: Text; Length: Integer): Text
    begin
        if StrLen(Text) > Length then
            Error(
              Text003,
              Text, Length);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

#if not CLEAN20
    [Obsolete('Replaced by InitializeRequest(outstream,...)', '20.0')]
    procedure InitializeRequest(newServerFileName: Text)
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
    end;

    [Obsolete('Replaced by InitializeRequest(outstream,...)', '20.0')]
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

    local procedure WriteHeader()
    begin
        if ExportFormat = ExportFormat::"2022" then
            exit;

        IntrastatFileWriter.WriteLine(Format('00' + Format(VATRegNo, 8) + Text002, 80));
        IntrastatFileWriter.WriteLine(Format('0100004', 80));
    end;

    local procedure WriteFooter()
    begin
        if ExportFormat = ExportFormat::"2022" then
            exit;

        if not ReceiptExists then
            IntrastatFileWriter.WriteLine(
                Format(
                    '02000' + Format(IntraReferenceNo, 4) + '100000' +
                    Format(VATRegNo, 8) + '1' + Format(IntraReferenceNo, 4),
                    80));
        if not ShipmentExists then
            IntrastatFileWriter.WriteLine(
                Format(
                    '02000' + Format(IntraReferenceNo, 4) + '200000' +
                    Format(VATRegNo, 8) + '2' + Format(IntraReferenceNo, 4),
                    80));
        IntrastatFileWriter.WriteLine(Format('10' + DecimalNumeralZeroFormat(StatisticalValueTotalAmt, 16), 80));
    end;

    local procedure WriteGroupTotalsToFile(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine."Total Weight" := IntraJnlManagement.RoundTotalWeight(IntrastatJnlLine."Total Weight");

        if ExportFormat = ExportFormat::"2021" then
            WriteGroupTotalsToFile2021(IntrastatJnlLine)
        else
            WriteGroupTotalsToFile2022(IntrastatJnlLine);
    end;

    local procedure WriteGroupTotalsToFile2021(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlLine3: Record "Intrastat Jnl. Line";
        CountryRegion: Record "Country/Region";
        ImportExport: Code[1];
        OK: Boolean;
        NoOfEntries: Text[3];
    begin
        OnBeforeWriteGroupTotalsToFile2021(IntrastatJnlLine);
        OK := CopyStr(IntrastatJnlLine."Internal Ref. No.", 8, 3) = '001';
        if OK then begin
            IntrastatJnlLine3.SetCurrentKey("Internal Ref. No.");
            IntrastatJnlLine3.SetRange(
                "Internal Ref. No.",
                CopyStr(IntrastatJnlLine."Internal Ref. No.", 1, 7) + '000',
                CopyStr(IntrastatJnlLine."Internal Ref. No.", 1, 7) + '999');
            IntrastatJnlLine3.FindLast();
            NoOfEntries := CopyStr(IntrastatJnlLine3."Internal Ref. No.", 8, 3);
        end;
        ImportExport := IncStr(Format(IntrastatJnlLine.Type, 1, 2));

        CountryRegion.Get(IntrastatJnlLine."Country/Region Code");
        CountryRegion.TestField("Intrastat Code");

        if OK then
            IntrastatFileWriter.WriteLine(
                Format(
                    '02' +
                    TextZeroFormat(DelChr(NoOfEntries), 3) +
                    Format(CopyStr(IntrastatJnlLine3."Internal Ref. No.", 1, 7) + '000', 10) +
                    Format(VATRegNo, 8) + Format(ImportExport, 1) + Format(IntraReferenceNo, 4),
                    80));

        IntrastatFileWriter.WriteLine(
            Format(
                '03' +
                TextZeroFormat(CopyStr(IntrastatJnlLine."Internal Ref. No.", 8, 3), 3) +
                Format(IntrastatJnlLine."Internal Ref. No.", 10) +
                Format(CountryRegion."Intrastat Code", 3) +
                Format(IntrastatJnlLine."Transaction Type", 2) +
                '0' + Format(IntrastatJnlLine."Transport Method", 1) + PadStr(DelChr(IntrastatJnlLine."Tariff No."), 9, '0') +
                DecimalNumeralZeroFormat(IntrastatJnlLine."Total Weight", 15) +
                DecimalNumeralZeroFormat(IntrastatJnlLine.Quantity, 10) +
                DecimalNumeralZeroFormat(IntrastatJnlLine."Statistical Value", 15),
                80));
    end;

    local procedure WriteGroupTotalsToFile2022(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        CountryRegion: Record "Country/Region";
        OriginCountryRegion: Record "Country/Region";
        sep: Text[1];
    begin
        OnBeforeWriteGroupTotalsToFile2022(IntrastatJnlLine);
        CountryRegion.Get(IntrastatJnlLine."Country/Region Code");
        CountryRegion.TestField("Intrastat Code");

        if IntrastatJnlLine."Country/Region of Origin Code" <> '' then
            if OriginCountryRegion.Get(IntrastatJnlLine."Country/Region of Origin Code") then
                if OriginCountryRegion."Intrastat Code" <> '' then
                    OriginCountryRegion.Code := OriginCountryRegion."Intrastat Code";

        sep[1] := 9; // TAB

        IntrastatFileWriter.WriteLine(
          PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0') + sep +
          Format(CountryRegion."Intrastat Code", 3) + sep +
          Format(IntrastatJnlLine."Transaction Type", 2) + sep +
          DecimalNumeralZeroFormat(IntrastatJnlLine.Quantity, 11) + sep +
          DecimalNumeralZeroFormat(IntrastatJnlLine."Total Weight", 10) + sep +
          DecimalNumeralZeroFormat(IntrastatJnlLine."Statistical Value", 11) + sep +
          Format(IntrastatJnlLine."Internal Ref. No.", 30) + sep +
          Format(IntrastatJnlLine."Partner VAT ID", 20) + sep +
          Format(OriginCountryRegion.Code, 3));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteGroupTotalsToFile2021(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteGroupTotalsToFile2022(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;
}
#endif