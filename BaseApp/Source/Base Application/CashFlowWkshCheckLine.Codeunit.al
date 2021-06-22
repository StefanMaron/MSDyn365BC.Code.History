codeunit 845 "Cash Flow Wksh.- Check Line"
{

    trigger OnRun()
    begin
    end;

    procedure RunCheck(var CFWkshLine: Record "Cash Flow Worksheet Line")
    var
        CFAccount: Record "Cash Flow Account";
    begin
        with CFWkshLine do begin
            if EmptyLine then
                exit;

            TestField("Cash Flow Forecast No.");
            TestField("Cash Flow Account No.");
            TestField("Cash Flow Date");
            if "Source Type" = "Source Type"::"G/L Budget" then
                TestField("G/L Budget Name");
            if ("Cash Flow Account No." <> '') and CFAccount.Get("Cash Flow Account No.") then
                CFAccount.TestField(Blocked, false);
        end;
    end;
}

