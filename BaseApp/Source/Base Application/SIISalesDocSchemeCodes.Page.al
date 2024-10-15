page 10770 "SII Sales Doc. Scheme Codes"
{
    Caption = 'SII Sales Document Special Scheme Codes';
    PageType = List;
    SourceTable = "SII Sales Document Scheme Code";

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

