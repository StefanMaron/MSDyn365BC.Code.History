codeunit 5951 "Service-Disc. (Yes/No)"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.Copy(Rec);
        GLSetup.Get();
        with ServiceLine do begin
            if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then begin
                if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                    CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
            end else begin
                if Confirm(Text1100000, false) then
                    CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
            end;
        end;

        Rec := ServiceLine;
    end;

    var
        Text000: Label 'Do you want to calculate the invoice discount?';
        ServiceLine: Record "Service Line";
        GLSetup: Record "General Ledger Setup";
        Text1100000: Label 'Do you want to calculate the invoice discount and payment discount?';
}

