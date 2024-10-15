page 12445 "Select Reporting Period"
{
    Caption = 'Extern. Report Month Select';
    Editable = false;
    PageType = List;
    SourceTable = Date;
    SourceTableView = SORTING("Period Type", "Period Start");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FORMAT(""Period End"",0,Text000)"; Format("Period End", 0, Text000))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                }
                field("FORMAT(""Period Start"",0,Text001)"; Format("Period Start", 0, Text001))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Specifies the year.';
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

    var
        Text000: Label '<Month Text>', Locked = true;
        Text001: Label '<Year4>', Locked = true;
}

