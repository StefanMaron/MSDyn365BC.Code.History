page 17201 "Tax Register Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Register Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Tax Register Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Condition Dimension Code"; "Condition Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a dimension code that describes the condition of the tax register.';
                }
                field("Kind Dimension Code"; "Kind Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a dimension code that describes the type of the tax register.';
                }
                field("Create Acquis. FA Tax Ledger"; "Create Acquis. FA Tax Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to create fixed asset ledger entries based on tax register transactions.';
                }
                field("Create Reclass. FA Tax Ledger"; "Create Reclass. FA Tax Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to create fixed asset reclassification ledger entries based on tax register transactions.';
                }
                field("Tax Depreciation Book"; "Tax Depreciation Book")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax depreciation book that is used for the depreciation of fixed assets of tax register entries.';
                }
                field("Future Exp. Depreciation Book"; "Future Exp. Depreciation Book")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax depreciation book that is used for the depreciation of future expenses of tax register entries.';
                }
                field("Create Acquis. FE Tax Ledger"; "Create Acquis. FE Tax Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to create future expense ledger entries based on tax register transactions.';
                }
                field("Use Group Depr. Method from"; "Use Group Depr. Method from")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the group depreciation method that you want to use for the depreciation of future expenses.';
                }
                field("Min. Group Balance"; "Min. Group Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum amount that is valid as the balance for the depreciation group.';
                }
                field("Write-off in Charges"; "Write-off in Charges")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to write off fixed asset charges for the tax register entries.';
                }
                field("Create Data for Printing Forms"; "Create Data for Printing Forms")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to store detailed tax register entry information that is printed on reports and forms.';
                }
                field("Calculate TD for each FA"; "Calculate TD for each FA")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want tax differences to be calculated for fixed assets.';
                }
                field("Default FA TD Code"; "Default FA TD Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the standard method code that is used to calculate tax differences for fixed assets.';
                }
                field("Rel. Act as Depr. Bonus Base"; "Rel. Act as Depr. Bonus Base")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'FA Release Act as Depr. Bonus Base';
                    ToolTip = 'Specifies if fixed asset releases are used to calculate the depreciation bonus base.';
                }
                field("Depr. Bonus TD Code"; "Depr. Bonus TD Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a tax difference code that is used to calculate the depreciation bonus.';
                }
                field("Depr. Bonus Recovery from"; "Depr. Bonus Recovery from")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date from which depreciation is recovered if the fixed asset is sold.';
                }
                field("Depr. Bonus Recov. Per. (Year)"; "Depr. Bonus Recov. Per. (Year)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period in which the depreciation bonus is applied.';
                }
                field("Depr. Bonus Recovery TD Code"; "Depr. Bonus Recovery TD Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference code that is used to calculate the depreciation bonus recovery amount.';
                }
                field("Disposal TD Code"; "Disposal TD Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax difference code that is used to calculate the disposal of fixed assets.';
                }
            }
            group(Templates)
            {
                Caption = 'Templates';
                field("Sales VAT Ledg. Template Code"; "Sales VAT Ledg. Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Sales Add. Sheet Templ. Code"; "Sales Add. Sheet Templ. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Purch. VAT Ledg. Template Code"; "Purch. VAT Ledg. Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("Purch. Add. Sheet Templ. Code"; "Purch. Add. Sheet Templ. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
                field("VAT Iss./Rcvd. Jnl. Templ Code"; "VAT Iss./Rcvd. Jnl. Templ Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Register Template Code"; "Tax Register Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the journal template that is used for the process in question. ';
                }
            }
        }
    }

    actions
    {
    }
}

