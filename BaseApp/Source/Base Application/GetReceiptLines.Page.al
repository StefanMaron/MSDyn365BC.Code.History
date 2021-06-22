page 5709 "Get Receipt Lines"
{
    Caption = 'Get Receipt Lines';
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Line';
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
                    ApplicationArea = Suite;
                    HideValue = DocumentNoHideValue;
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
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
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of additional receipts posted.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the currency that is used on the entry.';
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
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of the item on the line.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                    Visible = false;
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                    Visible = false;
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Qty. Rcd. Not Invoiced"; "Qty. Rcd. Not Invoiced")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of the received item that has been posted as received but that has not yet been posted as invoiced.';
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
        area(navigation)
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
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        PurchRcptHeader.Get("Document No.");
                        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader);
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action("Item &Tracking Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View serial or lot numbers that are assigned to items.';

                    trigger OnAction()
                    begin
                        ShowItemTrackingLines;
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

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            CreateLines;
    end;

    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        GetReceipts: Codeunit "Purch.-Get Receipt";
        [InDataSet]
        DocumentNoHideValue: Boolean;

    procedure SetPurchHeader(var PurchHeader2: Record "Purchase Header")
    begin
        PurchHeader.Get(PurchHeader2."Document Type", PurchHeader2."No.");
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Invoice);
    end;

    local procedure IsFirstDocLine(): Boolean
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        TempPurchRcptLine.Reset();
        TempPurchRcptLine.CopyFilters(Rec);
        TempPurchRcptLine.SetRange("Document No.", "Document No.");
        if not TempPurchRcptLine.FindFirst then begin
            PurchRcptLine.CopyFilters(Rec);
            PurchRcptLine.SetRange("Document No.", "Document No.");
            PurchRcptLine.SetFilter("Qty. Rcd. Not Invoiced", '<>0');
            if PurchRcptLine.FindFirst then begin
                TempPurchRcptLine := PurchRcptLine;
                TempPurchRcptLine.Insert();
            end;
        end;
        if "Line No." = TempPurchRcptLine."Line No." then
            exit(true);
    end;

    local procedure CreateLines()
    begin
        CurrPage.SetSelectionFilter(Rec);
        GetReceipts.SetPurchHeader(PurchHeader);
        GetReceipts.CreateInvLines(Rec);
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstDocLine then
            DocumentNoHideValue := true;
    end;
}

