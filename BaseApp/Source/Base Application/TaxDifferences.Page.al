page 17300 "Tax Differences"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Differences';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Difference";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identifying income or expense code that defines the source of the tax difference.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the tax difference code.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference represents Income or Expense for your organization.';
                }
                field(Category; Category)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference amount is a Constant or Temporary.';
                }
                field("Calculation Mode"; "Calculation Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference balance is calculated.';
                }
                field("Calc. Norm Jurisdiction Code"; "Calc. Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a tax jurisdiction code that is used to calculate taxable profits and losses for the tax period.';
                }
                field("Calc. Norm Code"; "Calc. Norm Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an income or expense code that is used to calculate taxable profits and losses for the tax difference.';
                }
                field("Tax Period Limited"; "Tax Period Limited")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference period is temporary and limited by a contract or legal requirements.';
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting group that is used for tax difference amounts.';
                }
                field("Norm Jurisdiction Code"; "Norm Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the norm jurisdiction that is used to calculate taxable profits and losses for the tax difference.';
                }
                field("Norm Code"; "Norm Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an income or expense code that is used to calculate taxable profits and losses for the tax period.';
                }
                field("Tax Amount"; "Tax Amount")
                {
                    ToolTip = 'Specifies the tax difference amount that is calculated for the tax period.';
                    Visible = false;
                }
                field("Source Code Mandatory"; "Source Code Mandatory")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the source code is a required component for calculating tax differences.';
                }
                field("Depreciation Bonus"; "Depreciation Bonus")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax difference amount is reported as a fixed asset depreciation bonus.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Tax Difference")
            {
                Caption = 'Tax Difference';
                action("Tax Diff. Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Diff. Ledger Entries';
                    Image = LedgerEntries;
                    RunObject = Page "Tax Diff. Ledger Entries";
                    RunPageLink = "Tax Diff. Code" = FIELD(Code);
                    RunPageView = SORTING("Tax Diff. Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View entries resulting from posting variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

