page 5582 "Voucher Entry Source Codes"
{
    PageType = List;
    SourceTable = "Voucher Entry Source Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code.';
                }
            }
        }
    }
}
