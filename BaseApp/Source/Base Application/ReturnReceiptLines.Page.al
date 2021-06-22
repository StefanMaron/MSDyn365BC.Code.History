page 6667 "Return Receipt Lines"
{
    Caption = 'Return Receipt Lines';
    Editable = false;
    PageType = List;
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
                    StyleExpr = 'Strong';
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
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
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies either the name of or the description of the item, general ledger account or item charge.';
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
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                    Visible = true;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of units of the item, general ledger account, or item charge on the line.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
                field("Quantity Invoiced"; "Quantity Invoiced")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
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
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        ReturnRcptHeader: Record "Return Receipt Header";
                    begin
                        ReturnRcptHeader.Get("Document No.");
                        PAGE.Run(PAGE::"Posted Return Receipt", ReturnRcptHeader);
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DocumentNoHideValue := false;
        DocumentNoOnFormat;
    end;

    trigger OnOpenPage()
    begin
        if AssignmentType = AssignmentType::Sale then
            SetRange("Sell-to Customer No.", SellToCustomerNo);
        FilterGroup(2);
        SetRange(Type, Type::Item);
        SetFilter(Quantity, '<>0');
        SetRange(Correction, false);
        SetRange("Job No.", '');
        FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
    end;

    var
        FromReturnRcptLine: Record "Return Receipt Line";
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        SellToCustomerNo: Code[20];
        UnitCost: Decimal;
        AssignmentType: Option Sale,Purchase;
        [InDataSet]
        DocumentNoHideValue: Boolean;

    procedure InitializeSales(NewItemChargeAssgnt: Record "Item Charge Assignment (Sales)"; NewSellToCustomerNo: Code[20]; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntSales := NewItemChargeAssgnt;
        SellToCustomerNo := NewSellToCustomerNo;
        UnitCost := NewUnitCost;
        AssignmentType := AssignmentType::Sale;
    end;

    procedure InitializePurchase(NewItemChargeAssgnt: Record "Item Charge Assignment (Purch)"; NewUnitCost: Decimal)
    begin
        ItemChargeAssgntPurch := NewItemChargeAssgnt;
        UnitCost := NewUnitCost;
        AssignmentType := AssignmentType::Purchase;
    end;

    local procedure IsFirstLine(DocNo: Code[20]; LineNo: Integer): Boolean
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        TempReturnRcptLine.Reset();
        TempReturnRcptLine.CopyFilters(Rec);
        TempReturnRcptLine.SetRange("Document No.", DocNo);
        if not TempReturnRcptLine.FindFirst then begin
            ReturnRcptLine.CopyFilters(Rec);
            ReturnRcptLine.SetRange("Document No.", DocNo);
            ReturnRcptLine.FindFirst;
            TempReturnRcptLine := ReturnRcptLine;
            TempReturnRcptLine.Insert();
        end;
        if TempReturnRcptLine."Line No." = LineNo then
            exit(true);
    end;

    local procedure LookupOKOnPush()
    begin
        FromReturnRcptLine.Copy(Rec);
        CurrPage.SetSelectionFilter(FromReturnRcptLine);
        if FromReturnRcptLine.FindFirst then
            // CETAF start
            if AssignmentType = AssignmentType::Sale then begin
                ItemChargeAssgntSales."Unit Cost" := UnitCost;
                AssignItemChargeSales.CreateRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntSales);
            end else
                if AssignmentType = AssignmentType::Purchase then begin
                    ItemChargeAssgntPurch."Unit Cost" := UnitCost;
                    AssignItemChargePurch.CreateReturnRcptChargeAssgnt(FromReturnRcptLine, ItemChargeAssgntPurch);
                end;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if not IsFirstLine("Document No.", "Line No.") then
            DocumentNoHideValue := true;
    end;
}

