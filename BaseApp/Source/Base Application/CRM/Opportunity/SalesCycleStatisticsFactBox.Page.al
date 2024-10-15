namespace Microsoft.CRM.Opportunity;

page 5175 "Sales Cycle Statistics FactBox"
{
    Caption = 'Sales Cycle Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = "Sales Cycle";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                field("No. of Opportunities"; Rec."No. of Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of opportunities that you have created using the sales cycle. This field is not editable.';
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of all the open opportunities that you have assigned to the sales cycle. This field is not editable.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the calculated current value of all the open opportunities that you have assigned to the sales cycle. This field is not editable.';
                }
            }
        }
    }

    actions
    {
    }
}

