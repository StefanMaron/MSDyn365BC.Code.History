page 5966 "Service Quote Lines"
{
    AutoSplitKey = true;
    Caption = 'Service Quote Lines';
    DataCaptionFields = "Document Type", "Document No.";
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            field(SelectionFilter; SelectionFilter)
            {
                ApplicationArea = Service;
                Caption = 'Service Quote Lines Filter';
                OptionCaption = 'All,Per Selected Service Item Line,Service Item Line Non-Related';
                ToolTip = 'Specifies a selection filter.';

                trigger OnValidate()
                begin
                    SelectionFilterOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item line number linked to this service line.';
                    Visible = false;
                }
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number linked to this service line.';
                }
                field("Service Item Serial No."; "Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the service item serial number linked to this line.';
                    Visible = false;
                }
                field("Service Item Line Description"; "Service Item Line Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the service item line in the service order.';
                    Visible = false;
                }
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
                        NoOnAfterValidate;
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the line.';
                }
                field(Nonstock; Nonstock)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the item is a catalog item.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the item, resource, or cost.';
                    Visible = false;
                }
                field("Substitution Available"; "Substitution Available")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether a substitute is available for the item.';
                    Visible = false;
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed by the resource registered on this line.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from where the items on the line should be taken and where they should be registered.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the number of item units, resource hours, cost on the service line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate;
                    end;
                }
                field("Fault Reason Code"; "Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault reason for this service line.';
                    Visible = false;
                }
                field("Fault Area Code"; "Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with this line.';
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; "Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom associated with this line.';
                    Visible = SymptomCodeVisible;
                }
                field("Fault Code"; "Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault associated with this line.';
                    Visible = FaultCodeVisible;
                }
                field("Resolution Code"; "Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the resolution associated with this line.';
                    Visible = ResolutionCodeVisible;
                }
                field("Serv. Price Adjmt. Gr. Code"; "Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service price adjustment group code that applies to this line.';
                    Visible = false;
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                }
                field("Line Discount Type"; "Line Discount Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the line discount assigned to this line.';
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
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Exclude Warranty"; "Exclude Warranty")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the warranty discount is excluded on this line.';
                }
                field("Exclude Contract Discount"; "Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the contract discount is excluded for the item, resource, or cost on this line.';
                }
                field(Warranty; Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a warranty discount is available on this line of type Item or Resource.';
                }
                field("Warranty Disc. %"; "Warranty Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the percentage of the warranty discount that is valid for the items or resources on this line.';
                    Visible = false;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contract, if the service order originated from a service contract.';
                }
                field("Contract Disc. %"; "Contract Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the contract discount percentage that is valid for the items, resources, and costs on this line.';
                    Visible = false;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                    Visible = false;
                }
                field("VAT Base Amount"; "VAT Base Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount that serves as a base for calculating the Amount Including VAT field.';
                    Visible = false;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; "Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Posting Group"; "Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the inventory posting group assigned to the item.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service line should be posted.';
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(3),
                                                                  "Dimension Value Type" = CONST(Standard),
                                                                  Blocked = CONST(false));
                    Visible = false;

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
                    Visible = false;

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
                    Visible = false;

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
                    Visible = false;

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
                    Visible = false;

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
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(Control1904739907; "Service Line FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = false;
            }
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
                        CurrPage.SaveRecord;
                    end;
                }
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
                        ApplicationArea = Location;
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
                action(ItemTrackingLines)
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
                action("Select Item &Substitution")
                {
                    ApplicationArea = Service;
                    Caption = 'Select Item &Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be sold instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        ShowItemSub;
                        CurrPage.Update(true);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateInvoiceDiscount)
                {
                    ApplicationArea = Service;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the service order.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Service-Disc. (Yes/No)", Rec);
                    end;
                }
                action("Get Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Get Price';
                    Image = Price;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        PickPrice();
                        CurrPage.Update;
                    end;
                }
                action("Get Li&ne Discount")
                {
                    ApplicationArea = Service;
                    Caption = 'Get Li&ne Discount';
                    Image = LineDiscount;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        PickDiscount();
                        CurrPage.Update;
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
                action("Insert &Starting Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Starting Fee';
                    Image = InsertStartingFee;
                    ToolTip = 'Add a general starting fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertStartFee;
                    end;
                }
                action("Insert &Travel Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Travel Fee';
                    Image = InsertTravelFee;
                    ToolTip = 'Add a general travel fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertTravelFee;
                    end;
                }
                action("Split &Resource Line")
                {
                    ApplicationArea = Service;
                    Caption = 'Split &Resource Line';
                    Image = Split;
                    ToolTip = 'Split planning lines of type Budget and Billable into two separate planning lines: Budget and Billable.';

                    trigger OnAction()
                    begin
                        SplitResourceLine;
                    end;
                }
                action("Ca&talog Items")
                {
                    AccessByPermission = TableData "Nonstock Item" = R;
                    ApplicationArea = Service;
                    Caption = 'Ca&talog Items';
                    Image = NonStockItem;
                    ToolTip = 'View the list of items that you do not carry in inventory. ';

                    trigger OnAction()
                    begin
                        ShowNonstock;
                        CurrPage.Update;
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Line No." := GetLineNo();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
        ServHeader.Get("Document Type", "Document No.");
        if ServHeader."Link Service to Service Item" then
            if SelectionFilter <> SelectionFilter::"Lines Not Item Related" then
                Validate("Service Item Line No.", ServItemLineNo)
            else
                Validate("Service Item Line No.", 0)
        else
            Validate("Service Item Line No.", 0);
    end;

    trigger OnOpenPage()
    begin
        Clear(SelectionFilter);
        SetSelectionFilter;

        ServMgtSetup.Get();
        case ServMgtSetup."Fault Reporting Level" of
            ServMgtSetup."Fault Reporting Level"::None:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := false;
                    ResolutionCodeVisible := false;
                end;
            ServMgtSetup."Fault Reporting Level"::Fault:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                begin
                    FaultAreaCodeVisible := true;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ShortcutDimCode: array[8] of Code[20];
        ServItemLineNo: Integer;
        SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related";
        [InDataSet]
        FaultAreaCodeVisible: Boolean;
        [InDataSet]
        SymptomCodeVisible: Boolean;
        [InDataSet]
        FaultCodeVisible: Boolean;
        [InDataSet]
        ResolutionCodeVisible: Boolean;

    procedure Initialize(ServItemLine: Integer)
    begin
        ServItemLineNo := ServItemLine;
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Service Lines":
                SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                SetRange("Service Item Line No.", ServItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                SetRange("Service Item Line No.", 0);
        end;
        CurrPage.Update(false);
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        OnBeforeInsertExtendedText(Rec);
        if TransferExtendedText.ServCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord;
            TransferExtendedText.InsertServExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate then
            CurrPage.Update;
    end;

    local procedure InsertStartFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 1, false) then
            CurrPage.Update;
    end;

    local procedure InsertTravelFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 0, false) then
            CurrPage.Update;
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

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update;
        SetSelectionFilter;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ServiceLine: Record "Service Line")
    begin
    end;
}

