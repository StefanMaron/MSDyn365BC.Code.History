codeunit 903 "Release Assembly Document"
{
    Permissions = TableData "Assembly Header" = m,
                  TableData "Assembly Line" = r;
    TableNo = "Assembly Header";

    trigger OnRun()
    var
        AssemblyLine: Record "Assembly Line";
        InvtSetup: Record "Inventory Setup";
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
    begin
        if Status = Status::Released then
            exit;

        OnBeforeReleaseAssemblyDoc(Rec);

        AssemblyLine.SetRange("Document Type", "Document Type");
        AssemblyLine.SetRange("Document No.", "No.");
        AssemblyLine.SetFilter(Type, '<>%1', AssemblyLine.Type::" ");
        AssemblyLine.SetFilter(Quantity, '<>0');
        if not AssemblyLine.Find('-') then
            Error(Text001, "Document Type", "No.");

        InvtSetup.Get();
        if InvtSetup."Location Mandatory" then begin
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
            if AssemblyLine.FindSet then
                repeat
                    if AssemblyLine.IsInventoriableItem then
                        AssemblyLine.TestField("Location Code");
                until AssemblyLine.Next = 0;
        end;

        Status := Status::Released;
        Modify;

        if "Document Type" = "Document Type"::Order then
            WhseAssemblyRelease.Release(Rec);

        OnAfterReleaseAssemblyDoc(Rec);
    end;

    var
        Text001: Label 'There is nothing to release for %1 %2.', Comment = '%1 = Document Type, %2 = No.';

    procedure Reopen(var AssemblyHeader: Record "Assembly Header")
    var
        WhseAssemblyRelease: Codeunit "Whse.-Assembly Release";
    begin
        with AssemblyHeader do begin
            if Status = Status::Open then
                exit;

            OnBeforeReopenAssemblyDoc(AssemblyHeader);

            Status := Status::Open;
            Modify(true);

            if "Document Type" = "Document Type"::Order then
                WhseAssemblyRelease.Reopen(AssemblyHeader);

            OnAfterReopenAssemblyDoc(AssemblyHeader);
        end;
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

