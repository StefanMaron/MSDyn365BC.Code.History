page 106 "Exchange Rate Adjmt. Register"
{
    ApplicationArea = Suite;
    Caption = 'Exchange Rate Adjustment Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Exch. Rate Adjmt. Reg.";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting date for the exchange rate adjustment register.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the account type that was adjusted for exchange rate fluctuations when you ran the Adjust Exchange Rates batch job.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting group of the exchange rate adjustment register on this line.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the code for the currency whose exchange rate was adjusted.';
                }
                field("Adjusted Base"; "Adjusted Base")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that was adjusted by the batch job for customer, vendor and/or bank ledger entries.';
                }
                field("Adjusted Base (LCY)"; "Adjusted Base (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount in LCY that was adjusted by the batch job for G/L, customer, vendor and/or bank ledger entries.';
                }
                field("Adjusted Amt. (LCY)"; "Adjusted Amt. (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount by which the batch job has adjusted G/L, customer, vendor and/or bank ledger entries for exchange rate fluctuations.';
                }
                field("Adjusted Base (Add.-Curr.)"; "Adjusted Base (Add.-Curr.)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional-reporting-currency amount the batch job has adjusted G/L, customer, and other entries for exchange rate fluctuations.';
                    Visible = false;
                }
                field("Adjusted Amt. (Add.-Curr.)"; "Adjusted Amt. (Add.-Curr.)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the additional-reporting-currency amount the batch job has adjusted G/L, customer, and other entries for exchange rate fluctuations.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

