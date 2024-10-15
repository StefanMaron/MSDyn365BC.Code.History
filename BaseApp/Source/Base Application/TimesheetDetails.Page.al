page 17442 "Timesheet Details"
{
    Caption = 'Timesheet Details';
    PageType = ListPart;
    PopulateAllFields = true;
    SourceTable = "Timesheet Detail";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the timesheet entry.';
                }
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the work activity.';
                }
                field("Time Activity Name"; "Time Activity Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the work activity.';
                }
                field(Overtime; Overtime)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies overtime details.';
                }
                field("Actual Hours"; "Actual Hours")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many hours the employee worked.';
                }
                field("Timesheet Code"; "Timesheet Code")
                {
                    ToolTip = 'Specifies the code of the timesheet.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the timesheet entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
            }
        }
    }

    actions
    {
    }
}

