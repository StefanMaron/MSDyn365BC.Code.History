page 12155 "Subcontr.Transfer Ord. Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Transfer Line";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item number that is assigned to the item in inventory.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code of the variant for which another variant can serve as a substitute.';
                    Visible = false;
                }
                field("WIP Item"; Rec."WIP Item")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the item is a work in process (WIP) item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity.';
                }
                field("WIP Quantity"; Rec."WIP Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of work in process (WIP) items on a subcontractor transfer order.';
                }
                field("Reserved Quantity Inbnd."; Rec."Reserved Quantity Inbnd.")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of inbound items that are reserved.';
                }
                field("Reserved Quantity Outbnd."; Rec."Reserved Quantity Outbnd.")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of outbound items that are reserved.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the item.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure for the item.';
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that will be shipped.';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that have been shipped.';

                    trigger OnDrillDown()
                    var
                        TransShptLine: Record "Transfer Shipment Line";
                    begin
                        TestField("Document No.");
                        TestField("Item No.");
                        TransShptLine.SetCurrentKey("Transfer Order No.", "Item No.", "Shipment Date");
                        TransShptLine.SetRange("Transfer Order No.", "Document No.");
                        TransShptLine.SetRange("Item No.", "Item No.");
                        PAGE.RunModal(0, TransShptLine);
                    end;
                }
                field("WIP Qty. To Ship"; Rec."WIP Qty. To Ship")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of work in process (WIP) items that will be shipped on a subcontractor transfer order.';
                }
                field("WIP Qty. Shipped"; Rec."WIP Qty. Shipped")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of work in process (WIP) items that have shipped on a subcontractor transfer order.';
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that will be received.';
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of items that have been received.';

                    trigger OnDrillDown()
                    var
                        TransRcptLine: Record "Transfer Receipt Line";
                    begin
                        TestField("Document No.");
                        TestField("Item No.");
                        TransRcptLine.SetCurrentKey("Transfer Order No.", "Item No.", "Receipt Date");
                        TransRcptLine.SetRange("Transfer Order No.", "Document No.");
                        TransRcptLine.SetRange("Item No.", "Item No.");
                        PAGE.RunModal(0, TransRcptLine);
                    end;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the items were shipped.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date of receipt.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company that handles the shipment.';
                    Visible = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company that handles the shipment.';
                    Visible = false;
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the time it takes from when the order is shipped from the warehouse to when the order is delivered to the customer''s address.';
                    Visible = false;
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the outbound warehouse handling time for the location. The program uses it to calculate date fields on the sales order line.';
                    Visible = false;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the inbound warehouse handling time for the location.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatExpression = '1,2,6';
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Manufacturing;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    ToolTip = 'Specifies a code for a shortcut dimension.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
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
                action(Reserve)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Reserve';
                    Image = Reserve;
                    ToolTip = 'Mark this as reserved.';

                    trigger OnAction()
                    begin
                        Find();
                        ShowReservation();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability By")
                {
                    Caption = 'Item Availability By';
                    Image = ItemAvailability;
                    action(Period)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the related period.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByPeriod());
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View the related variant.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByVariant());
                        end;
                    }
                    action(Location)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the related location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromTransLine(Rec, ItemAvailFormsMgt.ByLocation());
                        end;
                    }
                }
                action(Dimensions)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View the related dimensions.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                group("Item &Tracking Lines")
                {
                    Caption = 'Item &Tracking Lines';
                    Image = AllLines;
                    action(Shipment)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Shipment';
                        Image = Shipment;
                        ToolTip = 'View the related shipment.';

                        trigger OnAction()
                        begin
                            OpenItemTrackingLines("Transfer Direction"::Outbound);
                        end;
                    }
                    action(Receipt)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Receipt';
                        Image = Receipt;
                        ToolTip = 'View the related receipt.';

                        trigger OnAction()
                        begin
                            OpenItemTrackingLines("Transfer Direction"::Inbound);
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        if not TransferLineReserve.DeleteLineConfirm(Rec) then
            exit(false);
        TransferLineReserve.DeleteLine(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ShortcutDimCode: array[8] of Code[20];

    [Scope('OnPrem')]
    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;
}

