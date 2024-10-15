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
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Transaction Specification", Area);
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
                column(CompanyInfoEnterpriseNo; CompanyInfo."Enterprise No.")
                {
                }
                column(ApplicationVersion; 'Navision' + ' ' + ApplicationSystemConstants.ApplicationVersion() + ' ' + Text11306)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(NoOfRecordsRTC; NoOfRecordsRTC)
                {
                }
                column(PrintJnlLines; PrintJnlLines)
                {
                }
                column(IntrastatJnlLineType; Type)
                {
                }
                column(IntrastatJnlLineTariffNo; "Tariff No.")
                {
                }
                column(CountryIntrastatCode; Country."Intrastat Code")
                {
                }
                column(CountryName; Country.Name)
                {
                }
                column(IntrastatJnlLineTranType; "Transaction Type")
                {
                }
                column(IntrastatJnlLinTranMethod; "Transport Method")
                {
                }
                column(Heading; Heading)
                {
                }
                column(IntrastatJnlLineStatVal; "Statistical Value")
                {
                }
                column(IntrastatJnlLineQty; Quantity)
                {
                }
                column(IntrastatJnlLineTotalWt; "Total Weight")
                {
                }
                column(IntrastatJnlLineSupplementaryUnits; "Supplementary Units")
                {
                }
                column(IntrastatJnlLineNoOfSupplementaryUnits; "No. of Supplementary Units")
                {
                }
                column(IntrastatJnlLineUOM; "Unit of Measure")
                {
                }
                column(IntrastatJnlLineArea; Area)
                {
                }
                column(IntrastatJnlLineTransactionSpecification; "Transaction Specification")
                {
                }
                column(IntrastatJnlLineItemDesc; "Item Description")
                {
                }
                column(IntrastatJnlLineInternalRefNo; "Internal Ref. No.")
                {
                }
                column(NoOfDetails; NoOfDetails)
                {
                }
                column(SubTotalWeightRTC; 'SubTotalWeightRTC')
                {
                }
                column(TotalQuantity; 'TotalQuantity')
                {
                }
                column(TotalStatisticalValue; 'TotalStatisticalValue')
                {
                }
                column(NewNoOfRecords; 'NewNoOfRecords')
                {
                }
                column(SubTotalQuantity; 'SubTotalQuantity')
                {
                }
                column(SubTotalStatisticalValue; 'SubTotalStatisticalValue')
                {
                }
                column(NoOfRecords; NoOfRecords)
                {
                }
                column(IntrastatChecklistCaption; IntrastatChecklistCaptionLbl)
                {
                }
                column(PageCaption; PageCaptionLbl)
                {
                }
                column(EnterpriseNoCaption; EnterpriseNoCaptionLbl)
                {
                }
                column(TypeCaption_IntrastatJnlLine; FieldCaption(Type))
                {
                }
                column(TariffNoCaption; TariffNoCaptionLbl)
                {
                }
                column(CountryRegionCodeCaption; CountryRegionCodeCaptionLbl)
                {
                }
                column(TransTypeCaption; TransTypeCaptionLbl)
                {
                }
                column(TransportMethodCaption; TransportMethodCaptionLbl)
                {
                }
                column(TotalWeightCaption_IntrastatJnlLine; FieldCaption("Total Weight"))
                {
                }
                column(QtyCaption_IntrastatJnlLine; FieldCaption(Quantity))
                {
                }
                column(StatisticalValueCaption_IntrastatJnlLine; FieldCaption("Statistical Value"))
                {
                }
                column(SupplementaryUnitsCaption_IntrastatJnlLine; FieldCaption("Supplementary Units"))
                {
                }
                column(NoOfSupplementaryUnitsCaption_IntrastatJnlLine; FieldCaption("No. of Supplementary Units"))
                {
                }
                column(UOMCaption_IntrastatJnlLine; FieldCaption("Unit of Measure"))
                {
                }
                column(AreaCaption_IntrastatJnlLine; FieldCaption(Area))
                {
                }
                column(TransactionSpecCaption_IntrastatJnlLine; FieldCaption("Transaction Specification"))
                {
                }
                column(ItemDescCaption_IntrastatJnlLine; FieldCaption("Item Description"))
                {
                }
                column(InternalRefNoCaption_IntrastatJnlLine; FieldCaption("Internal Ref. No."))
                {
                }
                column(TariffNoCaption_IntrastatJnlLine; FieldCaption("Tariff No."))
                {
                }
                column(CountryRegionCodeCaption1; CountryRegionCodeCaptionLbl)
                {
                }
                column(TransTypeCaption_IntrastatJnlLine; FieldCaption("Transaction Type"))
                {
                }
                column(TransportMethodCaption_IntrastatJnlLine; FieldCaption("Transport Method"))
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(NoOfEntriesCaption; NoOfEntriesCaptionLbl)
                {
                }
                column(JnlTempName_IntrastatJnlLine; "Journal Template Name")
                {
                }
                column(JnlBatchName_IntrastatJnlLine; "Journal Batch Name")
                {
                }
                column(LineLineNo_IntrastatJnlLine; "Line No.")
                {
                }
                dataitem(Errorloop; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrortextNumber; Errortext[Number])
                    {
                    }
                    column(WarningTextCaption; WarningTextCaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        Errorcounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, Errorcounter);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
