report 501 "Intrastat - Form"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatForm.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Form';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JrnlTemName_IntrastatJnlBatch; "Journal Template Name")
            {
            }
            column(Name_IntrastatJnlBatch; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                RequestFilterFields = Type;
                column(IntrastatJnlBatchStatisticsPeriod; StrSubstNo(Text002, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(Type_IntrastatJnlLine; Format("Intrastat Jnl. Line".Type))
                {
                }
                column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                {
                }
                column(PhoneNo; PhoneNo)
                {
                }
                column(FaxNo; FaxNo)
                {
                }
                column(ObligationLevel; StrSubstNo('%1', ObligationLevel))
                {
                }
                column(Contact; Contact)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(IntraJnlLineFilter; "Intrastat Jnl. Line".TableCaption + ': ' + IntraJnlLineFilter)
                {
                }
                column(HeaderFilter; HeaderFilter)
                {
                }
                column(TariffNo_IntrastatJnlLine; "Tariff No.")
                {
                }
                column(ItemDesc_IntrastatJnlLine; "Item Description")
                {
                    IncludeCaption = true;
                }
                column(CountryIntrastatCode; Country."Intrastat Code")
                {
                }
                column(TransType_IntrastatJnlLine; "Transaction Type")
                {
                }
                column(TrnsprtMethod_IntrastatJnlLine; "Transport Method")
                {
                }
                column(IntrastatJnlLineTotalWeight; SubTotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(SttstclValue_IntrastatJnlLine; "Statistical Value")
                {
                    IncludeCaption = true;
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(CustVATRegNo_IntrastatJnlLine; "Partner VAT ID")
                {
                    IncludeCaption = true;
                }
                column(Amt_IntrastatJnlLine; Amount)
                {
                    IncludeCaption = true;
                }
                column(TrnsctnSpec_IntrastatJnlLine; "Transaction Specification")
                {
                    IncludeCaption = true;
                }
                column(SplmntyUts_IntrastatJnlLine; Format("Supplementary Units"))
                {
                }
                column(ShpmntdCode_IntrastatJnlLine; "Shpt. Method Code")
                {
                    IncludeCaption = true;
                }
                column(Area_IntrastatJnlLine; Area)
                {
                    IncludeCaption = true;
                }
                column(CntyRgnCode_IntrastatJnlLine; "Country/Region of Origin Code")
                {
                    IncludeCaption = true;
                }
                column(TotalWeight; TotalWeight)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(JnlTemName_IntrastatJnlLine; "Journal Template Name")
                {
                }
                column(IntrastatFormCaption; IntrastatFormCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(VATRegNoCaption; VATRegNoCaptionLbl)
                {
                }
                column(ContactCaption; ContactCaptionLbl)
                {
                }
                column(PhoneNoCaption; PhoneNoCaptionLbl)
                {
                }
                column(FaxNoCaption; FaxNoCaptionLbl)
                {
                }
                column(ObligationLevelCaption; ObligationLevelCaptionLbl)
                {
                }
                column(IntrastatJnlLineTariffNoCaption; IntrastatJnlLineTariffNoCaptionLbl)
                {
                }
                column(CountryIntrastatCodeCaption; CountryIntrastatCodeCaptionLbl)
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
                column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
                {
                }
                column(SupplementaryUnitsCaption; SupplementaryUnitsCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    NoOfRecords := NoOfRecords + 1;

                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Form", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        TestField("Total Weight");
                        if "Supplementary Units" then
                            TestField(Quantity);
                    end;

                    Country.Get("Country/Region Code");
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
                    GLSetup.Get();
                    if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then begin
                        GLSetup.TestField("Additional Reporting Currency");
                        HeaderText := StrSubstNo(Text003, GLSetup."Additional Reporting Currency");
                    end else begin
                        GLSetup.TestField("LCY Code");
                        HeaderText := StrSubstNo(Text003, GLSetup."LCY Code");
                    end;

                    if ("Intrastat Jnl. Batch"."Currency Identifier" = '') then
                        HeaderText := HeaderText + StrSubstNo(Text10800, "Intrastat Jnl. Batch".FieldCaption("Currency Identifier"))
                    else
                        HeaderText := HeaderText + StrSubstNo(' (%1 : %2)', "Intrastat Jnl. Batch".FieldCaption("Currency Identifier"),
                            "Intrastat Jnl. Batch"."Currency Identifier");
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
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ObligationLevel; ObligationLevel)
                    {
                        Caption = 'Obligation Level';
                        ToolTip = 'Specifies the obligation level based on the amount of receipts and dispatches from January 1 to December 31 in the previous year. For more information about the obligation level you should use, see the French Customs website.';
                    }
                    field(PhoneNo; PhoneNo)
                    {
                        Caption = 'Phone No.';
                        ToolTip = 'Specifies the telephone number.';
                    }
                    field(FaxNo; FaxNo)
                    {
                        Caption = 'Fax No.';
                        ToolTip = 'Specifies the fax number.';
                    }
                    field(Contact; Contact)
                    {
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CompanyInfo.Get();
            PhoneNo := CompanyInfo."Phone No.";
            FaxNo := CompanyInfo."Fax No.";
        end;
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
        if IntrastatSetup.Get() then;
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
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntraJnlLineFilter: Text;
        HeaderText: Text[100];
        NoOfRecords: Integer;
        HeaderLine: Text;
        HeaderFilter: Text;
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;
        Text10800: Label ' (no %1)';
        PhoneNo: Text[30];
        FaxNo: Text[30];
        Contact: Text[50];
        ObligationLevel: Option "1","2","3","4";
        IntrastatFormCaptionLbl: Label 'Intrastat - Form';
        CurrReportPageNoCaptionLbl: Label 'Page';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        ContactCaptionLbl: Label 'Contact';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        ObligationLevelCaptionLbl: Label 'Obligation Level';
        IntrastatJnlLineTariffNoCaptionLbl: Label 'Tariff No.';
        CountryIntrastatCodeCaptionLbl: Label 'Country/Region Code';
        TransactionTypeCaptionLbl: Label 'Transaction Type';
        TransportMethodCaptionLbl: Label 'Transport Method';
        TotalWeightCaptionLbl: Label 'Total Weight';
        NoOfRecordsCaptionLbl: Label 'Line No.';
        SupplementaryUnitsCaptionLbl: Label 'Supplementary Units';
        TotalCaptionLbl: Label 'Total';
}

