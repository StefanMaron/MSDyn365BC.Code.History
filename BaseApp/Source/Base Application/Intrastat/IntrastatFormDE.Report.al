report 11012 "Intrastat - Form DE"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatFormDE.rdlc';
    Caption = 'Intrastat - Form DE';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Journal Template Name", Name;
            column(Intrastat_Jnl__Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Batch_Name; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Transaction Specification", "Country/Region of Origin Code");
                RequestFilterFields = Type;
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(STRSUBSTNO_Text1140002_COPYSTR__Intrastat_Jnl__Batch___Statistics_Period; StrSubstNo(Text1140002, CopyStr("Intrastat Jnl. Batch"."Statistics Period", 3, 2) + CopyStr("Intrastat Jnl. Batch"."Statistics Period", 1, 2)))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(USERID; UserId)
                {
                }
                column(Intrastat_Jnl__Line__Intrastat_Jnl__Line__Type; "Intrastat Jnl. Line".Type)
                {
                }
                column(VATIDNo; VATIDNo)
                {
                }
                column(CompanyInfo_Area; CompanyInfo.Area)
                {
                }
                column(Intrastat_Jnl_Line_Type; Type)
                {
                }
                column(Intrastat_Jnl_Line_Country_Region_Code; "Country/Region Code")
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(Intrastat_Jnl__Line__TABLECAPTION__________IntraJnlLineFilter; "Intrastat Jnl. Line".TableCaption + ': ' + IntraJnlLineFilter)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__; "Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Item_Description_; "Item Description")
                {
                }
                column(Country__Intrastat_Code_; Country."Intrastat Code")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_; "Transaction Type")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight_; Transtotal)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Total_Weight_Rounded_; TranstotalRounded)
                {
                }
                column(Intrastat_Jnl__Line_Quantity; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value_; "Statistical Value")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification_; "Transaction Specification")
                {
                }
                column(Intrastat_Jnl__Line_Area; Area)
                {
                }
                column(OriginCountry__Intrastat_Code_; OriginCountryIntrastatCode)
                {
                }
                column(SumTotalWeight; SumTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(SumTotalWeightRounded; SumTotalWeightRounded)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140038; "Statistical Value")
                {
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line_Journal_Template_Name; "Journal Template Name")
                {
                }
                column(Intrastat_Jnl__Line_Journal_Batch_Name; "Journal Batch Name")
                {
                }
                column(Intrastat_Jnl__Line_Line_No_; "Line No.")
                {
                }
                column(Intrastat_Jnl__Line_Country_Region_of_Origin_Code; "Country/Region of Origin Code")
                {
                }
                column(Intrastat___FormCaption; Intrastat___FormCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(VATIDNoCaption; VATIDNoCaptionLbl)
                {
                }
                column(AreaCaption; AreaCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__Caption; Intrastat_Jnl__Line__Tariff_No__CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Item_Description_Caption; FieldCaption("Item Description"))
                {
                }
                column(Country__Intrastat_Code_Caption; Country__Intrastat_Code_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_Caption; Intrastat_Jnl__Line__Transaction_Type_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_Caption; Intrastat_Jnl__Line__Transport_Method_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight_Caption; Intrastat_Jnl__Line__Total_Weight_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value_Caption; FieldCaption("Statistical Value"))
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification_Caption; FieldCaption("Transaction Specification"))
                {
                }
                column(Intrastat_Jnl__Line_AreaCaption; FieldCaption(Area))
                {
                }
                column(OriginCountry__Intrastat_Code_Caption; OriginCountry__Intrastat_Code_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Total__Caption_Control1140036; Intrastat_Jnl__Line__Total__Caption_Control1140036Lbl)
                {
                }
                column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line_Partner_VAT_ID; "Partner VAT ID")
                {
                }

                trigger OnAfterGetRecord()
                var
                    OldTariffNo: Code[20];
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       (Area = '') and
                       ("Transaction Specification" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    OldTariffNo := "Tariff No.";
                    "Tariff No." := DelChr("Tariff No.");
#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Form DE", true);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Form DE", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        if CompanyInfo."Check Transport Method" then
                            TestField("Transport Method");
                        TestField(Area);
                        if CompanyInfo."Check Transaction Specific." then
                            TestField("Transaction Specification");
                        if Type = Type::Receipt then
                            TestField("Country/Region of Origin Code");
                        if "Supplementary Units" then
                            TestField(Quantity)
                    end;
#endif
                    if not "Supplementary Units" then
                        Quantity := 0;
                    "Tariff No." := OldTariffNo;
                    SumTotalWeight := SumTotalWeight + "Total Weight";
                    SumTotalWeightRounded := Round(SumTotalWeight, 1);

                    Country.Get("Country/Region Code");
                    Country.TestField("Intrastat Code");
                    OriginCountryIntrastatCode := "Country/Region of Origin Code";

                    if ("Intrastat Jnl. Line"."Journal Template Name" <> IntrastatJnlLine1."Journal Template Name") or
                       ("Intrastat Jnl. Line"."Journal Batch Name" <> IntrastatJnlLine1."Journal Batch Name") or
                       ("Intrastat Jnl. Line".Type <> IntrastatJnlLine1.Type) or
                       ("Intrastat Jnl. Line"."Country/Region Code" <> IntrastatJnlLine1."Country/Region Code") or
                       ("Intrastat Jnl. Line"."Tariff No." <> IntrastatJnlLine1."Tariff No.") or
                       ("Intrastat Jnl. Line"."Transaction Type" <> IntrastatJnlLine1."Transaction Type") or
                       ("Intrastat Jnl. Line"."Transport Method" <> IntrastatJnlLine1."Transport Method") or
                       ("Intrastat Jnl. Line".Area <> IntrastatJnlLine1.Area) or
                       ("Intrastat Jnl. Line"."Transaction Specification" <> IntrastatJnlLine1."Transaction Specification") or
                       ("Intrastat Jnl. Line"."Country/Region of Origin Code" <> IntrastatJnlLine1."Country/Region of Origin Code") or
                       ("Intrastat Jnl. Line"."Partner VAT ID" <> IntrastatJnlLine1."Partner VAT ID")
                    then begin
                        NoOfRecords := NoOfRecords + 1;
                        Transtotal := 0;
                    end;
                    IntrastatJnlLine1 := "Intrastat Jnl. Line";
                    Transtotal := Transtotal + "Total Weight";
                    TranstotalRounded := Round(Transtotal, 1);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                // Code moved from Section
                GLSetup.Get();
                if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderText := StrSubstNo(Text1140003, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1140003, GLSetup."LCY Code");
                end;

                Clear(SumTotalWeight);
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
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
            "Intrastat Jnl. Line".FieldError(Type, Text1140000);

        CompanyInfo.Get();
        VATIDNo := CopyStr(DelChr(UpperCase(CompanyInfo."Registration No."), '=', Text1140000), 1, 11);
#if not CLEAN19
        if IntrastatSetup.Get() then;
#endif
    end;

    var
        Text1140000: Label 'must be either Receipt or Shipment';
        Text1140002: Label 'Statistics Period: %1';
        Text1140003: Label 'All amounts are in %1';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        IntrastatJnlLine1: Record "Intrastat Jnl. Line";
#if not CLEAN19
        IntrastatSetup: Record "Intrastat Setup";
#endif
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntraJnlLineFilter: Text;
        HeaderText: Text[30];
        NoOfRecords: Integer;
        VATIDNo: Code[11];
        OriginCountryIntrastatCode: Code[10];
        SumTotalWeight: Decimal;
        SumTotalWeightRounded: Integer;
        Transtotal: Decimal;
        Intrastat___FormCaptionLbl: Label 'Intrastat - Form';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VATIDNoCaptionLbl: Label 'VAT Reg. No.';
        AreaCaptionLbl: Label 'Area';
        Intrastat_Jnl__Line__Tariff_No__CaptionLbl: Label 'Tariff No.';
        Country__Intrastat_Code_CaptionLbl: Label 'Country Code';
        Intrastat_Jnl__Line__Transaction_Type_CaptionLbl: Label 'Transaction Type';
        Intrastat_Jnl__Line__Transport_Method_CaptionLbl: Label 'Transport Method';
        Intrastat_Jnl__Line__Total_Weight_CaptionLbl: Label 'Total Weight';
        OriginCountry__Intrastat_Code_CaptionLbl: Label 'Country of Origin Code';
        Intrastat_Jnl__Line__Total__Caption_Control1140036Lbl: Label 'Total';
        NoOfRecordsCaptionLbl: Label 'No. of Combined Entries';
        TranstotalRounded: Integer;
}