#if CLEAN19
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Checklist", false);
#endif
                    if "Tariff No." = '' then
                        AddError("Intrastat Jnl. Line", FieldNo("Tariff No."), StrSubstNo(Text11300, FieldCaption("Tariff No.")))
                    else
                        if not Tariffnumber.Get("Tariff No.") then
                            AddError("Intrastat Jnl. Line", FieldNo("Tariff No."), StrSubstNo(Text11301, "Tariff No."))
                        else
                            TariffnumberExists := true;

                    if "Country/Region Code" = '' then
                        AddError("Intrastat Jnl. Line", FieldNo("Country/Region Code"), StrSubstNo(Text11300, FieldCaption("Country/Region Code")))
                    else
                        if not Country.Get("Country/Region Code") then
                            AddError(
                              "Intrastat Jnl. Line", FieldNo("Country/Region Code"), StrSubstNo(Text11307, "Country/Region Code"))
                        else
                            CountryExists := true;

                    if "Transaction Type" = '' then
                        AddError("Intrastat Jnl. Line", FieldNo("Transaction Type"), StrSubstNo(Text11300, FieldCaption("Transaction Type")));

                    if Area = '' then
                        AddError("Intrastat Jnl. Line", FieldNo(Area), StrSubstNo(Text11300, FieldCaption(Area)));
                    if not GLSetup."Simplified Intrastat Decl." then begin
                        if "Transport Method" = '' then
                            AddError("Intrastat Jnl. Line", FieldNo("Transport Method"), StrSubstNo(Text11300, FieldCaption("Transport Method")));
                        if "Transaction Specification" = '' then
                            AddError(
                              "Intrastat Jnl. Line", FieldNo("Transaction Specification"), StrSubstNo(Text11300, FieldCaption("Transaction Specification")));
                    end;

                    if TariffnumberExists then
                        if Tariffnumber."Weight Mandatory" then begin
                            if "Total Weight" <= 0 then
                                AddError(
                                  "Intrastat Jnl. Line", FieldNo("Total Weight"),
                                  StrSubstNo(
                                    Text11302,
                                    FieldCaption("Total Weight")))
                        end else
                            if not "Supplementary Units" then
                                AddError(
                                  "Intrastat Jnl. Line", FieldNo("Supplementary Units"),
                                  StrSubstNo(
                                    Text11303,
                                    FieldCaption("Supplementary Units"), true));

                    if "Supplementary Units" then begin
                        if Quantity = 0 then
                            AddError("Intrastat Jnl. Line", FieldNo(Quantity), StrSubstNo(Text11304, FieldCaption(Quantity)));
                        if "Conversion Factor" = 0 then
                            AddError("Intrastat Jnl. Line", FieldNo("Conversion Factor"), StrSubstNo(Text11304, FieldCaption("Conversion Factor")));
                    end;

                    if "Statistical Value" <= 0 then
                        AddError(
                          "Intrastat Jnl. Line", FieldNo("Statistical Value"),
                          StrSubstNo(
                            Text11302,
                            FieldCaption("Statistical Value")));
                    if CountryExists and (Country."Intrastat Code" = '') then
                        AddError(
                          "Intrastat Jnl. Line", FieldNo("Country/Region Code"),
                          StrSubstNo(Text11305, Country.Code));
                    TempIntrastatJnlLine.Reset();
                    TempIntrastatJnlLine.SetRange(Type, Type);
                    TempIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                    TempIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                    TempIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                    TempIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                    if not TempIntrastatJnlLine.FindFirst() then begin
                        TempIntrastatJnlLine := "Intrastat Jnl. Line";
                        TempIntrastatJnlLine.Insert();
                        NoOfRecordsRTC += 1;
                    end;

                    if (PrevIntrastatJnlLine.Type <> Type) or
                       (PrevIntrastatJnlLine."Tariff No." <> "Tariff No.") or
                       (PrevIntrastatJnlLine."Country/Region Code" <> "Country/Region Code") or
                       (PrevIntrastatJnlLine."Transaction Type" <> "Transaction Type") or
                       (PrevIntrastatJnlLine."Transport Method" <> "Transport Method")
                    then begin
                        PrevIntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                        PrevIntrastatJnlLine.SetRange(Type, Type);
                        PrevIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                        PrevIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                        PrevIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                        PrevIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                        PrevIntrastatJnlLine.FindFirst();
                    end;

                    if (TypeGroup <> Type) or
                       (CRCodeGroup <> "Country/Region Code") or
                       (TariffNoGroup <> "Tariff No.") or
                       (TransactionTypeGroup <> "Transaction Type") or
                       (TransportMethodGroup <> "Transport Method") or
                       (TransactionSpecificationGroup <> "Transaction Specification") or
                       (AreaGroup <> Area)
                    then begin
                        NoOfDetails := 0;
                        NoOfRecords := NoOfRecords + 1;

                        TypeGroup := Type;
                        CRCodeGroup := "Country/Region Code";
                        TariffNoGroup := "Tariff No.";
                        TransactionTypeGroup := "Transaction Type";
                        TransportMethodGroup := "Transport Method";
                        TransactionSpecificationGroup := "Transaction Specification";
                        AreaGroup := Area;
                    end;

                    NoOfDetails := NoOfDetails + 1;
                end;

                trigger OnPreDataItem()
                begin
                    ErrorMessage.SetContext("Intrastat Jnl. Batch");
                    ErrorMessage.ClearLog();

                    TempIntrastatJnlLine.DeleteAll();
                    NoOfDetails := 0;
                    NoOfRecords := 0;

                    if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then
                        ReportingCurr := GLSetup."Additional Reporting Currency"
                    else
                        ReportingCurr := GLSetup."LCY Code";
                    HeaderText := StrSubstNo(Text002, ReportingCurr);

                    CRCodeGroup := '0';
                    TariffNoGroup := '0';
                    TransactionTypeGroup := '0';
                    TransportMethodGroup := '0';
                    TransactionSpecificationGroup := '0';
                    AreaGroup := '0';
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLSetup.Get();
                if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then
                    GLSetup.TestField("Additional Reporting Currency")
                else
                    GLSetup.TestField("LCY Code");
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
                        ApplicationArea = Advanced;
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
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
#if not CLEAN19
        if IntrastatSetup.Get() then;
