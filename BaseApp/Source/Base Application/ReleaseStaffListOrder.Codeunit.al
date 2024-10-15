codeunit 17366 "Release Staff List Order"
{
    TableNo = "Staff List Order Header";

    trigger OnRun()
    begin
        if Status = Status::Released then
            exit;

        HRSetup.Get;
        HRSetup.TestField("Use Staff List Change Orders", true);

        TestField("No.");
        TestField("Document Date");
        TestField("Posting Date");
        TestField("HR Manager No.");
        TestField("Chief Accountant No.");
        TestField("HR Order No.");
        TestField("HR Order Date");

        StaffListOrderLine.SetRange("Document No.", "No.");
        if StaffListOrderLine.IsEmpty then
            Error(Text001, "No.");

        Status := Status::Released;
        Modify(true);
    end;

    var
        StaffListOrderLine: Record "Staff List Order Line";
        Text001: Label 'There is nothing to release for %1.';
        HRSetup: Record "Human Resources Setup";

    [Scope('OnPrem')]
    procedure Reopen(var StaffChangeHeader: Record "Staff List Order Header")
    begin
        with StaffChangeHeader do begin
            if Status = Status::Open then
                exit;

            HRSetup.Get;
            HRSetup.TestField("Use Staff List Change Orders", true);

            Status := Status::Open;
            Modify(true);
        end;
    end;
}

