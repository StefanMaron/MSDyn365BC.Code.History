codeunit 5879 "Phys. Invt. Order-Finish (Y/N)"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader.Copy(Rec);

        if Confirm(ConfirmFinishQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Finish", PhysInvtOrderHeader);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmFinishQst: Label 'Do you want to finish the order?';
}

