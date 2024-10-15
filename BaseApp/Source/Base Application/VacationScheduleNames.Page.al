page 17493 "Vacation Schedule Names"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vacation Schedules';
    PageType = List;
    SourceTable = "Vacation Schedule Name";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Approver No."; "Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Approve Date"; "Approve Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the record was approved.';
                }
                field("HR Manager No."; "HR Manager No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Union Document No."; "Union Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Union Document Date"; "Union Document Date")
                {
                    ApplicationArea = Basic, Suite;
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
            action("Edit Vacation Schedule")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Vacation Schedule';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    VacationScheduleWorksheet: Page "Vacation Schedule Worksheet";
                begin
                    VacationScheduleWorksheet.SetVacationSchedule(Year);
                    VacationScheduleWorksheet.Run;
                end;
            }
        }
    }
}

