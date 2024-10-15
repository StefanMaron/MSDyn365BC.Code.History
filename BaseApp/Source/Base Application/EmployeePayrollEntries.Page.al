page 5237 "Employee Payroll Entries"
{
    ApplicationArea = BasicHR;
    Caption = 'Employee Payroll Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Employee Payroll Entry" = m;
    PromotedActionCategories = 'New,Process,Report,Entry';
    SourceTable = "Employee Payroll Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
    }
}

