namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Reports;

page 99000866 "Capacity Constrained Resources"
{
    AdditionalSearchTerms = 'finite loading';
    ApplicationArea = Manufacturing;
    Caption = 'Capacity Constrained Resources';
    PageType = List;
    SourceTable = "Capacity Constrained Resource";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Capacity Type"; Rec."Capacity Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity type to apply finite loading to.';
                }
                field("Capacity No."; Rec."Capacity No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of an existing machine center or work center to assign finite loading to.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Enabled = true;
                    ToolTip = 'Specifies the name of the work center or machine center associated with the capacity number on this line.';
                }
                field("Critical Load %"; Rec."Critical Load %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the available capacity of a work center or machine center to apply load to. Operations on work centers or machine centers that are set up as constrained resources will always be planned serially. This means that if a constrained resource has multiple capacities, then those capacities can only be planned in sequence, not in parallel as they would be if the work or machine center was not set up as a constrained resource. In a constrained resource, the Capacity field on the work center or machine center is greater than 1.';
                }
                field("Dampener (% of Total Capacity)"; Rec."Dampener (% of Total Capacity)")
                {
                    ApplicationArea = Manufacturing;
                    Editable = true;
                    ToolTip = 'Specifies the tolerance as a percent that you will allow the critical load percent to be exceeded for this work or machine center.';
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
        area(reporting)
        {
            action("Work Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load';
                Image = "Report";
                RunObject = Report "Work Center Load";
                ToolTip = 'Get an overview of availability at the work center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
            }
            action("Work Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load/Bar';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Work Center Load/Bar";
                ToolTip = 'View a list of work centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
            }
            action("Machine Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load';
                Image = "Report";
                RunObject = Report "Machine Center Load";
                ToolTip = 'Get an overview of availability at the machine center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
            }
            action("Machine Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Center Load/Bar';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Machine Center Load/Bar";
                ToolTip = 'View a list of machine centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Work Center Load_Promoted"; "Work Center Load")
                {
                }
                actionref("Machine Center Load_Promoted"; "Machine Center Load")
                {
                }
            }
        }
    }
}

