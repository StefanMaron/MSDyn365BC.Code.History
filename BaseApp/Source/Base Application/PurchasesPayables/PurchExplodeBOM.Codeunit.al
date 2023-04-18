codeunit 73 "Purch.-Explode BOM"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("Quantity Received", 0);
        TestField("Return Qty. Shipped", 0);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        if "Sales Order No." <> '' then
            Error(
              Text000,
              "Sales Order No.");

        PurchHeader.Get("Document Type", "Document No.");
        PurchHeader.TestField(Status, PurchHeader.Status::Open);
        FromBOMComp.SetRange("Parent Item No.", "No.");
        NoOfBOMComp := FromBOMComp.Count();
        if NoOfBOMComp = 0 then
            Error(
              Text001,
              "No.");

        Selection := GetSelection(Rec);
        if Selection = 0 then
            exit;

        ToPurchLine := Rec;
        ToPurchLine.Init();
        ToPurchLine.Description := Description;
        ToPurchLine."Description 2" := "Description 2";
        OnRunOnBeforeToPurchLineModify(ToPurchLine, Rec);
        ToPurchLine.Modify();

        if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then
            TransferExtendedText.InsertPurchExtText(ToPurchLine);

        ExplodeBOMCompLines(Rec);
        ClearSpecialSalesOrderLineValuesOnExplodeBOM(Rec);

        OnAfterOnRun(ToPurchLine, Rec);
    end;

    var
        Text000: Label 'The BOM cannot be exploded on the purchase lines because it is associated with sales order %1.';
        Text001: Label 'Item %1 is not a BOM.';
        Text003: Label 'There is not enough space to explode the BOM.';
        Text005: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';
        ToPurchLine: Record "Purchase Line";
        FromBOMComp: Record "BOM Component";
        PurchHeader: Record "Purchase Header";
        ItemTranslation: Record "Item Translation";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        Selection: Integer;

    local procedure GetSelection(PurchaseLine: Record "Purchase Line") Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSelection(PurchaseLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := StrMenu(Text005, 2);
    end;

    procedure CallExplodeBOMCompLines(PurchLine: Record "Purchase Line")
    begin
        ExplodeBOMCompLines(PurchLine);
    end;

    local procedure ExplodeBOMCompLines(PurchLine: Record "Purchase Line")
    var
        PreviousPurchLine: Record "Purchase Line";
        Resource: Record Resource;
        InsertLinesBetween: Boolean;
        SkipComponent: Boolean;
    begin
        with PurchLine do begin
            ToPurchLine.Reset();
            ToPurchLine.SetRange("Document Type", "Document Type");
            ToPurchLine.SetRange("Document No.", "Document No.");
            ToPurchLine := PurchLine;
            NextLineNo := "Line No.";
            InsertLinesBetween := false;
            if ToPurchLine.Find('>') then
                if ToPurchLine.IsExtendedText() and (ToPurchLine."Attached to Line No." = "Line No.") then begin
                    ToPurchLine.SetRange("Attached to Line No.", "Line No.");
                    ToPurchLine.FindLast();
                    ToPurchLine.SetRange("Attached to Line No.");
                    NextLineNo := ToPurchLine."Line No.";
                    InsertLinesBetween := ToPurchLine.Find('>');
                end else
                    InsertLinesBetween := true;
            if InsertLinesBetween then
                LineSpacing := (ToPurchLine."Line No." - NextLineNo) div (1 + NoOfBOMComp)
            else
                LineSpacing := 10000;
            if LineSpacing = 0 then
                Error(Text003);

            FromBOMComp.Find('-');
            repeat
                SkipComponent := false;
                OnExplodeBOMCompLinesOnBeforeCreatePurchLine(PurchLine, FromBOMComp, SkipComponent);
                if not SkipComponent then begin
                    ToPurchLine.Init();
                    NextLineNo := NextLineNo + LineSpacing;
                    ToPurchLine."Line No." := NextLineNo;
                    case FromBOMComp.Type of
                        FromBOMComp.Type::" ":
                            ToPurchLine.Type := ToPurchLine.Type::" ";
                        FromBOMComp.Type::Item:
                            begin
                                Item.Get(FromBOMComp."No.");
                                ToPurchLine.Type := ToPurchLine.Type::Item;
                                ToPurchLine.Validate("No.", FromBOMComp."No.");
                                ToPurchLine.Validate("Variant Code", FromBOMComp."Variant Code");
                                ToPurchLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                                ToPurchLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, ToPurchLine."Unit of Measure Code");
                                ToPurchLine.Validate(
                                  Quantity,
                                  Round(
                                    "Quantity (Base)" * FromBOMComp."Quantity per" *
                                    UOMMgt.GetQtyPerUnitOfMeasure(
                                      Item, ToPurchLine."Unit of Measure Code") / ToPurchLine."Qty. per Unit of Measure",
                                    UOMMgt.QtyRndPrecision()));
                            end;
                        FromBOMComp.Type::Resource:
                            begin
                                Resource.Get(FromBOMComp."No.");
                                ToPurchLine.Type := ToPurchLine.Type::Resource;
                                ToPurchLine.Validate("No.", FromBOMComp."No.");
                                ToPurchLine.Validate("Variant Code", FromBOMComp."Variant Code");
                                ToPurchLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                                ToPurchLine."Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, ToPurchLine."Unit of Measure Code");
                                ToPurchLine.Validate(
                                  Quantity,
                                  Round(
                                    "Quantity (Base)" * FromBOMComp."Quantity per" *
                                    UOMMgt.GetResQtyPerUnitOfMeasure(
                                      Resource, ToPurchLine."Unit of Measure Code") / ToPurchLine."Qty. per Unit of Measure",
                                    UOMMgt.QtyRndPrecision()));
                            end;
                    end;

                    if (FromBOMComp.Type <> FromBOMComp.Type::" ") and
                       (PurchHeader."Expected Receipt Date" <> "Expected Receipt Date")
                    then
                        ToPurchLine.Validate("Expected Receipt Date", "Expected Receipt Date");

                    if PurchHeader."Language Code" = '' then
                        ToPurchLine.Description := FromBOMComp.Description
                    else
                        if not ItemTranslation.Get(FromBOMComp."No.", FromBOMComp."Variant Code", PurchHeader."Language Code") then
                            ToPurchLine.Description := FromBOMComp.Description;

                    OnBeforeInsertExplodedPurchLine(ToPurchLine, PurchLine, FromBOMComp);
                    ToPurchLine.Insert();
                    OnAfterInsertExplodedPurchLine(ToPurchLine, PurchLine, FromBOMComp);

                    if Selection = 1 then begin
                        ToPurchLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                        ToPurchLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                        ToPurchLine."Dimension Set ID" := "Dimension Set ID";
                        ToPurchLine.Modify();
                    end;

                    if PreviousPurchLine."Document No." <> '' then
                        if TransferExtendedText.PurchCheckIfAnyExtText(PreviousPurchLine, false) then
                            TransferExtendedText.InsertPurchExtText(PreviousPurchLine);

                    PreviousPurchLine := ToPurchLine;
                end;
            until FromBOMComp.Next() = 0;

            if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then
                TransferExtendedText.InsertPurchExtText(ToPurchLine);
        end;
        OnAfterExplodeBOMCompLines(PurchLine, Selection, LineSpacing);
    end;

    local procedure ClearSpecialSalesOrderLineValuesOnExplodeBOM(PurchLine: Record "Purchase Line")
    var
        SalesOrderLine: Record "Sales Line";
    begin
        if PurchLine."Special Order" then begin
            SalesOrderLine.LockTable();
            if SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::Order, PurchLine."Special Order Sales No.", PurchLine."Special Order Sales Line No.")
            then begin
                SalesOrderLine."Special Order Purchase No." := '';
                SalesOrderLine."Special Order Purch. Line No." := 0;
                SalesOrderLine.Modify();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(ToPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExplodeBOMCompLines(var PurchaseLine: Record "Purchase Line"; Selection: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSelection(PurchaseLine: Record "Purchase Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertExplodedPurchLine(var ToPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExplodedPurchLine(var ToPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnBeforeCreatePurchLine(PurchaseLine: Record "Purchase Line"; BOMComponent: Record "BOM Component"; var IsAvailable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeToPurchLineModify(var ToPurchLine: Record "Purchase Line"; RecPurchLine: Record "Purchase Line")
    begin
    end;
}

