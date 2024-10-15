codeunit 12453 "Release Item Document"
{
    TableNo = "Item Document Header";

    trigger OnRun()
    begin
        if Status = Status::Released then
            exit;

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then
            TestField("Location Code");
        TestField(Status, Status::Open);

        ItemDocLine.SetRange("Document Type", "Document Type");
        ItemDocLine.SetRange("Document No.", "No.");
        ItemDocLine.SetFilter(Quantity, '<>0');
        if not ItemDocLine.FindFirst then
            Error(Text002, "No.");
        ItemDocLine.Reset();

        Validate(Status, Status::Released);
        Modify;
    end;

    var
        Text002: Label 'There is nothing to release for item document %1.';
        ItemDocLine: Record "Item Document Line";
        InvtSetup: Record "Inventory Setup";

    [Scope('OnPrem')]
    procedure Reopen(var ItemDocHeader: Record "Item Document Header")
    begin
        with ItemDocHeader do begin
            if Status = Status::Open then
                exit;
            Validate(Status, Status::Open);
            Modify;
        end;
    end;
}

