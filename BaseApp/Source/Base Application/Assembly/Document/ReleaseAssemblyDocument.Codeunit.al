namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Setup;

codeunit 903 "Release Assembly Document"
{
    Permissions = TableData "Assembly Header" = rm,
                  TableData "Assembly Line" = r;
    TableNo = "Assembly Header";

    trigger OnRun()
    var
        AssemblyLine: Record "Assembly Line";
        InvtSetup: Record "Inventory Setup";
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
    begin
        if Rec.Status = Rec.Status::Released then
            exit;

        OnBeforeReleaseAssemblyDoc(Rec);

        AssemblyLine.SetRange("Document Type", Rec."Document Type");
        AssemblyLine.SetRange("Document No.", Rec."No.");
        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        AssemblyLine.SetFilter(Quantity, '<>0');
        if not AssemblyLine.Find('-') then
            Error(Text001, Rec."Document Type", Rec."No.");

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then begin
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
            if AssemblyLine.FindSet() then
                repeat
                    if AssemblyLine.IsInventoriableItem() then
                        AssemblyLine.TestField("Location Code");
                until AssemblyLine.Next() = 0;
        end;

        Rec.Status := Rec.Status::Released;
        Rec.Modify();

        if Rec."Document Type" = Rec."Document Type"::Order then
            WhseAssemblyRelease.Release(Rec);

        OnAfterReleaseAssemblyDoc(Rec);
    end;

    var
        Text001: Label 'There is nothing to release for %1 %2.', Comment = '%1 = Document Type, %2 = No.';

    procedure Reopen(var AssemblyHeader: Record "Assembly Header")
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
    begin
        if AssemblyHeader.Status = AssemblyHeader.Status::Open then
            exit;

        OnBeforeReopenAssemblyDoc(AssemblyHeader);

        AssemblyHeader.Status := AssemblyHeader.Status::Open;
        AssemblyHeader.Modify(true);

        if AssemblyHeader."Document Type" = AssemblyHeader."Document Type"::Order then
            WhseAssemblyRelease.Reopen(AssemblyHeader);

        OnAfterReopenAssemblyDoc(AssemblyHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseAssemblyDoc(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenAssemblyDoc(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseAssemblyDoc(var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenAssemblyDoc(var AssemblyHeader: Record "Assembly Header")
    begin
    end;
}

