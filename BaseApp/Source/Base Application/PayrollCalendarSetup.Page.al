page 17431 "Payroll Calendar Setup"
{
    Caption = 'Payroll Calendar Setup';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Payroll Calendar Setup";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Year; Year)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Type"; "Period Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period No."; "Period No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Period Name"; "Period Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Day No."; "Day No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Nonworking; Nonworking)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Work Hours"; "Work Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Night Hours"; "Night Hours")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Week Day"; "Week Day")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Day Status"; "Day Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Time Activity Code"; "Time Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Day No." := 1;
    end;
}

