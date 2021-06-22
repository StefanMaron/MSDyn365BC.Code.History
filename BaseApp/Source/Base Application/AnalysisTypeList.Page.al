page 7111 "Analysis Type List"
{
    Caption = 'Analysis Type List';
    Editable = false;
    PageType = List;
    SourceTable = "Analysis Type";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the code of the analysis type.';
                }
                field(Name; Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis type.';
                }
                field("Value Type"; "Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the value type that the analysis type is based on.';
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
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Analysis Types";
                ToolTip = 'Set up the analysis type.';
            }
        }
    }
}

