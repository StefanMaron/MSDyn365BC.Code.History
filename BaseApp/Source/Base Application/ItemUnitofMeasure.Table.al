table 5404 "Item Unit of Measure"
{
    Caption = 'Item Unit of Measure';
    LookupPageID = "Item Units of Measure";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                CalcWeight;
            end;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Unit of Measure";
        }
        field(3; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                if "Qty. per Unit of Measure" <= 0 then
                    FieldError("Qty. per Unit of Measure", Text000);
                if xRec."Qty. per Unit of Measure" <> "Qty. per Unit of Measure" then
                    CheckNoEntriesWithUoM;
                Item.Get("Item No.");
                if Item."Base Unit of Measure" = Code then
                    TestField("Qty. per Unit of Measure", 1);
                CalcWeight;
            end;
        }
        field(7300; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage;
            end;
        }
        field(7301; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage;
            end;
        }
        field(7302; Height; Decimal)
        {
            Caption = 'Height';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCubage;
            end;
        }
        field(7303; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(7304; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Qty. per Unit of Measure")
        {
        }
        key(Key3; "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Qty. per Unit of Measure")
        {
        }
    }

    trigger OnDelete()
    begin
        TestItemUOM;
        CheckNoEntriesWithUoM;
    end;

    trigger OnRename()
    begin
        TestItemUOM;
    end;

    var
        Text000: Label 'must be greater than 0';
        Item: Record Item;
        Text001: Label 'You cannot rename %1 %2 for item %3 because it is the item''s %4 and there are one or more open ledger entries for the item.';
        CannotModifyBaseUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s base unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifySalesUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s sales unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyPurchUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s purchase unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyPutAwayUnitOfMeasureErr: Label 'You cannot modify item unit of measure %1 for item %2 because it is the item''s put-away unit of measure.', Comment = '%1 Value of Measure (KG, PCS...), %2 Item ID';
        CannotModifyUnitOfMeasureErr: Label 'You cannot modify %1 %2 for item %3 because non-zero %5 with %2 exists in %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Entry Table Name, %5 Field Caption';
        CannotModifyUOMWithWhseEntriesErr: Label 'You cannot modify %1 %2 for item %3 because there are one or more warehouse adjustment entries for the item.', Comment = '%1 = Item Unit of Measure %2 = Code %3 = Item No.';

    local procedure CalcCubage()
    begin
        Cubage := Length * Width * Height;

        OnAfterCalcCubage(Rec);
    end;

    procedure CalcWeight()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");

        Weight := "Qty. per Unit of Measure" * Item."Net Weight";

        OnAfterCalcWeight(Rec);
    end;

    local procedure TestNoOpenEntriesExist()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if Item.Get("Item No.") then
            if Item."Base Unit of Measure" = xRec.Code then begin
                ItemLedgEntry.SetCurrentKey("Item No.", Open);
                ItemLedgEntry.SetRange("Item No.", "Item No.");
                ItemLedgEntry.SetRange(Open, true);
                if not ItemLedgEntry.IsEmpty then
                    Error(Text001, TableCaption, xRec.Code, "Item No.", Item.FieldCaption("Base Unit of Measure"));
            end;
    end;

    local procedure TestNoWhseAdjmtEntriesExist()
    var
        WhseEntry: Record "Warehouse Entry";
        Location: Record Location;
        Bin: Record Bin;
    begin
        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Unit of Measure Code", xRec.Code);
        if Location.FindSet then
            repeat
                if Bin.Get(Location.Code, Location."Adjustment Bin Code") then begin
                    WhseEntry.SetRange("Zone Code", Bin."Zone Code");
                    if not WhseEntry.IsEmpty then
                        Error(CannotModifyUOMWithWhseEntriesErr, TableCaption, xRec.Code, "Item No.");
                end;
            until Location.Next = 0;
    end;

    procedure TestItemSetup()
    begin
        if Item.Get("Item No.") then begin
            if Item."Base Unit of Measure" = xRec.Code then
                Error(CannotModifyBaseUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Sales Unit of Measure" = xRec.Code then
                Error(CannotModifySalesUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Purch. Unit of Measure" = xRec.Code then
                Error(CannotModifyPurchUnitOfMeasureErr, xRec.Code, "Item No.");
            if Item."Put-away Unit of Measure Code" = xRec.Code then
                Error(CannotModifyPutAwayUnitOfMeasureErr, xRec.Code, "Item No.");
        end;
    end;

    local procedure TestItemUOM()
    begin
        TestItemSetup;
        TestNoOpenEntriesExist;
        TestNoWhseAdjmtEntriesExist;
    end;

    procedure CheckNoEntriesWithUoM()
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", "Item No.");
        WarehouseEntry.SetRange("Unit of Measure Code", Code);
        WarehouseEntry.CalcSums("Qty. (Base)", Quantity);
        if (WarehouseEntry."Qty. (Base)" <> 0) or (WarehouseEntry.Quantity <> 0) then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.", WarehouseEntry.TableCaption,
              WarehouseEntry.FieldCaption(Quantity));

        CheckNoOutstandingQty;
    end;

    local procedure CheckNoOutstandingQty()
    begin
        CheckNoOutstandingQtyPurchLine;
        CheckNoOutstandingQtySalesLine;
        CheckNoOutstandingQtyTransferLine;
        CheckNoRemQtyProdOrderLine;
        CheckNoRemQtyProdOrderComponent;
        CheckNoOutstandingQtyServiceLine;
        CheckNoRemQtyAssemblyHeader;
        CheckNoRemQtyAssemblyLine;
    end;

    local procedure CheckNoOutstandingQtyPurchLine()
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", "Item No.");
        PurchLine.SetRange("Unit of Measure Code", Code);
        PurchLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not PurchLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              PurchLine.TableCaption, PurchLine.FieldCaption("Qty. to Receive"));
    end;

    local procedure CheckNoOutstandingQtySalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", "Item No.");
        SalesLine.SetRange("Unit of Measure Code", Code);
        SalesLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not SalesLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              SalesLine.TableCaption, SalesLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoOutstandingQtyTransferLine()
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Item No.", "Item No.");
        TransferLine.SetRange("Unit of Measure Code", Code);
        TransferLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not TransferLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              TransferLine.TableCaption, TransferLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoRemQtyProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", "Item No.");
        ProdOrderLine.SetRange("Unit of Measure Code", Code);
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderLine.SetFilter(Status, '<>%1', ProdOrderLine.Status::Finished);
        if not ProdOrderLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              ProdOrderLine.TableCaption, ProdOrderLine.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyProdOrderComponent()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", "Item No.");
        ProdOrderComponent.SetRange("Unit of Measure Code", Code);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderComponent.SetFilter(Status, '<>%1', ProdOrderComponent.Status::Finished);
        if not ProdOrderComponent.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              ProdOrderComponent.TableCaption, ProdOrderComponent.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoOutstandingQtyServiceLine()
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", "Item No.");
        ServiceLine.SetRange("Unit of Measure Code", Code);
        ServiceLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        if not ServiceLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              ServiceLine.TableCaption, ServiceLine.FieldCaption("Qty. to Ship"));
    end;

    local procedure CheckNoRemQtyAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.SetRange("Item No.", "Item No.");
        AssemblyHeader.SetRange("Unit of Measure Code", Code);
        AssemblyHeader.SetFilter("Remaining Quantity", '<>%1', 0);
        if not AssemblyHeader.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              AssemblyHeader.TableCaption, AssemblyHeader.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyAssemblyLine()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetRange("No.", "Item No.");
        AssemblyLine.SetRange("Unit of Measure Code", Code);
        AssemblyLine.SetFilter("Remaining Quantity", '<>%1', 0);
        if not AssemblyLine.IsEmpty then
            Error(
              CannotModifyUnitOfMeasureErr, TableCaption, xRec.Code, "Item No.",
              AssemblyLine.TableCaption, AssemblyLine.FieldCaption("Remaining Quantity"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCubage(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcWeight(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;
}

