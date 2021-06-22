page 5934 "Service Invoice Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Service Line";
    SourceTableView = WHERE("Document Type" = FILTER(Invoice));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service line.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate;
                    end;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate;
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Nonstock; Nonstock)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the item is a catalog item.';
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the line.';
                }
                field("Return Reason Code"; "Return Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code explaining why the item was returned.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from where the items on the line should be taken and where they should be registered.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the number of item units, resource hours, cost on the service line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate;
                    end;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValida;
                    end;
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                    Visible = false;
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                    Visible = false;
                }
                field("Tax Group Code"; "Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; "Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;
                }
                field("Serv. Price Adjmt. Gr. Code"; "Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service price adjustment group code that applies to this line.';
                    Visible = false;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract, if the service order originated from a service contract.';
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number linked to this service line.';
                    Visible = false;
                }
                field("Appl.-to Service Entry"; "Appl.-to Service Entry")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service ledger entry number this line is applied to.';
                    Visible = true;
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed by the resource registered on this line.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; "Appl.-to Item Entry")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the item ledger entry that the document or journal line is applied to.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(4),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(5),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(6),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(7),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(8),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = DimVisible8;

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
                action("Get &Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Get &Price';
                    Ellipsis = true;
                    Image = Price;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        PickPrice();
                    end;
                }
                action("Get Li&ne Discount")
                {
                    AccessByPermission = TableData "Sales Line Discount" = R;
                    ApplicationArea = Service;
                    Caption = 'Get Li&ne Discount';
                    Ellipsis = true;
                    Image = LineDiscount;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        PickDiscount();
                    end;
                }
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action(GetShipmentLines)
                {
                    ApplicationArea = Service;
                    Caption = 'Get &Shipment Lines';
                    Ellipsis = true;
                    Image = Shipment;
                    ToolTip = 'Select multiple shipments to the same customer because you want to combine them on one invoice.';

                    trigger OnAction()
                    begin
                        GetShipment;
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Service;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Service;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByPeriod);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByVariant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Service;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByLocation);
                        end;
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Service;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromServLine(Rec, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
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
                        OpenItemTrackingLines;
                    end;
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
        ReserveServLine: Codeunit "Service Line-Reserve";
    begin
        if (Quantity <> 0) and ItemExists("No.") then begin
            Commit();
            if not ReserveServLine.DeleteLineConfirm(Rec) then
                exit(false);
            ReserveServLine.DeleteLine(Rec);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Type := xRec.Type;
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility;
    end;

    var
        ServHeader: Record "Service Header";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ShortcutDimCode: array[8] of Code[20];
        Text000: Label 'This service invoice was created from the service contract. If you want to get shipment lines, you must create another service invoice.';
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Service-Disc. (Yes/No)", Rec);
    end;

    procedure GetShipment()
    begin
        ServHeader.Get("Document Type", "Document No.");
        if ServHeader."Contract No." <> '' then
            Error(Text000);
        CODEUNIT.Run(CODEUNIT::"Service-Get Shipment", Rec);
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);
        if TransferExtendedText.ServCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord;
            TransferExtendedText.InsertServExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate then
            UpdateForm(true);
    end;

    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
    end;

    local procedure QuantityOnAfterValidate()
    begin
        if Reserve = Reserve::Always then begin
            CurrPage.SaveRecord;
            AutoReserve;
        end;
    end;

    local procedure UnitofMeasureCodeOnAfterValida()
    begin
        if Reserve = Reserve::Always then begin
            CurrPage.SaveRecord;
            AutoReserve;
        end;
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ServiceLine: Record "Service Line")
    begin
    end;
}

