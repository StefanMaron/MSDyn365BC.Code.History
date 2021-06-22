codeunit 3003 DotNet_DateTime
{

    trigger OnRun()
    begin
    end;

    var
        DotNetDateTime: DotNet DateTime;

    procedure CreateUTC(Year: Integer; Month: Integer; Day: Integer; Hour: Integer; Minute: Integer; Second: Integer)
    var
        DotNet_DateTimeKind: DotNet DateTimeKind;
    begin
        DotNet_DateTimeKind := DotNet_DateTimeKind.Utc;
        DotNetDateTime := DotNetDateTime.DateTime(Year, Month, Day, Hour, Minute, Second, DotNet_DateTimeKind);
    end;

    procedure TryParse(DateTimeText: Text; DotNet_CultureInfo: Codeunit DotNet_CultureInfo; DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles): Boolean
    var
        DotNetCultureInfo: DotNet CultureInfo;
        DotNetDateTimeStyles: DotNet DateTimeStyles;
    begin
        DateTime(0);
        DotNet_CultureInfo.GetCultureInfo(DotNetCultureInfo);
        DotNet_DateTimeStyles.GetDateTimeStyles(DotNetDateTimeStyles);
        exit(DotNetDateTime.TryParse(DateTimeText, DotNetCultureInfo, DotNetDateTimeStyles, DotNetDateTime))
    end;

    procedure TryParseExact(DateTimeText: Text; Format: Text; DotNet_CultureInfo: Codeunit DotNet_CultureInfo; DotNet_DateTimeStyles: Codeunit DotNet_DateTimeStyles): Boolean
    var
        DotNetCultureInfo: DotNet CultureInfo;
        DotNetDateTimeStyles: DotNet DateTimeStyles;
    begin
        DateTime(0);
        DotNet_CultureInfo.GetCultureInfo(DotNetCultureInfo);
        DotNet_DateTimeStyles.GetDateTimeStyles(DotNetDateTimeStyles);
        exit(DotNetDateTime.TryParseExact(DateTimeText, Format, DotNetCultureInfo, DotNetDateTimeStyles, DotNetDateTime))
    end;

    procedure "DateTime"(IntegerDateTime: Integer)
    begin
        DotNetDateTime := DotNetDateTime.DateTime(IntegerDateTime)
    end;

    procedure "DateTime"(Year: Integer; Month: Integer; Day: Integer)
    begin
        DotNetDateTime := DotNetDateTime.DateTime(Year, Month, Day)
    end;

    procedure Day(): Integer
    begin
        exit(DotNetDateTime.Day)
    end;

    procedure Month(): Integer
    begin
        exit(DotNetDateTime.Month)
    end;

    procedure Year(): Integer
    begin
        exit(DotNetDateTime.Year)
    end;

    procedure Hour(): Integer
    begin
        exit(DotNetDateTime.Hour)
    end;

    procedure Minute(): Integer
    begin
        exit(DotNetDateTime.Minute)
    end;

    procedure Second(): Integer
    begin
        exit(DotNetDateTime.Second)
    end;

    procedure Millisecond(): Integer
    begin
        exit(DotNetDateTime.Millisecond)
    end;

    procedure IsDaylightSavingTim(): Boolean;
    begin
        exit(DotNetDateTime.IsDaylightSavingTime);
    end;

    procedure ToString(DotNet_DateTimeFormatInfo: Codeunit DotNet_DateTimeFormatInfo): Text
    var
        DotNetDateTimeFormatInfo: DotNet DateTimeFormatInfo;
    begin
        DotNet_DateTimeFormatInfo.GetDateTimeFormatInfo(DotNetDateTimeFormatInfo);
        exit(DotNetDateTime.ToString('d', DotNetDateTimeFormatInfo))
    end;

    procedure ToDateTime(): DateTime
    begin
        exit(DotNetDateTime);
    end;

    [Scope('OnPrem')]
    procedure GetDateTime(var DotNetDateTime2: DotNet DateTime)
    begin
        DotNetDateTime2 := DotNetDateTime
    end;

    [Scope('OnPrem')]
    procedure SetDateTime(DotNetDateTime2: DotNet DateTime)
    begin
        DotNetDateTime := DotNetDateTime2
    end;
}

