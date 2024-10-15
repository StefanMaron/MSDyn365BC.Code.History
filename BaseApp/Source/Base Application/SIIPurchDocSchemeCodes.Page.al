page 10771 "SII Purch. Doc. Scheme Codes"
{
    Caption = 'SII Purchase Document Special Scheme Codes';
    PageType = List;
    SourceTable = "SII Purch. Doc. Scheme Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Special Scheme Code"; "Special Scheme Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the special scheme codes that are used for VAT reporting.';
                }
            }
        }
    }

    actions
    {
    }
}

