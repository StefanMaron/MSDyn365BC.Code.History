page 5853 "Get Pst.Doc-RtrnRcptLn Subform"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Return Receipt Line";

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
                    ToolTip = 'Specifies the number of the return receipt.';
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
                    ToolTip = 'Specifies either the name of, or the description of, the item, general ledger account, or item charge.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency code for the amount on this line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location in which the return receipt line was registered.';
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
                    ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge specified on the line.';
                }
                field("Return Qty. Rcd. Not Invd."; "Return Qty. Rcd. Not Invd.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the quantity from the line that has been posted as received but that has not yet been posted as invoiced.';
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
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRecord(Which, Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(true);
    end;

    var
        ReturnRcptLine: Record "Return Receipt Line";
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    local procedure IsFirstDocLine(): Boolean
    begin
        TempReturnRcptLine.Reset();
        TempReturnRcptLine.CopyFilters(Rec);
        TempReturnRcptLine.SetRange("Document No.", "Document No.");
        if not TempReturnRcptLine.FindFirst then begin
            ReturnRcptLine.CopyFilters(Rec);
            ReturnRcptLine.SetRange("Document No.", "Document No.");
            if not ReturnRcptLine.FindFirst then
                exit(false);
            TempReturnRcptLine := ReturnRcptLine;
            TempReturnRcptLine.Insert();
        end;

        exit("Line No." = TempReturnRcptLine."Line No.");
    end;

    procedure GetSelectedLine(var FromReturnRcptLine: Record "Return Receipt Line")
    begin
        FromReturnRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnRcptLine);
    end;

    local procedure ShowDocument()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        if not ReturnRcptHeader.Get("Document No.") then
            exit;
        PAGE.Run(PAGE::"Posted Return Receipt", ReturnRcptHeader);
    end;

    local procedure ItemTrackingLines()
    var
        FromReturnRcptLine: Record "Return Receipt Line";
    begin
        GetSelectedLine(FromReturnRcptLine);
        FromReturnRcptLine.ShowItemTrackingLines;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            DocumentNoHideValue := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(Which: Text; var ReturnReceiptLine: Record "Return Receipt Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;
}

