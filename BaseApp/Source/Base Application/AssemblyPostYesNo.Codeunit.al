codeunit 901 "Assembly-Post (Yes/No)"
{
    TableNo = "Assembly Header";

    trigger OnRun()
    begin
        AssemblyHeader.Copy(Rec);
        Code;
        Rec := AssemblyHeader;
    end;

    var
        AssemblyHeader: Record "Assembly Header";
        Text000: Label 'Do you want to post the %1?';

    local procedure "Code"()
    begin
        with AssemblyHeader do begin
            if not Confirm(Text000, false, "Document Type") then
                exit;

            CODEUNIT.Run(CODEUNIT::"Assembly-Post", AssemblyHeader);
        end;
    end;
}

