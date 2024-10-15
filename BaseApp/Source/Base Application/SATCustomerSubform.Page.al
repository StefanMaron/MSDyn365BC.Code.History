page 27014 "SAT Customer Subform"
{
    Caption = 'SAT Customer Subform';
    PageType = ListPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved customer.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the involved customer.';
                }
                field("CFDI Purpose"; "CFDI Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the CFDI document. ';
                }
                field("CFDI Relation"; "CFDI Relation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relation of the CFDI document. ';
                }
            }
        }
    }

    actions
    {
    }
}

