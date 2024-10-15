// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
// using Microsoft.Foundation.Enums;
using Microsoft.Finance.VAT.Calculation;

report 12 "VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "VAT Statement Name";

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            PrintOnlyIfDetail = true;
            column(StmtTmplName_VATStmtName; "Statement Template Name")
            {
            }
            column(Name_VATStmtName; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));
                RequestFilterFields = "Row No.";
                column(Heading; Heading)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Heading2; Heading2)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(AllAmountsAreIn; AllAmountsAreInLbl)
                {
                }
                column(VATStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(VATStmtLineDesc_VATStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(Selection; Selection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(StmtName_VATStmtLine; "Statement Name")
                {
                }
                column(VATStatementCaption; VATStatementCaptionLbl)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, 0);

                    if "Round Factor" = "Round Factor"::"1" then
                        if (Abs(TotalAmount) mod 1) <= 0.5 then
                            TotalAmount := Round(TotalAmount, 1, '<')
                        else
                            TotalAmount := Round(TotalAmount, 1, '>');

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
            begin
                GLSetup.Get();
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
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the start date for the time interval for VAT statement lines in the report.';

                            trigger OnValidate()
                            begin
                                if StartDate <> 0D then
                                    VATPeriod := '';
                            end;
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT statement lines in the report.';

                            trigger OnValidate()
                            begin
                                if EndDateReq <> 0D then
                                    VATPeriod := '';
                            end;
                        }
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';

                        trigger OnValidate()
                        begin
                            if Selection in [Selection::"Open and Closed", Selection::Open] then
                                VATPeriod := '';
                        end;
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';

                        trigger OnValidate()
                        begin
                            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                                VATPeriod := '';
                        end;
                    }
                    field(VatPeriod; VATPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vat Period';
                        Importance = Additional;
                        LookupPageID = "Periodic VAT Settlement List";
                        TableRelation = "Periodic Settlement VAT Entry";
                        ToolTip = 'Specifies the period of time that defines the VAT period.';

                        trigger OnValidate()
                        begin
                            if VATPeriod <> '' then begin
                                Selection := Selection::Closed;
                                PeriodSelection := PeriodSelection::"Within Period";
                                StartDate := 0D;
                                EndDateReq := 0D;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodSelection := PeriodSelection::"Within Period";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
        VATStmtLine.SetRange("Date Filter", StartDate, EndDateReq);
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text000
        else
            Heading := Text004;
        Heading2 := StrSubstNo(Text005, StartDate, EndDateReq);
        VATStmtLineFilter := VATStmtLine.GetFilters();
        if Selection = Selection::Closed then
            Heading := 'VAT Period : ' + VATPeriod
    end;

    var
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Amount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Heading2: Text[50];
        PeriodicSettlVATEntry: Record "Periodic Settlement VAT Entry";
        VATPeriod: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'VAT entries before and within the period';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2';
#pragma warning restore AA0470
#pragma warning restore AA0074        
        AllAmountsAreInLbl: Label 'All amounts are in';
        VATStatementCaptionLbl: Label 'VAT Statement';
        TotalAmountCaptionLbl: Label 'Amount';

    protected var
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        HeaderText: Text[50];
        PrintInIntegers: Boolean;
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        Selection: Enum "VAT Statement Report Selection";
        TotalAmount: Decimal;
        UseAmtsInAddCurr: Boolean;
        CountryRegionFilter: Text[250];

    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        if Level = 0 then
            TotalAmount := 0;
        Amount := 0;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLAcc.SetRange("Date Filter", StartDate, EndDate);
                    OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(GLAcc, VATStmtLine2);
                    Amount := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAcc."Net Change", GLAcc."Additional-Currency Net Change");
                        until GLAcc.Next() = 0;
                    OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    Amount := 0;
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                          "Tax Jurisdiction Code", "Use Tax", "Tax Liable", "VAT Period", "Operation Occurred Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if GLSetup."Use Activity Code" then
                        VATEntry.SetFilter("Activity Code", "VAT Statement Line".GetFilter("Activity Code Filter"));
                    if (EndDateReq = 0D) and (StartDate = 0D) then
                        VATEntry.SetRange("Operation Occurred Date")
                    else
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Operation Occurred Date", 0D, EndDate)
                        else
                            VATEntry.SetRange("Operation Occurred Date", StartDate, EndDate);

                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            begin
                                VATEntry.SetRange(Closed, true);
                                if VATPeriod <> '' then begin
                                    VATEntry.SetRange("VAT Period", VATPeriod);
                                    VATEntry.SetRange("Operation Occurred Date");
                                end;
                            end;
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if CountryRegionFilter <> '' then
                        VATEntry.SetFilter("Country/Region Code", CountryRegionFilter);
                    OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine2, VATEntry, Selection);
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Nondeductible Base", "Additional-Currency Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Nondeductible Base",
                                    VATEntry."Additional-Currency Base" + VATEntry."Add. Curr. Nondeductible Base");
                            end;
                        VATStmtLine2."Amount Type"::"Full Amount":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums(
                                    Amount, "Additional-Currency Amount", "Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount :=
                                    ConditionalAdd(0, VATEntry.Amount + VATEntry."Non-Deductible VAT Amount", VATEntry."Additional-Currency Amount" + VATEntry."Non-Deductible VAT Amount ACY");
                            end else begin
                                VATEntry.CalcSums(
                                    Amount, "Additional-Currency Amount", "Nondeductible Amount", "Add. Curr. Nondeductible Amt.");
                                Amount :=
                                    ConditionalAdd(0, VATEntry.Amount + VATEntry."Nondeductible Amount", VATEntry."Additional-Currency Amount" + VATEntry."Add. Curr. Nondeductible Amt.");
                            end;
                        VATStmtLine2."Amount Type"::"Full Base":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Non-Deductible VAT Base", VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
                            end else begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Nondeductible Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Nondeductible Base", VATEntry."Additional-Currency Base" + VATEntry."Add. Curr. Nondeductible Base");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Amount":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums("Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount ACY");
                            end else begin
                                VATEntry.CalcSums("Nondeductible Amount", "Add. Curr. Nondeductible Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Nondeductible Amount", VATEntry."Add. Curr. Nondeductible Amt.");
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Base":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end else begin
                                VATEntry.CalcSums("Nondeductible Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry."Nondeductible Base", VATEntry."Add. Curr. Nondeductible Base");
                            end;
                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
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
                        until VATStmtLine2.Next() = 0;
                end;
            VATStmtLine2.Type::Description:
                ;

            VATStmtLine2.Type::"Periodic VAT Settl.":    // IT
                begin
                    case Selection of
                        Selection::Open:
                            begin
                                PeriodicSettlVATEntry.Reset();
                                PeriodicSettlVATEntry.SetCurrentKey("VAT Period Closed");
                                PeriodicSettlVATEntry.SetRange("VAT Period Closed", false);
                            end;
                        Selection::Closed:
                            begin
                                PeriodicSettlVATEntry.Reset();
                                PeriodicSettlVATEntry.SetRange("VAT Period", VATPeriod);
                            end;
                    end;

                    case VATStmtLine2."Gen. Posting Type" of
                        VATStmtLine2."Gen. Posting Type"::"Prior Period Input VAT":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Prior Period Input VAT", "Add Curr. Prior Per. Inp. VAT");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Prior Period Input VAT", PeriodicSettlVATEntry."Add Curr. Prior Per. Inp. VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Prior Period Output VAT":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Prior Period Output VAT", "Add Curr. Prior Per. Out VAT");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Prior Period Output VAT", PeriodicSettlVATEntry."Add Curr. Prior Per. Out VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::Paid:
                            begin
                                PeriodicSettlVATEntry.CalcSums("Paid Amount", "Add-Curr. Paid. Amount");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Paid Amount", PeriodicSettlVATEntry."Add-Curr. Paid. Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::Advanced:
                            begin
                                PeriodicSettlVATEntry.CalcSums("Advanced Amount", "Add-Curr. Advanced Amount");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Advanced Amount", PeriodicSettlVATEntry."Add-Curr. Advanced Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Credit VAT Compens.":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Credit VAT Compensation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Credit VAT Compensation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Payab. VAT Variation":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Payable VAT Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Payable VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Deduc. VAT Variation.":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Deductible VAT Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Deductible VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Tax Debit Variat.":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Tax Debit Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Debit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Tax Credit Variation":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Tax Credit Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Credit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Tax Deb. Variat. Int.":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Tax Debit Variation Interest");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Debit Variation Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Unpaid VAT Prev. Periods":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Unpaid VAT Previous Periods");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Unpaid VAT Previous Periods", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Omit Payable Int.":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Omit VAT Payable Interest");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Omit VAT Payable Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        VATStmtLine2."Gen. Posting Type"::"Special Credit":
                            begin
                                PeriodicSettlVATEntry.CalcSums("Special Credit");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Special Credit", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
                        else
                            Amount := 0;

                    end;
                end;
            else
                OnCalcLineTotalWithBaseOnCaseElse(VATStmtLine2, Amount, TotalAmount, Level, PeriodSelection, StartDate, EndDate, EndDateReq, PrintInIntegers, UseAmtsInAddCurr);
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := Round(Amount, 1, '<');
        TotalAmount := TotalAmount + Amount;
    end;

    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10])
    begin
        InitializeRequest(NewVATStmtName, NewVATStatementLine, NewSelection, NewPeriodSelection, NewPrintInIntegers, NewUseAmtsInAddCurr, NewVATPeriod, '');
    end;

    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10]; NewCountryRegionFilter: Text[250])
    begin
        "VAT Statement Name".Copy(NewVATStmtName);
        "VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
            StartDate := NewVATStatementLine.GetRangeMin("Date Filter");
            EndDateReq := NewVATStatementLine.GetRangeMax("Date Filter");
            EndDate := EndDateReq;
        end else begin
            StartDate := 0D;
            EndDateReq := 0D;
            EndDate := DMY2Date(31, 12, 9999);
        end;
        CountryRegionFilter := NewCountryRegionFilter;
        VATPeriod := NewVATPeriod;
    end;

    local procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);

        exit(Amount + AmountToAdd);
    end;

    protected procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; Selection: Enum "VAT Statement Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalWithBaseOnCaseElse(var VATStmtLine2: Record "VAT Statement Line"; var Amount: Decimal; var TotalAmount: Decimal; Level: Integer; PeriodSelection: Enum "VAT Statement Report Period Selection"; StartDate: Date; EndDate: Date; EndDateReq: Date; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(var GLAccount: Record "G/L Account"; VATStatementLine2: Record "VAT Statement Line")
    begin
    end;
}

