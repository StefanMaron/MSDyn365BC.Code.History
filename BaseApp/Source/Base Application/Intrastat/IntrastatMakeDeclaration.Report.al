#if not CLEAN22
report 593 "Intrastat - Make Declaration"
{
    Caption = 'Intrastat - Make Declaration';
    ProcessingOnly = true;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';
    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                var
                    CountryRegion: Record "Country/Region";
                    CountryCode: Code[3];
                    CountryOfOriginCode: Code[3];
                    StatSystem: Code[1];
                begin
                    RecNo := RecNo + 1;

                    Window.Update(2, Round(RecNo / TotalRecNo * 10000, 1));

                    if IsBlankedLine(IntrastatJnlLine) then
                        CurrReport.Skip();

                    "Tariff No." := DelChr("Tariff No.");
                    CheckLine(IntrastatJnlLine);

                    if "Total Weight" > 9999999999999.0 then
                        Error(Text1100000, FieldCaption("Total Weight"), "Total Weight");

                    if Amount > 9999999999999.0 then
                        Error(Text1100000, FieldCaption(Amount), Amount);

                    if Quantity > 9999999999999.0 then
                        Error(Text1100000, FieldCaption(Quantity), Quantity);

                    if "Statistical Value" > 9999999999999.0 then
                        Error(Text1100000, FieldCaption("Statistical Value"), "Statistical Value");

                    if CountryRegion.Get("Country/Region Code") then
                        CountryCode := CountryRegion."EU Country/Region Code"
                    else
                        CountryCode := '';

                    CountryOfOriginCode := CopyStr("Country/Region of Origin Code", 1, MaxStrLen(CountryOfOriginCode));
                    if CountryRegion.Get("Country/Region of Origin Code") then
                        if CountryRegion."EU Country/Region Code" <> '' then
                            CountryOfOriginCode := CopyStr(CountryRegion."EU Country/Region Code", 1, MaxStrLen(CountryOfOriginCode));

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

                    WriteGroupTotalsToFile(IntrastatJnlLine, CountryCode, CountryOfOriginCode, StatSystem);
                end;

                trigger OnPostDataItem()
                begin
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);

                    IntrastatFileWriter.AddCurrFileToResultFile();
                end;

                trigger OnPreDataItem()
                begin
                    Window.Open(
                      '#1###################################################\\' +
                      '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\');
                    TotalRecNo := IntrastatJnlLine.Count();

                    Window.Update(1, StrSubstNo(Text1100001, ClientFilename));
                    IntrastatFileWriter.InitializeNextFile(ClientFilename);
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
            ExportFormat := ExportFormat::"2022";
            FilterSourceLinesByIntrastatSetupExportTypes();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ClientFilename := IntrastatFileWriter.GetDefaultIndexedFileName();
    end;

    trigger OnPreReport()
    begin
        IntrastatFileWriter.Initialize(true, false, 1000);

        if ExportFormatIsSpecified then
            ExportFormat := SpecifiedExportFormat;
    end;

    trigger OnPostReport()
    begin
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    var
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        IntraReferenceNo: Text[10];
        Text1100000: Label 'The value of %1 %2  is bigger than maximum value allowed (9.999.999.999.999).';
        Text1100001: Label 'Exporting to file %1';
        TotalRecNo: Integer;
        RecNo: Integer;
        Window: Dialog;
        ClientFilename: Text;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;

    local procedure FilterSourceLinesByIntrastatSetupExportTypes()
    begin
        if not IntrastatSetup.Get() then
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
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Declaration", false);
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

    local procedure SetBatchIsExported(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlBatch.Validate(Reported, true);
        IntrastatJnlBatch.Modify(true);
    end;

    procedure InitializeRequest(var newResultFileOutStream: OutStream; NewExportFormat: Enum "Intrastat Export Format")
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
        SpecifiedExportFormat := NewExportFormat;
        ExportFormatIsSpecified := true;
    end;

    local procedure WriteGroupTotalsToFile(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; CountryCode: Code[3]; CountryOfOriginCode: Code[3]; StatSystem: Code[1])
    begin
        IntrastatJnlLine."Total Weight" := IntraJnlManagement.RoundTotalWeight(IntrastatJnlLine."Total Weight");

        if ExportFormat = ExportFormat::"2021" then
            WriteGroupTotalsToFile2021(IntrastatJnlLine, CountryCode, CountryOfOriginCode, StatSystem)
        else
            WriteGroupTotalsToFile2022(IntrastatJnlLine, CountryCode, CountryOfOriginCode, StatSystem);
    end;

    local procedure WriteGroupTotalsToFile2021(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; CountryCode: Code[3]; CountryOfOriginCode: Code[3]; StatSystem: Code[1])
    begin
        IntrastatFileWriter.WriteLine(
            CopyStr(CountryCode, 1, 2) + ';' +
            CopyStr(IntrastatJnlLine.Area, 1, 2) + ';' +
            CopyStr(IntrastatJnlLine."Shpt. Method Code", 1, 3) + ';' +
            CopyStr(IntrastatJnlLine."Transaction Type", 1, 2) + ';' +
            CopyStr(IntrastatJnlLine."Transport Method", 1, 1) + ';' +
            CopyStr(IntrastatJnlLine."Entry/Exit Point", 1, 4) + ';' +
            PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0') + ';' +
            CopyStr(CountryOfOriginCode, 1, 2) + ';' +
            StatSystem + ';' +
            DecimalFormat(IntrastatJnlLine."Total Weight", '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine.Quantity, '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine.Amount, '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine."Statistical Value", '<Precision,2:><Integer><Decimal>')
            );
    end;

    local procedure WriteGroupTotalsToFile2022(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; CountryCode: Code[3]; CountryOfOriginCode: Code[3]; StatSystem: Code[1])
    begin
        IntrastatFileWriter.WriteLine(
            CopyStr(CountryCode, 1, 2) + ';' +
            CopyStr(IntrastatJnlLine.Area, 1, 2) + ';' +
            CopyStr(IntrastatJnlLine."Shpt. Method Code", 1, 3) + ';' +
            CopyStr(IntrastatJnlLine."Transaction Type", 1, 2) + ';' +
            CopyStr(IntrastatJnlLine."Transport Method", 1, 1) + ';' +
            CopyStr(IntrastatJnlLine."Entry/Exit Point", 1, 4) + ';' +
            PadStr(DelChr(IntrastatJnlLine."Tariff No."), 8, '0') + ';' +
            CopyStr(CountryOfOriginCode, 1, 2) + ';' +
            StatSystem + ';' +
            DecimalFormat(IntrastatJnlLine."Total Weight", '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine.Quantity, '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine.Amount, '<Precision,2:><Integer><Decimal>') + ';' +
            DecimalFormat(IntrastatJnlLine."Statistical Value", '<Precision,2:><Integer><Decimal>') + ';' +
            IntrastatJnlLine."Partner VAT ID"
        );
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

    local procedure DecimalFormat(DecimalNumeral: Decimal; FormatText: Text): Text
    begin
        exit(Format(DecimalNumeral, 0, FormatText));
    end;
}
#endif