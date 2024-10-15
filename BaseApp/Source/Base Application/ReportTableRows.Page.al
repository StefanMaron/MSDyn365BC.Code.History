page 26553 "Report Table Rows"
{
    AutoSplitKey = true;
    Caption = 'Report Table Rows';
    DataCaptionFields = "Table Code";
    PageType = List;
    SourceTable = "Stat. Report Table Row";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the statutory report table row.';
                }
                field("Row Code"; "Row Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row code associated with the statutory report table row.';
                }
                field("Requisites Group Name"; "Requisites Group Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the requisites group name associated with the statutory report table row.';
                }
                field("Excel Row No."; "Excel Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel row number associated with the statutory report table row.';
                }
                field("Inserted Requisite"; "Inserted Requisite")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the inserted requisite associated with the statutory report table row.';
                }
                field("Column Name for Ins. Rqst."; "Column Name for Ins. Rqst.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column name for the inserted requisite associated with the statutory report table row.';
                }
                field(Bold; Bold)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                }
            }
        }
    }

    actions
    {
    }
}

