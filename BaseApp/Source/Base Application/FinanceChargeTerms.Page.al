#if not CLEAN20
page 6 "Finance Charge Terms"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Finance Charge Terms';
    CardPageID = "Finance Charge Terms Card";
    PageType = List;
    SourceTable = "Finance Charge Terms";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the finance charge terms.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the finance charge terms.';
                }
                field("Interest Calculation"; "Interest Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which entries should be used in interest calculation on finance charge memos.';
                }
                field("Interest Calculation Method"; "Interest Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interest calculation method for this set of finance charge terms.';
                }
                field("Interest Rate"; "Interest Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage to use to calculate interest for this finance charge code.';
                }
                field("Interest Period (Days)"; "Interest Period (Days)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period that the interest rate applies to. Enter the number of days in the period.';
                }
                field("Minimum Amount (LCY)"; "Minimum Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a minimum interest charge in LCY.';
                }
                field("Additional Fee (LCY)"; "Additional Fee (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a fee amount in LCY.';
                }
                field("Grace Period"; "Grace Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grace period length for this set of finance charge terms.';
                }
                field("Due Date Calculation"; "Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that determines how to calculate the due date of the finance charge memo.';
                }
                field("Line Description"; "Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines.';
                }
                field("Detailed Lines Description"; "Detailed Lines Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines if multiple interest rates are set up for different payment delay periods and the description must show the sum of these.';
                    Visible = ReplaceMulIntRateEnabled;
                }
                field("Grace Tax Period"; "Grace Tax Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grace period for tax.';
                    Visible = not ReplaceMulIntRateEnabled;
                    ObsoleteState = Pending;
                    ObsoleteTag = '20.0';
                    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
                }
                field("Detailed Line Description"; "Detailed Line Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description to be used in the Description field on the finance charge memo lines if multiple interest rates are set up for different payment delay periods and the description must show the sum of these.';
                    Visible = not ReplaceMulIntRateEnabled;
                    ObsoleteState = Pending;
                    ObsoleteTag = '20.0';
                    ObsoleteReason = 'Replaced by Finance Charge Interest Rate';
                }
                field("Post Interest"; "Post Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not interest listed on the finance charge memo should be posted to the general ledger and customer accounts when the finance charge memo is issued.';
                }
                field("Post Additional Fee"; "Post Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not any additional fee listed on the finance charge memo should be posted to the general ledger and customer accounts when the memo is issued.';
                }
                field("Add. Line Fee in Interest"; "Add. Line Fee in Interest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that any additional fees are included in the interest calculation for the finance charge.';
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
        area(navigation)
        {
            group("Ter&ms")
            {
                Caption = 'Ter&ms';
                Image = BeginningText;
                action("Interest Rates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Interest Rates';
                    Image = Percentage;
                    RunObject = Page "Finance Charge Interest Rates";
                    RunPageLink = "Fin. Charge Terms Code" = FIELD(Code);
                    ToolTip = 'Set up interest rates.';
                    Visible = ReplaceMulIntRateEnabled;
                }
                action(BeginningText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Beginning Text';
                    Image = BeginningText;
                    RunObject = Page "Finance Charge Text";
                    RunPageLink = "Fin. Charge Terms Code" = FIELD(Code),
                                  Position = CONST(Beginning);
                    ToolTip = 'Define a beginning text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
                action(EndingText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Text';
                    Image = EndingText;
                    RunObject = Page "Finance Charge Text";
                    RunPageLink = "Fin. Charge Terms Code" = FIELD(Code),
                                  Position = CONST(Ending);
                    ToolTip = 'Define an ending text for each finance charge term. The text will then be printed on the finance charge memo.';
                }
                separator(Action35)
                {
                }
                action("C&urrencies")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&urrencies';
                    Image = Currency;
                    RunObject = Page "Currencies for Fin. Chrg Terms";
                    RunPageLink = "Fin. Charge Terms Code" = FIELD(Code);
                    ToolTip = 'Set up finance charge terms in foreign currencies. For example, you can use this table to set up finance charge terms with an additional fee of FRF 100.';
                }
                action("&Interest Rates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Interest Rates (Obsolete)';
                    Image = Percentage;
                    RunObject = Page "Multiple Interest Rates";
                    RunPageLink = "Finance Charge Code" = FIELD(Code);
                    ToolTip = 'Set up interest rates.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by standard Interest Rates action';
                    ObsoleteTag = '20.0';
                    Visible = not ReplaceMulIntRateEnabled;
                }
            }
        }
    }

#pragma warning disable AL0432
    var
        ReplaceMulIntRateMgt: Codeunit "Replace Mul. Int. Rate Mgt.";
        ReplaceMulIntRateEnabled: Boolean;

    trigger OnOpenPage()
    begin
        ReplaceMulIntRateEnabled := ReplaceMulIntRateMgt.IsEnabled();
    end;
#pragma warning restore AL0432
}

#endif