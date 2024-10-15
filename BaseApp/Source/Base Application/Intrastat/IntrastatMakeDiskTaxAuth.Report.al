report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
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
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Statistical Value" = 0) and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

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
                        TestField("Statistical Value");
                        if "Supplementary Units" then
                            TestField(Quantity);
                    end;
#endif
                    if StrLen(Format(Round(Quantity, 1), 0, '<Sign><Integer><Decimals>')) > 11 then
                        Error(Text11201, FieldCaption(Quantity));
                    if StrLen(Format(Round("Total Weight", 1), 0, '<Sign><Integer><Decimals>')) > 11 then
                        Error(Text11201, FieldCaption("Total Weight"));
                    if StrLen(Format(Round("Statistical Value", 1), 0, '<Sign><Integer><Decimals>')) > 11 then
                        Error(Text11201, FieldCaption("Statistical Value"));

                    CompoundField :=
                      Format("Country/Region Code", 10) + Format(DelChr("Tariff No."), 10) +
                      Format("Transaction Type", 10) + Format("Transport Method", 10) +
                      Format("Partner VAT ID", 50) + Format("Country/Region of Origin Code", 10);

                    if (TempType <> Type) or (StrLen(TempCompoundField) = 0) then begin
                        TempType := Type;
                        TempCompoundField := CompoundField;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + Format(Type, 1, 2) + '01001';
                    end else
                        if (TempCompoundField <> CompoundField) then begin
                            TempCompoundField := CompoundField;
                            if CopyStr(IntraReferenceNo, 8, 3) = '999' then
                                IntraReferenceNo := IncStr(CopyStr(IntraReferenceNo, 1, 7)) + '001'
                            else
                                IntraReferenceNo := IncStr(IntraReferenceNo);
                        end;

                    "Internal Ref. No." := IntraReferenceNo;
                    Modify;
                end;

                trigger OnPostDataItem()
                begin
#if CLEAN19
                    IntraJnlManagement.CheckForJournalBatchError("Intrastat Jnl. Line", true);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.CheckForJournalBatchError("Intrastat Jnl. Line", true);
