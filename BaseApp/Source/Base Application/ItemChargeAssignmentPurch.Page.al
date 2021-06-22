page 5805 "Item Charge Assignment (Purch)"
{
    AutoSplitKey = true;
    Caption = 'Item Charge Assignment (Purch)';
    DataCaptionExpression = DataCaption;
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = Worksheet;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Item Charge';
    RefreshOnActivate = true;
    SourceTable = "Item Charge Assignment (Purch)";

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
                        if PurchLine2.Quantity * "Qty. to Assign" < 0 then
                            Error(Text000,
                              FieldCaption("Qty. to Assign"), PurchLine2.FieldCaption(Quantity));
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
                field("<Gross Weight>"; GrossWeight)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the initial weight of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field("<Unit Volume>"; UnitVolume)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Unit Volume';
                    DecimalPlaces = 0 : 4;
                    Editable = false;
                    ToolTip = 'Specifies the volume of one unit of the item. The value may be used to complete customs documents and waybills.';
                }
                field(QtyToReceiveBase; QtyToReceiveBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. to Receive (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have not yet been posted as received.';
                }
                field(QtyReceivedBase; QtyReceivedBase)
                {
                    ApplicationArea = ItemCharges;
                    BlankZero = true;
                    Caption = 'Qty. Received (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item on the documents line for this item charge assignment have been posted as received.';
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
                        field(AssgntAmount; AssgntAmount)
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
                            ToolTip = 'Specifies the quantity of the item charge that has not yet been assigned.';
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
                action(GetReceiptLines)
                {
                    AccessByPermission = TableData "Purch. Rcpt. Header" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Get &Receipt Lines';
                    Image = Receipt;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Select a posted purchase receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original purchase receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                        ReceiptLines: Page "Purch. Receipt Lines";
                    begin
                        PurchLine2.TestField("Qty. to Invoice");

                        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");

                        ReceiptLines.SetTableView(PurchRcptLine);
                        if ItemChargeAssgntPurch.FindLast then
                            ReceiptLines.Initialize(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
                        else
                            ReceiptLines.Initialize(Rec, PurchLine2."Unit Cost");

                        ReceiptLines.LookupMode(true);
                        ReceiptLines.RunModal;
                    end;
                }
                action(GetTransferReceiptLines)
                {
                    AccessByPermission = TableData "Transfer Header" = R;
                    ApplicationArea = Location;
                    Caption = 'Get &Transfer Receipt Lines';
                    Image = TransferReceipt;
                    ToolTip = 'Select a posted transfer receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original transfer receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                        PostedTransferReceiptLines: Page "Posted Transfer Receipt Lines";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");

                        TransferRcptLine.FilterGroup(2);
                        TransferRcptLine.SetFilter("Item No.", '<>%1', '');
                        TransferRcptLine.SetFilter(Quantity, '<>0');
                        TransferRcptLine.FilterGroup(0);

                        PostedTransferReceiptLines.SetTableView(TransferRcptLine);
                        if ItemChargeAssgntPurch.FindLast then
                            PostedTransferReceiptLines.Initialize(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
                        else
                            PostedTransferReceiptLines.Initialize(Rec, PurchLine2."Unit Cost");

                        PostedTransferReceiptLines.LookupMode(true);
                        PostedTransferReceiptLines.RunModal;
                    end;
                }
                action(GetReturnShipmentLines)
                {
                    AccessByPermission = TableData "Return Shipment Header" = R;
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Get Return &Shipment Lines';
                    Image = ReturnShipment;
                    ToolTip = 'Select a posted return shipment for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original return shipment.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                        ShipmentLines: Page "Return Shipment Lines";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");

                        ShipmentLines.SetTableView(ReturnShptLine);
                        if ItemChargeAssgntPurch.FindLast then
                            ShipmentLines.Initialize(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
                        else
                            ShipmentLines.Initialize(Rec, PurchLine2."Unit Cost");

                        ShipmentLines.LookupMode(true);
                        ShipmentLines.RunModal;
                    end;
                }
                action(GetSalesShipmentLines)
                {
                    AccessByPermission = TableData "Sales Shipment Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get S&ales Shipment Lines';
                    Image = SalesShipment;
                    ToolTip = 'Select a posted sales shipment for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original sales shipment.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                        SalesShipmentLines: Page "Sales Shipment Lines";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");

                        SalesShipmentLines.SetTableView(SalesShptLine);
                        if ItemChargeAssgntPurch.FindLast then
                            SalesShipmentLines.InitializePurchase(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
                        else
                            SalesShipmentLines.InitializePurchase(Rec, PurchLine2."Unit Cost");

                        SalesShipmentLines.LookupMode(true);
                        SalesShipmentLines.RunModal;
                    end;
                }
                action(GetReturnReceiptLines)
                {
                    AccessByPermission = TableData "Return Receipt Header" = R;
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Get Ret&urn Receipt Lines';
                    Image = ReturnReceipt;
                    ToolTip = 'Select a posted return receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original return receipt.';

                    trigger OnAction()
                    var
                        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
                        ReturnRcptLines: Page "Return Receipt Lines";
                    begin
                        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
                        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
                        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");

                        ReturnRcptLines.SetTableView(ReturnRcptLine);
                        if ItemChargeAssgntPurch.FindLast then
                            ReturnRcptLines.InitializePurchase(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
                        else
                            ReturnRcptLines.InitializePurchase(Rec, PurchLine2."Unit Cost");

                        ReturnRcptLines.LookupMode(true);
                        ReturnRcptLines.RunModal;
                    end;
                }
                action(SuggestItemChargeAssignment)
                {
                    AccessByPermission = TableData "Item Charge" = R;
                    ApplicationArea = ItemCharges;
                    Caption = 'Suggest &Item Charge Assignment';
                    Ellipsis = true;
                    Image = Suggest;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Use a function that assigns and distributes the item charge when the document has more than one line of type Item. You can select between four distribution methods. ';

                    trigger OnAction()
                    var
                        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
                    begin
                        AssignItemChargePurch.SuggestAssgnt(PurchLine2, AssignableQty, AssgntAmount);
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
            PurchLine2.TestField("Receipt No.", '');
            PurchLine2.TestField("Return Shipment No.", '');
        end;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange("Document Type", PurchLine2."Document Type");
        SetRange("Document No.", PurchLine2."Document No.");
        SetRange("Document Line No.", PurchLine2."Line No.");
        SetRange("Item Charge No.", PurchLine2."No.");
        FilterGroup(0);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if RemAmountToAssign <> 0 then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text001, RemAmountToAssign, "Document Type", "Document No."), true)
            then
                exit(false);
    end;

    var
        Text000: Label 'The sign of %1 must be the same as the sign of %2 of the item charge.';
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReturnShptLine: Record "Return Shipment Line";
        TransferRcptLine: Record "Transfer Receipt Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        AssignableQty: Decimal;
        TotalQtyToAssign: Decimal;
        RemQtyToAssign: Decimal;
        AssgntAmount: Decimal;
        TotalAmountToAssign: Decimal;
        RemAmountToAssign: Decimal;
        QtyToReceiveBase: Decimal;
        QtyReceivedBase: Decimal;
        QtyToShipBase: Decimal;
        QtyShippedBase: Decimal;
        DataCaption: Text[250];
        Text001: Label 'The remaining amount to assign is %1. It must be zero before you can post %2 %3.\ \Are you sure that you want to close the window?', Comment = '%2 = Document Type, %3 = Document No.';
        GrossWeight: Decimal;
        UnitVolume: Decimal;

    local procedure UpdateQtyAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        PurchLine2.CalcFields("Qty. to Assign", "Qty. Assigned");
        AssignableQty :=
          PurchLine2."Qty. to Invoice" + PurchLine2."Quantity Invoiced" - PurchLine2."Qty. Assigned";

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", "Document Line No.");
        ItemChargeAssgntPurch.CalcSums("Qty. to Assign", "Amount to Assign");
        TotalQtyToAssign := ItemChargeAssgntPurch."Qty. to Assign";
        TotalAmountToAssign := ItemChargeAssgntPurch."Amount to Assign";

        RemQtyToAssign := AssignableQty - TotalQtyToAssign;
        RemAmountToAssign := AssgntAmount - TotalAmountToAssign;
    end;

    local procedure UpdateQty()
    begin
        case "Applies-to Doc. Type" of
            "Applies-to Doc. Type"::Order, "Applies-to Doc. Type"::Invoice:
                begin
                    PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := PurchLine."Qty. to Receive (Base)";
                    QtyReceivedBase := PurchLine."Qty. Received (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := PurchLine."Gross Weight";
                    UnitVolume := PurchLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Return Order", "Applies-to Doc. Type"::"Credit Memo":
                begin
                    PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := PurchLine."Return Qty. to Ship (Base)";
                    QtyShippedBase := PurchLine."Return Qty. Shipped (Base)";
                    GrossWeight := PurchLine."Gross Weight";
                    UnitVolume := PurchLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::Receipt:
                begin
                    PurchRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := PurchRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := PurchRcptLine."Gross Weight";
                    UnitVolume := PurchRcptLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Return Shipment":
                begin
                    ReturnShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := ReturnShptLine."Quantity (Base)";
                    GrossWeight := ReturnShptLine."Gross Weight";
                    UnitVolume := ReturnShptLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Transfer Receipt":
                begin
                    TransferRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := TransferRcptLine.Quantity;
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := TransferRcptLine."Gross Weight";
                    UnitVolume := TransferRcptLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Sales Shipment":
                begin
                    SalesShptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := 0;
                    QtyToShipBase := 0;
                    QtyShippedBase := SalesShptLine."Quantity (Base)";
                    GrossWeight := SalesShptLine."Gross Weight";
                    UnitVolume := SalesShptLine."Unit Volume";
                end;
            "Applies-to Doc. Type"::"Return Receipt":
                begin
                    ReturnRcptLine.Get("Applies-to Doc. No.", "Applies-to Doc. Line No.");
                    QtyToReceiveBase := 0;
                    QtyReceivedBase := ReturnRcptLine."Quantity (Base)";
                    QtyToShipBase := 0;
                    QtyShippedBase := 0;
                    GrossWeight := ReturnRcptLine."Gross Weight";
                    UnitVolume := ReturnRcptLine."Unit Volume";
                end;
        end;
    end;

    procedure Initialize(NewPurchLine: Record "Purchase Line"; NewLineAmt: Decimal)
    begin
        PurchLine2 := NewPurchLine;
        DataCaption := PurchLine2."No." + ' ' + PurchLine2.Description;
        AssgntAmount := NewLineAmt;
        OnAfterInitialize(PurchLine2, AssgntAmount);
    end;

    local procedure QtytoAssignOnAfterValidate()
    begin
        CurrPage.Update(false);
        UpdateQtyAssgnt;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var PurchaseLine: Record "Purchase Line"; var AssgntAmount: Decimal)
    begin
    end;
}

