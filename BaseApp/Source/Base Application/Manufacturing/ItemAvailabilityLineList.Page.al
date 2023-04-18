page 99000902 "Item Availability Line List"
{
    Caption = 'Item Availability Line List';
    Editable = false;
    PageType = List;
    SourceTable = "Item Availability Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name for this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this entry.';

                    trigger OnDrillDown()
                    begin
                        LookupEntries();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        DeleteAll();
        MakeWhat();
    end;

    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        PurchLine: Record "Purchase Line";
        TransLine: Record "Transfer Line";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        AvailType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All;
        Sign: Integer;
        QtyByUnitOfMeasure: Decimal;

        Text000: Label '%1 Receipt';
        Text001: Label '%1 Release';
        Text002: Label 'Firm planned %1';
        Text003: Label 'Released %1';

    procedure Init(NewType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; var NewItem: Record Item)
    begin
        AvailType := NewType;
        Item.Copy(NewItem);
    end;

    local procedure MakeEntries()
    begin
        case AvailType of
            AvailType::"Gross Requirement":
                begin
                    InsertEntry(
                      DATABASE::"Sales Line",
                      Item.FieldNo("Qty. on Sales Order"),
                      SalesLine.TableCaption(),
                      Item."Qty. on Sales Order");
                    InsertEntry(
                      DATABASE::"Service Line",
                      Item.FieldNo("Qty. on Service Order"),
                      ServLine.TableCaption(),
                      Item."Qty. on Service Order");
                    InsertEntry(
                      DATABASE::"Job Planning Line",
                      Item.FieldNo("Qty. on Job Order"),
                      JobPlanningLine.TableCaption(),
                      Item."Qty. on Job Order");
                    InsertEntry(
                      DATABASE::"Prod. Order Component",
                      Item.FieldNo("Qty. on Component Lines"),
                      ProdOrderComp.TableCaption(),
                      Item."Qty. on Component Lines");
                    InsertEntry(
                      DATABASE::"Planning Component",
                      Item.FieldNo("Planning Issues (Qty.)"),
                      PlanningComponent.TableCaption(),
                      Item."Planning Issues (Qty.)");
                    InsertEntry(
                      DATABASE::"Transfer Line",
                      Item.FieldNo("Trans. Ord. Shipment (Qty.)"),
                      Item.FieldCaption("Trans. Ord. Shipment (Qty.)"),
                      Item."Trans. Ord. Shipment (Qty.)");
                    InsertEntry(
                      DATABASE::"Purchase Line",
                      0,
                      PurchLine.TableCaption(),
                      Item."Qty. on Purch. Return");
                    InsertEntry(
                      DATABASE::"Assembly Line",
                      Item.FieldNo("Qty. on Asm. Component"),
                      AssemblyLine.TableCaption(),
                      Item."Qty. on Asm. Component");
                end;
            AvailType::"Planned Order Receipt":
                begin
                    InsertEntry(
                      DATABASE::"Requisition Line",
                      Item.FieldNo("Purch. Req. Receipt (Qty.)"),
                      ReqLine.TableCaption(),
                      Item."Purch. Req. Receipt (Qty.)");
                    InsertEntry(
                      DATABASE::"Prod. Order Line",
                      Item.FieldNo("Planned Order Receipt (Qty.)"),
                      StrSubstNo(Text000, ProdOrderLine.TableCaption()),
                      Item."Planned Order Receipt (Qty.)");
                end;
            AvailType::"Planned Order Release":
                begin
                    InsertEntry(
                      DATABASE::"Requisition Line",
                      Item.FieldNo("Purch. Req. Release (Qty.)"),
                      ReqLine.TableCaption(),
                      Item."Purch. Req. Release (Qty.)");
                    InsertEntry(
                      DATABASE::"Prod. Order Line",
                      Item.FieldNo("Planned Order Release (Qty.)"),
                      StrSubstNo(Text001, ProdOrderLine.TableCaption()),
                      Item."Planned Order Release (Qty.)");
                    InsertEntry(
                      DATABASE::"Requisition Line",
                      Item.FieldNo("Planning Release (Qty.)"),
                      ReqLine.TableCaption(),
                      Item."Planning Release (Qty.)");
                end;
            AvailType::"Scheduled Order Receipt":
                begin
                    InsertEntry(
                      DATABASE::"Purchase Line",
                      Item.FieldNo("Qty. on Purch. Order"),
                      PurchLine.TableCaption(),
                      Item."Qty. on Purch. Order");
                    InsertEntry(
                      DATABASE::"Prod. Order Line",
                      Item.FieldNo("FP Order Receipt (Qty.)"),
                      StrSubstNo(Text002, ProdOrderLine.TableCaption()),
                      Item."FP Order Receipt (Qty.)");
                    InsertEntry(
                      DATABASE::"Prod. Order Line",
                      Item.FieldNo("Rel. Order Receipt (Qty.)"),
                      StrSubstNo(Text003, ProdOrderLine.TableCaption()),
                      Item."Rel. Order Receipt (Qty.)");
                    InsertEntry(
                      DATABASE::"Transfer Line",
                      Item.FieldNo("Qty. in Transit"),
                      Item.FieldCaption("Qty. in Transit"),
                      Item."Qty. in Transit");
                    InsertEntry(
                      DATABASE::"Transfer Line",
                      Item.FieldNo("Trans. Ord. Receipt (Qty.)"),
                      Item.FieldCaption("Trans. Ord. Receipt (Qty.)"),
                      Item."Trans. Ord. Receipt (Qty.)");
                    InsertEntry(
                      DATABASE::"Sales Line",
                      0,
                      SalesLine.TableCaption(),
                      Item."Qty. on Sales Return");
                    InsertEntry(
                      DATABASE::"Assembly Header",
                      Item.FieldNo("Qty. on Assembly Order"),
                      AssemblyHeader.TableCaption(),
                      Item."Qty. on Assembly Order");
                end;
        end;

        OnAfterMakeEntries(Item, Rec, AvailType, Sign);
    end;

    local procedure MakeWhat()
    begin
        Sign := 1;
        if AvailType <> AvailType::All then
            MakeEntries()
        else begin
            Item.SetRange("Date Filter", 0D, Item.GetRangeMax("Date Filter"));
            OnItemSetFilter(Item);
            Item.CalcFields(
              "Qty. on Purch. Order",
              "Qty. on Sales Order",
              "Qty. on Service Order",
              "Qty. on Job Order",
              "Net Change",
              "Scheduled Receipt (Qty.)",
              "Qty. on Component Lines",
              "Planned Order Receipt (Qty.)",
              "FP Order Receipt (Qty.)",
              "Rel. Order Receipt (Qty.)",
              "Planned Order Release (Qty.)",
              "Purch. Req. Receipt (Qty.)",
              "Planning Issues (Qty.)",
              "Purch. Req. Release (Qty.)",
              "Qty. in Transit");
            Item.CalcFields(
              "Trans. Ord. Shipment (Qty.)",
              "Trans. Ord. Receipt (Qty.)",
              "Qty. on Assembly Order",
              "Qty. on Asm. Component",
              "Qty. on Purch. Return",
              "Qty. on Sales Return");

            OnItemCalcFields(Item);

            if Item.Inventory <> 0 then begin
                "Table No." := DATABASE::"Item Ledger Entry";
                QuerySource := Item.FieldNo(Inventory);
                Name := ItemLedgerEntry.TableCaption();
                Quantity := AdjustWithQtyByUnitOfMeasure(Item.Inventory);
                Insert();
            end;
            AvailType := AvailType::"Gross Requirement";
            Sign := -1;
            MakeEntries();
            AvailType := AvailType::"Planned Order Receipt";
            Sign := 1;
            MakeEntries();
            AvailType := AvailType::"Scheduled Order Receipt";
            Sign := 1;
            MakeEntries();
            AvailType := AvailType::All;
        end;
    end;

    local procedure LookupEntries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupEntries(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        case "Table No." of
            DATABASE::"Item Ledger Entry":
                begin
                    ItemLedgerEntry.SetCurrentKey("Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", Item."No.");
                    ItemLedgerEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                    ItemLedgerEntry.SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
                    ItemLedgerEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
                    ItemLedgerEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
                    ItemLedgerEntry.SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
                    OnItemLedgerEntrySetFilter(ItemLedgerEntry);
                    PAGE.RunModal(0, ItemLedgerEntry);
                end;
            DATABASE::"Sales Line":
                begin
                    if QuerySource > 0 then
                        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::Order)
                    else
                        SalesLine.FindLinesWithItemToPlan(Item, SalesLine."Document Type"::"Return Order");
                    SalesLine.SetRange("Drop Shipment", false);
                    PAGE.RunModal(0, SalesLine);
                end;
            DATABASE::"Service Line":
                begin
                    ServLine.FindLinesWithItemToPlan(Item);
                    PAGE.RunModal(0, ServLine);
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.FindLinesWithItemToPlan(Item);
                    PAGE.RunModal(0, JobPlanningLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.SetCurrentKey("Document Type", Type, "No.");
                    if QuerySource > 0 then
                        PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::Order)
                    else
                        PurchLine.FindLinesWithItemToPlan(Item, PurchLine."Document Type"::"Return Order");
                    PurchLine.SetRange("Drop Shipment", false);
                    OnLookupEntriesOnAfterPurchLineSetFilters(Item, PurchLine);
                    PAGE.RunModal(0, PurchLine);
                end;
            DATABASE::"Transfer Line":
                begin
                    case QuerySource of
                        Item.FieldNo("Trans. Ord. Shipment (Qty.)"):
                            TransLine.FindLinesWithItemToPlan(Item, false, false);
                        Item.FieldNo("Trans. Ord. Receipt (Qty.)"), Item.FieldNo("Qty. in Transit"):
                            TransLine.FindLinesWithItemToPlan(Item, true, false);
                    end;
                    PAGE.RunModal(0, TransLine);
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.FindLinesWithItemToPlan(Item);
                    PAGE.RunModal(0, PlanningComponent);
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.FindLinesWithItemToPlan(Item, true);
                    PAGE.RunModal(0, ProdOrderComp);
                end;
            DATABASE::"Requisition Line":
                begin
                    ReqLine.FindLinesWithItemToPlan(Item);
                    case QuerySource of
                        Item.FieldNo("Purch. Req. Receipt (Qty.)"):
                            Item.CopyFilter("Date Filter", ReqLine."Due Date");
                        Item.FieldNo("Purch. Req. Release (Qty.)"):
                            begin
                                Item.CopyFilter("Date Filter", ReqLine."Order Date");
                                ReqLine.SetFilter("Planning Line Origin", '%1|%2',
                                  ReqLine."Planning Line Origin"::" ", ReqLine."Planning Line Origin"::Planning);
                            end;
                    end;
                    PAGE.RunModal(0, ReqLine);
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ProdOrderLine.Reset();
                    ProdOrderLine.SetCurrentKey(Status, "Item No.");
                    case QuerySource of
                        Item.FieldNo("Planned Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                        Item.FieldNo("Planned Order Release (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Planned);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Starting Date");
                            end;
                        Item.FieldNo("FP Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                        Item.FieldNo("Rel. Order Receipt (Qty.)"):
                            begin
                                ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
                                Item.CopyFilter("Date Filter", ProdOrderLine."Due Date");
                            end;
                    end;
                    ProdOrderLine.SetRange("Item No.", Item."No.");
                    Item.CopyFilter("Variant Filter", ProdOrderLine."Variant Code");
                    Item.CopyFilter("Location Filter", ProdOrderLine."Location Code");
                    Item.CopyFilter("Global Dimension 1 Filter", ProdOrderLine."Shortcut Dimension 1 Code");
                    Item.CopyFilter("Global Dimension 2 Filter", ProdOrderLine."Shortcut Dimension 2 Code");
                    Item.CopyFilter("Unit of Measure Filter", ProdOrderLine."Unit of Measure Code");
                    PAGE.RunModal(0, ProdOrderLine);
                end;
            DATABASE::"Assembly Header":
                begin
                    AssemblyHeader.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
                    PAGE.RunModal(0, AssemblyHeader);
                end;
            DATABASE::"Assembly Line":
                begin
                    AssemblyLine.FindItemToPlanLines(Item, AssemblyHeader."Document Type"::Order);
                    PAGE.RunModal(0, AssemblyLine);
                end;
            else
                OnLookupExtensionTable(Item, "Table No.", QuerySource, SalesLine);
        end;

        OnAfterLookupEntries(Item, "Table No.", Rec);
    end;

    procedure InsertEntry("Table": Integer; "Field": Integer; TableName: Text[100]; Qty: Decimal)
    begin
        if Qty = 0 then
            exit;

        "Table No." := Table;
        QuerySource := Field;
        Name := CopyStr(TableName, 1, MaxStrLen(Name));
        Quantity := AdjustWithQtyByUnitOfMeasure(Qty * Sign);
        Insert();
    end;

    local procedure AdjustWithQtyByUnitOfMeasure(Quantity: Decimal): Decimal
    begin
        if QtyByUnitOfMeasure <> 0 then
            exit(Quantity / QtyByUnitOfMeasure);
        exit(Quantity);
    end;

    procedure SetQtyByUnitOfMeasure(NewQtyByUnitOfMeasure: Decimal);
    begin
        QtyByUnitOfMeasure := NewQtyByUnitOfMeasure;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemCalcFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemSetFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLedgerEntrySetFilter(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option; Sign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; TableID: Integer; ItemAvailabilityLine: Record "Item Availability Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupExtensionTable(var Item: Record Item; TableID: Integer; QuerySource: Integer; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupEntries(ItemAvailabilityLine: Record "Item Availability Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupEntriesOnAfterPurchLineSetFilters(var Item: Record Item; var PurchLine: Record "Purchase Line")
    begin
    end;
}

