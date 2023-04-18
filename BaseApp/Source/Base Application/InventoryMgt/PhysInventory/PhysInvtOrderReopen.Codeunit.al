codeunit 5882 "Phys. Invt. Order-Reopen"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        PhysInvtOrderHeader.Copy(Rec);
        Code();
        Rec := PhysInvtOrderHeader;

        OnAfterOnRun(Rec);
    end;

    var
        ReopeningLinesMsg: Label 'Reopening lines              #2######', Comment = '%2 = counter';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        ReservEntry: Record "Reservation Entry";
        Window: Dialog;
        LineCount: Integer;

    procedure "Code"()
    begin
        with PhysInvtOrderHeader do begin
            TestField("No.");
            TestField(Status, Status::Finished);

            Window.Open(
              '#1#################################\\' + ReopeningLinesMsg);
            Window.Update(1, StrSubstNo('%1 %2', TableCaption(), "No."));

            LockTable();
            PhysInvtOrderLine.LockTable();

            LineCount := 0;
            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetRange("Document No.", "No.");
            if PhysInvtOrderLine.Find('-') then
                repeat
                    if not PhysInvtOrderLine.EmptyLine() then begin
                        LineCount := LineCount + 1;
                        Window.Update(2, LineCount);

                        ReservEntry.Reset();
                        ReservEntry.SetSourceFilter(
                          DATABASE::"Phys. Invt. Order Line", 0, PhysInvtOrderLine."Document No.", PhysInvtOrderLine."Line No.", false);
                        ReservEntry.SetSourceFilter('', 0);
                        ReservEntry.DeleteAll();

                        PhysInvtOrderLine."Pos. Qty. (Base)" := 0;
                        PhysInvtOrderLine."Neg. Qty. (Base)" := 0;
                        PhysInvtOrderLine."Quantity (Base)" := 0;
                        PhysInvtOrderLine."Entry Type" := PhysInvtOrderLine."Entry Type"::" ";
                        OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine);
                        PhysInvtOrderLine.Modify();
                    end;
                until PhysInvtOrderLine.Next() = 0;

            Status := Status::Open;
            Modify();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line");
    begin
    end;
}

