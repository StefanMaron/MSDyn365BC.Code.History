page 12134 "Withholding Exceptional Events"
{
    Caption = 'Withholding Tax Exceptional Events';
    PageType = List;
    SourceTable = "Withholding Exceptional Event";
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an exception event to use in withholding tax exports.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the exception event.';
                }
            }
        }
    }
}
