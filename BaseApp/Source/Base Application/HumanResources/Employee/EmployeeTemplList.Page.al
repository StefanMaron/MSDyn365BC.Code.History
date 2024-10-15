namespace Microsoft.HumanResources.Employee;

page 1387 "Employee Templ. List"
{
    Caption = 'Employee Templates';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Employee Templ.";
    CardPageId = "Employee Templ. Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the template.';
                }
            }
        }
    }
}