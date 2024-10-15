codeunit 61 "Sales-Disc. (Yes/No)"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Copy(Rec);
        GLSetup.Get();
        with SalesLine do begin
            if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then begin
                if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                    CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            end else begin
                if ConfirmManagement.GetResponseOrDefault(Text1100000, true) then
                    CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            end;
        end;

        Rec := SalesLine;
    end;

    var
        Text000: Label 'Do you want to calculate the invoice discount?';
        SalesLine: Record "Sales Line";
        Text1100000: Label 'Do you want to calculate the invoice discount and payment discount?';
        GLSetup: Record "General Ledger Setup";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

