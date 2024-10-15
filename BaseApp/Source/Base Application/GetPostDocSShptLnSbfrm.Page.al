page 5851 "Get Post.Doc - S.ShptLn Sbfrm"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Sales Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the customer.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                    Visible = false;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Nonstock; Nonstock)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies that the item on the sales line is a catalog item, which means it is not normally kept in inventory.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies either the name of or the description of the item, general ledger account or item charge.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location in which the invoice line was registered.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge on the line.';
                }
                field("Qty. Shipped Not Invoiced"; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the quantity of the shipped item that has been posted as shipped but that has not yet been posted as invoiced.';
                }
                field(QtyNotReturned; QtyNotReturned)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Qty. Not Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity from the posted document line that has been shipped to the customer and not returned by the customer.';
                }
                field(QtyReturned; GetQtyReturned)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Qty. Returned';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity that was returned.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field(RevUnitCostLCY; RevUnitCostLCY)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatType = 2;
                    Caption = 'Reverse Unit Cost (LCY)';
                    ToolTip = 'Specifies the unit cost that will appear on the new document lines.';
                    Visible = false;
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Blanket Order No."; "Blanket Order No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order that the record originates from.';
                    Visible = false;
                }
                field("Blanket Order Line No."; "Blanket Order Line No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the blanket order line that the record originates from.';
                    Visible = false;
                }
                field("Appl.-from Item Entry"; "Appl.-from Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied from.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ShowDocument)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowPostedShipment;
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        ShowShptItemTrackingLines;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not Visible then
            exit(false);

        if Find(Which) then begin
            SalesShptLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := SalesShptLine;
                    if Find(Which) then
                        while true do begin
                            ShowRec := IsShowRec(Rec);
                            if ShowRec then
                                exit(true);
                            if Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        SalesShptLine := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                SalesShptLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := SalesShptLine;
        Find;
        exit(RealSteps);
    end;

    var
        SalesShptLine: Record "Sales Shipment Line";
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        QtyNotReturned: Decimal;
        RevUnitCostLCY: Decimal;
        RevQtyFilter: Boolean;
        FillExactCostReverse: Boolean;
        Visible: Boolean;
        ShowRec: Boolean;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        SalesShptLine2: Record "Sales Shipment Line";
        QtyNotReturned2: Decimal;
        RevUnitCostLCY2: Decimal;
    begin
        TempSalesShptLine.Reset();
        TempSalesShptLine.CopyFilters(Rec);
        TempSalesShptLine.SetRange("Document No.", "Document No.");
        if not TempSalesShptLine.FindFirst then begin
            QtyNotReturned2 := QtyNotReturned;
            RevUnitCostLCY2 := RevUnitCostLCY;
            SalesShptLine2.CopyFilters(Rec);
            SalesShptLine2.SetRange("Document No.", "Document No.");
            if not SalesShptLine2.FindSet then
                exit(false);
            repeat
                ShowRec := IsShowRec(SalesShptLine2);
                if ShowRec then begin
                    TempSalesShptLine := SalesShptLine2;
                    TempSalesShptLine.Insert();
                end;
            until (SalesShptLine2.Next = 0) or ShowRec;
            QtyNotReturned := QtyNotReturned2;
            RevUnitCostLCY := RevUnitCostLCY2;
        end;

        exit("Line No." = TempSalesShptLine."Line No.");
    end;

    local procedure IsShowRec(SalesShptLine2: Record "Sales Shipment Line"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsShowRec(Rec, SalesShptLine2, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        with SalesShptLine2 do begin
            QtyNotReturned := 0;
            if RevQtyFilter and (Type = Type::" ") then
                exit("Attached to Line No." = 0);
            if Type <> Type::Item then
                exit(true);
            CalcShippedSaleNotReturned(QtyNotReturned, RevUnitCostLCY, FillExactCostReverse);
            if not RevQtyFilter then
                exit(true);
            exit(QtyNotReturned > 0);
        end;
    end;

    local procedure GetQtyReturned(): Decimal
    begin
        if (Type = Type::Item) and (Quantity - QtyNotReturned > 0) then
            exit(Quantity - QtyNotReturned);
        exit(0);
    end;

    procedure Initialize(NewRevQtyFilter: Boolean; NewFillExactCostReverse: Boolean; NewVisible: Boolean)
    begin
        RevQtyFilter := NewRevQtyFilter;
        FillExactCostReverse := NewFillExactCostReverse;
        Visible := NewVisible;

        if Visible then begin
            TempSalesShptLine.Reset();
            TempSalesShptLine.DeleteAll();
        end;
    end;

    procedure GetSelectedLine(var FromSalesShptLine: Record "Sales Shipment Line")
    begin
        FromSalesShptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromSalesShptLine);
    end;

    local procedure ShowPostedShipment()
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        if not SalesShptHeader.Get("Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Sales Shipment", SalesShptHeader);
    end;

    local procedure ShowShptItemTrackingLines()
    var
        FromSalesShptLine: Record "Sales Shipment Line";
    begin
        GetSelectedLine(FromSalesShptLine);
        FromSalesShptLine.ShowItemTrackingLines;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsShowRec(var SalesShipmentLine: Record "Sales Shipment Line"; var SalesShipmentLine2: Record "Sales Shipment Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
}

