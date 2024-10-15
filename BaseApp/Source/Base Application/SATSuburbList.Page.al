page 27029 "SAT Suburb List"
{
    PageType = List;
    Caption = 'SAT Suburbs';
    SourceTable = "SAT Suburb";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Suburb Code"; "Suburb Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT suburb code where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field("Postal Code"; "Postal Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT postal code (PO, BOX) where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
                field(Description; Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the description of the colony or similar data where the domicile of the origin or destination of the goods or merchandise that are moved in the different means of transport is located.';
                }
            }
        }
    }

    actions
    {
    }
}

