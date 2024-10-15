#if not CLEAN18
page 31048 "Credits Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Credits Setup (Obsolete)';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Credits Setup";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Credit Bal. Account No."; "Credit Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number for credit card posting.';
                }
                field("Max. Rounding Amount"; "Max. Rounding Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum rounding amount.';
                }
                field("Debit Rounding Account"; "Debit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for debit rounding.';
                }
                field("Credit Rounding Account"; "Credit Rounding Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account for credit rounding.';
                }
                field("Credit Proposal By"; "Credit Proposal By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the credits will be proposed according Registration no. or bussiness relation.';
                }
                field("Show Empty when not Found"; "Show Empty when not Found")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if only items of the same customer and vendor can be display.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Credit Nos."; "Credit Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to credits.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;
}
#endif