#endif                
                end;
            }
            dataitem(IntrastatJnlLine2; "Intrastat Jnl. Line")
            {
                DataItemTableView = SORTING("Internal Ref. No.");

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Statistical Value" = 0) and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();
                    "Tariff No." := DelChr("Tariff No.");

                    TotalWeightAmt += "Total Weight";
                    QuantityAmt += Quantity;
                    StatisticalValueAmt += "Statistical Value";

                    IntrastatJnlLine5.Copy(IntrastatJnlLine2);
                    if IntrastatJnlLine5.Next = 1 then begin
                        if (DelChr(IntrastatJnlLine5."Tariff No.") = "Tariff No.") and
                           (IntrastatJnlLine5."Country/Region Code" = "Country/Region Code") and
                           (IntrastatJnlLine5."Transaction Type" = "Transaction Type") and
                           (IntrastatJnlLine5."Transport Method" = "Transport Method")
                        then
                            GroupTotal := false
                        else
                            GroupTotal := true;
                    end else
                        GroupTotal := true;

                    if GroupTotal then begin
                        TotalWeightAmt := IntraJnlManagement.RoundTotalWeight(TotalWeightAmt);

                        WriteGrTotalsToFile(TotalWeightAmt, QuantityAmt, StatisticalValueAmt);
                        StatisticalValueTotalAmt += StatisticalValueAmt;
                        TotalWeightAmt := 0;
                        QuantityAmt := 0;
                        StatisticalValueAmt := 0;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    IntraFile.Close;

                    "Intrastat Jnl. Batch".Reported := true;
                    "Intrastat Jnl. Batch".Modify();

                    if ServerFileName = '' then
                        FileMgt.DownloadHandler(FileName, '', '', FileMgt.GetToFilterText('', DefaultFilenameTxt), DefaultFilenameTxt)
                    else
                        FileMgt.CopyServerFile(FileName, ServerFileName, true);
                end;

                trigger OnPreDataItem()
                begin
                    CompanyInfo.Get();
                    VATRegNo := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');

                    IntrastatJnlLine2.CopyFilters("Intrastat Jnl. Line");

                    SetRange("Internal Ref. No.", CopyStr(IntraReferenceNo, 1, 4), CopyStr(IntraReferenceNo, 1, 4) + '9');

                    IntrastatJnlLine3.SetCurrentKey("Internal Ref. No.");
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

        IntrastatJnlLine4.CopyFilters("Intrastat Jnl. Line");
        if FileName = '' then
            Error(Text000);
        IntraFile.TextMode := true;
        IntraFile.WriteMode := true;
        IntraFile.Create(FileName);

        if ExportFormatIsSpecified then
            ExportFormat := SpecifiedExportFormat;

        if ("Intrastat Jnl. Line".GetFilter(Type) <> Format("Intrastat Jnl. Line".Type::Receipt)) and
           ("Intrastat Jnl. Line".GetFilter(Type) <> Format("Intrastat Jnl. Line".Type::Shipment))
        then
            Error(Text11200, "Intrastat Jnl. Line".FieldCaption(Type));
    end;

    var
        Text000: Label 'Enter the file name.';
        Text001: Label 'WwWw';
        Text002: Label 'INTRASTAT';
        Text003: Label 'It is not possible to display %1 in a field with a length of %2.';
        IntrastatJnlLine3: Record "Intrastat Jnl. Line";
        IntrastatJnlLine4: Record "Intrastat Jnl. Line";
        IntrastatJnlLine5: Record "Intrastat Jnl. Line";
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        FileMgt: Codeunit "File Management";
        IntraFile: File;
        QuantityAmt: Decimal;
        StatisticalValueAmt: Decimal;
        StatisticalValueTotalAmt: Decimal;
        TotalWeightAmt: Decimal;
        FileName: Text;
        IntraReferenceNo: Text[10];
        CompoundField: Text[100];
        TempCompoundField: Text[100];
        ServerFileName: Text;
        TempType: Integer;
        NoOfEntries: Text[3];
        Receipt: Boolean;
        Shipment: Boolean;
        VATRegNo: Code[20];
        DefaultFilenameTxt: Label 'Default.txt', Locked = true;
        GroupTotal: Boolean;
        ExportFormat: Enum "Intrastat Export Format";
        SpecifiedExportFormat: Enum "Intrastat Export Format";
        ExportFormatIsSpecified: Boolean;
        Text11200: Label 'Please enter either Receipt or Shipment for the %1 field.';
        Text11201: Label '%1 exceeds the maximum value to be imported into IDEP.';

    local procedure DecimalNumeralZeroFormat(DecimalNumeral: Decimal; Length: Integer): Text[250]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumeral), 1, '<'), 0, 1)), Length));
    end;

    local procedure TextZeroFormat(Text: Text[250]; Length: Integer): Text[250]
    begin
        if StrLen(Text) > Length then
            Error(
              Text003,
              Text, Length);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
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

    [Scope('OnPrem')]
    procedure WriteGrTotalsToFile(TotalWeightAmt: Decimal; QuantityAmt: Decimal; StatisticalValueAmt: Decimal)
    var
        CountryRegion: Record "Country/Region";
        OK: Boolean;
    begin
        if ExportFormat = ExportFormat::"2022" then begin
            WriteGrTotalsToFile2022(TotalWeightAmt, QuantityAmt, StatisticalValueAmt);
            exit;
        end;

        OK := CopyStr(IntrastatJnlLine2."Internal Ref. No.", 8, 3) = '001';
            if OK then begin
                IntrastatJnlLine3.SetRange(
                  "Internal Ref. No.",
              CopyStr(IntrastatJnlLine2."Internal Ref. No.", 1, 7) + '000',
              CopyStr(IntrastatJnlLine2."Internal Ref. No.", 1, 7) + '999');
                IntrastatJnlLine3.FindLast;
                NoOfEntries := CopyStr(IntrastatJnlLine3."Internal Ref. No.", 8, 3);
            end;

        if IntrastatJnlLine2.Type = IntrastatJnlLine2.Type::Receipt then
                Receipt := true
            else
                Shipment := true;
        CountryRegion.Get(IntrastatJnlLine2."Country/Region Code");
        CountryRegion.TestField("Intrastat Code");

            IntraFile.Write(
          Format(CountryRegion."Intrastat Code", 2) + ';' +
          Format(IntrastatJnlLine2."Transaction Type", 1) + ';' +
          PadStr(IntrastatJnlLine2."Tariff No.", 8, '0') + ';' +
          Format(QuantityAmt, 0, '<Sign><Integer><Decimals>') + ';' +
          Format(TotalWeightAmt, 0, '<Sign><Integer><Decimals>') + ';' +
          Format(StatisticalValueAmt, 0, '<Sign><Integer><Decimals>'));
    end;

    local procedure WriteGrTotalsToFile2022(TotalWeightAmt: Decimal; QuantityAmt: Decimal; StatisticalValueAmt: Decimal)
    var
        CountryRegion: Record "Country/Region";
        OriginCountryRegion: Record "Country/Region";
        sep: Text[1];
    begin
        CountryRegion.Get(IntrastatJnlLine2."Country/Region Code");
        CountryRegion.TestField("Intrastat Code");
        OriginCountryRegion.Get(IntrastatJnlLine2."Country/Region of Origin Code");
        OriginCountryRegion.TestField("Intrastat Code");
        sep[1] := 9; // TAB

        IntraFile.Write(
          PadStr(IntrastatJnlLine2."Tariff No.", 8, '0') + sep +
          Format(CountryRegion."Intrastat Code", 3) + sep +
          Format(IntrastatJnlLine2."Transaction Type", 2) + sep +
          DecimalNumeralZeroFormat(QuantityAmt, 11) + sep +
          DecimalNumeralZeroFormat(TotalWeightAmt, 10) + sep +
          DecimalNumeralZeroFormat(StatisticalValueAmt, 11) + sep +
          Format(IntrastatJnlLine2."Internal Ref. No.", 30) + sep +
          Format(IntrastatJnlLine2."Partner VAT ID", 20) + sep +
          Format(OriginCountryRegion."Intrastat Code", 3));
    end;
}

