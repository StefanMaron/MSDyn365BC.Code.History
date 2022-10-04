page 1513 "Notification Schedule"
{
    Caption = 'Notification Schedule';
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Notification Schedule";

    layout
    {
        area(content)
        {
            group("Recurrence Pattern")
            {
                Caption = 'Recurrence Pattern';
                field(Recurrence; Recurrence)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the recurrence pattern in which the user receives notifications. The value in this field is displayed in the Schedule field in the Notification Setup window.';

                    trigger OnValidate()
                    begin
                        if Recurrence = Recurrence::Daily then
                            Validate("Daily Frequency", "Daily Frequency");
                    end;
                }
                field(Time; Time)
                {
                    ApplicationArea = Suite;
                    Enabled = Recurrence <> Recurrence::Instantly;
                    ToolTip = 'Specifies what time of the day the user receives notifications when the value in the Recurrence field is different from Instantly..';
                }
            }
            group(Daily)
            {
                Caption = 'Daily';
                Visible = Recurrence = Recurrence::Daily;
                field(Frequency; "Daily Frequency")
                {
                    ApplicationArea = Suite;
                    Caption = 'Frequency';
                    ToolTip = 'Specifies on which type of days the user receives notifications when the value in the Recurrence field is Daily. Select Weekday to receive notifications every work day of the week. Select Daily to receive notifications every day of the week, including weekends.';
                }
            }
            group(Weekly)
            {
                Caption = 'Weekly';
                Enabled = true;
                Visible = Recurrence = Recurrence::Weekly;
                field(Monday; Monday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Mondays.';
                }
                field(Tuesday; Tuesday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Tuesdays.';
                }
                field(Wednesday; Wednesday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Wednesdays.';
                }
                field(Thursday; Thursday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Thursdays.';
                }
                field(Friday; Friday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Fridays.';
                }
                field(Saturday; Saturday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Saturdays.';
                }
                field(Sunday; Sunday)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user receives notifications on Sundays.';
                }
            }
            group(Monthly)
            {
                Caption = 'Monthly';
                Visible = Recurrence = Recurrence::Monthly;
                field("Monthly Notification Date"; Rec."Monthly Notification Date")
                {
                    ApplicationArea = Suite;
                    Caption = 'Notification Date';
                    ToolTip = 'Specifies that the user receives notifications once a month on the date in this field when the value in the Date of Month field is Custom.';
                }
                field("Date of Month"; Rec."Date of Month")
                {
                    ApplicationArea = Suite;
                    Editable = "Monthly Notification Date" = "Monthly Notification Date"::Custom;
                    MaxValue = 31;
                    MinValue = 1;
                    ToolTip = 'Specifies that the user receives notifications on the first, last, or a specific date of the month. Select Custom to specify a specific day in the Monthly Notification Date field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if HasFilter() then
            if not FindFirst() then
                CreateNewRecord(GetRangeMin("User ID"), GetRangeMin("Notification Type"));
    end;
}

