codeunit 5951 "Service-Disc. (Yes/No)"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.Copy(Rec);
        with ServiceLine do
            if ConfirmManagement.GetResponseOrDefault(Text000, true) then
                CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
        Rec := ServiceLine;
    end;

    var
        ServiceLine: Record "Service Line";

        Text000: Label 'Do you want to calculate the invoice discount?';
}

