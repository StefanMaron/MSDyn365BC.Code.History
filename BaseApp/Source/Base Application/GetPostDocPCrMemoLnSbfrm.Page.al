page 5859 "Get Post.Doc-P.Cr.MemoLn Sbfrm"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Purch. Cr. Memo Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Suite;
                    HideValue = DocumentNoHideValue;
                    Lookup = false;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the credit memo number.';
                }
                field("PurchCrMemoHeader.""Posting Date"""; PurchCrMemoHeader."Posting Date")
                {
                    ApplicationArea = Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the record.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the date the items were received.';
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this item is a catalog item.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies either the name of, or a description of, the item or general ledger account.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location where the credit memo line is registered.';
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of units of the item specified on the credit memo line.';
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
                field(DirectUnitCost; DirectUnitCost)
                {
                    ApplicationArea = SalesReturnOrder;
                    AutoFormatExpression = PurchCrMemoHeader."Currency Code";
                    AutoFormatType = 2;
                    Caption = 'Direct Unit Cost';
                    ToolTip = 'Specifies the direct unit cost. ';
                    Visible = false;
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = PurchCrMemoHeader."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Line Amount';
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("PurchCrMemoHeader.""Currency Code"""; PurchCrMemoHeader."Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                    Visible = false;
                }
                field("PurchCrMemoHeader.""Prices Including VAT"""; PurchCrMemoHeader."Prices Including VAT")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Prices Including VAT';
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                    Visible = false;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; "Inv. Discount Amount")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
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
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
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
                    ApplicationArea = Suite;
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
                        ShowLineDimensions;
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
        if Find(Which) then begin
            PurchCrMemoLine := Rec;
            while true do begin
                ShowRec := IsShowRec(Rec);
                if ShowRec then
                    exit(true);
                if Next(1) = 0 then begin
                    Rec := PurchCrMemoLine;
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

        PurchCrMemoLine := Rec;
        repeat
            NextSteps := Next(Steps / Abs(Steps));
            ShowRec := IsShowRec(Rec);
            if ShowRec then begin
                RealSteps := RealSteps + NextSteps;
                PurchCrMemoLine := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := PurchCrMemoLine;
        Find;
        exit(RealSteps);
    end;

    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TempPurchCrMemoLine: Record "Purch. Cr. Memo Line" temporary;
        DirectUnitCost: Decimal;
        LineAmount: Decimal;
        [InDataSet]
        DocumentNoHideValue: Boolean;
        ShowRec: Boolean;

    local procedure IsFirstDocLine(): Boolean
    begin
        TempPurchCrMemoLine.Reset();
        TempPurchCrMemoLine.CopyFilters(Rec);
        TempPurchCrMemoLine.SetRange("Document No.", "Document No.");
        if not TempPurchCrMemoLine.FindFirst then begin
            PurchCrMemoLine.CopyFilters(Rec);
            PurchCrMemoLine.SetRange("Document No.", "Document No.");
            if not PurchCrMemoLine.FindFirst then
                exit(false);
            TempPurchCrMemoLine := PurchCrMemoLine;
            TempPurchCrMemoLine.Insert();
        end;

        if "Document No." <> PurchCrMemoHeader."No." then
            PurchCrMemoHeader.Get("Document No.");

        DirectUnitCost := "Direct Unit Cost";
        LineAmount := "Line Amount";

        exit("Line No." = TempPurchCrMemoLine."Line No.");
    end;

    local procedure IsShowRec(PurchCrMemoLine2: Record "Purch. Cr. Memo Line"): Boolean
    begin
        with PurchCrMemoLine2 do begin
            if "Document No." <> PurchCrMemoHeader."No." then
                PurchCrMemoHeader.Get("Document No.");
            if PurchCrMemoHeader."Prepayment Credit Memo" then
                exit(false);
            exit(true);
        end;
    end;

    procedure GetSelectedLine(var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        FromPurchCrMemoLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromPurchCrMemoLine);
    end;

    local procedure ShowDocument()
    begin
        if not PurchCrMemoHeader.Get("Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader);
    end;

    local procedure ShowLineDimensions()
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GetSelectedLine(FromPurchCrMemoLine);
        FromPurchCrMemoLine.ShowDimensions;
    end;

    local procedure ItemTrackingLines()
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GetSelectedLine(FromPurchCrMemoLine);
        FromPurchCrMemoLine.ShowItemTrackingLines;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            DocumentNoHideValue := true;
    end;
}

