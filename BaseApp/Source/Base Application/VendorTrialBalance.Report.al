report 329 "Vendor - Trial Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VendorTrialBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Trial Balance';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("Vendor Posting Group");
            RequestFilterFields = "No.", "Date Filter", "Vendor Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PeriodPeriodFilter; StrSubstNo(Text003, PeriodFilter))
            {
            }
            column(VendPostGrpGroupTotal; StrSubstNo(Text005, FieldCaption("Vendor Posting Group")))
            {
            }
            column(VendTblCapVendFilter; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PeriodStartDate; Format(PeriodStartDate))
            {
            }
            column(PeriodFilter; PeriodFilter)
            {
            }
            column(FiscalYearStartDate; Format(FiscalYearStartDate))
            {
            }
            column(FiscalYearFilter; FiscalYearFilter)
            {
            }
            column(PeriodEndDate; Format(PeriodEndDate))
            {
            }
            column(VendorPostingGroup_Vendor; "Vendor Posting Group")
            {
            }
            column(YTDTotal; YTDTotal)
            {
                AutoFormatType = 1;
            }
            column(YTDCreditAmt; YTDCreditAmt)
            {
                AutoFormatType = 1;
            }
            column(YTDDebitAmt; YTDDebitAmt)
            {
                AutoFormatType = 1;
            }
            column(YTDBeginBalance; YTDBeginBalance)
            {
            }
            column(PeriodCreditAmt; PeriodCreditAmt)
            {
            }
            column(PeriodDebitAmt; PeriodDebitAmt)
            {
            }
            column(PeriodBeginBalance; PeriodBeginBalance)
            {
            }
            column(Name_Vendor; Name)
            {
                IncludeCaption = true;
            }
            column(No_Vendor; "No.")
            {
                IncludeCaption = true;
            }
            column(TotForFrmtVendPostGrp; Text004 + Format(' ') + "Vendor Posting Group")
            {
            }
            column(VendTrialBalanceCap; VendTrialBalanceCapLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AmountsinLCYCaption; AmountsinLCYCaptionLbl)
            {
            }
            column(VendWithEntryPeriodCapt; VendWithEntryPeriodCaptLbl)
            {
            }
            column(PeriodBeginBalCap; PeriodBeginBalCapLbl)
            {
            }
            column(PeriodDebitAmtCaption; PeriodDebitAmtCaptionLbl)
            {
            }
            column(PeriodCreditAmtCaption; PeriodCreditAmtCaptionLbl)
            {
            }
            column(YTDTotalCaption; YTDTotalCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(FiscalYearToDateCaption; FiscalYearToDateCaptionLbl)
            {
            }
            column(NetChangeCaption; NetChangeCaptionLbl)
            {
            }
            column(TotalinLCYCaption; TotalinLCYCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcAmounts(
                  PeriodStartDate, PeriodEndDate,
                  PeriodBeginBalance, PeriodDebitAmt, PeriodCreditAmt, YTDTotal);

                CalcAmounts(
                  FiscalYearStartDate, PeriodEndDate,
                  YTDBeginBalance, YTDDebitAmt, YTDCreditAmt, YTDTotal);
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
        with Vendor do begin
            PeriodFilter := GetFilter("Date Filter");
            PeriodStartDate := GetRangeMin("Date Filter");
            PeriodEndDate := GetRangeMax("Date Filter");
            SetRange("Date Filter");
            VendFilter := GetFilters;
            SetRange("Date Filter", PeriodStartDate, PeriodEndDate);
            AccountingPeriod.SetRange("Starting Date", 0D, PeriodEndDate);
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if AccountingPeriod.FindLast then
                FiscalYearStartDate := AccountingPeriod."Starting Date"
            else
                Error(Text000, AccountingPeriod.FieldCaption("Starting Date"), AccountingPeriod.TableCaption);
            FiscalYearFilter := Format(FiscalYearStartDate) + '..' + Format(PeriodEndDate);
        end;
    end;

    var
        Text000: Label 'It was not possible to find a %1 in %2.';
        AccountingPeriod: Record "Accounting Period";
        PeriodBeginBalance: Decimal;
        PeriodDebitAmt: Decimal;
        PeriodCreditAmt: Decimal;
        YTDBeginBalance: Decimal;
        YTDDebitAmt: Decimal;
        YTDCreditAmt: Decimal;
        YTDTotal: Decimal;
        PeriodFilter: Text;
        FiscalYearFilter: Text;
        VendFilter: Text;
        PeriodStartDate: Date;
        PeriodEndDate: Date;
        FiscalYearStartDate: Date;
        Text003: Label 'Period: %1';
        Text004: Label 'Total for';
        Text005: Label 'Group Totals: %1';
        VendTrialBalanceCapLbl: Label 'Vendor - Trial Balance';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AmountsinLCYCaptionLbl: Label 'Amounts in LCY';
        VendWithEntryPeriodCaptLbl: Label 'Only includes vendors with entries in the period';
        PeriodBeginBalCapLbl: Label 'Beginning Balance';
        PeriodDebitAmtCaptionLbl: Label 'Debit';
        PeriodCreditAmtCaptionLbl: Label 'Credit';
        YTDTotalCaptionLbl: Label 'Ending Balance';
        PeriodCaptionLbl: Label 'Period';
        FiscalYearToDateCaptionLbl: Label 'Fiscal Year-To-Date';
        NetChangeCaptionLbl: Label 'Net Change';
        TotalinLCYCaptionLbl: Label 'Total in LCY';

    local procedure CalcAmounts(DateFrom: Date; DateTo: Date; var BeginBalance: Decimal; var DebitAmt: Decimal; var CreditAmt: Decimal; var TotalBalance: Decimal)
    var
        VendorCopy: Record Vendor;
    begin
        VendorCopy.Copy(Vendor);
        VendorCopy.SetRange("Date Filter", 0D, DateFrom - 1);
        VendorCopy.CalcFields("Net Change (LCY)");
        BeginBalance := -VendorCopy."Net Change (LCY)";

        VendorCopy.SetRange("Date Filter", DateFrom, DateTo);
        VendorCopy.CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
        DebitAmt := VendorCopy."Debit Amount (LCY)";
        CreditAmt := VendorCopy."Credit Amount (LCY)";

        TotalBalance := BeginBalance + DebitAmt - CreditAmt;
    end;
}

