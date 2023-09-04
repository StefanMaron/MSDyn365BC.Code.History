page 532 "Company Sizes"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Company Size";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code that identifies the company size.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the company size.';
                }
            }
        }
    }
}
