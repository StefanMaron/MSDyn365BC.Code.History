codeunit 5883 "Phys. Invt. Order-Post (Y/N)"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader.Copy(Rec);

        if Confirm(ConfirmPostQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Order-Post", PhysInvtOrderHeader);

        Rec := PhysInvtOrderHeader;
    end;

    var
        ConfirmPostQst: Label 'Do you want to post the order?';
}

