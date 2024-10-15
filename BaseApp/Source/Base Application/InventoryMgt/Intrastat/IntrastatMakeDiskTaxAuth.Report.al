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

                trigger OnPreDataItem()
                begin
                    SetRange(Type, IntraJnlLineType);
                end;

                trigger OnPostDataItem()
                begin
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
                end;
            }
            dataitem(ShipmentAndReceiptIntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.");

                trigger OnAfterGetRecord()
                begin
                    ProcessNextLine(ShipmentAndReceiptIntrastatJnlLine);
                end;

                trigger OnPostDataItem()
                begin
                    if ReceiptExists or ShipmentExists then
                        WriteGroupTotalsToFile(TempIntrastatJnlLineGroupTotals);
                    WriteFooter(ShipmentAndReceiptIntrastatJnlLine);
                    IntrastatFileWriter.AddCurrFileToResultFile();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Type, IntraJnlLineType);
                    CompanyInfo.Get();

                    LineNo := '00000';

                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');
                    PrevCompoundField := '';
                    IntrastatFileWriter.InitializeNextFile(IntrastatFileWriter.GetDefaultFileName());
                    WriteHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if IntraJnlLineType = 0 then
                    TestField("Reported Receipt", false)
                else
                    TestField("Reported Shipment", false);

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
                    field(IntrastatJnlLineType; IntraJnlLineType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intrastat Journal Line Type';
                        OptionCaption = 'Receipt,Shipment';
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
        if not IntrastatFileSetup.Get() then
            Error(MissingFileSetupConfigErr);

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
        IntrastatFileSetup: Record "Intrastat - File Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        IntraReferenceNo: Text[10];
        CompoundField: Text;
        PrevCompoundField: Text;
        PrevType: Integer;
        ReceiptExists: Boolean;
        ShipmentExists: Boolean;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;
        TotalAmount: Decimal;
        Text1090000: Label 'must be either Receipt or Shipment';
        IntraJnlLineType: Option Receipt,Shipment;
        LineNo: Text[5];
        MissingFileSetupConfigErr: Label 'You have not set up any Intrastat transfer files. To set up a transfer file, go to the Transfer File window.';

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
            GroupIntrastatJnlLine."Quantity 2" += IntrastatJnlLine."Quantity 2";
            GroupIntrastatJnlLine."Statistical Value" += IntrastatJnlLine."Statistical Value";
            GroupIntrastatJnlLine.Amount += IntrastatJnlLine.Amount;
        end else
            GroupIntrastatJnlLine := IntrastatJnlLine;
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
        if IntraJnlLineType = 0 then
            IntrastatJnlBatch.Validate("Reported Receipt", true)
        else
            IntrastatJnlBatch.Validate("Reported Shipment", true);
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
    procedure InitializeRequest(newServerFileName: Text; newIntraJnlLineType: Option)
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
        IntraJnlLineType := newIntraJnlLineType;
    end;

    [Obsolete('Replaced by InitializeRequest(outstream,...)', '20.0')]
    procedure InitializeRequestWithExportFormat(newServerFileName: Text; newIntraJnlLineType: Option; NewExportFormat: Enum "Intrastat Export Format")
    begin
        IntrastatFileWriter.SetServerFileName(newServerFileName);
        IntraJnlLineType := newIntraJnlLineType;
        SpecifiedExportFormat := NewExportFormat;
        ExportFormatIsSpecified := true;
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream; NewExportFormat: Enum "Intrastat Export Format"; newIntraJnlLineType: Option)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
        SpecifiedExportFormat := NewExportFormat;
        ExportFormatIsSpecified := true;

        IntraJnlLineType := newIntraJnlLineType;
    end;

    local procedure WriteHeader()
    var
        FileType: Text[1];
        StatCustChamber: Text[17];
        StatPeriod: Code[4];
        CompanyCode: Code[3];
        LinePos: Integer;
        BusinessIdCode: Code[20];
        TempDate: Date;
    begin
        BusinessIdCode := CompanyInfo."Business Identity Code";
        CompanyCode := IntrastatFileSetup."Company Serial No.";
        StatPeriod := "Intrastat Jnl. Batch"."Statistics Period";
        StatCustChamber := IntrastatFileSetup."Custom Code";
        LinePos := StrPos(BusinessIdCode, '-');

        if IntraJnlLineType = 0 then
            FileType := 'A'
        else
            FileType := 'D';

        if LinePos <> 0 then
            BusinessIdCode := DelStr(BusinessIdCode, LinePos, 1);

        if IntrastatFileSetup."Last Transfer Date" = Today then
            IntrastatFileSetup."File No." := IncStr(IntrastatFileSetup."File No.")
        else begin
            IntrastatFileSetup."Last Transfer Date" := Today;
            IntrastatFileSetup."File No." := '001';
        end;

        IntrastatFileWriter.WriteLine(Format('KON0037' + Format(BusinessIdCode, 8), 20));

        Evaluate(TempDate, '0101' + Format(Today, 0, '<Year,2>'));
        IntrastatFileWriter.WriteLine(
            Format('OTS' + Format(Today, 0, '<Year,2>') + StatCustChamber +
            TextZeroFormat(Format(Today - TempDate + 1), 3) + CompanyCode +
            IntrastatFileSetup."File No." + FileType + StatPeriod + 'T  ' + '             ' +
            'FI' + BusinessIdCode + '       ' + '                           ' + StatCustChamber +
            '               ' + 'EUR', 101));

        IntrastatFileSetup.Modify();
    end;

    local procedure WriteFooter(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatFileWriter.WriteLine(
            Format(
            'SUM' + TextZeroFormat(CopyStr(IntrastatJnlLine."Internal Ref. No.", 8, 3), 18) +
            DecimalNumeralZeroFormat(Round(TotalAmount, 1, '>'), 18), 39));
    end;

    local procedure WriteGroupTotalsToFile(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        Quantity2Code: Text[3];
        CountryFormat: Text[6];
    begin
        if IntrastatJnlLine."Quantity 2" <> 0 then begin
            Quantity2Code := 'AAE';
            IntrastatJnlLine.TestField("Unit of Measure");
        end else
            IntrastatJnlLine."Unit of Measure" := '';

        CountryFormat := Format(IntrastatJnlLine."Country/Region of Origin Code", 2);
        if IntrastatJnlLine.Type = IntrastatJnlLine.Type::Receipt then
            CountryFormat += Format(IntrastatJnlLine."Country/Region Code", 2) + '  '
        else
            CountryFormat += '  ' + Format(IntrastatJnlLine."Country/Region Code", 2);

        LineNo := IncStr(LineNo);
        IntrastatJnlLine."Total Weight" := IntraJnlManagement.RoundTotalWeight(IntrastatJnlLine."Total Weight");

        if ExportFormat = ExportFormat::"2021" then
            WriteGroupTotalsToFile2021(IntrastatJnlLine, Quantity2Code, CountryFormat)
        else
            WriteGroupTotalsToFile2022(IntrastatJnlLine, Quantity2Code, CountryFormat);

        TotalAmount += IntrastatJnlLine.Amount;
    end;

    local procedure WriteGroupTotalsToFile2021(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Quantity2Code: Text[3]; CountryFormat: Text[6])
    begin
        OnBeforeWriteGroupTotalsToFile2021(IntrastatJnlLine);
        IntrastatFileWriter.WriteLine(
            Format('NIM' + LineNo +
            PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0') + Format(IntrastatJnlLine."Transaction Type", 2) +
            CountryFormat + Format(IntrastatJnlLine."Transport Method", 1) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine."Statistical Value", 1, '>'), 10) +
            Format(IntrastatJnlLine."Internal Ref. No.", 15) + 'WT ' + 'KGM' +
            DecimalNumeralZeroFormat(IntrastatJnlLine."Total Weight", 10) +
            Format(Quantity2Code, 3) + Format(IntrastatJnlLine."Unit of Measure", 3) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine."Quantity 2", 1, '>'), 10) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine.Amount, 1, '>'), 10), 92));
    end;

    local procedure WriteGroupTotalsToFile2022(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; Quantity2Code: Text[3]; CountryFormat: Text[6])
    begin
        OnBeforeWriteGroupTotalsToFile2022(IntrastatJnlLine);
        IntrastatFileWriter.WriteLine(
            Format('NIM' + LineNo +
            PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0') + Format(IntrastatJnlLine."Transaction Type", 2) +
            CountryFormat + Format(IntrastatJnlLine."Transport Method", 1) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine."Statistical Value", 1, '>'), 10) +
            Format(IntrastatJnlLine."Internal Ref. No.", 15) + 'WT ' + 'KGM' +
            DecimalNumeralZeroFormat(IntrastatJnlLine."Total Weight", 10) +
            Format(Quantity2Code, 3) + Format(IntrastatJnlLine."Unit of Measure", 3) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine."Quantity 2", 1, '>'), 10) +
            DecimalNumeralZeroFormat(Round(IntrastatJnlLine.Amount, 1, '>'), 10) +
            Format(IntrastatJnlLine."Partner VAT ID", 14), 106));
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
