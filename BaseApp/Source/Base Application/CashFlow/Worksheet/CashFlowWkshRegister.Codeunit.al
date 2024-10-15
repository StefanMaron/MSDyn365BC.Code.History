namespace Microsoft.CashFlow.Worksheet;

codeunit 843 "Cash Flow Wksh. - Register"
{
    TableNo = "Cash Flow Worksheet Line";

    trigger OnRun()
    begin
        CFWkshLine.Copy(Rec);
        Code();
        Rec.Copy(CFWkshLine);
    end;

    var
        CFWkshLine: Record "Cash Flow Worksheet Line";

#pragma warning disable AA0074
        Text1001: Label 'Do you want to register the worksheet lines?';
        Text1002: Label 'There is nothing to register.';
        Text1003: Label 'The worksheet lines were successfully registered.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        if not Confirm(Text1001) then
            exit;

        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch", CFWkshLine);

        if CFWkshLine."Line No." = 0 then
            Message(Text1002)
        else
            Message(Text1003);

        if not CFWkshLine.Find('=><') then begin
            CFWkshLine.Reset();
            CFWkshLine."Line No." := 1;
        end;
    end;
}

