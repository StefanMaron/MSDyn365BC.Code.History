page 1221 "Bank Statement Line Details"
{
    Caption = 'Bank Statement Line Details';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Data Exch. Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; GetFieldName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of a column in the imported bank statement file.';
                }
                field(Value; Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value in a column in the imported bank statement file, such as account number, posting date, and amount.';
                }
            }
        }
    }

    actions
    {
    }
}

