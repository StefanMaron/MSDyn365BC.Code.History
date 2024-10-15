page 31086 "Acc. Schedule Line List"
{
    Caption = 'Acc. Schedule Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Acc. Schedule Line";
    SourceTableView = SORTING("Schedule Name", "Line No.")
                      WHERE("Row Correction" = CONST(''));

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field("Schedule Name"; "Schedule Name")
                {
                    ToolTip = 'Specifies the account schedule name.';
                    Visible = false;
                }
                field("Row No."; "Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the account schedule line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies text that will appear on the account schedule line.';
                }
                field("Totaling Type"; "Totaling Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the totaling type for the account schedule line. The type determines which accounts within the totaling interval you specify in the Totaling field will be totaled.';
                }
                field(Totaling; Totaling)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies totaling for acc. schedule line';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;
}

