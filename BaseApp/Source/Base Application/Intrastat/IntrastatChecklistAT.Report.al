report 11105 "Intrastat - Checklist AT"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatChecklistAT.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Intrastat - Checklist AT';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
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
                column(STRSUBSTNO_Text001__Intrastat_Jnl__Batch___Statistics_Period__; StrSubstNo(Text001, "Intrastat Jnl. Batch"."Statistics Period"))
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
                column(PrintJnlLines; PrintJnlLines)
                {
                }
                column(Heading; Heading)
                {
                }
                column(HeaderText; HeaderText)
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
                column(OriginCountry__Intrastat_Code_; OriginCountry."Intrastat Code")
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
                column(Intrastat_Jnl__Line__Country_Region_Code_; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line_Type_Control38; Type)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No___Control39; "Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type__Control42; "Transaction Type")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control43; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control44; "Total Weight")
                {
                }
                column(Intrastat_Jnl__Line_Quantity_Control45; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control46; "Statistical Value")
                {
                }
                column(OriginCountry__Intrastat_Code__Control1140011; OriginCountry."Intrastat Code")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification__Control1140012; "Transaction Specification")
                {
                }
                column(Intrastat_Jnl__Line_Area_Control1140013; Area)
                {
                }
                column(Country__Intrastat_Code__Control40; Country."Intrastat Code")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control47; "Total Weight")
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line_Quantity_Control48; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control49; "Statistical Value")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control51; "Total Weight")
                {
                }
                column(Intrastat_Jnl__Line_Quantity_Control52; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control53; "Statistical Value")
                {
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control56; "Total Weight")
                {
                }
                column(Intrastat_Jnl__Line_Quantity_Control57; Quantity)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control58; "Statistical Value")
                {
                }
                column(NoOfRecords_Control62; NoOfRecords)
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
                column(CompanyInfo_AreaCaption; CompanyInfo_AreaCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line_Type_Control38Caption; FieldCaption(Type))
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No___Control39Caption; Intrastat_Jnl__Line__Tariff_No___Control39CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type__Control42Caption; Intrastat_Jnl__Line__Transaction_Type__Control42CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control43Caption; Intrastat_Jnl__Line__Transport_Method__Control43CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control44Caption; FieldCaption("Total Weight"))
                {
                }
                column(Intrastat_Jnl__Line_Quantity_Control45Caption; FieldCaption(Quantity))
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value__Control46Caption; FieldCaption("Statistical Value"))
                {
                }
                column(OriginCountry__Intrastat_Code__Control1140011Caption; OriginCountry__Intrastat_Code__Control1140011CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification__Control1140012Caption; FieldCaption("Transaction Specification"))
                {
                }
                column(Intrastat_Jnl__Line_Area_Control1140013Caption; FieldCaption(Area))
                {
                }
                column(Country__Intrastat_Code__Control40Caption; Country__Intrastat_Code__Control40CaptionLbl)
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
                column(OriginCountry__Intrastat_Code_Caption; OriginCountry__Intrastat_Code_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight__Control51Caption; Intrastat_Jnl__Line__Total_Weight__Control51CaptionLbl)
                {
                }
                column(No__of_EntriesCaption; No__of_EntriesCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(TotalCaption_Control55; TotalCaption_Control55Lbl)
                {
                }
                column(NoOfRecords_Control62Caption; NoOfRecords_Control62CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ("Journal Template Name" <> OldJournalTemplateName) or
                       ("Journal Batch Name" <> OldJournalBatchName) or
                       (Type <> OldType) or
                       ("Country/Region Code" <> OldCountry_RegionCode) or
                       ("Tariff No." <> OldTariffNo) or
                       ("Transaction Type" <> OldTransactionType) or
                       ("Transport Method" <> OldTransportMethod) or
                       (Area <> OldArea) or
                       ("Transaction Specification" <> OldTransactionSpecification) or
                       ("Country/Region of Origin Code" <> OldCountry_RegionofOriginCode)
                    then begin
                        NoOfRecords := NoOfRecords + 1;
                        OldJournalTemplateName := "Journal Template Name";
                        OldJournalBatchName := "Journal Batch Name";
                        OldType := Type;
                        OldCountry_RegionCode := "Country/Region Code";
                        OldTariffNo := "Tariff No.";
                        OldTransactionType := "Transaction Type";
                        OldTransportMethod := "Transport Method";
                        OldArea := Area;
                        OldTransactionSpecification := "Transaction Specification";
                        OldCountry_RegionofOriginCode := "Country/Region of Origin Code";
                    end;

                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Transaction Specification" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    OldTariffNo := "Tariff No.";
                    "Tariff No." := DelChr("Tariff No.");

#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist AT", true);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist AT", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        if CompanyInfo."Check Transport Method" then
                            TestField("Transport Method");
                        if CompanyInfo."Check Transaction Specific." then
                            TestField("Transaction Specification");
                        if Type = Type::Receipt then
                            TestField("Country/Region of Origin Code");
                        if "Supplementary Units" then
                            TestField(Quantity);
                    end;
#endif

                    if Type = Type::Receipt then begin
                        OriginCountry.Get("Country/Region of Origin Code");
                        OriginCountry.TestField("Intrastat Code");
                    end else
                        Clear(OriginCountry);

                    Country.Get("Country/Region Code");
                    Country.TestField("Intrastat Code");

                    "Tariff No." := OldTariffNo;
                end;
            }
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
        VATIDNo := CopyStr(DelChr(UpperCase(CompanyInfo."Registration No."), '=', Text000), 1, 11);

        GLSetup.Get();
        if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then begin
            GLSetup.TestField("Additional Reporting Currency");
            HeaderText := StrSubstNo(Text002, GLSetup."Additional Reporting Currency");
        end else begin
            GLSetup.TestField("LCY Code");
            HeaderText := StrSubstNo(Text002, GLSetup."LCY Code");
        end;
#if not CLEAN19
        if IntrastatSetup.Get() then;
#endif
        IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
    end;

    var
        Text000: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/-.+';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        OriginCountry: Record "Country/Region";
#if not CLEAN19
        IntrastatSetup: Record "Intrastat Setup";
#endif
        IntraJnlManagement: Codeunit IntraJnlManagement;
        NoOfRecords: Integer;
        PrintJnlLines: Boolean;
        Heading: Boolean;
        HeaderText: Text[30];
        VATIDNo: Code[11];
        OldJournalTemplateName: Code[10];
        OldJournalBatchName: Code[10];
        OldType: Integer;
        OldCountry_RegionCode: Code[10];
        OldTariffNo: Code[20];
        OldTransactionType: Code[10];
        OldTransportMethod: Code[10];
        OldArea: Code[10];
        OldTransactionSpecification: Code[10];
        OldCountry_RegionofOriginCode: Code[10];
        Intrastat___ChecklistCaptionLbl: Label 'Intrastat - Checklist';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VATIDNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo_AreaCaptionLbl: Label 'Area';
        Intrastat_Jnl__Line__Tariff_No___Control39CaptionLbl: Label 'Tariff No.';
        Intrastat_Jnl__Line__Transaction_Type__Control42CaptionLbl: Label 'Transaction Type';
        Intrastat_Jnl__Line__Transport_Method__Control43CaptionLbl: Label 'Transport Method';
        OriginCountry__Intrastat_Code__Control1140011CaptionLbl: Label 'Country of Origin Code';
        Country__Intrastat_Code__Control40CaptionLbl: Label 'Country Code';
        Country__Intrastat_Code_CaptionLbl: Label 'Country Code';
        OriginCountry__Intrastat_Code_CaptionLbl: Label 'Country of Origin Code';
        Intrastat_Jnl__Line__Total_Weight__Control51CaptionLbl: Label 'Total';
        No__of_EntriesCaptionLbl: Label 'No. of Entries';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control55Lbl: Label 'Total';
        NoOfRecords_Control62CaptionLbl: Label 'No. of Entries';
}

