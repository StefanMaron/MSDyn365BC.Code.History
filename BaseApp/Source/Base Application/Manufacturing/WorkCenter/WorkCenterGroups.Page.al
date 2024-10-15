namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Manufacturing.Reports;

page 99000758 "Work Center Groups"
{
    ApplicationArea = Manufacturing;
    Caption = 'Work Center Groups';
    PageType = List;
    SourceTable = "Work Center Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for the work center group.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a name for the work center group.';
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
        area(navigation)
        {
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action(Calendar)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calendar';
                    Image = MachineCenterCalendar;
                    RunObject = Page "Work Ctr. Group Calendar";
                    ToolTip = 'Open the shop calendar.';
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Work Center Group Load";
                    RunPageLink = Code = field(Code),
                                  "Date Filter" = field("Date Filter"),
                                  "Work Shift Filter" = field("Work Shift Filter");
                    ToolTip = 'View the availability of the machine or work center, including its capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
                }
            }
        }
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
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Work Center Load_Promoted"; "Work Center Load")
                {
                }
            }
        }
    }
}

