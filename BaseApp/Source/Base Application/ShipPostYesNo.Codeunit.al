codeunit 10011 "Ship-Post (Yes/No)"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code;
        Rec := SalesHeader;
    end;

    var
        Text1020001: Label 'Do you want to ship the %1?';
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";

    local procedure "Code"()
    begin
        with SalesHeader do
            if "Document Type" = "Document Type"::Order then begin
                if not Confirm(Text1020001, false, "Document Type") then begin
                    "Shipping No." := '-1';
                    exit;
                end;
                Ship := true;
                Invoice := false;
                SalesPost.Run(SalesHeader);
            end;
    end;
}

