table 5401 "Item Variant"
{
    Caption = 'Item Variant';
    DataCaptionFields = "Item No.", "Code", Description;
    LookupPageID = "Item Variants";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = '' then
                    Clear("Item Id")
                else
                    if Item.Get("Item No.") then
                        "Item Id" := Item.SystemId;
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Item Id"; Guid)
        {
            Caption = 'Item Id';
            TableRelation = Item.SystemId;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if IsNullGuid("Item Id") then
                    "Item No." := ''
                else
                    if Item.GetBySystemId("Item Id") then
                        "Item No." := Item."No.";
            end;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; "Item Id", "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Code", Description)
        {
        }
    }

    trigger OnDelete()
    var
        ItemTranslation: Record "Item Translation";
        SKU: Record "Stockkeeping Unit";
        ItemIdent: Record "Item Identifier";
        ItemReference: Record "Item Reference";
        BOMComp: Record "BOM Component";
        ItemJnlLine: Record "Item Journal Line";
        RequisitionLine: Record "Requisition Line";
        PurchOrderLine: Record "Purchase Line";
        SalesOrderLine: Record "Sales Line";
        ProdOrderComp: Record "Prod. Order Component";
        TransLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        ProdBOMLine: Record "Production BOM Line";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        AssemblyHeader: Record "Assembly Header";
        ItemSubstitution: Record "Item Substitution";
        ItemVend: Record "Item Vendor";
        PlanningAssignment: Record "Planning Assignment";
        ServiceItemComponent: Record "Service Item Component";
        BinContent: Record "Bin Content";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        AssemblyLine: Record "Assembly Line";
    begin
        BOMComp.Reset();
        BOMComp.SetCurrentKey(Type, "No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        BOMComp.SetRange("No.", "Item No.");
        BOMComp.SetRange("Variant Code", Code);
        if not BOMComp.IsEmpty() then
            Error(Text001, Code, BOMComp.TableCaption());

        ProdBOMLine.Reset();
        ProdBOMLine.SetCurrentKey(Type, "No.");
        ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);
        ProdBOMLine.SetRange("No.", "Item No.");
        ProdBOMLine.SetRange("Variant Code", Code);
        if not ProdBOMLine.IsEmpty() then
            Error(Text001, Code, ProdBOMLine.TableCaption());

        ProdOrderComp.Reset();
        ProdOrderComp.SetCurrentKey(Status, "Item No.");
        ProdOrderComp.SetRange("Item No.", "Item No.");
        ProdOrderComp.SetRange("Variant Code", Code);
        if not ProdOrderComp.IsEmpty() then
            Error(Text001, Code, ProdOrderComp.TableCaption());

        if ProdOrderExist() then
            Error(Text002, "Item No.");

        AssemblyHeader.Reset();
        AssemblyHeader.SetCurrentKey("Document Type", "Item No.");
        AssemblyHeader.SetRange("Item No.", "Item No.");
        AssemblyHeader.SetRange("Variant Code", Code);
        if not AssemblyHeader.IsEmpty() then
            Error(Text001, Code, AssemblyHeader.TableCaption());

        AssemblyLine.Reset();
        AssemblyLine.SetCurrentKey("Document Type", Type, "No.");
        AssemblyLine.SetRange("No.", "Item No.");
        AssemblyLine.SetRange("Variant Code", Code);
        if not AssemblyLine.IsEmpty() then
            Error(Text001, Code, AssemblyLine.TableCaption());

        BinContent.Reset();
        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "Item No.");
        BinContent.SetRange("Variant Code", Code);
        if not BinContent.IsEmpty() then
            Error(Text001, Code, BinContent.TableCaption());

        TransLine.Reset();
        TransLine.SetCurrentKey("Item No.");
        TransLine.SetRange("Item No.", "Item No.");
        TransLine.SetRange("Variant Code", Code);
        if not TransLine.IsEmpty() then
            Error(Text001, Code, TransLine.TableCaption());

        RequisitionLine.Reset();
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", "Item No.");
        RequisitionLine.SetRange("Variant Code", Code);
        if not RequisitionLine.IsEmpty() then
            Error(Text001, Code, RequisitionLine.TableCaption());

        PurchOrderLine.Reset();
        PurchOrderLine.SetCurrentKey(Type, "No.");
        PurchOrderLine.SetRange(Type, PurchOrderLine.Type::Item);
        PurchOrderLine.SetRange("No.", "Item No.");
        PurchOrderLine.SetRange("Variant Code", Code);
        if not PurchOrderLine.IsEmpty() then
            Error(Text001, Code, PurchOrderLine.TableCaption());

        SalesOrderLine.Reset();
        SalesOrderLine.SetCurrentKey(Type, "No.");
        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);
        SalesOrderLine.SetRange("No.", "Item No.");
        SalesOrderLine.SetRange("Variant Code", Code);
        if not SalesOrderLine.IsEmpty() then
            Error(Text001, Code, SalesOrderLine.TableCaption());

        ServiceItem.Reset();
        ServiceItem.SetCurrentKey("Item No.", "Serial No.");
        ServiceItem.SetRange("Item No.", "Item No.");
        ServiceItem.SetRange("Variant Code", Code);
        if not ServiceItem.IsEmpty() then
            Error(Text001, Code, ServiceItem.TableCaption());

        ServiceLine.Reset();
        ServiceLine.SetCurrentKey(Type, "No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("No.", "Item No.");
        ServiceLine.SetRange("Variant Code", Code);
        if not ServiceLine.IsEmpty() then
            Error(Text001, Code, ServiceLine.TableCaption());

        ServiceContractLine.Reset();
        ServiceContractLine.SetRange("Item No.", "Item No.");
        ServiceContractLine.SetRange("Variant Code", Code);
        if not ServiceContractLine.IsEmpty() then
            Error(Text001, Code, ServiceContractLine.TableCaption());

        ServiceItemComponent.Reset();
        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.SetRange("No.", "Item No.");
        ServiceItemComponent.SetRange("Variant Code", Code);
        ServiceItemComponent.ModifyAll("Variant Code", '');

        ItemJnlLine.Reset();
        ItemJnlLine.SetCurrentKey("Item No.");
        ItemJnlLine.SetRange("Item No.", "Item No.");
        ItemJnlLine.SetRange("Variant Code", Code);
        if not ItemJnlLine.IsEmpty() then
            Error(Text001, Code, ItemJnlLine.TableCaption());

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", "Item No.");
        ItemLedgerEntry.SetRange("Variant Code", Code);
        if not ItemLedgerEntry.IsEmpty() then
            Error(Text001, Code, ItemLedgerEntry.TableCaption());

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", "Item No.");
        ValueEntry.SetRange("Variant Code", Code);
        if not ValueEntry.IsEmpty() then
            Error(Text001, Code, ValueEntry.TableCaption());

        ItemTranslation.SetRange("Item No.", "Item No.");
        ItemTranslation.SetRange("Variant Code", Code);
        ItemTranslation.DeleteAll();

        ItemIdent.Reset();
        ItemIdent.SetCurrentKey("Item No.");
        ItemIdent.SetRange("Item No.", "Item No.");
        ItemIdent.SetRange("Variant Code", Code);
        ItemIdent.DeleteAll();

        ItemReference.SetRange("Item No.", "Item No.");
        ItemReference.SetRange("Variant Code", Code);
        ItemReference.DeleteAll();

        ItemSubstitution.Reset();
        ItemSubstitution.SetRange(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.SetRange("No.", "Item No.");
        ItemSubstitution.SetRange("Substitute Type", ItemSubstitution."Substitute Type"::Item);
        ItemSubstitution.SetRange("Variant Code", Code);
        ItemSubstitution.DeleteAll();

        ItemVend.Reset();
        ItemVend.SetCurrentKey("Item No.");
        ItemVend.SetRange("Item No.", "Item No.");
        ItemVend.SetRange("Variant Code", Code);
        ItemVend.DeleteAll();

        SKU.SetRange("Item No.", "Item No.");
        SKU.SetRange("Variant Code", Code);
        SKU.DeleteAll(true);

        PlanningAssignment.Reset();
        PlanningAssignment.SetRange("Item No.", "Item No.");
        PlanningAssignment.SetRange("Variant Code", Code);
        PlanningAssignment.DeleteAll();
    end;

    var
        Text001: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.';
        Text002: Label 'You cannot delete item variant %1 because there are one or more outstanding production orders that include this item.';

    local procedure ProdOrderExist(): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetRange("Item No.", "Item No.");
        ProdOrderLine.SetRange("Variant Code", Code);
        if not ProdOrderLine.IsEmpty() then
            exit(true);

        exit(false);
    end;

    procedure UpdateReferencedIds()
    var
        Item: Record Item;
    begin
        if "Item No." = '' then begin
            Clear("Item Id");
            exit;
        end;

        if not Item.Get("Item No.") then
            exit;

        "Item Id" := Item.SystemId;
    end;
}

