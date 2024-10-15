page 10860 "Payment Class List"
{
    Caption = 'Payment Class List';
    Editable = false;
    PageType = List;
    SourceTable = "Payment Class";
    SourceTableView = WHERE(Enable = CONST(true));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a payment class code.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies text to describe the payment class.';
                }
            }
        }
    }

    actions
    {
    }
}

