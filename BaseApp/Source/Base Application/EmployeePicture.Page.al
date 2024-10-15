page 5202 "Employee Picture"
{
    Caption = 'Employee Picture';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Person;

    layout
    {
        area(content)
        {
            field(Picture; Picture)
            {
                ToolTip = 'Specifies a picture that has been imported for the employee.';
            }
        }
    }

    actions
    {
    }
}

