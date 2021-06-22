page 2160 "O365 Sales Graph"
{
    Caption = 'O365 Sales Graph';
    SourceTable = "O365 Sales Graph";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(Component; Component)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field(Type; Type)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            field("Schema"; Schema)
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
    }

    trigger OnModifyRecord(): Boolean
    begin
        ParseRefresh;
    end;
}

