codeunit 17367 "Staff List Order-Post (Y/N)"
{
    TableNo = "Staff List Order Header";

    trigger OnRun()
    begin
        StaffOrderHeader.Copy(Rec);
        Code;
        Rec := StaffOrderHeader;
    end;

    var
        Text000: Label 'Do you want to post %1?';
        Text001: Label 'Staff List Order %1 was successfully posted.';
        StaffOrderHeader: Record "Staff List Order Header";
        StaffOrderPost: Codeunit "Staff List Order-Post";

    local procedure "Code"()
    begin
        with StaffOrderHeader do begin
            if not Confirm(Text000, false, TableCaption) then
                exit;
            StaffOrderPost.Run(StaffOrderHeader);
            Message(Text001, "No.");
        end;
    end;
}

