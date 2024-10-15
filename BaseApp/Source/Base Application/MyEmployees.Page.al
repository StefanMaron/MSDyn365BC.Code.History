page 35657 "My Employees"
{
    Caption = 'My Employees';
    PageType = ListPart;
    SourceTable = "My Employee";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';

                    trigger OnValidate()
                    begin
                        GetEmployee;
                    end;
                }
                field("Employee.GetNameInitials"; Employee.GetNameInitials)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Employee.GetJobTitleName"; Employee.GetJobTitleName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Job Title';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Return';

                trigger OnAction()
                begin
                    OpenEmployeeCard;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetEmployee;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Employee);
    end;

    trigger OnOpenPage()
    begin
        SetRange("User ID", UserId);
    end;

    var
        Employee: Record Employee;

    [Scope('OnPrem')]
    procedure GetEmployee()
    begin
        Clear(Employee);

        Employee.Get("Employee No.");
    end;

    [Scope('OnPrem')]
    procedure OpenEmployeeCard()
    begin
        if Employee.Get("Employee No.") then
            PAGE.Run(PAGE::"Employee Card", Employee);
    end;
}

