page 2143 "O365 VAT Product Posting Gr."
{
    Caption = 'VAT Rates';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "VAT Product Posting Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a code for the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies a description of the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Prod. Posting Group" = FIELD(Code);
                ToolTip = 'View or edit combinations of VAT business posting groups and VAT product posting groups, which determine which G/L accounts to post to when you post journals and documents.';
            }
        }
    }
}

