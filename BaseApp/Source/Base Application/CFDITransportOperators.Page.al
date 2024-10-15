page 27007 "CFDI Transport Operators"
{
    DelayedInsert = true;
    Caption = 'CFDI Transport Operators';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "CFDI Transport Operator";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Operator Code"; "Operator Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the operator of the vehicle that transports the goods or merchandise.';
                }
                field("Operator Name"; "Operator Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the operator of the vehicle that transports the goods or merchandise.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}

