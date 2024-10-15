page 12149 "G/L Book Reprinting Info."
{
    Caption = 'G/L Book Reprinting Information';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Reprint Info Fiscal Reports";
    SourceTableView = WHERE(Report = CONST("G/L Book - Print"));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the start date that is associated with the printed fiscal report.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the end date that is associated with the printed fiscal report.';
                }
                field("First Page Number"; "First Page Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page number of the first page of the fiscal report.';
                }
            }
        }
    }

    actions
    {
    }
}

