page 5856 "Get Post.Doc - P.RcptLn Sbfrm"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Purch. Rcpt. Line";

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
                    ToolTip = 'Specifies the receipt number.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the date the items were expected.';
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
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
                    ToolTip = 'Specifies the cross-reference number related to the item.';
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
                    ToolTip = 'Specifies that this item is a catalog item.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies either the name of or a description of the item or general ledger account.';
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
                    ToolTip = 'Specifies the code for the location where the receipt line is registered.';
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
                    ToolTip = 'Specifies the number of units of the item specified on the line.';
                }
                field("Qty. Rcd. Not Invoiced"; "Qty. Rcd. Not Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the quantity of the returned item that has been posted as received but that has not yet been posted as invoiced.';
                }
                field(RemainingQty; RemainingQty)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Remaining Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity from the posted document line that remains in inventory.';
                }
                field(AppliedQty; GetAppliedQty)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Applied Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item in the line that has been used for outbound transactions.';
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
                action("Show Document")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ShowDocument;
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        ItemTrackingLines;
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
            PurchRcptLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := PurchRcptLine;
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

        PurchRcptLine := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                PurchRcptLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := PurchRcptLine;
        Find;
        exit(RealSteps);
    end;

    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        RemainingQty: Decimal;
        RevUnitCostLCY: Decimal;
        RevQtyFilter: Boolean;
        FillExactCostReverse: Boolean;
        Visible: Boolean;
        ShowRec: Boolean;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    var
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        RemainingQty2: Decimal;
        RevUnitCostLCY2: Decimal;
    begin
        TempPurchRcptLine.Reset();
        TempPurchRcptLine.CopyFilters(Rec);
        TempPurchRcptLine.SetRange("Document No.", "Document No.");
        if not TempPurchRcptLine.FindFirst then begin
            RemainingQty2 := RemainingQty;
            RevUnitCostLCY2 := RevUnitCostLCY;
            PurchRcptLine2.CopyFilters(Rec);
            PurchRcptLine2.SetRange("Document No.", "Document No.");
            if not PurchRcptLine2.FindSet then
                exit(false);
            repeat
                ShowRec := IsShowRec(PurchRcptLine2);
                if ShowRec then begin
                    TempPurchRcptLine := PurchRcptLine2;
                    TempPurchRcptLine.Insert();
                end;
            until (PurchRcptLine2.Next = 0) or ShowRec;
            RemainingQty := RemainingQty2;
            RevUnitCostLCY := RevUnitCostLCY2;
        end;

        exit("Line No." = TempPurchRcptLine."Line No.");
    end;

    local procedure IsShowRec(PurchRcptLine2: Record "Purch. Rcpt. Line"): Boolean
    begin
        with PurchRcptLine2 do begin
            RemainingQty := 0;
            if RevQtyFilter and (Type = Type::" ") then
                exit("Attached to Line No." = 0);
            if Type <> Type::Item then
                exit(true);
            if ("Job No." <> '') or ("Prod. Order No." <> '') then
                exit(not RevQtyFilter);
            CalcReceivedPurchNotReturned(RemainingQty, RevUnitCostLCY, FillExactCostReverse);
            if not RevQtyFilter then
                exit(true);
            exit(RemainingQty > 0);
        end;
    end;

    local procedure GetAppliedQty(): Decimal
    begin
        if (Type = Type::Item) and (Quantity - RemainingQty > 0) then
            exit(Quantity - RemainingQty);
        exit(0);
    end;

    procedure Initialize(NewRevQtyFilter: Boolean; NewFillExactCostReverse: Boolean; NewVisible: Boolean)
    begin
        RevQtyFilter := NewRevQtyFilter;
        FillExactCostReverse := NewFillExactCostReverse;
        Visible := NewVisible;

        if Visible then begin
            TempPurchRcptLine.Reset();
            TempPurchRcptLine.DeleteAll();
        end;
    end;

    procedure GetSelectedLine(var FromPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        FromPurchRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromPurchRcptLine);
    end;

    local procedure ShowDocument()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if not PurchRcptHeader.Get("Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        GetSelectedLine(FromPurchRcptLine);
        FromPurchRcptLine.ShowItemTrackingLines;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            DocumentNoHideValue := true;
    end;
}

