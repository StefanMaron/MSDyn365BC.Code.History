codeunit 71 "Purch.-Disc. (Yes/No)"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        GLSetup.Get();
        if GLSetup."Payment Discount Type" <> GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines" then begin
            if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", Rec);
        end else begin
            if ConfirmManagement.GetResponseOrDefault(Text1100000, true) then
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", Rec);
        end;
    end;

    var
        Text000: Label 'Do you want to calculate the invoice discount?';
        Text1100000: Label 'Do you want to calculate the invoice discount and payment discount?';
        GLSetup: Record "General Ledger Setup";
}

