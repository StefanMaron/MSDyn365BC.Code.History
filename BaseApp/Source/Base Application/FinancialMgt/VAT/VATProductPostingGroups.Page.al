page 471 "VAT Product Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Product Posting Groups';
    PageType = List;
    SourceTable = "VAT Product Posting Group";
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
                    ToolTip = 'Specifies a code for the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the posting group the determines how to calculate VAT for items or resources that you purchase or sell.';
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
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Prod. Posting Group" = FIELD(Code);
                ToolTip = 'View or edit combinations of VAT business posting groups and VAT product posting groups, which determine which G/L accounts to post to when you post journals and documents.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Text
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        FilterString: Text;
    begin
        CurrPage.SetSelectionFilter(VATProductPostingGroup);
        // Creating a simple filter, instead of using SelectionFilterManagement code unit.
        if VATProductPostingGroup.FindFirst() then
            repeat
                if FilterString <> '' then
                    FilterString := FilterString + '|';
                FilterString := FilterString + '''' + VATProductPostingGroup.Code + '''';
            until VATProductPostingGroup.Next() = 0;
        exit(FilterString);
    end;
}

