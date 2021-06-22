codeunit 843 "Cash Flow Wksh. - Register"
{
    TableNo = "Cash Flow Worksheet Line";

    trigger OnRun()
    begin
        CFWkshLine.Copy(Rec);
        Code;
        Copy(CFWkshLine);
    end;

    var
        Text1001: Label 'Do you want to register the worksheet lines?';
        Text1002: Label 'There is nothing to register.';
        Text1003: Label 'The worksheet lines were successfully registered.';
        CFWkshLine: Record "Cash Flow Worksheet Line";

    local procedure "Code"()
    begin
        with CFWkshLine do begin
            if not Confirm(Text1001) then
                exit;

            CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch", CFWkshLine);

            if "Line No." = 0 then
                Message(Text1002)
            else
                Message(Text1003);

            if not Find('=><') then begin
                Reset;
                "Line No." := 1;
            end;
        end;
    end;
}

