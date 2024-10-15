#if not CLEAN22
report 11013 "Intrastat - Checklist DE"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatChecklistDE.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Intrastat - Checklist DE';
    UsageCategory = ReportsAndAnalysis;
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
            column(Intrastat_Jnl__Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Batch_Name; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Transaction Specification", "Country/Region of Origin Code");
                RequestFilterFields = Type;
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(STRSUBSTNO_Text1140001__Intrastat_Jnl__Batch___Statistics_Period__; StrSubstNo(Text1140001, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(USERID; UserId)
                {
                }
                column(VATIDNo; VATIDNo)
                {
                }
                column(CompanyInfo_Area; CompanyInfo.Area)
                {
                }
                column(Heading; Heading)
                {
                }
                column(Intrastat_Jnl__Line_Country_Region_Code; "Country/Region Code")
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(PrintJnlLines; PrintJnlLines)
                {
                }
                column(Intrastat_Jnl__Line_Type; Type)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__; "Tariff No.")
                {
                }
                column(Country__Intrastat_Code_; Country."Intrastat Code")
                {
                }
                column(Country_Name; Country.Name)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_; "Transaction Type")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_; "Transport Method")
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
                column(Intrastat_Jnl__Line__Item_Description_; "Item Description")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight_; "Total Weight")
                {
                    DecimalPlaces = 2 : 2;
                }
                column(Intrastat_Jnl__Line_Quantity; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value_; "Statistical Value")
                {
                }
                column(Intrastat_Jnl__Line__Internal_Ref__No__; "Internal Ref. No.")
                {
                }
                column(Intrastat_Jnl__Line_Type_Control1140049; Type)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No___Control1140050; "Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type__Control1140051; "Transaction Type")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1140052; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control1140053; Transctotal)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line_Quantity_Control1140054; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140055; "Statistical Value")
                {
                }
                column(OriginCountry__Intrastat_Code__Control1140056; OriginCountryIntrastatCode)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification__Control1140057; "Transaction Specification")
                {
                }
                column(Intrastat_Jnl__Line_Area_Control1140058; Area)
                {
                }
                column(Country__Intrastat_Code__Control1140059; Country."Intrastat Code")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control1140060; "Total Weight")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line_Quantity_Control1140061; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140062; "Statistical Value")
                {
                }
                column(SumTotalWeight; SumTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line_Quantity_Control1140065; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140066; "Statistical Value")
                {
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(SumTotalWeight_Control1140071; SumTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line_Quantity_Control1140072; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140073; "Statistical Value")
                {
                }
                column(NoOfRecords_Control1140075; NoOfRecords)
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
                column(Intrastat___ChecklistCaption; Intrastat___ChecklistCaptionLbl)
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
                column(Intrastat_Jnl__Line_Type_Control1140049Caption; FieldCaption(Type))
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No___Control1140050Caption; Intrastat_Jnl__Line__Tariff_No___Control1140050CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type__Control1140051Caption; Intrastat_Jnl__Line__Transaction_Type__Control1140051CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1140052Caption; Intrastat_Jnl__Line__Transport_Method__Control1140052CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control1140053Caption; Intrastat_Jnl__Line__Total_Weight__Control1140053CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line_Quantity_Control1140054Caption; FieldCaption(Quantity))
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control1140055Caption; FieldCaption("Statistical Value"))
                {
                }
                column(Country_of_Origin_CodeCaption; Country_of_Origin_CodeCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification__Control1140057Caption; FieldCaption("Transaction Specification"))
                {
                }
                column(Intrastat_Jnl__Line_Area_Control1140058Caption; FieldCaption(Area))
                {
                }
                column(Country_CodeCaption; Country_CodeCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Item_Description_Caption; FieldCaption("Item Description"))
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight_Caption; FieldCaption("Total Weight"))
                {
                }
                column(Intrastat_Jnl__Line_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value_Caption; FieldCaption("Statistical Value"))
                {
                }
                column(Intrastat_Jnl__Line__Internal_Ref__No__Caption; FieldCaption("Internal Ref. No."))
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__Caption; FieldCaption("Tariff No."))
                {
                }
                column(Country__Intrastat_Code_Caption; Country__Intrastat_Code_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_Caption; FieldCaption("Transaction Type"))
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_Caption; FieldCaption("Transport Method"))
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification_Caption; FieldCaption("Transaction Specification"))
                {
                }
                column(Intrastat_Jnl__Line_AreaCaption; FieldCaption(Area))
                {
                }
                column(Country_of_Origin_CodeCaption_Control1140043; Country_of_Origin_CodeCaption_Control1140043Lbl)
                {
                }
                column(SumTotalWeightCaption; SumTotalWeightCaptionLbl)
                {
                }
                column(No__of_EntriesCaption; No__of_EntriesCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(TotalCaption_Control1140070; TotalCaption_Control1140070Lbl)
                {
                }
                column(NoOfRecords_Control1140075Caption; NoOfRecords_Control1140075CaptionLbl)
                {
                }
                column(Intrastat_Jnl_Line_Partner_VAT_ID; "Partner VAT ID")
                {
                }
                column(Intrastat_Jnl_Line_Partner_VAT_ID_Caption; PartnerVATIDLbl)
                {
                }

                trigger OnAfterGetRecord()
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
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist DE", true);
                    OriginCountryIntrastatCode := '';
                    if Type = Type::Receipt then
                        OriginCountryIntrastatCode := IntrastatExportMgtDACH.GetOriginCountryCode("Country/Region of Origin Code")
                    else
                        if "Country/Region of Origin Code" <> '' then
                            OriginCountryIntrastatCode := IntrastatExportMgtDACH.GetOriginCountryCode("Country/Region of Origin Code");

                    Country.Get("Country/Region Code");
                    Country.TestField("Intrastat Code");

                    "Tariff No." := OldTariffNo;

                    if Number = 0 then
                        Heading := false
                    else
                        Heading := true;
                    Number := Number + 1;
                    SumTotalWeight := SumTotalWeight + Round("Total Weight", 1);

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
                        Transctotal := 0;
                        Heading := false;
                    end;
                    IntrastatJnlLine1 := "Intrastat Jnl. Line";
                    Transctotal := Transctotal + Round("Total Weight", 1);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(IntrastatJnlLine1);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(SumTotalWeight);

                GLSetup.Get();
                if "Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    HeaderText := StrSubstNo(Text1140002, GLSetup."Additional Reporting Currency");
                end else begin
                    GLSetup.TestField("LCY Code");
                    HeaderText := StrSubstNo(Text1140002, GLSetup."LCY Code");
                end;
                Number := 0;
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
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
                    field(PrintJnlLines; PrintJnlLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Intrastat Journal Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if the report only displays the information that must be reported to the tax authorities and not the lines in the journal.';
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
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        VATIDNo := CopyStr(DelChr(UpperCase(CompanyInfo."Registration No."), '=', Text1140000), 1, 11);
    end;

    var
        Text1140000: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/-.+';
        Text1140001: Label 'Statistics Period: %1';
        Text1140002: Label 'All amounts are in %1';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        IntrastatJnlLine1: Record "Intrastat Jnl. Line";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        NoOfRecords: Integer;
        PrintJnlLines: Boolean;
        Heading: Boolean;
        HeaderText: Text[30];
        OldTariffNo: Code[20];
        VATIDNo: Code[11];
        OriginCountryIntrastatCode: Code[10];
        SumTotalWeight: Decimal;
        Number: Integer;
        Transctotal: Decimal;
        Intrastat___ChecklistCaptionLbl: Label 'Intrastat - Checklist';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VATIDNoCaptionLbl: Label 'VAT Reg. No.';
        AreaCaptionLbl: Label 'Area';
        Intrastat_Jnl__Line__Tariff_No___Control1140050CaptionLbl: Label 'Tariff No.';
        Intrastat_Jnl__Line__Transaction_Type__Control1140051CaptionLbl: Label 'Transaction Type';
        Intrastat_Jnl__Line__Transport_Method__Control1140052CaptionLbl: Label 'Transport Method';
        Intrastat_Jnl__Line__Total_Weight__Control1140053CaptionLbl: Label 'Total Weight';
        Country_of_Origin_CodeCaptionLbl: Label 'Country of Origin';
        Country_CodeCaptionLbl: Label 'Country Code';
        Country__Intrastat_Code_CaptionLbl: Label 'Country Code';
        Country_of_Origin_CodeCaption_Control1140043Lbl: Label 'Country of Origin';
        SumTotalWeightCaptionLbl: Label 'Total';
        No__of_EntriesCaptionLbl: Label 'No. of Combined Entries';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control1140070Lbl: Label 'Total';
        NoOfRecords_Control1140075CaptionLbl: Label 'No. of Entries';
        PartnerVATIDLbl: Label 'Partner VAT ID';
}
#endif