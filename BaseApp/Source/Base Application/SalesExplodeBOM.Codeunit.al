codeunit 63 "Sales-Explode BOM"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("Quantity Shipped", 0);
        TestField("Return Qty. Received", 0);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        ReservMgt.SetReservSource(Rec);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(true, 0);

        if "Purch. Order Line No." <> 0 then
            Error(
              Text000,
              "Purchase Order No.");
        if "Job Contract Entry No." <> 0 then begin
            TestField("Job No.", '');
            TestField("Job Contract Entry No.", 0);
        end;
        SalesHeader.Get("Document Type", "Document No.");
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        FromBOMComp.SetRange("Parent Item No.", "No.");
        NoOfBOMComp := FromBOMComp.Count();

        OnBeforeConfirmExplosion(Rec, Selection, HideDialog);

        if not HideDialog then begin
            if NoOfBOMComp = 0 then
                Error(Text001, "No.");

            Selection := StrMenu(Text004, 2);
            if Selection = 0 then
                exit;
        end else
            Selection := 2;

        OnAfterConfirmExplosion(Rec, Selection, HideDialog);

        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice] then begin
            ToSalesLine := Rec;
            FromBOMComp.SetRange(Type, FromBOMComp.Type::Item);
            FromBOMComp.SetFilter("No.", '<>%1', '');
            OnAfterFromBOMCompSetFilters(FromBOMComp, Rec);
            if FromBOMComp.FindSet then
                repeat
                    FromBOMComp.TestField(Type, FromBOMComp.Type::Item);
                    OnBeforeCopyFromBOMToSalesLine(ToSalesLine, FromBOMComp);
                    Item.Get(FromBOMComp."No.");
                    ToSalesLine."Line No." := 0;
                    ToSalesLine."No." := FromBOMComp."No.";
                    ToSalesLine."Variant Code" := FromBOMComp."Variant Code";
                    ToSalesLine."Unit of Measure Code" := FromBOMComp."Unit of Measure Code";
                    ToSalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, FromBOMComp."Unit of Measure Code");
                    ToSalesLine."Outstanding Quantity" := Round("Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision);
                    if ToSalesLine."Outstanding Quantity" > 0 then
                        if ItemCheckAvail.SalesLineCheck(ToSalesLine) then
                            ItemCheckAvail.RaiseUpdateInterruptedError;
                until FromBOMComp.Next = 0;
        end;

        if "BOM Item No." = '' then
            BOMItemNo := "No."
        else
            BOMItemNo := "BOM Item No.";

        ToSalesLine := Rec;
        ToSalesLine.Init();
        ToSalesLine.Description := Description;
        ToSalesLine."Description 2" := "Description 2";
        ToSalesLine."BOM Item No." := BOMItemNo;
        OnBeforeToSalesLineModify(ToSalesLine, Rec);
        ToSalesLine.Modify();

        if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then
            TransferExtendedText.InsertSalesExtText(ToSalesLine);

        ExplodeBOMCompLines(Rec);
    end;

    var
        Text000: Label 'The BOM cannot be exploded on the sales lines because it is associated with purchase order %1.';
        Text001: Label 'Item %1 is not a BOM.';
        Text003: Label 'There is not enough space to explode the BOM.';
        Text004: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';
        ToSalesLine: Record "Sales Line";
        FromBOMComp: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        ItemTranslation: Record "Item Translation";
        Item: Record Item;
        Resource: Record Resource;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReservMgt: Codeunit "Reservation Management";
        BOMItemNo: Code[20];
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        Selection: Integer;

    local procedure ExplodeBOMCompLines(SalesLine: Record "Sales Line")
    var
        PreviousSalesLine: Record "Sales Line";
        InsertLinesBetween: Boolean;
    begin
        with SalesLine do begin
            ToSalesLine.Reset();
            ToSalesLine.SetRange("Document Type", "Document Type");
            ToSalesLine.SetRange("Document No.", "Document No.");
            ToSalesLine := SalesLine;
            NextLineNo := "Line No.";
            InsertLinesBetween := false;
            if ToSalesLine.Find('>') then
                if ToSalesLine."Attached to Line No." = "Line No." then begin
                    ToSalesLine.SetRange("Attached to Line No.", "Line No.");
                    ToSalesLine.FindLast;
                    ToSalesLine.SetRange("Attached to Line No.");
                    NextLineNo := ToSalesLine."Line No.";
                    InsertLinesBetween := ToSalesLine.Find('>');
                end else
                    InsertLinesBetween := true;
            if InsertLinesBetween then
                LineSpacing := (ToSalesLine."Line No." - NextLineNo) div (1 + NoOfBOMComp)
            else
                LineSpacing := 10000;
            if LineSpacing = 0 then
                Error(Text003);

            FromBOMComp.Reset();
            FromBOMComp.SetRange("Parent Item No.", "No.");
            FromBOMComp.FindSet;
            repeat
                ToSalesLine.Init();
                NextLineNo := NextLineNo + LineSpacing;
                ToSalesLine."Line No." := NextLineNo;

                case FromBOMComp.Type of
                    FromBOMComp.Type::" ":
                        ToSalesLine.Type := ToSalesLine.Type::" ";
                    FromBOMComp.Type::Item:
                        ToSalesLine.Type := ToSalesLine.Type::Item;
                    FromBOMComp.Type::Resource:
                        ToSalesLine.Type := ToSalesLine.Type::Resource;
                end;
                if ToSalesLine.Type <> ToSalesLine.Type::" " then begin
                    FromBOMComp.TestField("No.");
                    ToSalesLine.Validate("No.", FromBOMComp."No.");
                    if SalesHeader."Location Code" <> "Location Code" then
                        ToSalesLine.Validate("Location Code", "Location Code");
                    if FromBOMComp."Variant Code" <> '' then
                        ToSalesLine.Validate("Variant Code", FromBOMComp."Variant Code");
                    if ToSalesLine.Type = ToSalesLine.Type::Item then begin
                        ToSalesLine."Drop Shipment" := "Drop Shipment";
                        Item.Get(FromBOMComp."No.");
                        ToSalesLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                        ToSalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, ToSalesLine."Unit of Measure Code");
                        ToSalesLine.Validate(Quantity,
                          Round(
                            "Quantity (Base)" * FromBOMComp."Quantity per" *
                            UOMMgt.GetQtyPerUnitOfMeasure(
                              Item, ToSalesLine."Unit of Measure Code") / ToSalesLine."Qty. per Unit of Measure",
                            UOMMgt.QtyRndPrecision));
                    end else
                        if ToSalesLine.Type = ToSalesLine.Type::Resource then begin
                            Resource.Get(FromBOMComp."No.");
                            ToSalesLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                            ToSalesLine."Qty. per Unit of Measure" :=
                              UOMMgt.GetResQtyPerUnitOfMeasure(Resource, ToSalesLine."Unit of Measure Code");
                            ToSalesLine.Validate(Quantity,
                              Round(
                                "Quantity (Base)" * FromBOMComp."Quantity per" *
                                UOMMgt.GetResQtyPerUnitOfMeasure(
                                  Resource, ToSalesLine."Unit of Measure Code") / ToSalesLine."Qty. per Unit of Measure",
                                UOMMgt.QtyRndPrecision));
                        end else
                            ToSalesLine.Validate(Quantity, "Quantity (Base)" * FromBOMComp."Quantity per");

                    if SalesHeader."Shipment Date" <> "Shipment Date" then
                        ToSalesLine.Validate("Shipment Date", "Shipment Date");
                end;
                if SalesHeader."Language Code" = '' then
                    ToSalesLine.Description := FromBOMComp.Description
                else
                    if not ItemTranslation.Get(FromBOMComp."No.", FromBOMComp."Variant Code", SalesHeader."Language Code") then
                        ToSalesLine.Description := FromBOMComp.Description;

                ToSalesLine."BOM Item No." := BOMItemNo;

                OnInsertOfExplodedBOMLineToSalesLine(ToSalesLine, SalesLine, FromBOMComp);

                ToSalesLine.Insert();

                ToSalesLine.Validate("Qty. to Assemble to Order");

                if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine.Reserve = ToSalesLine.Reserve::Always) then
                    ToSalesLine.AutoReserve;

                if Selection = 1 then begin
                    ToSalesLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                    ToSalesLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                    ToSalesLine."Dimension Set ID" := "Dimension Set ID";
                    ToSalesLine.Modify();
                end;

                if PreviousSalesLine."Document No." <> '' then
                    if TransferExtendedText.SalesCheckIfAnyExtText(PreviousSalesLine, false) then
                        TransferExtendedText.InsertSalesExtText(PreviousSalesLine);

                PreviousSalesLine := ToSalesLine;
            until FromBOMComp.Next = 0;

            if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then
                TransferExtendedText.InsertSalesExtText(ToSalesLine);
        end;

        OnAfterExplodeBOMCompLines(SalesLine, Selection);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromBOMCompSetFilters(var BOMComponent: Record "BOM Component"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmExplosion(var SalesLine: Record "Sales Line"; var Selection: Integer; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExplodeBOMCompLines(var SalesLine: Record "Sales Line"; Selection: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmExplosion(var SalesLine: Record "Sales Line"; var Selection: Integer; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromBOMToSalesLine(var SalesLine: Record "Sales Line"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToSalesLineModify(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOfExplodedBOMLineToSalesLine(var ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; BOMComponent: Record "BOM Component")
    begin
    end;
}

