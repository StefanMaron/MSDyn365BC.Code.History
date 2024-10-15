namespace Microsoft.HumanResources.Employee;

page 1377 "Select Employee Templ. List"
{
    Caption = 'Select a template for a new employee';
    PageType = List;
    SourceTable = "Employee Templ.";
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