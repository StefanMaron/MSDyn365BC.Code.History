namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

page 159 "Receivables-Payables"
{
    ApplicationArea = Suite;
    Caption = 'Receivables-Payables';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "General Ledger Setup";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::"Accounting Period" then
                            PeriodPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid();
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate();
                    end;
                }
            }
            part(ReceivPayablesLines; "Receivables-Payables Lines")
            {
                ApplicationArea = Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm();
    end;

    var
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    local procedure UpdateSubForm()
    begin
        CurrPage.ReceivPayablesLines.PAGE.SetLines(Rec, PeriodType, AmountType);
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure PeriodPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush();
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush();
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
    end;

    local procedure PeriodPeriodTypeOnValidate()
    begin
        PeriodPeriodTypeOnPush();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
    end;
}

