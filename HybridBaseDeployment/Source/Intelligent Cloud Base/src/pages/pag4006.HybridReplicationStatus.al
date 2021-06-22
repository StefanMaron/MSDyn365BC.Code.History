page 4006 "Intelligent Cloud Details"
{
    Caption = 'Table Migration Status';
    SourceTable = "Hybrid Replication Detail";
    PageType = List;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Company Name"; "Company Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Errors; GetErrors())
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}