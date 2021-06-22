page 5814 "Item Charge Assignment (Sales)"
{
    AutoSplitKey = true;
    Caption = 'Item Charge Assignment (Sales)';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Item Charge';
    RefreshOnActivate = true;
    SourceTable = "Item Charge Assignment (Sales)";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the type of the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. Line No."; "Applies-to Doc. Line No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the number of the line on the document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the item number on the document line that this item charge is assigned to.';
                }
                field(Description; Description)
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a description of the item on the document line that this item charge is assigned to.';
                }
                field("Qty. to Assign"; "Qty. to Assign")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies how many units of the item charge will be assigned to the document line. If the document has more than one line of type Item, then this quantity reflects the distribution that you selected when you chose the Suggest Item Charge Assignment action.';

                    trigger OnValidate()
                    begin
                        if SalesLine2.Quantity * "Qty. to Assign" < 0 then
                            Error(Text000,
                              FieldCaption("Qty. to Assign"), SalesLine2.FieldCaption(Quantity));
                        QtytoAssignOnAfterValidate;
                    end;
                }
                field("Qty. Assigned"; "Qty. Assigned")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of units of the item charge will be the assigned to the document line.';
                }
                field("Amount to Assign"; "Amount to Assign")
                {
                    ApplicationArea = ItemCharges;
                    Editable = false;
                    ToolTip = 'Specifies the value of the item charge that will be the assigned to the document line.';
                }
                field(GrossWeight; GrossWeight)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the initial weight of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(UnitVolume; UnitVolume)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Unit Volume';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the volume of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(QtyToShipBase; QtyToShipBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. to Ship (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have not yet been posted as shipped.';
                }
                field(QtyShippedBase; QtyShippedBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. Shipped (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have been posted as shipped.';
                }
                field(QtyToRetReceiveBase; QtyToRetReceiveBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Return Qty. to Receive (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies a value if the sales line on this assignment line Specifies units that have not been posted as a received return from your customer.';
                }
                field(QtyRetReceivedBase; QtyRetReceivedBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Return Qty. Received (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of returned units that have been posted as received on the sales line on this assignment line.';
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group(Assignable)
                    {
                        Caption = 'Assignable';
                        field(AssignableQty; AssignableQty)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Total (Qty.)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(AssignableAmount; AssignableAmount)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Total (Amount)';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total value of the item charge that you can assign to the related document line.';
                        }
                    }
                    group("To Assign")
                    {
                        Caption = 'To Assign';
                        field(TotalQtyToAssign; TotalQtyToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total quantity of the item charge that you can assign to the related document line.';
                        }
                        field(TotalAmountToAssign; TotalAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Amount to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ToolTip = 'Specifies the total value of the item charge that you can assign to the related document line.';
                        }
                    }
                    group("Rem. to Assign")
                    {
                        Caption = 'Rem. to Assign';
                        field(RemQtyToAssign; RemQtyToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Qty. to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemQtyToAssign <> 0;
                            ToolTip = 'Specifies the quantity of the item charge that you have not yet assigned to items in the assignment lines.';
                        }
                        field(RemAmountToAssign; RemAmountToAssign)
                        {
                            ApplicationArea = ItemCharges;
                            Caption = 'Rem. Amount to Assign';
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            Style = Unfavorable;
                            StyleExpr = RemAmountToAssign <> 0;
                            ToolTip = 'Specifies the value of the quantity of the item charge that has not yet been assigned.';
                        }
                    }
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
                action(GetShipmentLines)
                {
                    AccessByPermission = TableData "Sales Shipment Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get &Shipment Lines';
                    Image = Shipment;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Select multiple shipments to the same customer because you want to combine them on one invoice.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
                        ShipmentLines: Page "Sales Shipment Lines";
                    begin
                        SalesLine2.TestField("Qty. to Invoice");

                        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntSales.SetRange("Document Line No.", "Document Line No.");

                        ShipmentLines.SetTableView(SalesShptLine);
                        if ItemChargeAssgntSales.FindLast then
                            ShipmentLines.InitializeSales(ItemChargeAssgntSales, SalesLine2."Sell-to Customer No.", UnitCost)
                        else
                            ShipmentLines.InitializeSales(Rec, SalesLine2."Sell-to Customer No.", UnitCost);

                        ShipmentLines.LookupMode(true);
                        ShipmentLines.RunModal;
                    end;
                }
                action(GetReturnReceiptLines)
                {
                    AccessByPermission = TableData "Return Receipt Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get &Return Receipt Lines';
                    Image = ReturnReceipt;
                    ToolTip = 'Select a posted purchase return receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original purchase return.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
                        ReceiptLines: Page "Return Receipt Lines";
                    begin
                        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntSales.SetRange("Document Line No.", "Document Line No.");

                        ReceiptLines.SetTableView(ReturnRcptLine);
                        if ItemChargeAssgntSales.FindLast then
                            ReceiptLines.InitializeSales(ItemChargeAssgntSales, SalesLine2."Sell-to Customer No.", UnitCost)
                        else
                            ReceiptLines.InitializeSales(Rec, SalesLine2."Sell-to Customer No.", UnitCost);

                        ReceiptLines.LookupMode(true);
                        ReceiptLines.RunModal;
                    end;
                }
                action(SuggestItemChargeAssignment)
                {
                    AccessByPermission = TableData "Item Charge" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Suggest Item &Charge Assignment';
                    Image = Suggest;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Use a function that assigns and distributes the item charge when the document has more than one line of type Item. You can select between four distribution methods. ';

                    trigger OnAction()
                    var
                        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
                    begin
                        AssignItemChargeSales.SuggestAssignment(SalesLine2, AssignableQty, AssignableAmount);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateQtyAssgnt;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateQty;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if "Document Type" = "Applies-to Doc. Type" then begin
            SalesLine2.TestField("Shipment No.", '');
            SalesLine2.TestField("Return Receipt No.", '');
        end;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange("Document Type", SalesLine2."Document Type");
        SetRange("Document No.", SalesLine2."Document No.");
        SetRange("Document Line No.", SalesLine2."Line No.");
        SetRange("Item Charge No.", SalesLine2."No.");
        FilterGroup(0);
    end;

    var
        Text000: Label 'The sign of %1 must be the same as the sign of %2 of the item charge.';
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        AssignableQty: Decimal;
        TotalQtyToAssign: Decimal;
        RemQtyToAssign: Decimal;
        AssignableAmount: Decimal;
        TotalAmountToAssign: Decimal;
        RemAmountToAssign: Decimal;
        QtyToRetReceiveBase: Decimal;
        QtyRetReceivedBase: Decimal;
        QtyToShipBase: Decimal;
        QtyShippedBase: Decimal;
        UnitCost: Decimal;
        GrossWeight: Decimal;
        UnitVolume: Decimal;
        DataCaption: Text[250];

    local procedure UpdateQtyAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        SalesLine2.CalcFields("Qty. to Assign", "Qty. Assigned");
        AssignableQty := SalesLine2."Qty. to Invoice" + SalesLine2."Quantity Invoiced" - SalesLine2."Qty. Assigned";
        OnUpdateQtyAssgntOnAfterAssignableQty(SalesLine2, AssignableQty);

        if AssignableQty <> 0 then
            UnitCost := AssignableAmount / AssignableQty
        else
            UnitCost := 0;

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", "Document Line No.");
        ItemChargeAssgntSales.CalcSums("Qty. to Assign", "Amount to Assign");
        TotalQtyToAssign := ItemChargeAssgntSales."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssgntSales."Amount to Assign";

        RemQtyToAssign := AssignableQty - TotalQtyToAssign;
        RemAmountToAssign := AssignableAmount - TotalAmountToAssign;
    end;

    local procedure UpdateQty()
    begin
        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Order, "Applies-to Doc. Type"::Invoice:
                begin
                    SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToShipBase := SalesLine."Qty. to Ship (Base)";
                    QtyShippedBase := SalesLine."Qty. Shipped (Base)";
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := 0;
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Return Order", "Applies-to Doc. Type"::"Credit Memo":
                begin
                    SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := SalesLine."Return Qty. to Receive (Base)";
                    QtyRetReceivedBase := SalesLine."Return Qty. Received (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := ReturnRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::Shipment:
                begin
                    SalesShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToRetReceiveBase := 0;
                    QtyRetReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := SalesShptLine."Quantity (Base)";
                    GrossWeight := SalesLine."Gross Weight";
                    UnitVolume := SalesLine."Unit Volume";
                end;
        end;
    end;

    procedure Initialize(NewSalesLine: Record "Sales Line"; NewLineAmt: Decimal)
    begin
        SalesLine2 := NewSalesLine;
        DataCaption := SalesLine2."No." + ' ' + SalesLine2.Description;
        AssignableAmount := NewLineAmt;
    end;

    local procedure QtytoAssignOnAfterValidate()
    begin
        CurrPage.Update(false);
        UpdateQtyAssgnt;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyAssgntOnAfterAssignableQty(var SalesLine: Record "Sales Line"; var AssignableQty: Decimal)
    begin
    end;
}

