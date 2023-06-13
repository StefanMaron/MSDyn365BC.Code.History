codeunit 246 "Item Jnl.-Explode BOM"
{
    TableNo = "Item Journal Line";

    trigger OnRun()
    var
        Selection: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        FromBOMComp.SetRange("Parent Item No.", "Item No.");
        FromBOMComp.SetRange(Type, FromBOMComp.Type::Item);
        NoOfBOMComp := FromBOMComp.Count();
        if NoOfBOMComp = 0 then
            Error(
              Text000,
              "Item No.");

        Selection := StrMenu(Text003, 2);
        if Selection = 0 then
            exit;

        ToItemJnlLine.Reset();
        ToItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ToItemJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        ToItemJnlLine.SetRange("Document No.", "Document No.");
        ToItemJnlLine.SetRange("Posting Date", "Posting Date");
        ToItemJnlLine.SetRange("Entry Type", "Entry Type");
        ToItemJnlLine := Rec;

        LineSpacing := GetItemJnlLineSpacing(Rec, ToItemJnlLine);

        ToItemJnlLine := Rec;
        FromBOMComp.SetFilter("No.", '<>%1', '');
        OnAfterFromBOMCompSetFilters(FromBomComp);
        if FromBOMComp.Find('-') then
            repeat
                Item.Get(FromBOMComp."No.");
                ToItemJnlLine."Line No." := 0;
                ToItemJnlLine."Item No." := FromBOMComp."No.";
                ToItemJnlLine."Variant Code" := FromBOMComp."Variant Code";
                ToItemJnlLine."Unit of Measure Code" := FromBOMComp."Unit of Measure Code";
                ToItemJnlLine."Qty. per Unit of Measure" :=
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, FromBOMComp."Unit of Measure Code");
                ToItemJnlLine.Quantity := Round("Quantity (Base)" * FromBOMComp."Quantity per", 0.00001);
                if ToItemJnlLine.Quantity > 0 then
                    if ItemCheckAvail.ItemJnlCheckLine(ToItemJnlLine) then
                        ItemCheckAvail.RaiseUpdateInterruptedError();
            until FromBOMComp.Next() = 0;

        ToItemJnlLine := Rec;
        ToItemJnlLine.Init();
        ToItemJnlLine.Description := Description;
        ToItemJnlLine.Modify();

        FromBOMComp.Reset();
        FromBOMComp.SetRange("Parent Item No.", "Item No.");
        FromBOMComp.SetRange(Type, FromBOMComp.Type::Item);
        FromBOMComp.Find('-');
        NextLineNo := "Line No.";

        repeat
            ToItemJnlLine.Init();
            ToItemJnlLine."Journal Template Name" := "Journal Template Name";
            ToItemJnlLine."Document No." := "Document No.";
            ToItemJnlLine."Document Date" := "Document Date";
            ToItemJnlLine."Posting Date" := "Posting Date";
            ToItemJnlLine."External Document No." := "External Document No.";
            ToItemJnlLine."Entry Type" := "Entry Type";
            ToItemJnlLine."Location Code" := "Location Code";
            NextLineNo := NextLineNo + LineSpacing;
            OnBeforeAssignToItemJnlLineNo(Rec, NextLineNo);
            ToItemJnlLine."Line No." := NextLineNo;
            ToItemJnlLine."Drop Shipment" := "Drop Shipment";
            ToItemJnlLine."Source Code" := "Source Code";
            ToItemJnlLine."Reason Code" := "Reason Code";
            ToItemJnlLine.Validate("Item No.", FromBOMComp."No.");
            ToItemJnlLine.Validate("Variant Code", FromBOMComp."Variant Code");
            ToItemJnlLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
            ToItemJnlLine.Validate(
              Quantity,
              Round("Quantity (Base)" * FromBOMComp."Quantity per", 0.00001));
            ToItemJnlLine.Description := FromBOMComp.Description;
            OnBeforeToItemJnlLineInsert(ToItemJnlLine, Rec, NextLineNo);
            ToItemJnlLine.Insert();

            if Selection = 1 then begin
                ToItemJnlLine."Shortcut Dimension 1 Code" := "Shortcut Dimension 1 Code";
                ToItemJnlLine."Shortcut Dimension 2 Code" := "Shortcut Dimension 2 Code";
                ToItemJnlLine."Dimension Set ID" := "Dimension Set ID";
                ToItemJnlLine.Modify();
            end;
        until FromBOMComp.Next() = 0;
    end;

    var
        ToItemJnlLine: Record "Item Journal Line";
        FromBOMComp: Record "BOM Component";
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;

        Text000: Label 'Item %1 is not a BOM.';
        Text002: Label 'There is not enough space to explode the BOM.';
        Text003: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';

    local procedure GetItemJnlLineSpacing(OldItemJnlLine: Record "Item Journal Line"; var ToItemJnlLine: Record "Item Journal Line") LineSpacing: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemJnlLineSpacing(OldItemJnlLine, ToItemJnlLine, LineSpacing, IsHandled);
        if IsHandled then
            exit(LineSpacing);

        if ToItemJnlLine.Find('>') then begin
            LineSpacing := (ToItemJnlLine."Line No." - OldItemJnlLine."Line No.") div (1 + NoOfBOMComp);
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignToItemJnlLineNo(FromItemJournalLine: Record "Item Journal Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemJnlLineSpacing(OldItemJnlLine: Record "Item Journal Line"; var ToItemJnlLine: Record "Item Journal Line"; var LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToItemJnlLineInsert(var ToItemJournalLine: Record "Item Journal Line"; FromItemJournalLine: Record "Item Journal Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromBOMCompSetFilters(var FromBOMComponent: Record "BOM Component")
    begin
    end;
}

