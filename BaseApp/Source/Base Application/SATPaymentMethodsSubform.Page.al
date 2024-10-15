page 27012 "SAT Payment Methods Subform"
{
    Caption = 'SAT Payment Methods Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Payment Method";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the SAT payment method.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the SAT payment method.';
                }
                field("SAT Method of Payment"; "SAT Method of Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the SAT payment method.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Caption := '';
    end;
}

