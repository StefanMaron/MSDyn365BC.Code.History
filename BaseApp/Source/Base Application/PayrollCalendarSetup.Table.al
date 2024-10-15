table 17429 "Payroll Calendar Setup"
{
    Caption = 'Payroll Calendar Setup';
    DataCaptionFields = "Calendar Code";

    fields
    {
        field(1; "Calendar Code"; Code[10])
        {
            Caption = 'Calendar Code';
            Editable = false;
            TableRelation = "Payroll Calendar";
        }
        field(2; Year; Integer)
        {
            BlankZero = true;
            Caption = 'Year';
            MaxValue = 9999;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Period No.");
            end;
        }
        field(3; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = ' ,Week,Month,Shift';
            OptionMembers = " ",Week,Month,Shift;

            trigger OnValidate()
            begin
                if "Period Type" <> xRec."Period Type" then begin
                    "Period No." := 0;
                    "Period Name" := '';
                    "Week Day" := 0;
                    Description := '';
                    Nonworking := false;
                    "Work Hours" := 0;
                    "Night Hours" := 0;
                    "Starting Time" := 0T;
                end;
            end;
        }
        field(4; "Period No."; Integer)
        {
            BlankZero = true;
            Caption = 'Period No.';
            MinValue = 0;

            trigger OnValidate()
            begin
                case "Period Type" of
                    "Period Type"::Week:
                        if "Period No." > 0 then
                            if "Period No." <= 53 then
                                "Period Name" := Format("Period No.")
                            else
                                Error(Text000, FieldCaption("Period No."), 52)
                        else
                            "Period Name" := '';
                    "Period Type"::Month:
                        case "Period No." of
                            0:
                                "Period Name" := '';
                            1 .. 12:
                                "Period Name" := LocMgt.GetMonthName(DMY2Date(1, "Period No.", 2000), false);
                            else
                                Error(Text000, FieldCaption("Period No."), 12);
                        end;
                end;
                Validate("Week Day");
            end;
        }
        field(5; "Period Name"; Text[30])
        {
            Caption = 'Period Name';
            Editable = false;
        }
        field(6; "Day No."; Integer)
        {
            Caption = 'Day No.';
            MinValue = 1;

            trigger OnValidate()
            begin
                case "Period Type" of
                    "Period Type"::Week:
                        case "Day No." of
                            0:
                                Description := '';
                            1 .. 7:
                                begin
                                    "Week Day" := "Day No.";
                                    Description := Format("Week Day");
                                end
                            else
                                Error(Text002, Format("Period Type"::Week));
                        end;
                    "Period Type"::Month:
                        begin
                            if Year <> 0 then
                                Date := DMY2Date("Day No.", "Period No.", Year)
                            else
                                case "Period No." of
                                    1, 3, 5, 7, 8, 10, 12:
                                        if "Day No." > 31 then
                                            Error(Text002, Format("Period Type"::Month));
                                    2:
                                        if "Day No." > 29 then
                                            Error(Text002, Format("Period Type"::Month));
                                    4, 6, 9, 11:
                                        if "Day No." > 30 then
                                            Error(Text002, Format("Period Type"::Month));
                                end;
                            Description := '';
                            if ("Day No." <> 0) and ("Period No." > 0) and ("Period No." <= 12) then
                                Description := Format("Day No.") + ' ' +
                                  LocMgt.GetMonthName(DMY2Date(1, "Period No.", 2000), true);
                        end;
                end;
            end;
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
            InitValue = true;

            trigger OnValidate()
            begin
                if Nonworking then begin
                    "Work Hours" := 0;
                    "Starting Time" := 0T;
                end;
            end;
        }
        field(9; "Starting Time"; Time)
        {
            BlankNumbers = BlankZero;
            Caption = 'Starting Time';
        }
        field(10; "Work Hours"; Decimal)
        {
            BlankZero = true;
            Caption = 'Work Hours';
            MaxValue = 24;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Work Hours" > 0 then
                    Nonworking := false;
            end;
        }
        field(11; "Week Day"; Option)
        {
            Caption = 'Week Day';
            OptionCaption = ' ,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            OptionMembers = " ",Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;

            trigger OnValidate()
            begin
                UpdateDayName;
            end;
        }
        field(12; "Day Status"; Option)
        {
            Caption = 'Day Status';
            OptionCaption = ' ,Weekend,Holiday';
            OptionMembers = " ",Weekend,Holiday;
        }
        field(13; "Time Activity Code"; Code[10])
        {
            Caption = 'Time Activity Code';
            TableRelation = "Time Activity";
        }
        field(14; "Night Hours"; Decimal)
        {
            Caption = 'Night Hours';

            trigger OnValidate()
            begin
                GetCalendar;
                if PayrollCalendar."Shift Days" = 0 then
                    Error(Text001, FieldCaption("Night Hours"));
            end;
        }
    }

    keys
    {
        key(Key1; "Calendar Code", Year, "Period Type", "Period No.", "Day No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1 can not be greater than %2.';
        Text001: Label 'You can enter %1 in shift calendar only.';
        Text002: Label 'Wrong day of the %1.';
        PayrollCalendar: Record "Payroll Calendar";
        LocMgt: Codeunit "Localisation Management";
        Date: Date;

    [Scope('OnPrem')]
    procedure UpdateDayName()
    begin
        case "Period Type" of
            "Period Type"::Month:
                "Week Day" := "Week Day"::" ";
            "Period Type"::Week:
                "Week Day" := "Day No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCalendar()
    begin
        TestField("Calendar Code");
        if "Calendar Code" <> PayrollCalendar.Code then
            PayrollCalendar.Get("Calendar Code");
    end;

    [Scope('OnPrem')]
    procedure GetMaxShiftDay(CalendarCode: Code[10]): Integer
    var
        PayrollCalendarSetup: Record "Payroll Calendar Setup";
        MaxShiftDay: Integer;
    begin
        PayrollCalendarSetup.SetRange("Calendar Code", CalendarCode);

        MaxShiftDay := 0;
        if PayrollCalendarSetup.FindSet then
            repeat
                if PayrollCalendarSetup."Day No." > MaxShiftDay then
                    MaxShiftDay := PayrollCalendarSetup."Day No.";
            until PayrollCalendarSetup.Next = 0;

        exit(MaxShiftDay);
    end;
}

