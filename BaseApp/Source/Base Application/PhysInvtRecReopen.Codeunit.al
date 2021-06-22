codeunit 5878 "Phys. Invt. Rec.-Reopen"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    begin
        PhysInvtRecordHeader.Copy(Rec);
        Code;
        Rec := PhysInvtRecordHeader;

        OnAfterOnRun(Rec);
    end;

    var
        ReopeningLinesMsg: Label 'Reopening lines              #2######', Comment = '%2 = counter';
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        Window: Dialog;
        LineCount: Integer;

    procedure "Code"()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        with PhysInvtRecordHeader do begin
            TestField("Order No.");
            TestField("Recording No.");
            TestField(Status, Status::Finished);

            Window.Open(
              '#1#################################\\' + ReopeningLinesMsg);
            Window.Update(1, StrSubstNo('%1 %2', TableCaption, "Order No."));

            PhysInvtOrderHeader.Get("Order No.");
            PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);

            LineCount := 0;
            PhysInvtRecordLine.Reset();
            PhysInvtRecordLine.SetRange("Order No.", "Order No.");
            PhysInvtRecordLine.SetRange("Recording No.", "Recording No.");
            if PhysInvtRecordLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);
                    if PhysInvtRecordLine."Item No." <> '' then begin
                        PhysInvtOrderLine.Get(PhysInvtRecordLine."Order No.", PhysInvtRecordLine."Order Line No.");
                        PhysInvtOrderLine."Qty. Recorded (Base)" -= PhysInvtRecordLine."Quantity (Base)";
                        PhysInvtOrderLine."No. Finished Rec.-Lines" -= 1;
                        PhysInvtOrderLine."On Recording Lines" := PhysInvtOrderLine."No. Finished Rec.-Lines" <> 0;
                        OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, PhysInvtRecordLine);
                        PhysInvtOrderLine.Modify();

                        PhysInvtRecordLine."Order Line No." := 0;
                        PhysInvtRecordLine."Recorded Without Order" := false;
                        PhysInvtRecordLine.Modify();
                    end;
                until PhysInvtRecordLine.Next = 0;

            Status := Status::Open;
            Modify;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
}

