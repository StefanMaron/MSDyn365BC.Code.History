codeunit 51 "BOM-Explode BOM"
{
    TableNo = "BOM Component";

    trigger OnRun()
    begin
        TestField(Type, Type::Item);
        if "No." = "Parent Item No." then
            Error(Text000);

        FromBOMComp.SetRange("Parent Item No.", "No.");
        ToBOMComp.SetRange("Parent Item No.", "Parent Item No.");

        NoOfBOMComp := FromBOMComp.Count();
        if NoOfBOMComp = 0 then
            Error(
              Text001,
              "No.");

        ToBOMComp := Rec;
        if ToBOMComp.Find('>') then begin
            LineSpacing := (ToBOMComp."Line No." - "Line No.") div (1 + NoOfBOMComp);
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        Item.Get("No.");
        QtyPerUnitOfMeasure := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        OnRunOnAfterGetQtyPerUnitOfMeasure(Rec, Item, QtyPerUnitOfMeasure);

        FromBOMComp.Find('-');
        NextLineNo := "Line No.";
        repeat
            NextLineNo := NextLineNo + LineSpacing;
            ToBOMComp := FromBOMComp;
            ToBOMComp."Parent Item No." := "Parent Item No.";
            ToBOMComp."Line No." := NextLineNo;
            ToBOMComp."Quantity per" := Round(QtyPerUnitOfMeasure * "Quantity per" * FromBOMComp."Quantity per", 0.00001);
            ToBOMComp.Position := StrSubstNo(Position, FromBOMComp.Position);
            ToBOMComp."Installed in Line No." := "Installed in Line No.";
            ToBOMComp."Installed in Item No." := "Installed in Item No.";
            OnRunOnBeforeToBOMCompInsert(ToBOMComp, FromBOMComp);
            ToBOMComp.Insert();
        until FromBOMComp.Next() = 0;

        Delete();
    end;

    var
        FromBOMComp: Record "BOM Component";
        ToBOMComp: Record "BOM Component";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        QtyPerUnitOfMeasure: Decimal;

        Text000: Label 'A bill of materials cannot be a component of itself.';
        Text001: Label 'Item %1 is not a BOM.';
        Text002: Label 'There is not enough space to explode the BOM.';

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeToBOMCompInsert(var ToBOMComp: Record "BOM Component"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterGetQtyPerUnitOfMeasure(BOMComponent: Record "BOM Component"; Item: Record Item; var QtyPerUnitOfMeasure: Decimal)
    begin
    end;
}

