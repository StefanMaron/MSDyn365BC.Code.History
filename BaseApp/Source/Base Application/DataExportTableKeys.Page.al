page 11026 "Data Export Table Keys"
{
    Caption = 'Data Export Table Keys';
    DataCaptionFields = TableNo;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Key";

    layout
    {
        area(content)
        {
            repeater(Control1101100000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the number of the key.';
                }
                field("Key"; Key)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Key';
                    ToolTip = 'Specifies the key.';
                }
                field(SumIndexFields; SumIndexFields)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SumIndexFields';
                }
                field(SQLIndex; SQLIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SQLIndex';
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies that the key is enabled for export of data from a table to improve performance. For example, to increase performance for exporting data from the G/L Entry table, you can specify the G/L Account No.,Posting Date key.';
                }
                field(MaintainSQLIndex; MaintainSQLIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MaintainSQLIndex';
                }
                field(MaintainSIFTIndex; MaintainSIFTIndex)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'MaintainSIFTIndex';
                }
                field(Clustered; Clustered)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clustered';
                    ToolTip = 'Specifies if the table data is clustered.';
                }
            }
        }
    }

    actions
    {
    }
}

