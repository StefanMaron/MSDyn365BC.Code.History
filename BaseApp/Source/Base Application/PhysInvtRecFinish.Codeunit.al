codeunit 5876 "Phys. Invt. Rec.-Finish"
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
        FinishingLinesMsg: Label 'Finishing lines              #2######', Comment = '%2 = counter';
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        NoLinesRecordedErr: Label 'There are no Lines recorded.';
        Window: Dialog;
        ErrorText: Text[250];
        LineCount: Integer;
        NextOrderLineNo: Integer;
        NoOfOrderLines: Integer;

    procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        InvtSetup.Get();
        with PhysInvtRecordHeader do begin
            TestField("Order No.");
            TestField("Recording No.");
            TestField(Status, Status::Open);

            PhysInvtRecordLine.Reset();
            PhysInvtRecordLine.SetRange("Order No.", "Order No.");
            PhysInvtRecordLine.SetRange("Recording No.", "Recording No.");
            PhysInvtRecordLine.SetFilter("Item No.", '<>%1', '');
            if not PhysInvtRecordLine.Find('-') then
                Error(NoLinesRecordedErr);

            Window.Open(
              '#1#################################\\' + FinishingLinesMsg);
            Window.Update(1, StrSubstNo('%1 %2', TableCaption, "Order No."));

            PhysInvtOrderHeader.LockTable();
            PhysInvtOrderLine.LockTable();
            PhysInvtOrderLine.Reset();
            PhysInvtOrderLine.SetRange("Document No.", "Order No.");
            if PhysInvtOrderLine.FindLast then
                NextOrderLineNo := PhysInvtOrderLine."Line No." + 10000
            else
                NextOrderLineNo := 10000;

            PhysInvtOrderHeader.Get("Order No.");

            LineCount := 0;
            PhysInvtRecordLine.Reset();
            PhysInvtRecordLine.SetRange("Order No.", "Order No.");
            PhysInvtRecordLine.SetRange("Recording No.", "Recording No.");
            if PhysInvtRecordLine.Find('-') then
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(2, LineCount);

                    if not PhysInvtRecordLine.EmptyLine then begin
                        PhysInvtRecordLine.TestField("Item No.");
                        PhysInvtRecordLine.TestField(Recorded, true);
                        if PhysInvtRecordLine."Location Code" <> '' then begin
                            Location.Get(PhysInvtRecordLine."Location Code");
                            Location.TestField("Directed Put-away and Pick", false);
                            if Location."Bin Mandatory" then
                                PhysInvtRecordLine.TestField("Bin Code")
                            else
                                PhysInvtRecordLine.TestField("Bin Code", '');
                        end else begin
                            if InvtSetup."Location Mandatory" then
                                PhysInvtRecordLine.TestField("Location Code");
                            PhysInvtRecordLine.TestField("Bin Code", '');
                        end;
                        IsHandled := false;
                        OnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtRecordLine, NoOfOrderLines, ErrorText, IsHandled);
                        if not IsHandled then
                            NoOfOrderLines :=
                              PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                                PhysInvtRecordLine."Item No.", PhysInvtRecordLine."Variant Code",
                                PhysInvtRecordLine."Location Code", PhysInvtRecordLine."Bin Code",
                                ErrorText, PhysInvtOrderLine);
                        if NoOfOrderLines > 1 then
                            Error(ErrorText);
                        if NoOfOrderLines = 0 then begin
                            if not "Allow Recording Without Order" then
                                Error(ErrorText);
                            PhysInvtOrderLine.Init();
                            PhysInvtOrderLine."Document No." := "Order No.";
                            PhysInvtOrderLine."Line No." := NextOrderLineNo;
                            PhysInvtOrderLine.Validate("Item No.", PhysInvtRecordLine."Item No.");
                            PhysInvtOrderLine.Validate("Variant Code", PhysInvtRecordLine."Variant Code");
                            PhysInvtOrderLine.Validate("Location Code", PhysInvtRecordLine."Location Code");
                            PhysInvtOrderLine.Validate("Bin Code", PhysInvtRecordLine."Bin Code");
                            PhysInvtOrderLine."Recorded Without Order" := true;
                            OnBeforePhysInvtOrderLineInsert(PhysInvtOrderLine, PhysInvtRecordLine);
                            PhysInvtOrderLine.CreateDim(DATABASE::Item, PhysInvtOrderLine."Item No.");
                            PhysInvtOrderLine.Insert(true);
                            NextOrderLineNo := NextOrderLineNo + 10000;
                        end;

                        PhysInvtRecordLine."Order Line No." := PhysInvtOrderLine."Line No.";
                        PhysInvtRecordLine."Recorded Without Order" := PhysInvtOrderLine."Recorded Without Order";
                        PhysInvtRecordLine.Modify();

                        PhysInvtOrderLine."Qty. Recorded (Base)" += PhysInvtRecordLine."Quantity (Base)";
                        PhysInvtOrderLine."No. Finished Rec.-Lines" += 1;
                        PhysInvtOrderLine."On Recording Lines" := PhysInvtOrderLine."No. Finished Rec.-Lines" <> 0;
                        OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, PhysInvtRecordLine);
                        PhysInvtOrderLine.Modify();
                    end;
                until PhysInvtRecordLine.Next = 0;

            Status := Status::Finished;
            Modify;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSamePhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var NoOfOrderLines: Integer; var ErrorText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineInsert(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
}

