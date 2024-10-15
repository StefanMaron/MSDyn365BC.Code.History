page 17301 "Tax Diff. Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Diff. Posting Groups';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Diff. Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1000000000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the tax differences posting group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code description associated with the tax difference posting group.';
                }
                field("CTA Tax Account"; "CTA Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is debited for the constant tax arising (CTA) amount.';
                }
                field("CTL Tax Account"; "CTL Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is debited for the constant tax liability (CTL) amount.';
                }
                field("DTA Tax Account"; "DTA Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is debited for the deferred tax asset (DTA) amount.';
                }
                field("DTL Tax Account"; "DTL Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is debited for the deferred tax liability (DTL) amount.';
                }
                field("CTA Account"; "CTA Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account to which the constant tax arising (CTA) amount is posted.';
                }
                field("CTL Account"; "CTL Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account to which the constant tax liability (CTL) amount is posted.';
                }
                field("DTA Account"; "DTA Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account to which the deferred tax asset (DTA) amount is posted.';
                }
                field("DTL Account"; "DTL Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account to which the deferred tax liability (DTL) amount is posted.';
                }
                field("DTA Disposal Account"; "DTA Disposal Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax asset (DTA) disposal account.';
                }
                field("DTL Disposal Account"; "DTL Disposal Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax liability (DTL) disposal account.';
                }
                field("DTA Transfer Bal. Account"; "DTA Transfer Bal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax asset (DTA) transfer balance account.';
                }
                field("DTL Transfer Bal. Account"; "DTL Transfer Bal. Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the deferred tax liability (DTL) transfer balance account.';
                }
                field("CTA Transfer Tax Account"; "CTA Transfer Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for posting the gain and loss on the credit side.';
                }
                field("CTL Transfer Tax Account"; "CTL Transfer Tax Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for the posting gain and loss, on the debit side.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;
}

