page 99000920 "Registered Absences"
{
    ApplicationArea = Manufacturing;
    Caption = 'Registered Absences';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Registered Absence";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Capacity Type"; "Capacity Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the absence entry is related to a machine center or a work center.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date of the absence. If the absence covers several days, there will be an entry line for each day.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a short description of the reason for the absence.';
                }
                field("Starting Date-Time"; "Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the absence, such as the time the employee normally starts to work or the time the machine starts to operate.';
                    Visible = false;
                }
                field("Ending Date-Time"; "Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';
                    Visible = false;
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of day of the absence, such as the time the employee normally leaves, or the time the machine stops operating.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the amount of capacity, which cannot be used during the absence period.';
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
            action("Implement Registered Absence")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Implement Registered Absence';
                Image = ImplementRegAbsence;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Implement Registered Absence";
                ToolTip = 'Implement the absence entries that you have made in the Reg. Abs. (from Machine Ctr.), Reg. Abs. (from Work Center), and Capacity Absence windows.';
            }
            action("Reg. Abs. (from Machine Ctr.)")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Reg. Abs. (from Machine Ctr.)';
                Image = CalendarMachine;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Reg. Abs. (from Machine Ctr.)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
            action("Reg. Abs. (from Work Ctr.)")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Reg. Abs. (from Work Ctr.)';
                Image = CalendarWorkcenter;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Reg. Abs. (from Work Center)";
                ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
            }
        }
    }
}

