codeunit 5855 "Release Invt. Document"
{
    TableNo = "Invt. Document Header";

    trigger OnRun()
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then
            Rec.TestField("Location Code");
        Rec.TestField(Status, Status::Open);

        InvtDocLine.SetRange("Document Type", Rec."Document Type");
        InvtDocLine.SetRange("Document No.", Rec."No.");
        InvtDocLine.SetFilter(Quantity, '<>0');
        if not InvtDocLine.FindFirst() then
            Error(NothingToReleaseErr, Rec."No.");
        InvtDocLine.Reset();

        Rec.Validate(Status, Rec.Status::Released);
        Rec.Modify();
    end;

    var
        InvtDocLine: Record "Invt. Document Line";
        InvtSetup: Record "Inventory Setup";
        NothingToReleaseErr: Label 'There is nothing to release for item document %1.', Comment = '%1 - document number';

    procedure Reopen(var InvtDocHeader: Record "Invt. Document Header")
    begin
        if InvtDocHeader.Status = InvtDocHeader.Status::Open then
            exit;
        InvtDocHeader.Validate(Status, InvtDocHeader.Status::Open);
        InvtDocHeader.Modify();
    end;
}
