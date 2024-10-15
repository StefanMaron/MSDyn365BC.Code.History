report 502 "Intrastat - Checklist"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatChecklist.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Checklist';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(IntrastatJnlBatJnlTemName; "Journal Template Name")
            {
            }
            column(IntrastatJnlBatchName; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING ("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID");
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(IntrastatJnlBatStatPeriod; StrSubstNo(Text001, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(HeaderLine; HeaderLine)
                {
                }
                column(PrintJnlLines; PrintJnlLines)
                {
                }
                column(NoOfRecordsRTC; NoOfRecordsRTC)
                {
                }
                column(IntrastatJnlLineType; Type)
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLineTariffNo; "Tariff No.")
                {
                    IncludeCaption = true;
                }
                column(CountryIntrastatCode; Country."Intrastat Code")
                {
                }
                column(CountryName; Country.Name)
                {
                }
                column(IntrastatJnlLineTranType; "Transaction Type")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLinTranMethod; "Transport Method")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLineItemDesc; "Item Description")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLineTotalWt; "Total Weight")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLineTotalWt2; TotalWeight)
                {
                }
                column(IntrastatJnlLineQty; Quantity)
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLineStatVal; "Statistical Value")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLinInterRefNo; "Internal Ref. No.")
                {
                    IncludeCaption = true;
                }
                column(IntrastatJnlLinSubTotalWt; SubTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(IntrastatJnlLinJnlTemName; "Journal Template Name")
                {
                }
                column(IntrastatJnlLinJnlBatName; "Journal Batch Name")
                {
                }
                column(IntrastatJnlLineLineNo; "Line No.")
                {
                }
                column(IntrastatChecklistCaption; IntrastatChecklistCaptionLbl)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; VATRegNoCaptionLbl)
                {
                }
                column(TariffNoCaption; TariffNoCaptionLbl)
                {
                }
                column(CountryRegionCodeCaption; CountryRegionCodeCaptionLbl)
                {
                }
                column(TransactionTypeCaption; TransactionTypeCaptionLbl)
                {
                }
                column(TransactionMethodCaption; TransactionMethodCaptionLbl)
                {
                }
                column(NoOfEntriesCaption; NoOfEntriesCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(CountryRegionofOriginCode; "Country/Region of Origin Code")
                {
                }
                column(PartnerVATID; "Partner VAT ID")
                {
                }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    ItemIsInventoriable: Boolean;
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);
#endif
                    // NAVCZ
                    ItemIsInventoriable := false;
                    if Item.Get("Item No.") then
                        ItemIsInventoriable := Item.IsInventoriableType();
                    if StatReportingSetup."Tariff No. Mandatory" then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo("Tariff No."), ErrorMessage."Message Type"::Error);
                    if StatReportingSetup."Country/Region of Origin Mand." and (Type <> Type::Shipment) then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
                    if StatReportingSetup."Transaction Type Mandatory" and ItemIsInventoriable then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo("Transaction Type"), ErrorMessage."Message Type"::Error);
                    if StatReportingSetup."Transport Method Mandatory" and ItemIsInventoriable then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo("Transport Method"), ErrorMessage."Message Type"::Error);
                    if StatReportingSetup."Net Weight Mandatory" and ItemIsInventoriable then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo("Total Weight"), ErrorMessage."Message Type"::Error);
                    if not CountryOfOrigin.Get("Country/Region of Origin Code") then
                        Clear(CountryOfOrigin);
                    // NAVCZ

                    if "Supplementary Units" then
                        ErrorMessage.LogIfEmpty("Intrastat Jnl. Line", FieldNo(Quantity), ErrorMessage."Message Type"::Error);

                    if Country.Get("Country/Region Code") then;
                    IntrastatJnlLineTemp.Reset();
                    IntrastatJnlLineTemp.SetRange(Type, Type);
                    IntrastatJnlLineTemp.SetRange("Tariff No.", "Tariff No.");
                    IntrastatJnlLineTemp.SetRange("Country/Region Code", "Country/Region Code");
                    IntrastatJnlLineTemp.SetRange("Transaction Type", "Transaction Type");
                    IntrastatJnlLineTemp.SetRange("Transport Method", "Transport Method");
                    IntrastatJnlLineTemp.SetRange("Country/Region of Origin Code", "Country/Region of Origin Code");
                    IntrastatJnlLineTemp.SetRange("Partner VAT ID", "Partner VAT ID");
                    if not IntrastatJnlLineTemp.FindFirst() then begin
                        IntrastatJnlLineTemp := "Intrastat Jnl. Line";
                        IntrastatJnlLineTemp.Insert();
                        NoOfRecordsRTC += 1;
                    end;
                    if (PrevIntrastatJnlLine.Type <> Type) or
                       (PrevIntrastatJnlLine."Tariff No." <> "Tariff No.") or
                       (PrevIntrastatJnlLine."Country/Region Code" <> "Country/Region Code") or
                       (PrevIntrastatJnlLine."Transaction Type" <> "Transaction Type") or
                       (PrevIntrastatJnlLine."Transport Method" <> "Transport Method") or
                       (PrevIntrastatJnlLine."Country/Region of Origin Code" <> "Country/Region of Origin Code") or
                       (PrevIntrastatJnlLine."Partner VAT ID" <> "Partner VAT ID")
                    then begin
                        SubTotalWeight := 0;
                        PrevIntrastatJnlLine.SetCurrentKey(
                          "Journal Template Name", "Journal Batch Name", Type, "Country/Region Code",
                          "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID");
                        PrevIntrastatJnlLine.SetRange(Type, Type);
                        PrevIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                        PrevIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                        PrevIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                        PrevIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                        PrevIntrastatJnlLine.SetRange("Country/Region of Origin Code", "Country/Region of Origin Code");
                        PrevIntrastatJnlLine.SetRange("Partner VAT ID", "Partner VAT ID");
                        PrevIntrastatJnlLine.FindFirst();
                    end;

                    // NAVCZ
                    // SubTotalWeight := SubTotalWeight + ROUND("Total Weight",1);
                    // TotalWeight := TotalWeight + ROUND("Total Weight",1);
                    SubTotalWeight := SubTotalWeight + RoundValue("Total Weight");
                    TotalWeight := TotalWeight + RoundValue("Total Weight");
                    // NAVCZ
                end;

                trigger OnPreDataItem()
                begin
                    IntrastatJnlLineTemp.DeleteAll();
                    NoOfRecordsRTC := 0;

                    if GetFilter(Type) <> '' then
                        exit;

                    if not IntrastatSetup.Get then
                        exit;

                    if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
                        SetRange(Type)
                    else
                        if IntrastatSetup."Report Receipts" then
                            SetRange(Type, Type::Receipt)
                        else
                            if IntrastatSetup."Report Shipments" then
                                SetRange(Type, Type::Shipment)
                            else
                                Error(NoValuesErr);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ErrorMessage.SetContext("Intrastat Jnl. Batch");
                ErrorMessage.ClearLog;

                GLSetup.Get();
                if "Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderLine := StrSubstNo(Text002, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderLine := StrSubstNo(Text002, GLSetup."LCY Code");
                end;
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
                    field(ShowIntrastatJournalLines; PrintJnlLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Intrastat Journal Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if the report will show detailed information from the journal lines. If you do not select this field, it shows only the information that must be reported to the tax authorities and not the lines in the journal.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        TotalWeightCaption = 'Total Weight';
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text000, '    ');
        StatReportingSetup.Get(); // NAVCZ
    end;

    var
        Text000: Label 'WwWw';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        IntrastatJnlLineTemp: Record "Intrastat Jnl. Line" temporary;
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        ErrorMessage: Record "Error Message";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        NoOfRecords: Integer;
        NoOfRecordsRTC: Integer;
        PrintJnlLines: Boolean;
        HeaderText: Text;
        HeaderLine: Text;
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;
        IntrastatChecklistCaptionLbl: Label 'Intrastat - Checklist';
        PageNoCaptionLbl: Label 'Page';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        TariffNoCaptionLbl: Label 'Tariff No.';
        CountryRegionCodeCaptionLbl: Label 'Country/Region Code';
        TransactionTypeCaptionLbl: Label 'Transaction Type';
        TransactionMethodCaptionLbl: Label 'Transport Method';
        NoOfEntriesCaptionLbl: Label 'No. of Combined Entries';
        TotalCaptionLbl: Label 'Total';
        StatReportingSetup: Record "Stat. Reporting Setup";
        CountryOfOrigin: Record "Country/Region";
        NoValuesErr: Label 'There are no values to report as per Intrastat Setup.';
}

