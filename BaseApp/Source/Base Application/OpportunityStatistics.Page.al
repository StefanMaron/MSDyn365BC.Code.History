page 5127 "Opportunity Statistics"
{
    Caption = 'Opportunity Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No. of Interactions"; "No. of Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of interactions linked to this opportunity.';
                }
                field("Current Sales Cycle Stage"; "Current Sales Cycle Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the current sales cycle stage of the opportunity.';
                }
                field("Estimated Value (LCY)"; "Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunity.';
                }
                field("Chances of Success %"; "Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the chances of success of the opportunity.';
                }
                field("Completed %"; "Completed %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the percentage of the sales cycle that has been completed for this opportunity.';
                }
                field("Probability %"; "Probability %")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the probability of the opportunity resulting in a sale.';
                }
                field("Calcd. Current Value (LCY)"; "Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the current calculated value of the opportunity.';
                }
            }
        }
    }

    actions
    {
    }
}

