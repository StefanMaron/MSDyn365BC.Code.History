page 17429 "Payroll Calendar List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payroll Calendars';
    CardPageID = "Payroll Calendar Card";
    Editable = false;
    PageType = List;
    SourceTable = "Payroll Calendar";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Code';
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Calendar")
            {
                Caption = '&Calendar';
                action("Where Used")
                {
                    Caption = 'Where Used';
                    Image = "Where-Used";
                    RunObject = Page "Employee List";
                    RunPageLink = "Calendar Code" = FIELD(Code);
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;
}

