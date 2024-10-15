namespace Microsoft.CashFlow.Worksheet;

using Microsoft.CashFlow.Account;

codeunit 845 "Cash Flow Wksh.- Check Line"
{

    trigger OnRun()
    begin
    end;

    procedure RunCheck(var CFWkshLine: Record "Cash Flow Worksheet Line")
    var
        CFAccount: Record "Cash Flow Account";
    begin
        if CFWkshLine.EmptyLine() then
            exit;

        CFWkshLine.TestField("Cash Flow Forecast No.");
        CFWkshLine.TestField("Cash Flow Account No.");
        CFWkshLine.TestField("Cash Flow Date");
        if CFWkshLine."Source Type" = CFWkshLine."Source Type"::"G/L Budget" then
            CFWkshLine.TestField("G/L Budget Name");
        if (CFWkshLine."Cash Flow Account No." <> '') and CFAccount.Get(CFWkshLine."Cash Flow Account No.") then
            CFAccount.TestField(Blocked, false);
    end;
}

