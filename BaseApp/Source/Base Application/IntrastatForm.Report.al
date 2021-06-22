report 501 "Intrastat - Form"
{
    DefaultLayout = RDLC;
    RDLCLayout = './IntrastatForm.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Form';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JnlTmplName_IntraJnlBatch; "Journal Template Name")
            {
            }
            column(Name_IntraJnlBatch; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                RequestFilterFields = Type;
                column(IntraJnlBatchStaticPeriod; StrSubstNo(Text002, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Type_IntraJnlLine; Format(Type))
                {
                }
                column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                {
                }
                column(HeaderLine; HeaderLine)
                {
                }
                column(HeaderFilter; HeaderFilter)
                {
                }
                column(TariffNo_IntraJnlLine; "Tariff No.")
                {
                }
                column(ItemDesc_IntraJnlLine; "Item Description")
                {
                }
                column(CountryIntraCode; Country."Intrastat Code")
                {
                }
                column(CountryName; Country.Name)
                {
                }
                column(TransacType_IntraJnlLine; "Transaction Type")
                {
                }
                column(TransportMet_IntraJnlLine; "Transport Method")
                {
                }
                column(SubTotalWeight; SubTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Quantity_IntraJnlLine; Quantity)
                {
                }
                column(StatisValue_IntraJnlLine; "Statistical Value")
                {
                }
                column(TotalWeight_IntraJnlLine; TotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(JnlTmplName_IntraJnlLine; "Journal Template Name")
                {
                }
                column(IntraFormCaption; IntraFormCaptionLbl)
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
                column(ItemDescriptionCaption; FieldCaption("Item Description"))
                {
                }
                column(CountryRegionCodeCaption; CountryRegionCodeCaptionLbl)
                {
                }
                column(CountryNameCaption; CountryNameCaptionLbl)
                {
                }
                column(TransactionTypeCaption; TransactionTypeCaptionLbl)
                {
                }
                column(TransportMethodCaption; TransportMethodCaptionLbl)
                {
                }
                column(TotalWeightCaption; TotalWeightCaptionLbl)
                {
                }
                column(QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(StatisticalValueCaption; FieldCaption("Statistical Value"))
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Country.Get("Country/Region Code");
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    TestField("Tariff No.");
                    TestField("Country/Region Code");
                    TestField("Transaction Type");
                    TestField("Total Weight");
                    if "Supplementary Units" then
                        TestField(Quantity);

                    if (PrevIntrastatJnlLine.Type <> Type) or
                       (PrevIntrastatJnlLine."Tariff No." <> "Tariff No.") or
                       (PrevIntrastatJnlLine."Country/Region Code" <> "Country/Region Code") or
                       (PrevIntrastatJnlLine."Transaction Type" <> "Transaction Type") or
                       (PrevIntrastatJnlLine."Transport Method" <> "Transport Method")
                    then begin
                        SubTotalWeight := 0;
                        PrevIntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                        PrevIntrastatJnlLine.SetRange(Type, Type);
                        PrevIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                        PrevIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                        PrevIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                        PrevIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                        PrevIntrastatJnlLine.FindFirst;
                    end;

                    SubTotalWeight := SubTotalWeight + Round("Total Weight", 1);
                    TotalWeight := TotalWeight + Round("Total Weight", 1);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLSetup.Get();
                if "Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderLine := StrSubstNo(Text003, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderLine := StrSubstNo(Text003, GLSetup."LCY Code");
                end;
                HeaderFilter := "Intrastat Jnl. Line".TableCaption + ': ' + IntraJnlLineFilter;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        IntraJnlLineFilter := "Intrastat Jnl. Line".GetFilters;
        if not ("Intrastat Jnl. Line".GetRangeMin(Type) = "Intrastat Jnl. Line".GetRangeMax(Type)) then
            "Intrastat Jnl. Line".FieldError(Type, Text000);

        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');
    end;

    var
        Text000: Label 'must be either Receipt or Shipment';
        Text001: Label 'WwWw';
        Text002: Label 'Statistics Period: %1';
        Text003: Label 'All amounts are in %1.';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntraJnlLineFilter: Text;
        NoOfRecords: Integer;
        HeaderLine: Text;
        HeaderFilter: Text;
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;
        IntraFormCaptionLbl: Label 'Intrastat - Form';
        PageNoCaptionLbl: Label 'Page';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        TariffNoCaptionLbl: Label 'Tariff No.';
        CountryRegionCodeCaptionLbl: Label 'Country/Region Code';
        CountryNameCaptionLbl: Label 'Name';
        TransactionTypeCaptionLbl: Label 'Transaction Type';
        TransportMethodCaptionLbl: Label 'Transport Method';
        TotalWeightCaptionLbl: Label 'Total Weight';
        TotalCaptionLbl: Label 'Total';
        NoOfRecordsCaptionLbl: Label 'No. of Entries';
}

