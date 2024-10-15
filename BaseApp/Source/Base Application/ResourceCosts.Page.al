page 203 "Resource Costs"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Resource Costs';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Resource Cost";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type.';
                }
                field("Code"; Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code.';
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the type of work. You can also assign a unit price to a work type.';
                }
                field("Cost Type"; "Cost Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of cost.';
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
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
    }
}

