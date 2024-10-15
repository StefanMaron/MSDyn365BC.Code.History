#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 502 "Intrastat - Checklist"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Intrastat/IntrastatChecklist.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Checklist';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(IntrastatJnlBatJnlTemName; "Journal Template Name")
            {
            }
            column(IntrastatJnlBatchName; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Country/Region of Origin Code", "Partner VAT ID");
                RequestFilterFields = Type;
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(IntrastatJnlBatStatPeriod; StrSubstNo(Text001, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
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
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);

                    if Country.Get("Country/Region Code") then;
                    TempIntrastatJnlLine.Reset();
                    TempIntrastatJnlLine.SetRange(Type, Type);
                    TempIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                    TempIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                    TempIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                    TempIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                    TempIntrastatJnlLine.SetRange("Country/Region of Origin Code", "Country/Region of Origin Code");
                    TempIntrastatJnlLine.SetRange("Partner VAT ID", "Partner VAT ID");
                    if not TempIntrastatJnlLine.FindFirst() then begin
                        TempIntrastatJnlLine := "Intrastat Jnl. Line";
                        TempIntrastatJnlLine.Insert();
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

                    SubTotalWeight := SubTotalWeight + Round("Total Weight", 1);
                    TotalWeight := TotalWeight + Round("Total Weight", 1);
                end;

                trigger OnPreDataItem()
                begin
                    TempIntrastatJnlLine.DeleteAll();
                    NoOfRecordsRTC := 0;

                    if GetFilter(Type) <> '' then
                        exit;

                    if not IntrastatSetup.Get() then
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
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");

                GLSetup.Get();
                if "Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderLine := StrSubstNo(Text002, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderLine := StrSubstNo(Text002, GLSetup."LCY Code");
                end;
            end;

            trigger OnPreDataItem()
            begin
                if "Intrastat Jnl. Line".GetFilter("Journal Template Name") <> '' then
                    SetFilter("Journal Template Name", "Intrastat Jnl. Line".GetFilter("Journal Template Name"));
                if "Intrastat Jnl. Line".GetFilter("Journal Batch Name") <> '' then
                    SetFilter(Name, "Intrastat Jnl. Line".GetFilter("Journal Batch Name"));
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
                        ApplicationArea = BasicEU;
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
    end;

    var
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        NoOfRecords: Integer;
        NoOfRecordsRTC: Integer;
        PrintJnlLines: Boolean;
        HeaderText: Text;
        HeaderLine: Text;
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;

        Text000: Label 'WwWw';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1.';
        IntrastatChecklistCaptionLbl: Label 'Intrastat - Checklist';
        PageNoCaptionLbl: Label 'Page';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        TariffNoCaptionLbl: Label 'Tariff No.';
        CountryRegionCodeCaptionLbl: Label 'Country/Region Code';
        TransactionTypeCaptionLbl: Label 'Transaction Type';
        TransactionMethodCaptionLbl: Label 'Transport Method';
        NoOfEntriesCaptionLbl: Label 'No. of Combined Entries';
        TotalCaptionLbl: Label 'Total';
        NoValuesErr: Label 'There are no values to report as per Intrastat Setup.';
}
#endif
