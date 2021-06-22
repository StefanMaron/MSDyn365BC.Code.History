page 497 "Reservation Entries"
{
    Caption = 'Reservation Entries';
    DataCaptionExpression = TextCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Reservation Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reservation Status"; "Reservation Status")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the status of the reservation.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item that has been reserved in this entry.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the Location of the items that have been reserved in the entry.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the lot number of the item that is being handled with the associated document line.';
                    Visible = false;
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the reserved items are expected to enter inventory.';
                    Visible = false;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of the item that has been reserved in the entry.';

                    trigger OnValidate()
                    begin
                        ReservEngineMgt.ModifyReservEntry(xRec, "Quantity (Base)", Description, false);
                        QuantityBaseOnAfterValidate;
                    end;
                }
                field("ReservEngineMgt.CreateForText(Rec)"; ReservEngineMgt.CreateForText(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved For';
                    Editable = false;
                    ToolTip = 'Specifies which line or entry the items are reserved for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupReservedFor;
                    end;
                }
                field(ReservedFrom; ReservEngineMgt.CreateFromText(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved From';
                    Editable = false;
                    ToolTip = 'Specifies which line or entry the items are reserved from.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupReservedFrom;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies a description of the reservation entry.';
                    Visible = false;
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies for which source type the reservation entry is related to.';
                    Visible = false;
                }
                field("Source Subtype"; "Source Subtype")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which source subtype the reservation entry is related to.';
                    Visible = false;
                }
                field("Source ID"; "Source ID")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies which source ID the reservation entry is related to.';
                    Visible = false;
                }
                field("Source Batch Name"; "Source Batch Name")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the journal batch name if the reservation entry is related to a journal or requisition line.';
                    Visible = false;
                }
                field("Source Ref. No."; "Source Ref. No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies a reference number for the line, which the reservation entry is related to.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Creation Date"; "Creation Date")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the entry was created.';
                    Visible = false;
                }
                field("Transferred from Entry No."; "Transferred from Entry No.")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies a value when the order tracking entry is for the quantity that remains on a document line after a partial posting.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CancelReservation)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Cancel Reservation';
                    Image = Cancel;
                    ToolTip = 'Cancel the selected reservation entry.';

                    trigger OnAction()
                    var
                        ReservEntry: Record "Reservation Entry";
                    begin
                        CurrPage.SetSelectionFilter(ReservEntry);
                        if ReservEntry.Find('-') then
                            repeat
                                ReservEntry.TestField("Reservation Status", "Reservation Status"::Reservation);
                                ReservEntry.TestField("Disallow Cancellation", false);
                                if Confirm(
                                     Text001, false, ReservEntry."Quantity (Base)",
                                     ReservEntry."Item No.", ReservEngineMgt.CreateForText(Rec),
                                     ReservEngineMgt.CreateFromText(Rec))
                                then begin
                                    ReservEngineMgt.CancelReservation(ReservEntry);
                                    Commit();
                                end;
                            until ReservEntry.Next = 0;
                    end;
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        ReservEngineMgt.ModifyReservEntry(xRec, "Quantity (Base)", Description, true);
        exit(false);
    end;

    var
        Text001: Label 'Cancel reservation of %1 of item number %2, reserved for %3 from %4?';
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";

    local procedure LookupReservedFor()
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Get("Entry No.", false);
        LookupReserved(ReservEntry);
    end;

    local procedure LookupReservedFrom()
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Get("Entry No.", true);
        LookupReserved(ReservEntry);
    end;

    procedure LookupReserved(ReservEntry: Record "Reservation Entry")
    var
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        TransLine: Record "Transfer Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        with ReservEntry do
            case "Source Type" of
                DATABASE::"Sales Line":
                    begin
                        SalesLine.Reset();
                        SalesLine.SetRange("Document Type", "Source Subtype");
                        SalesLine.SetRange("Document No.", "Source ID");
                        SalesLine.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(PAGE::"Sales Lines", SalesLine);
                    end;
                DATABASE::"Requisition Line":
                    begin
                        ReqLine.Reset();
                        ReqLine.SetRange("Worksheet Template Name", "Source ID");
                        ReqLine.SetRange("Journal Batch Name", "Source Batch Name");
                        ReqLine.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
                    end;
                DATABASE::"Purchase Line":
                    begin
                        PurchLine.Reset();
                        PurchLine.SetRange("Document Type", "Source Subtype");
                        PurchLine.SetRange("Document No.", "Source ID");
                        PurchLine.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(PAGE::"Purchase Lines", PurchLine);
                    end;
                DATABASE::"Item Journal Line":
                    begin
                        ItemJnlLine.Reset();
                        ItemJnlLine.SetRange("Journal Template Name", "Source ID");
                        ItemJnlLine.SetRange("Journal Batch Name", "Source Batch Name");
                        ItemJnlLine.SetRange("Line No.", "Source Ref. No.");
                        ItemJnlLine.SetRange("Entry Type", "Source Subtype");
                        PAGE.RunModal(PAGE::"Item Journal Lines", ItemJnlLine);
                    end;
                DATABASE::"Item Ledger Entry":
                    begin
                        ItemLedgEntry.Reset();
                        ItemLedgEntry.SetRange("Entry No.", "Source Ref. No.");
                        PAGE.RunModal(0, ItemLedgEntry);
                    end;
                DATABASE::"Prod. Order Line":
                    begin
                        ProdOrderLine.Reset();
                        ProdOrderLine.SetRange(Status, "Source Subtype");
                        ProdOrderLine.SetRange("Prod. Order No.", "Source ID");
                        ProdOrderLine.SetRange("Line No.", "Source Prod. Order Line");
                        PAGE.RunModal(0, ProdOrderLine);
                    end;
                DATABASE::"Prod. Order Component":
                    begin
                        ProdOrderComp.Reset();
                        ProdOrderComp.SetRange(Status, "Source Subtype");
                        ProdOrderComp.SetRange("Prod. Order No.", "Source ID");
                        ProdOrderComp.SetRange("Prod. Order Line No.", "Source Prod. Order Line");
                        ProdOrderComp.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(0, ProdOrderComp);
                    end;
                DATABASE::"Planning Component":
                    begin
                        PlanningComponent.Reset();
                        PlanningComponent.SetRange("Worksheet Template Name", "Source ID");
                        PlanningComponent.SetRange("Worksheet Batch Name", "Source Batch Name");
                        PlanningComponent.SetRange("Worksheet Line No.", "Source Prod. Order Line");
                        PlanningComponent.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(0, PlanningComponent);
                    end;
                DATABASE::"Transfer Line":
                    begin
                        TransLine.Reset();
                        TransLine.SetRange("Document No.", "Source ID");
                        TransLine.SetRange("Line No.", "Source Ref. No.");
                        TransLine.SetRange("Derived From Line No.", "Source Prod. Order Line");
                        PAGE.RunModal(0, TransLine);
                    end;
                DATABASE::"Service Line":
                    begin
                        ServLine.SetRange("Document Type", "Source Subtype");
                        ServLine.SetRange("Document No.", "Source ID");
                        ServLine.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(0, ServLine);
                    end;
                DATABASE::"Job Planning Line":
                    begin
                        JobPlanningLine.SetRange(Status, "Source Subtype");
                        JobPlanningLine.SetRange("Job No.", "Source ID");
                        JobPlanningLine.SetRange("Job Contract Entry No.", "Source Ref. No.");
                        PAGE.RunModal(0, JobPlanningLine);
                    end;
                DATABASE::"Assembly Header":
                    begin
                        AssemblyHeader.SetRange("Document Type", "Source Subtype");
                        AssemblyHeader.SetRange("No.", "Source ID");
                        PAGE.RunModal(0, AssemblyHeader);
                    end;
                DATABASE::"Assembly Line":
                    begin
                        AssemblyLine.SetRange("Document Type", "Source Subtype");
                        AssemblyLine.SetRange("Document No.", "Source ID");
                        AssemblyLine.SetRange("Line No.", "Source Ref. No.");
                        PAGE.RunModal(0, AssemblyLine);
                    end;
            end;

        OnAfterLookupReserved(ReservEntry);
    end;

    local procedure QuantityBaseOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupReserved(var ReservEntry: Record "Reservation Entry")
    begin
    end;
}

