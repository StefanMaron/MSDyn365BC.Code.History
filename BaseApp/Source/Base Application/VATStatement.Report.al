report 12 "VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = SORTING("Statement Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Statement Template Name", Name;
            column(StmtName1_VatStmtName; "Statement Template Name")
            {
            }
            column(Name1_VatStmtName; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = FIELD("Statement Template Name"), "Statement Name" = FIELD(Name);
                DataItemTableView = SORTING("Statement Template Name", "Statement Name") WHERE(Print = CONST(true));
                RequestFilterFields = "Row No.";
                column(Heading; Heading)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(StmtName_VatStmtName; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(Name_VatStmtName; "VAT Statement Name".Name)
                {
                }
                column(Heading2; Heading2)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(GlSetupLCYCode; GLSetup."LCY Code")
                {
                }
                column(Allamountsarein; AllamountsareinLbl)
                {
                }
                column(TxtGLSetupAddnalReportCur; StrSubstNo(Text003, GLSetup."Additional Reporting Currency"))
                {
                }
                column(GLSetupAddRepCurrency; GLSetup."Additional Reporting Currency")
                {
                }
                column(VatStmLineTableCaptFilter; TableCaption + ': ' + VATStmtLineFilter)
                {
                }
                column(VatStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(VatStmtLineRowNo; "Row No.")
                {
                    IncludeCaption = true;
                }
                column(Description_VatStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency;
                    AutoFormatType = 1;
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(Selection; Selection)
                {
                }
                column(PeriodSelection; PeriodSelection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(VATStmtCaption; VATStmtCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(VATStmtTemplateCaption; VATStmtTemplateCaptionLbl)
                {
                }
                column(VATStmtNameCaption; VATStmtNameCaptionLbl)
                {
                }
                column(AmtsareinwholeLCYsCaption; AmtsareinwholeLCYsCaptionLbl)
                {
                }
                column(ReportinclallVATentriesCaption; ReportinclallVATentriesCaptionLbl)
                {
                }
                column(RepinclonlyclosedVATentCaption; RepinclonlyclosedVATentCaptionLbl)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, 0);
                    if PrintInIntegers then
                        // NAVCZ
                        TotalAmount := RoundAmount(TotalAmount);
                    case Show of
                        Show::"Zero If Negative":
                            if TotalAmount < 0 then
                                TotalAmount := 0;
                        Show::"Zero If Positive":
                            if TotalAmount > 0 then
                                TotalAmount := 0;
                    end;
                    // NAVCZ
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;
                    PageGroupNo := NextPageGroupNo;
                    if "New Page" then
                        NextPageGroupNo := PageGroupNo + 1;
                end;

                trigger OnPreDataItem()
                begin
                    PageGroupNo := 1;
                    NextPageGroupNo := 1;
                end;
            }

            trigger OnPreDataItem()
            var
                RegistrationCountryRegion: Record "Registration Country/Region";
            begin
                GLSetup.Get();
                // NAVCZ
                if PerfCountryCodeFilter <> '' then
                    if RegistrationCountryRegion.Get(RegistrationCountryRegion."Account Type"::"Company Information", '', PerfCountryCodeFilter) then
                        GLSetup."LCY Code" := RegistrationCountryRegion."Currency Code (Local)";
                // NAVCZ
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
                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(StartingDate; StartDate2)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the start date for the time interval for VAT statement lines in the report.';
                        }
                        field(EndingDate; EndDateReq2)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT statement lines in the report.';
                        }
                    }
                    group("Date Row Filter Period")
                    {
                        Caption = 'Date Row Filter Period';
                        field(StartDate1; StartDate1)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the starting date';
                        }
                        field(EndDateReq1; EndDateReq1)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the last date in the period.';
                        }
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        OptionCaption = 'Open,Closed,Open and Closed';
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        OptionCaption = 'Before and Within Period,Within Period';
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(RoundToWholeNumbers; PrintInIntegers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to Whole Numbers';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the amounts in the report to be rounded to whole numbers.';

                        trigger OnValidate()
                        begin
                            // NAVCZ
                            RoundingDirectionCtrlVisible := PrintInIntegers;
                        end;
                    }
                    group(Control1220006)
                    {
                        ShowCaption = false;
                        Visible = RoundingDirectionCtrlVisible;
                        field(RoundingDirectionCtrl; RoundingDirection)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rounding Direction';
                            OptionCaption = 'Nearest,Down,Up';
                            ToolTip = 'Specifies rounding direction of the vat statement';
                        }
                    }
                    field(PerfCountryCodeFilter; PerfCountryCodeFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Performance Country';
                        TableRelation = "Country/Region";
                        ToolTip = 'Specifies performance country code for VAT entries filtr.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
                        ObsoleteTag = '15.3';
                    }
                    field(ShowAmtInAddCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        Importance = Additional;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
                    }
                    field(SettlementNoFilter; SettlementNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Filter VAT Settlement No.';
                        ToolTip = 'Specifies the filter setup of document number which the VAT entries were closed.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // NAVCZ
            RoundingDirectionCtrlVisible := PrintInIntegers;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        // NAVCZ
        if EndDateReq2 = 0D then
            EndDate2 := DMY2Date(31, 12, 9999)
        else
            EndDate2 := EndDateReq2;
        VATStmtLine.SetRange("Date Filter", StartDate2, EndDateReq2);
        if EndDateReq1 = 0D then
            EndDate1 := DMY2Date(31, 12, 9999)
        else
            EndDate1 := EndDateReq1;
        VATStmtLine.SetRange("Date Row Filter", StartDate1, EndDateReq1);
        // NAVCZ
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text000
        else
            Heading := Text004;
        Heading2 := StrSubstNo(Text005, StartDate2, EndDateReq2); // NAVCZ
        VATStmtLineFilter := VATStmtLine.GetFilters;
        // NAVCZ
        if PerfCountryCodeFilter <> '' then
            Heading2 := Heading2 + ',' + VATEntry.FieldCaption("Perform. Country/Region Code") + ':' + PerfCountryCodeFilter;
        if SettlementNoFilter <> '' then
            Heading2 := Heading2 + ',' + VATEntry.FieldCaption("VAT Settlement No.") + ':' + SettlementNoFilter;
        // NAVCZ
    end;

    var
        Text000: Label 'VAT entries before and within the period';
        Text003: Label 'Amounts are in %1, rounded without decimals.';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2';
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        PerfCountryCurrExchRate: Record "Perf. Country Curr. Exch. Rate";
        VATEntry2: Record "VAT Entry";
        VATStmtLine: Record "VAT Statement Line";
        Selection: Option Open,Closed,"Open and Closed";
        PeriodSelection: Option "Before and Within Period","Within Period";
        PrintInIntegers: Boolean;
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Amount: Decimal;
        TotalAmount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[50];
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        Heading2: Text;
        AllamountsareinLbl: Label 'All amounts are in';
        VATStmtCaptionLbl: Label 'VAT Statement';
        CurrReportPageNoCaptionLbl: Label 'Page';
        VATStmtTemplateCaptionLbl: Label 'VAT Statement Template';
        VATStmtNameCaptionLbl: Label 'VAT Statement Name';
        AmtsareinwholeLCYsCaptionLbl: Label 'Amounts are in whole LCYs.';
        ReportinclallVATentriesCaptionLbl: Label 'The report includes all VAT entries.';
        RepinclonlyclosedVATentCaptionLbl: Label 'The report includes only closed VAT entries.';
        TotalAmountCaptionLbl: Label 'Amount';
        RoundingDirection: Option Nearest,Down,Up;
        EndDate1: Date;
        StartDate1: Date;
        EndDateReq1: Date;
        EndDate2: Date;
        StartDate2: Date;
        EndDateReq2: Date;
        [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this variable should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
        PerfCountryCodeFilter: Code[10];
        SettlementNoFilter: Text[50];
        Amount2: Decimal;
        CallLevel: Integer;
        DivisionError: Boolean;
        Text020: Label 'Formula cannot be calculated due to circular references.';
        Text013: Label 'Dividing by zero is not possible.';
        Text012: Label 'You have entered an invalid value or a nonexistent row number.';
        [InDataSet]
        RoundingDirectionCtrlVisible: Boolean;

    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    var
        SalesTax: Boolean;
        StartingDate: Date;
    begin
        // NAVCZ
        if VATStmtLine2."Use Row Date Filter" and (StartDate1 <> 0D) and (EndDateReq1 <> 0D) then begin
            EndDateReq := EndDateReq1;
            StartDate := StartDate1;
            EndDate := EndDate1;
        end else begin
            EndDateReq := EndDateReq2;
            StartDate := StartDate2;
            EndDate := EndDate2;
        end;
        // NAVCZ
        if Level = 0 then
            TotalAmount := 0;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLAcc.SetRange("Date Filter", StartDate, EndDate);
                    Amount := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            // NAVCZ
                            case VATStmtLine2."G/L Amount Type" of
                                VATStmtLine2."G/L Amount Type"::"Net Change":
                                    begin
                                        GLAcc.CalcFields("Net Change (VAT Date)", "Net Change ACY (VAT Date)");
                                        Amount := ConditionalAdd(Amount, GLAcc."Net Change (VAT Date)", GLAcc."Net Change ACY (VAT Date)");
                                    end;
                                VATStmtLine2."G/L Amount Type"::Debit:
                                    begin
                                        GLAcc.CalcFields("Debit Amount (VAT Date)", "Debit Amount ACY (VAT Date)");
                                        Amount := ConditionalAdd(Amount, GLAcc."Debit Amount (VAT Date)", GLAcc."Debit Amount ACY (VAT Date)");
                                    end;
                                VATStmtLine2."G/L Amount Type"::Credit:
                                    begin
                                        GLAcc.CalcFields("Credit Amount (VAT Date)", "Credit Amount ACY (VAT Date)");
                                        Amount := ConditionalAdd(Amount, GLAcc."Credit Amount (VAT Date)", GLAcc."Credit Amount ACY (VAT Date)");
                                    end;
                            end;
                        // NAVCZ
                        until GLAcc.Next = 0;
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                         "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "EU 3-Party Trade", "EU 3-Party Intermediate Role",
                         "VAT Date") // NAVCZ
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                        // NAVCZ
                        if VATStmtLine2."Gen. Bus. Posting Group" <> '' then
                            VATEntry.SetRange("Gen. Bus. Posting Group", VATStmtLine2."Gen. Bus. Posting Group");
                        if VATStmtLine2."Gen. Prod. Posting Group" <> '' then
                            VATEntry.SetRange("Gen. Prod. Posting Group", VATStmtLine2."Gen. Prod. Posting Group");
                        case VATStmtLine2."EU-3 Party Trade" of
                            VATStmtLine2."EU-3 Party Trade"::Yes:
                                VATEntry.SetRange("EU 3-Party Trade", true);
                            VATStmtLine2."EU-3 Party Trade"::No:
                                VATEntry.SetRange("EU 3-Party Trade", false);
                        end;
                        case VATStmtLine2."EU 3-Party Intermediate Role" of
                            VATStmtLine2."EU 3-Party Intermediate Role"::Yes:
                                VATEntry.SetRange("EU 3-Party Intermediate Role", true);
                            VATStmtLine2."EU 3-Party Intermediate Role"::No:
                                VATEntry.SetRange("EU 3-Party Intermediate Role", false);
                        end;
                        // NAVCZ
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                        SalesTax := true; // NAVCZ
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if (EndDateReq <> 0D) or (StartDate <> 0D) then
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            // NAVCZ
                            StartingDate := 0D
                        else
                            StartingDate := StartDate;
                    if SalesTax then
                        VATEntry.SetRange("Posting Date", StartingDate, EndDate)
                    else
                        VATEntry.SetRange("VAT Date", StartingDate, EndDate);

                    if SettlementNoFilter <> '' then
                        VATEntry.SetFilter("VAT Settlement No.", SettlementNoFilter);
                    // NAVCZ

                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    // NAVCZ
                    case VATStmtLine2."Prepayment Type" of
                        VATStmtLine2."Prepayment Type"::"Not Prepayment":
                            VATEntry.SetRange("Prepayment Type", VATEntry."Prepayment Type"::" ");
                        VATStmtLine2."Prepayment Type"::Prepayment:
                            VATEntry.SetRange("Prepayment Type", VATEntry."Prepayment Type"::Prepayment);
                        VATStmtLine2."Prepayment Type"::Advance:
                            VATEntry.SetRange("Prepayment Type", VATEntry."Prepayment Type"::Advance);
                        else
                            VATEntry.SetRange("Prepayment Type");
                    end;

                    if PerfCountryCodeFilter <> '' then
                        VATEntry.SetRange("Perform. Country/Region Code", PerfCountryCodeFilter)
                    else
                        VATEntry.SetRange("Perform. Country/Region Code", '');

                    VATEntry2.Reset();
                    VATEntry2.CopyFilters(VATEntry);
                    Amount := 0;
                    // NAVCZ
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                // NAVCZ
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2.Amount, VATEntry2."Additional-Currency Amount");
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    // NAVCZ
                                    Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base");
                                // NAVCZ
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2.Base, VATEntry2."Additional-Currency Base");
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    // NAVCZ
                                    Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                            end;
                        // NAVCZ
                        VATStmtLine2."Amount Type"::"Adv. Base":
                            begin
                                VATEntry.CalcSums("Advance Base", "Additional-Currency Base");
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2."Advance Base", VATEntry2."Additional-Currency Base");
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    Amount := ConditionalAdd(0, VATEntry."Advance Base", VATEntry."Additional-Currency Base");
                            end;
                        // NAVCZ
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                // NAVCZ
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(
                                                0, VATEntry2."Remaining Unrealized Amount", VATEntry2."Add.-Curr. Rem. Unreal. Amount");
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    // NAVCZ
                                    Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                // NAVCZ
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2."Remaining Unrealized Base", VATEntry2."Add.-Curr. Rem. Unreal. Base");
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    // NAVCZ
                                    Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                            end;
                        // NAVCZ
                        VATStmtLine2."Amount Type"::"VAT Amount (Non Deductible)":
                            begin
                                VATEntry.CalcSums("VAT Amount (Non Deductible)");
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2."VAT Amount (Non Deductible)", 0);
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    Amount := ConditionalAdd(0, VATEntry."VAT Amount (Non Deductible)", 0);
                            end;
                        VATStmtLine2."Amount Type"::"VAT Base (Non Deductible)":
                            begin
                                VATEntry.CalcSums("VAT Base (Non Deductible)");
                                if PerfCountryCodeFilter <> '' then
                                    if VATEntry2.FindSet(false, false) then
                                        repeat
                                            Amount2 := ConditionalAdd(0, VATEntry2."VAT Base (Non Deductible)", 0);
                                            Amount := Amount + ExchangeAmount(Amount2);
                                        until VATEntry2.Next = 0;
                                if PerfCountryCodeFilter = '' then
                                    Amount := ConditionalAdd(0, VATEntry."VAT Base (Non Deductible)", 0);
                            end;
                    // NAVCZ
                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.Find('-') then
                        repeat
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next = 0;
                end;
            VATStmtLine2.Type::Description:
                ;
            // NAVCZ
            VATStmtLine2.Type::Formula:
                begin
                    Amount := EvaluateExpression(true, VATStmtLine2."Row Totaling", VATStmtLine2, true);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
        // NAVCZ
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := RoundAmount(Amount); // NAVCZ
        TotalAmount := TotalAmount + Amount;
    end;

    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Option Open,Closed,"Open and Closed"; NewPeriodSelection: Option "Before and Within Period","Within Period"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; SettlementNoFilter2: Text[50]; PerfCountryCodeFilter2: Code[10])
    begin
        "VAT Statement Name".Copy(NewVATStmtName);
        "VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        // NAVCZ
        if NewVATStatementLine.GetFilter("Date Row Filter") <> '' then begin
            StartDate1 := NewVATStatementLine.GetRangeMin("Date Row Filter");
            EndDateReq1 := NewVATStatementLine.GetRangeMax("Date Row Filter");
            EndDate1 := EndDateReq1;
        end else
            if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
                StartDate1 := NewVATStatementLine.GetRangeMin("Date Filter");
                EndDateReq1 := NewVATStatementLine.GetRangeMax("Date Filter");
                EndDate1 := EndDateReq1;
            end else begin
                StartDate1 := 0D;
                EndDateReq1 := 0D;
                EndDate1 := DMY2Date(31, 12, 9999);
            end;
        if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
            StartDate2 := NewVATStatementLine.GetRangeMin("Date Filter");
            EndDateReq2 := NewVATStatementLine.GetRangeMax("Date Filter");
            EndDate2 := EndDateReq2;
        end else begin
            StartDate2 := 0D;
            EndDateReq2 := 0D;
            EndDate2 := DMY2Date(31, 12, 9999);
        end;
        SettlementNoFilter := SettlementNoFilter2;
        PerfCountryCodeFilter := PerfCountryCodeFilter2;
        // NAVCZ
    end;

    local procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);

        exit(Amount + AmountToAdd);
    end;

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    [Scope('OnPrem')]
    procedure SetRoundingDirection(NewRoundingDirection: Option)
    begin
        // NAVCZ
        RoundingDirection := NewRoundingDirection;
    end;

    [Scope('OnPrem')]
    procedure RoundAmount(Amount3: Decimal): Decimal
    var
        RoundDirParameter: Text[1];
    begin
        // NAVCZ
        case RoundingDirection of
            RoundingDirection::Nearest:
                RoundDirParameter := '=';
            RoundingDirection::Up:
                RoundDirParameter := '>';
            RoundingDirection::Down:
                RoundDirParameter := '<';
        end;
        exit(Round(Amount3, 1, RoundDirParameter));
    end;

    local procedure EvaluateExpression(IsVATStmtLineExpression: Boolean; Expression: Text[80]; VATStmtLine: Record "VAT Statement Line"; CalcAddCurr: Boolean): Decimal
    var
        Result: Decimal;
        Parantheses: Integer;
        Operator: Char;
        LeftOperand: Text[80];
        RightOperand: Text[80];
        LeftResult: Decimal;
        RightResult: Decimal;
        i: Integer;
        IsExpression: Boolean;
        IsFilter: Boolean;
        Operators: Text[8];
        OperatorNo: Integer;
        VATStmtLineID: Integer;
        LineTotalAmount: Decimal;
    begin
        // NAVCZ
        Result := 0;

        CallLevel := CallLevel + 1;
        if CallLevel > 25 then
            Error(Text020);

        Expression := DelChr(Expression, '<>', '');
        if StrLen(Expression) > 0 then begin
            Parantheses := 0;
            IsExpression := false;
            Operators := '+-*/^';
            OperatorNo := 1;
            repeat
                i := StrLen(Expression);
                repeat
                    if Expression[i] = '(' then
                        Parantheses := Parantheses + 1
                    else
                        if Expression[i] = ')' then
                            Parantheses := Parantheses - 1;
                    if (Parantheses = 0) and (Expression[i] = Operators[OperatorNo]) then
                        IsExpression := true
                    else
                        i := i - 1;
                until IsExpression or (i <= 0);
                if not IsExpression then
                    OperatorNo := OperatorNo + 1;
            until (OperatorNo > StrLen(Operators)) or IsExpression;
            if IsExpression then begin
                if i > 1 then
                    LeftOperand := CopyStr(Expression, 1, i - 1)
                else
                    LeftOperand := '';
                if i < StrLen(Expression) then
                    RightOperand := CopyStr(Expression, i + 1)
                else
                    RightOperand := '';
                Operator := Expression[i];
                LeftResult :=
                  EvaluateExpression(
                    IsVATStmtLineExpression, LeftOperand, VATStmtLine, CalcAddCurr);
                RightResult :=
                  EvaluateExpression(
                    IsVATStmtLineExpression, RightOperand, VATStmtLine, CalcAddCurr);
                case Operator of
                    '^':
                        Result := Power(LeftResult, RightResult);
                    '*':
                        Result := LeftResult * RightResult;
                    '/':
                        if RightResult = 0 then begin
                            Result := 0;
                            DivisionError := true;
                            if DivisionError then
                                Error(Text013);
                        end else
                            Result := LeftResult / RightResult;
                    '+':
                        Result := LeftResult + RightResult;
                    '-':
                        Result := LeftResult - RightResult;
                end;
            end else
                if (Expression[1] = '(') and (Expression[StrLen(Expression)] = ')') then
                    Result :=
                      EvaluateExpression(
                        IsVATStmtLineExpression, CopyStr(Expression, 2, StrLen(Expression) - 2),
                        VATStmtLine, CalcAddCurr)
                else begin
                    IsFilter :=
                      (StrPos(Expression, '..') +
                       StrPos(Expression, '|') +
                       StrPos(Expression, '<') +
                       StrPos(Expression, '>') +
                       StrPos(Expression, '&') +
                       StrPos(Expression, '=') > 0);
                    if (StrLen(Expression) > 10) and (not IsFilter) then
                        Evaluate(Result, Expression)
                    else
                        if IsVATStmtLineExpression then begin
                            VATStmtLine.SetRange("Statement Template Name", VATStmtLine."Statement Template Name");
                            VATStmtLine.SetRange("Statement Name", VATStmtLine."Statement Name");
                            VATStmtLine.SetFilter("Row No.", Expression);

                            VATStmtLineID := VATStmtLine."Line No.";
                            if VATStmtLine.Find('-') then
                                repeat
                                    if VATStmtLine."Line No." <> VATStmtLineID then begin
                                        CalcLineTotal(VATStmtLine, LineTotalAmount, 0);
                                        Result := Result + LineTotalAmount;
                                    end
                                until VATStmtLine.Next = 0
                            else
                                if IsFilter or (not Evaluate(Result, Expression)) then
                                    Error(Text012);
                        end
                end;
        end;
        CallLevel := CallLevel - 1;
        exit(Result);
    end;

    [Scope('OnPrem')]
    [Obsolete('The functionality of VAT Registration in Other Countries will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)','15.3')]
    procedure ExchangeAmount(AmountAdd: Decimal): Decimal
    begin
        // NAVCZ
        with VATEntry2 do
            exit(PerfCountryCurrExchRate.ExchangeAmount(
                "Posting Date", "Perform. Country/Region Code", "Currency Code", AmountAdd * "Currency Factor"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal)
    begin
    end;
}

