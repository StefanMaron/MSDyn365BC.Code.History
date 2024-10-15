#if not CLEAN19
page 31010 "Sales Advanced Paym. Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Advance Payment Templates (Obsolete)';
    PageType = List;
    SourceTable = "Sales Adv. Payment Template";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            repeater(Control1220009)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales advanced payment templates.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for sales advance.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer s market type to link business transactions to.';
                    Visible = false;
                }
                field("Amounts Including VAT"; Rec."Amounts Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Advance Letter Nos."; Rec."Advance Letter Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to advance letter.';
                }
                field("Advance Invoice Nos."; Rec."Advance Invoice Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to advance invoice.';
                    Visible = false;
                }
                field("Advance Credit Memo Nos."; Rec."Advance Credit Memo Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to credit memo.';
                    Visible = false;
                }
                field("Post Advance VAT Option"; Rec."Post Advance VAT Option")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the option setup for post advance VAT option (never, optional, always).';
                    Visible = false;
                }
                field("Check Posting Group on Link"; Rec."Check Posting Group on Link")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies checking the posting group on invoice and advance.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}
#endif
