codeunit 3051 DotNet_RegexOptions
{

    trigger OnRun()
    begin
    end;

    var
        DotNetRegexOptions: DotNet RegexOptions;

    procedure Compiled(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.Compiled;
        exit(DotNetRegexOptions);
    end;

    procedure CultureInvariant(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.CultureInvariant;
        exit(DotNetRegexOptions);
    end;

    procedure ECMAScript(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.ECMAScript;
        exit(DotNetRegexOptions);
    end;

    procedure ExplicitCapture(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.ExplicitCapture;
        exit(DotNetRegexOptions);
    end;

    procedure IgnoreCase(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.IgnoreCase;
        exit(DotNetRegexOptions);
    end;

    procedure IgnorePatternWhitespace(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.IgnorePatternWhitespace;
        exit(DotNetRegexOptions);
    end;

    procedure Multiline(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.Multiline;
        exit(DotNetRegexOptions);
    end;

    procedure "None"(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.None;
        exit(DotNetRegexOptions);
    end;

    procedure RightToLeft(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.RightToLeft;
        exit(DotNetRegexOptions);
    end;

    procedure Singleline(): Integer
    begin
        DotNetRegexOptions := DotNetRegexOptions.Singleline;
        exit(DotNetRegexOptions);
    end;

    procedure ToString(): Text
    begin
        exit(DotNetRegexOptions.ToString());
    end;

    procedure ToInteger(): Integer
    begin
        exit(DotNetRegexOptions);
    end;

    procedure FromInteger(Value: Integer)
    begin
        DotNetRegexOptions := Value;
    end;

    procedure IsDotNetNull(): Boolean
    begin
        exit(IsNull(DotNetRegexOptions));
    end;

    [Scope('OnPrem')]
    procedure GetRegexOptions(var DotNetRegexOptions2: DotNet RegexOptions)
    begin
        DotNetRegexOptions2 := DotNetRegexOptions;
    end;

    [Scope('OnPrem')]
    procedure SetRegexOptions(var DotNetRegexOptions2: DotNet RegexOptions)
    begin
        DotNetRegexOptions := DotNetRegexOptions2;
    end;
}

