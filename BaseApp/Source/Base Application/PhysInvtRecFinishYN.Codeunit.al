codeunit 5875 "Phys. Invt. Rec.-Finish (Y/N)"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader.Copy(Rec);

        if Confirm(ConfirmFinishQst, false) then
            CODEUNIT.Run(CODEUNIT::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);

        Rec := PhysInvtRecordHeader;
    end;

    var
        ConfirmFinishQst: Label 'Do you want to finish the recording?';
}

