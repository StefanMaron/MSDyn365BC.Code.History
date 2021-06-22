page 867 "CF Availability by Periods"
{
    Caption = 'CF Availability by Periods';
    InsertAllowed = false;
    PageType = ListPlus;
    SaveValues = true;
    SourceTable = "Cash Flow Forecast";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Manual Payments From"; "Manual Payments From")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a starting date from which manual payments should be included in cash flow forecast.';
                }
                field("Manual Payments To"; "Manual Payments To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To';
                    Editable = false;
                    ToolTip = 'Specifies a starting date to which manual payments should be included in cash flow forecast.';
                }
                field(LiquidFunds; LiquidFunds)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = MatrixMgt.GetFormatString(RoundingFactor, false);
                    AutoFormatType = 11;
                    Caption = 'Liquid Funds';
                    Editable = false;
                    ToolTip = 'Specifies if the cash flow forecast must include liquid funds in the general ledger.';

                    trigger OnDrillDown()
                    begin
                        DrillDownEntriesFromSource("Source Type Filter"::"Liquid Funds");
                    end;
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date that the forecast was created.';
                }
                field(RoundingFactor; RoundingFactor)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rounding Factor';
                    OptionCaption = 'None,1,1000,1000000';
                    ToolTip = 'Specifies the factor that is used to round the amounts.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm;
                    end;
                }
            }
            part(CFAvailabLines; "Cash Flow Availability Lines")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm;
    end;

    var
        MatrixMgt: Codeunit "Matrix Management";
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
        RoundingFactor: Option "None","1","1000","1000000";
        LiquidFunds: Decimal;

    local procedure UpdateSubForm()
    begin
        CurrPage.CFAvailabLines.PAGE.Set(Rec, PeriodType, AmountType, RoundingFactor);
        LiquidFunds := MatrixMgt.RoundValue(CalcAmountFromSource("Source Type Filter"::"Liquid Funds"), RoundingFactor);
    end;
}

