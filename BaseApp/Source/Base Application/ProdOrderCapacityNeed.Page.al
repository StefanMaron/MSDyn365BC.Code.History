#if not CLEAN20
page 99000820 "Prod. Order Capacity Need"
{
    Caption = 'Prod. Order Capacity Need';
    DataCaptionFields = Status, "Prod. Order No.";
    Editable = false;
    PageType = List;
    SourceTable = "Prod. Order Capacity Need";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of capacity need.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of the capacity need.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of the capacity need.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field(Date; CurrDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date when this capacity need occurred.';

                    trigger OnValidate()
                    begin
                        Validate(Date, CurrDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Send-Ahead Type"; Rec."Send-Ahead Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the send-ahead quantity is of type Input, Output, or Both.';
                }
                field("Time Type"; Rec."Time Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the time type of the capacity need.';
                }
                field("Allocated Time"; Rec."Allocated Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity need of planned operations.';
                }
                field(AllocTimeInMin; AllocTimeInMin)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Time (Min)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies allocated time in minutes';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The functionality will be removed and this field should not be used.';
                    ObsoleteTag = '20.0';
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
        // NAVCZ
        if "Needed Time" <> 0 then
            AllocTimeInMin := ("Ending Date-Time" - "Starting Date-Time") *
              "Allocated Time" / (60000 * "Needed Time")
        else
            AllocTimeInMin := 0;
        // NAVCZ

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
        AllocTimeInMin: Decimal;
        StartingTime: Time;
        EndingTime: Time;
        CurrDate: Date;
        DateAndTimeFieldVisible: Boolean;
}
#endif
