namespace Microsoft.Finance.Dimension;

page 544 "Default Dimension Where-Used"
{
    PageType = List;
    SourceTable = "Default Dimension";
    InsertAllowed = false;
    Editable = false;
    DeleteAllowed = false;
    DataCaptionFields = "Dimension Value Code", "Dimension Code";


    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}