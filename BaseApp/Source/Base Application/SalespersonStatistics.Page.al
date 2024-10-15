page 5117 "Salesperson Statistics"
{
    Caption = 'Salesperson Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Salesperson/Purchaser";

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
                    ToolTip = 'Specifies the number of interactions handled by this salesperson.';
                }
                field("Cost (LCY)"; "Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total cost of all the interactions handled by the salesperson. The field is not editable.';
                }
                field(AvgCostPerResp; AvgCostPerResp)
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatType = 1;
                    Caption = 'Avg. Cost per Response';
                    ToolTip = 'Specifies the cost of the campaign per response.';
                }
                field("Duration (Min.)"; "Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total duration of all the interactions handled by the salesperson. The field is not editable.';
                }
                field(AvgDurationPerResp; AvgDurationPerResp)
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatType = 1;
                    Caption = 'Avg. Duration per Response';
                    ToolTip = 'Specifies how long the campaign took per response.';
                }
            }
            group(Opportunities)
            {
                Caption = 'Opportunities';
                field("No. of Opportunities"; "No. of Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of open opportunities handled by the salesperson.';
                }
                field("Estimated Value (LCY)"; "Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total estimated value of all the opportunities handled by the salesperson. The field is not editable.';
                }
                field("Avg. Estimated Value (LCY)"; "Avg. Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the average estimated value of the opportunities handled by the salesperson.';
                }
                field("Calcd. Current Value (LCY)"; "Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total calculated current value of all the opportunities handled by the salesperson. The field is not editable.';
                }
                field("Avg.Calcd. Current Value (LCY)"; "Avg.Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the average calculated current value of the opportunities handled by that salesperson.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if "No. of Interactions" = 0 then begin
            AvgCostPerResp := 0;
            AvgDurationPerResp := 0;
        end else begin
            AvgCostPerResp := Round("Cost (LCY)" / "No. of Interactions");
            AvgDurationPerResp := Round("Duration (Min.)" / "No. of Interactions", 0.01);
        end;
    end;

    var
        AvgCostPerResp: Decimal;
        AvgDurationPerResp: Decimal;
}

