page 12464 "Posted Document Signatures"
{
    Caption = 'Posted Document Signatures';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Document Signature";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Employee Type"; "Employee Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee type associated with the posted document signature information.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; "Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee name associated with the posted document signature information.';
                }
                field("Employee Job Title"; "Employee Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee position associated with the posted document signature information.';
                }
                field("Employee Org. Unit"; "Employee Org. Unit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee department associated with the posted document signature information.';
                }
                field("Warrant Description"; "Warrant Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant description associated with the posted document signature information.';
                }
                field("Warrant No."; "Warrant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant number associated with the posted document signature information.';
                }
                field("Warrant Date"; "Warrant Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warranty date of the posted document.';
                }
            }
        }
    }

    actions
    {
    }
}

