page 27002 "SAT Payment Method Codes"
{
    Caption = 'SAT Payment Method Codes';
    PageType = List;
    SourceTable = "SAT Payment Method Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT payment method.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description the SAT payment method.';
                }
            }
        }
    }

    actions
    {
    }
}

