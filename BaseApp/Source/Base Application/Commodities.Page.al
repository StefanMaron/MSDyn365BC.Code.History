page 31095 Commodities
{
    ApplicationArea = Basic, Suite;
    Caption = 'Commodities';
    PageType = List;
    SourceTable = Commodity;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of commodities.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of commodities.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220005; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220006; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Commodity Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Commodity Setup';
                Image = SetupLines;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                //PromotedIsBig = true;
                RunObject = Page "Commodity Setup";
                RunPageLink = "Commodity Code" = FIELD(Code);
                RunPageView = SORTING("Commodity Code", "Valid From");
                ToolTip = 'The funkcion opens the page for commodity limit amount setup.';
            }
        }
    }
}

