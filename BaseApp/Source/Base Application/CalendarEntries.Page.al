page 99000759 "Calendar Entries"
{
    Caption = 'Calendar Entries';
    DataCaptionExpression = Caption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Calendar Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Capacity Type"; "Capacity Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of capacity for the calendar entry.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; CurrDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date when this capacity refers to.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Validate(Date, CurrDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Work Shift Code"; "Work Shift Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies code for the work shift that the capacity refers to.';
                }
                field("Starting Date-Time"; "Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';

                    trigger OnValidate()
                    begin
                        GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
                        Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of this calendar entry.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; "Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';

                    trigger OnValidate()
                    begin
                        GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
                        Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of this calendar entry.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field(Efficiency; Efficiency)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the efficiency of this calendar entry.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity of this calendar entry.';
                }
                field("Capacity (Total)"; "Capacity (Total)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total capacity of this calendar entry.';
                }
                field("Capacity (Effective)"; "Capacity (Effective)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the effective capacity of this calendar entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
    end;

    trigger OnInit()
    begin
        DateAndTimeFieldVisible := false;
    end;

    trigger OnOpenPage()
    begin
        DateAndTimeFieldVisible := false;
    end;

    var
        StartingTime: Time;
        EndingTime: Time;
        CurrDate: Date;
        DateAndTimeFieldVisible: Boolean;
}

