page 12463 "Document Signatures"
{
    Caption = 'Document Signatures';
    PageType = List;
    SourceTable = "Document Signature";

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Employee Type"; "Employee Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee type associated with the document signature.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Name"; "Employee Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee name associated with this document signature information.';
                }
                field("Employee Job Title"; "Employee Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee position associated with this document signature information.';
                }
                field("Employee Org. Unit"; "Employee Org. Unit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee department associated with this document signature information.';
                }
                field("Warrant Description"; "Warrant Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant description associated with this document signature information.';
                }
                field("Warrant No."; "Warrant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant number associated with this document signature information.';
                }
                field("Warrant Date"; "Warrant Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant date associated with this document signature information.';
                }
            }
        }
    }

    actions
    {
    }
}

