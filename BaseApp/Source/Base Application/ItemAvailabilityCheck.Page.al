page 1872 "Item Availability Check"
{
    AutoSplitKey = false;
    Caption = 'Availability Check';
    DelayedInsert = false;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    MultipleNewLines = false;
    PopulateAllFields = false;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SaveValues = false;
    ShowFilter = true;
    SourceTable = Item;
    SourceTableTemporary = false;

    layout
    {
        area(content)
        {
            label(Control2)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Heading;
                ShowCaption = false;
            }
            group(Inventory)
            {
                Caption = 'Inventory';
                field(InventoryQty; InventoryQty)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = AvailableInventoryCaption;
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field(TotalQuantity; TotalQuantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Shortage';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory. The Total Quantity field is used to calculate the Available Inventory field as follows: Available Inventory = Total Quantity - Reserved Quantity.';
                }
                field("All locations"; Inventory)
                {
                    ApplicationArea = Location;
                    Caption = 'All locations';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of the item that is currently in inventory at all locations.';

                    trigger OnDrillDown()
                    begin
                        PAGE.RunModal(PAGE::"Item Availability by Location", Rec)
                    end;
                }
            }
            part(AvailabilityCheckDetails; "Item Availability Check Det.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = FIELD("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Manage")
            {
                Caption = '&Manage';
                action("Page Item Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item';
                    Image = Item;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    RunPageMode = View;
                    ToolTip = 'View and edit detailed information for the item.';
                }
            }
            group(Create)
            {
                Caption = 'Create';
                action("Purchase Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Purchase Invoice';
                    Image = NewPurchaseInvoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Create a new purchase invoice.';

                    trigger OnAction()
                    begin
                        ShowNewPurchaseDocument(DummyPurchaseHeader."Document Type"::Invoice);
                    end;
                }
                action("Purchase Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Purchase Order';
                    Image = NewOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Create a new purchase order.';

                    trigger OnAction()
                    begin
                        ShowNewPurchaseDocument(DummyPurchaseHeader."Document Type"::Order);
                    end;
                }
            }
        }
    }

    var
        DummyPurchaseHeader: Record "Purchase Header";
        TotalQuantity: Decimal;
        InventoryQty: Decimal;
        LocationCode: Code[10];
        Heading: Text;
        SelectVentorTxt: Label 'Select a vendor to buy from.';
        AvailableInventoryLbl: Label 'Available Inventory';
        AvailableInventoryCaption: Text;

    procedure PopulateDataOnNotification(var AvailabilityCheckNotification: Notification; ItemNo: Code[20]; UnitOfMeasureCode: Code[20]; InventoryQty: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity: Decimal; EarliestAvailDate: Date; LocationCode: Code[10])
    begin
        AvailabilityCheckNotification.SetData('ItemNo', ItemNo);
        AvailabilityCheckNotification.SetData('UnitOfMeasureCode', UnitOfMeasureCode);
        AvailabilityCheckNotification.SetData('GrossReq', Format(GrossReq));
        AvailabilityCheckNotification.SetData('ReservedReq', Format(ReservedReq));
        AvailabilityCheckNotification.SetData('SchedRcpt', Format(SchedRcpt));
        AvailabilityCheckNotification.SetData('ReservedRcpt', Format(ReservedRcpt));
        AvailabilityCheckNotification.SetData('CurrentQuantity', Format(CurrentQuantity));
        AvailabilityCheckNotification.SetData('CurrentReservedQty', Format(CurrentReservedQty));
        AvailabilityCheckNotification.SetData('TotalQuantity', Format(TotalQuantity));
        AvailabilityCheckNotification.SetData('InventoryQty', Format(InventoryQty));
        AvailabilityCheckNotification.SetData('EarliestAvailDate', Format(EarliestAvailDate));
        AvailabilityCheckNotification.SetData('LocationCode', LocationCode);
    end;

    [Scope('OnPrem')]
    procedure InitializeFromNotification(AvailabilityCheckNotification: Notification)
    var
        GrossReq: Decimal;
        SchedRcpt: Decimal;
        ReservedReq: Decimal;
        ReservedRcpt: Decimal;
        CurrentQuantity: Decimal;
        CurrentReservedQty: Decimal;
        EarliestAvailDate: Date;
    begin
        Get(AvailabilityCheckNotification.GetData('ItemNo'));
        SetRange("No.", AvailabilityCheckNotification.GetData('ItemNo'));
        Evaluate(TotalQuantity, AvailabilityCheckNotification.GetData('TotalQuantity'));
        Evaluate(InventoryQty, AvailabilityCheckNotification.GetData('InventoryQty'));
        Evaluate(LocationCode, AvailabilityCheckNotification.GetData('LocationCode'));
        CurrPage.AvailabilityCheckDetails.PAGE.SetUnitOfMeasureCode(
          AvailabilityCheckNotification.GetData('UnitOfMeasureCode'));

        if AvailabilityCheckNotification.GetData('GrossReq') <> '' then begin
            Evaluate(GrossReq, AvailabilityCheckNotification.GetData('GrossReq'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetGrossReq(GrossReq);
        end;
        if AvailabilityCheckNotification.GetData('ReservedReq') <> '' then begin
            Evaluate(ReservedReq, AvailabilityCheckNotification.GetData('ReservedReq'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetReservedReq(ReservedReq);
        end;
        if AvailabilityCheckNotification.GetData('SchedRcpt') <> '' then begin
            Evaluate(SchedRcpt, AvailabilityCheckNotification.GetData('SchedRcpt'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetSchedRcpt(SchedRcpt);
        end;
        if AvailabilityCheckNotification.GetData('ReservedRcpt') <> '' then begin
            Evaluate(ReservedRcpt, AvailabilityCheckNotification.GetData('ReservedRcpt'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetReservedRcpt(ReservedRcpt);
        end;
        if AvailabilityCheckNotification.GetData('CurrentQuantity') <> '' then begin
            Evaluate(CurrentQuantity, AvailabilityCheckNotification.GetData('CurrentQuantity'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentQuantity(CurrentQuantity);
        end;
        if AvailabilityCheckNotification.GetData('CurrentReservedQty') <> '' then begin
            Evaluate(CurrentReservedQty, AvailabilityCheckNotification.GetData('CurrentReservedQty'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetCurrentReservedQty(CurrentReservedQty);
        end;
        if AvailabilityCheckNotification.GetData('EarliestAvailDate') <> '' then begin
            Evaluate(EarliestAvailDate, AvailabilityCheckNotification.GetData('EarliestAvailDate'));
            CurrPage.AvailabilityCheckDetails.PAGE.SetEarliestAvailDate(EarliestAvailDate);
        end;

        if LocationCode = '' then
            AvailableInventoryCaption := AvailableInventoryLbl
        else
            AvailableInventoryCaption := StrSubstNo('%1 (%2)', AvailableInventoryLbl, LocationCode);
    end;

    procedure SetHeading(Value: Text)
    begin
        Heading := Value;
    end;

    local procedure SelectVendor(var Vendor: Record Vendor): Boolean
    var
        VendorList: Page "Vendor List";
    begin
        VendorList.LookupMode(true);
        VendorList.Caption(SelectVentorTxt);
        if VendorList.RunModal = ACTION::LookupOK then begin
            VendorList.GetRecord(Vendor);
            exit(true);
        end;

        exit(false);
    end;

    local procedure ShowNewPurchaseDocument(DocumentType: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if CreateNewPurchaseDocument(DocumentType, PurchaseHeader) then
            case DocumentType of
                PurchaseHeader."Document Type"::Invoice:
                    PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
                PurchaseHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
            end;
    end;

    local procedure CreateNewPurchaseDocument(DocumentType: Integer; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        if "Vendor No." = '' then begin
            if not SelectVendor(Vendor) then
                exit(false);

            "Vendor No." := Vendor."No."
        end;
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", "Vendor No.");
        PurchaseHeader.Modify(true);

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", 10000);
        PurchaseLine.Insert(true);

        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Validate("No.", "No.");
        PurchaseLine.Modify(true);

        exit(true);
    end;
}