#endif
    end;

    var
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        Tariffnumber: Record "Tariff Number";
        ErrorMessage: Record "Error Message";
#if not CLEAN19
        IntrastatSetup: Record "Intrastat Setup";
#endif
        ApplicationSystemConstants: Codeunit "Application System Constants";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        NoOfRecords: Integer;
        NoOfRecordsRTC: Integer;
        PrintJnlLines: Boolean;
        Heading: Boolean;
        HeaderText: Text[80];
        Errorcounter: Integer;
        Errortext: array[99] of Text[250];
        TariffnumberExists: Boolean;
        CountryExists: Boolean;
        NoOfDetails: Integer;
        ReportingCurr: Code[10];
        TypeGroup: Option;
        CRCodeGroup: Code[10];
        TariffNoGroup: Code[10];
        TransactionTypeGroup: Code[10];
        TransportMethodGroup: Code[10];
        TransactionSpecificationGroup: Code[10];
        AreaGroup: Code[10];

        Text11300: Label '%1 must be specified.';
        Text11301: Label 'Tariff Number %1 does not exist.';
        Text11302: Label '%1 must be more than 0.';
        Text11303: Label '%1 must be %2.';
        Text11304: Label '%1 must not be 0.';
        Text11305: Label 'Intrastat Code must be specified for Country/Region %1.';
        Text11306: Label 'Report for internal use only, must not be used as an official statement';
        Text11307: Label 'Country/Region %1 does not exist.';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1.';
        IntrastatChecklistCaptionLbl: Label 'Intrastat - Checklist';
        PageCaptionLbl: Label 'Page';
        EnterpriseNoCaptionLbl: Label 'Enterprise No.';
        TariffNoCaptionLbl: Label 'Tariff No.';
        CountryRegionCodeCaptionLbl: Label 'Country/Region Code';
        TransTypeCaptionLbl: Label 'Transaction Type';
        TransportMethodCaptionLbl: Label 'Transport Method';
        TotalCaptionLbl: Label 'Total';
        NoOfEntriesCaptionLbl: Label 'No. of Entries';
        WarningTextCaptionLbl: Label 'Warning!';

    local procedure AddError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; FieldNo: Integer; Text: Text[250])
    begin
        Errorcounter := Errorcounter + 1;
        Errortext[Errorcounter] := Text;

        ErrorMessage.LogMessage(IntrastatJnlLine, FieldNo, ErrorMessage."Message Type"::Error, Text);
    end;
}

