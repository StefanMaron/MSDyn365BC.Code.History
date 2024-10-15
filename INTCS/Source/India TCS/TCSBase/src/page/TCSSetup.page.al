page 18813 "TCS Setup"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "TCS Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Tax Type"; "Tax Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Tax Type for Tax Collected at Source.';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Reset();
        if not Get() then
            Insert();
    end;
}