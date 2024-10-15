page 31030 "Purchase Adv. Paym. Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Purchase Advance Payment Templates';
    PageType = Card;
    SourceTable = "Purchase Adv. Payment Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1220011)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purchase advanced payment templates.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for purchase advance.';
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies a VAT business posting group code.';
                    Visible = false;
                }
                field("Amounts Including VAT"; "Amounts Including VAT")
                {
                    ToolTip = 'Specifies whether the unit price on the line should be displayed including or excluding VAT.';
                    Visible = false;
                }
                field("Automatic Adv. Invoice Posting"; "Automatic Adv. Invoice Posting")
                {
                    ToolTip = 'Specifies this option for automatic advance invoice posting.';
                    Visible = false;
                }
                field("Advance Letter Nos."; "Advance Letter Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to advance letter.';
                }
                field("Advance Invoice Nos."; "Advance Invoice Nos.")
                {
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to advance invoice.';
                    Visible = false;
                }
                field("Advance Credit Memo Nos."; "Advance Credit Memo Nos.")
                {
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to credit memo.';
                    Visible = false;
                }
                field("Post Advance VAT Option"; "Post Advance VAT Option")
                {
                    ToolTip = 'Specifies the option setup for post advance VAT option (never, optional, always).';
                    Visible = false;
                }
                field("Check Posting Group on Link"; "Check Posting Group on Link")
                {
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

