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
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Caption"; "Table Caption")
                {
                    ApplicationArea = All;
                }
                field("No."; "No.")
                {
                    ApplicationArea = All;
                }
                field("Value Posting"; "Value Posting")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}