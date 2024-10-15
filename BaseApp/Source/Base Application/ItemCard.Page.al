﻿page 30 "Item Card"
{
    Caption = 'Item Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Item,History,Prices & Discounts,Approve,Request Approval';
    RefreshOnActivate = true;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(Item)
            {
                Caption = 'Item';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the item.';
                    Visible = DescriptionFieldVisible;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item that is placed in quarantine.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item card represents a physical inventory unit (Inventory), a labor time unit (Service), or a physical unit that is not tracked in inventory (Non-Inventory).';

                    trigger OnValidate()
                    begin
                        EnableControls;
                    end;
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        Get("No.");
                    end;
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the item card was last modified.';
                }
                field(GTIN; GTIN)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NOT IsService;
                    Importance = Additional;
                    ToolTip = 'Specifies the Global Trade Item Number (GTIN) for the item. For example, the GTIN is used with bar codes to track items, and when sending and receiving documents electronically. The GTIN number typically contains a Universal Product Code (UPC), or European Article Number (EAN).';
                }
                field("Item Category Code"; "Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category that the item belongs to. Item categories also contain any assigned item attributes.';

                    trigger OnValidate()
                    begin
                        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData("No.");
                        EnableCostingControls;
                    end;
                }
                field("Service Item Group"; "Service Item Group")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the service item group that the item belongs to.';
                }
                field("Automatic Ext. Texts"; "Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that an extended text that you have set up will be added automatically on sales or purchase documents for this item.';
                }
                field("Common Item No."; "Common Item No.")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the unique common item number that the intercompany partners agree upon.';
                }
                field("Purchasing Code"; "Purchasing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for a special procurement method, such as drop shipment.';
                }
            }
            group(InventoryGrp)
            {
                Caption = 'Inventory';
                Visible = IsInventoriable;
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where to find the item in the warehouse. This is informational only.';
                }
                field("Created From Nonstock Item"; "Created From Nonstock Item")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the item was created from a catalog item.';
                }
                field("Search Description"; "Search Description")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a search description that you use to find the item in lists.';
                }
                field(Inventory; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsInventoriable;
                    HideValue = IsNonInventoriable;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                    Visible = IsFoundationEnabled;

                    trigger OnAssistEdit()
                    var
                        AdjustInventory: Page "Adjust Inventory";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);

                        if RecRef.IsDirty() then begin
                            Modify(true);
                            Commit();
                        end;

                        AdjustInventory.SetItem("No.");
                        if AdjustInventory.RunModal() in [ACTION::LookupOK, ACTION::OK] then
                            Get("No.");
                        CurrPage.Update()
                    end;
                }
                field(InventoryNonFoundation; Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Inventory';
                    Enabled = IsInventoriable;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                    Visible = NOT IsFoundationEnabled;
                }
                field("Qty. on Purch. Order"; "Qty. on Purch. Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item are inbound on purchase orders, meaning listed on outstanding purchase order lines.';
                }
                field("Qty. on Prod. Order"; "Qty. on Prod. Order")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are allocated to production orders, meaning listed on outstanding production order lines.';
                }
                field("Qty. on Component Lines"; "Qty. on Component Lines")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how many units of the item are allocated as production order components, meaning listed under outstanding production order lines.';
                }
                field("Qty. on Sales Order"; "Qty. on Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units of the item are allocated to sales orders, meaning listed on outstanding sales orders lines.';
                }
                field("Qty. on Service Order"; "Qty. on Service Order")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';
                }
                field("Qty. on Job Order"; "Qty. on Job Order")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies how many units of the item are allocated to jobs, meaning listed on outstanding job planning lines.';
                }
                field("Qty. on Assembly Order"; "Qty. on Assembly Order")
                {
                    ApplicationArea = Assembly;
                    Importance = Additional;
                    ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                }
                field("Qty. on Asm. Component"; "Qty. on Asm. Component")
                {
                    ApplicationArea = Assembly;
                    Importance = Additional;
                    ToolTip = 'Specifies how many units of the item are allocated as assembly components, which means how many are listed on outstanding assembly order lines.';
                }
                field(StockoutWarningDefaultYes; "Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Stockout Warning';
                    Editable = IsInventoriable;
                    OptionCaption = 'Default (Yes),No,Yes';
                    ToolTip = 'Specifies if a warning is displayed when you enter a quantity on a sales document that brings the item''s inventory below zero.';
                    Visible = ShowStockoutWarningDefaultYes;
                }
                field(StockoutWarningDefaultNo; "Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Stockout Warning';
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies if a warning is displayed when you enter a quantity on a sales document that brings the item''s inventory below zero.';
                    Visible = ShowStockoutWarningDefaultNo;
                }
                field(PreventNegInventoryDefaultYes; "Prevent Negative Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prevent Negative Inventory';
                    Importance = Additional;
                    OptionCaption = 'Default (Yes),No,Yes';
                    ToolTip = 'Specifies if you can post a transaction that will bring the item''s inventory below zero.';
                    Visible = ShowPreventNegInventoryDefaultYes;
                }
                field(PreventNegInventoryDefaultNo; "Prevent Negative Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prevent Negative Inventory';
                    Importance = Additional;
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies if you can post a transaction that will bring the item''s inventory below zero.';
                    Visible = ShowPreventNegInventoryDefaultNo;
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Gross Weight"; "Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the gross weight of the item.';
                }
                field("Unit Volume"; "Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                }
                field("SAT Item Classification"; "SAT Item Classification")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the classification required for reporting to the Mexican tax authorities (SAT)';
                }
                field("Over-Receipt Code"; "Over-Receipt Code")
                {
                    ApplicationArea = All;
                    Visible = OverReceiptAllowed;
                    ToolTip = 'Specifies the policy that will be used for the item if more items than ordered are received.';
                }
            }
            group("Costs & Posting")
            {
                Caption = 'Costs & Posting';
                group("Cost Details")
                {
                    Caption = 'Cost Details';
                    field("Costing Method"; "Costing Method")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies how the item''s cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation.';

                        trigger OnValidate()
                        begin
                            EnableCostingControls;
                        end;
                    }
                    field("Standard Cost"; "Standard Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = StandardCostEnable;
                        ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';

                        trigger OnDrillDown()
                        var
                            ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                        begin
                            ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Rec)
                        end;
                    }
                    field("Unit Cost"; "Unit Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = UnitCostEditable;
                        Enabled = UnitCostEnable;
                        Importance = Promoted;
                        ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';

                        trigger OnDrillDown()
                        var
                            ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                        begin
                            ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Rec)
                        end;
                    }
                    field("Indirect Cost %"; "Indirect Cost %")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = IsInventoriable;
                        Importance = Additional;
                        ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    }
                    field("Last Direct Cost"; "Last Direct Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the most recent direct unit cost of the item.';
                    }
                    field("Net Invoiced Qty."; "Net Invoiced Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies how many units of the item in inventory have been invoiced.';
                    }
                    field("Cost is Adjusted"; "Cost is Adjusted")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies whether the item''s unit cost has been adjusted, either automatically or manually.';
                    }
                    field("Cost is Posted to G/L"; "Cost is Posted to G/L")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies that all the inventory costs for this item have been posted to the general ledger.';
                    }
                    field(SpecialPurchPriceListTxt; PurchPriceListsText)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Prices & Discounts';
                        Editable = false;
                        Visible = ExtendedPriceEnabled;
                        ToolTip = 'Specifies purchase price lists for the item.';

                        trigger OnDrillDown()
                        var
                            AmountType: Enum "Price Amount Type";
                            PriceType: Enum "Price Type";
                        begin
                            if PurchPriceListsText = ViewExistingTxt then
                                Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Any)
                            else
                                PAGE.RunModal(PAGE::"Purchase Price Lists");
                            UpdateSpecialPriceListsTxt(PriceType::Purchase);
                        end;
                    }
                    field(SpecialPurchPricesAndDiscountsTxt; SpecialPurchPricesAndDiscountsTxt)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Prices & Discounts';
                        Editable = false;
                        Visible = not ExtendedPriceEnabled;
                        ToolTip = 'Specifies purchase prices and line discounts for the item.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                        ObsoleteTag = '17.0';

                        trigger OnDrillDown()
                        var
                            PurchasePrice: Record "Purchase Price";
                            PurchaseLineDiscount: Record "Purchase Line Discount";
                            PurchasesPriceAndLineDisc: Page "Purchases Price and Line Disc.";
                        begin
                            if SpecialPurchPricesAndDiscountsTxt = ViewExistingTxt then begin
                                PurchasesPriceAndLineDisc.LoadItem(Rec);
                                PurchasesPriceAndLineDisc.RunModal;
                                exit;
                            end;

                            case StrMenu(StrSubstNo('%1,%2', CreateNewSpecialPriceTxt, CreateNewSpecialDiscountTxt), 1, '') of
                                1:
                                    begin
                                        PurchasePrice.SetRange("Item No.", "No.");
                                        PAGE.RunModal(PAGE::"Purchase Prices", PurchasePrice);
                                    end;
                                2:
                                    begin
                                        PurchaseLineDiscount.SetRange("Item No.", "No.");
                                        PAGE.RunModal(PAGE::"Purchase Line Discounts", PurchaseLineDiscount);
                                    end;
                            end;

                            UpdateSpecialPricesAndDiscountsTxt;
                        end;
                    }
                }
                group("Posting Details")
                {
                    Caption = 'Posting Details';
                    field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field("Tax Group Code"; "Tax Group Code")
                    {
                        ApplicationArea = SalesTax;
                        Importance = Promoted;
                        ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                    }
                    field("Inventory Posting Group"; "Inventory Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = IsInventoriable;
                        Importance = Promoted;
                        ShowMandatory = IsInventoriable;
                        ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
                    }
                    field("Default Deferral Template Code"; "Default Deferral Template Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Default Deferral Template';
                        ToolTip = 'Specifies how revenue or expenses for the item are deferred to other accounting periods by default.';
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Tariff No."; "Tariff No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies a code for the item''s tariff number.';
                    }
                    field("Country/Region of Origin Code"; "Country/Region of Origin Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                    }
                }
            }
            group("Prices & Sales")
            {
                Caption = 'Prices & Sales';
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Editable = PriceEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field(CalcUnitPriceExclVAT; CalcUnitPriceExclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '2,0,' + FieldCaption("Unit Price");
                    Importance = Additional;
                    ToolTip = 'Specifies the unit price excluding VAT.';
                }
                field("Price Includes VAT"; "Price Includes VAT")
                {
                    ApplicationArea = VAT;
                    Importance = Additional;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on sales document lines for this item should be shown with or without VAT.';

                    trigger OnValidate()
                    begin
                        if "Price Includes VAT" = xRec."Price Includes VAT" then
                            exit;
                    end;
                }
                field("Price/Profit Calculation"; "Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this item.';

                    trigger OnValidate()
                    begin
                        EnableControls;
                    end;
                }
                field("Profit %"; "Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 2;
                    Editable = ProfitEditable;
                    ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
                }
                field(SpecialSalesPriceListTxt; SalesPriceListsText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts';
                    Editable = false;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Specifies sales price lists for the item.';

                    trigger OnDrillDown()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        if SalesPriceListsText = ViewExistingTxt then
                            Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any)
                        else
                            PAGE.RunModal(PAGE::"Sales Price Lists");
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
                field(SpecialPricesAndDiscountsTxt; SpecialPricesAndDiscountsTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts';
                    Editable = false;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Specifies sales prices and line discounts for the item.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '16.0';

                    trigger OnDrillDown()
                    var
                        SalesPrice: Record "Sales Price";
                        SalesLineDiscount: Record "Sales Line Discount";
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        if SpecialPricesAndDiscountsTxt = ViewExistingTxt then begin
                            SalesPriceAndLineDiscounts.InitPage(true);
                            SalesPriceAndLineDiscounts.LoadItem(Rec);
                            SalesPriceAndLineDiscounts.RunModal;
                            exit;
                        end;

                        case StrMenu(StrSubstNo('%1,%2', CreateNewSpecialPriceTxt, CreateNewSpecialDiscountTxt), 1, '') of
                            1:
                                begin
                                    SalesPrice.SetRange("Item No.", "No.");
                                    PAGE.RunModal(PAGE::"Sales Prices", SalesPrice);
                                end;
                            2:
                                begin
                                    SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
                                    SalesLineDiscount.SetRange(Code, "No.");
                                    PAGE.RunModal(PAGE::"Sales Line Discounts", SalesLineDiscount);
                                end;
                        end;

                        UpdateSpecialPricesAndDiscountsTxt;
                    end;
                }
                field("Allow Invoice Disc."; "Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if the item should be included in the calculation of an invoice discount on documents where the item is traded.';
                }
                field("Item Disc. Group"; "Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies an item group code that can be used as a criterion to grant a discount when the item is sold to a certain customer.';
                }
                field("Sales Unit of Measure"; "Sales Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the unit of measure code used when you sell the item.';
                }
                field("Sales Blocked"; "Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the item cannot be entered on sales documents, except return orders and credit memos, and journals.';
                }
                field("Application Wksh. User ID"; "Application Wksh. User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of a user who is working in the Application Worksheet window.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; "VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the sales price including VAT to apply.';
                }
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; "Replenishment System")
                {
                    ApplicationArea = Assembly, Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Assembly, Planning;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; "Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the vendor code of who supplies this item by default.';
                    }
                    field("Vendor Item No."; "Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the number that the vendor uses for this item.';
                    }
                    field("Purch. Unit of Measure"; "Purch. Unit of Measure")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the unit of measure code used when you purchase the item.';
                    }
                    field("Purchasing Blocked"; "Purchasing Blocked")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies that the item cannot be entered on purchase documents, except return orders and credit memos, and journals.';
                    }
                }
                group(Replenishment_Production)
                {
                    Caption = 'Production';
                    field("Manufacturing Policy"; "Manufacturing Policy")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies if additional orders for any related components are calculated.';
                    }
                    field("Routing No."; "Routing No.")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the number of the production routing that the item is used in.';
                    }
                    field("Production BOM No."; "Production BOM No.")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the number of the production BOM that the item represents.';
                    }
                    field("Rounding Precision"; "Rounding Precision")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies how calculated consumption quantities are rounded when entered on consumption journal lines.';
                    }
                    field("Flushing Method"; "Flushing Method")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    }
                    field("Overhead Rate"; "Overhead Rate")
                    {
                        ApplicationArea = Manufacturing;
                        Enabled = IsInventoriable;
                        Importance = Additional;
                        ToolTip = 'Specifies the item''s indirect cost as an absolute amount.';
                    }
                    field("Scrap %"; "Scrap %")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the percentage of the item that you expect to be scrapped in the production process.';
                    }
                    field("Lot Size"; "Lot Size")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies how many units of the item are processed in one production operation by default.';
                    }
                }
                group(Replenishment_Assembly)
                {
                    Caption = 'Assembly';
                    field("Assembly Policy"; "Assembly Policy")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies which default order flow is used to supply this assembly item.';
                    }
                    field(AssemblyBOM; "Assembly BOM")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies if the item is an assembly BOM.';

                        trigger OnDrillDown()
                        var
                            BOMComponent: Record "BOM Component";
                        begin
                            Commit();
                            BOMComponent.SetRange("Parent Item No.", "No.");
                            PAGE.Run(PAGE::"Assembly BOM", BOMComponent);
                            CurrPage.Update;
                        end;
                    }
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                field("Reordering Policy"; "Reordering Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the reordering policy.';

                    trigger OnValidate()
                    begin
                        EnablePlanningControls();
                    end;
                }
                field(Reserve; Reserve)
                {
                    ApplicationArea = Reservation;
                    Importance = Additional;
                    ToolTip = 'Specifies if and how the item will be reserved. Never: It is not possible to reserve the item. Optional: You can reserve the item manually. Always: The item is automatically reserved from demand, such as sales orders, against inventory, purchase orders, assembly orders, and production orders.';
                }
                field("Order Tracking Policy"; "Order Tracking Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies if and how order tracking entries are created and maintained between supply and its corresponding demand.';
                }
                field("Stockkeeping Unit Exists"; "Stockkeeping Unit Exists")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies that a stockkeeping unit exists for this item.';
                }
                field("Dampener Period"; "Dampener Period")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerPeriodEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward. The dampener period limits the number of insignificant rescheduling of existing supply to a later date if that new date is within the dampener period. The dampener period function is only initiated if the supply can be rescheduled to a later date and not if the supply can be rescheduled to an earlier date. Accordingly, if the suggested new supply date is after the dampener period, then the rescheduling suggestion is not blocked. If the lot accumulation period is less than the dampener period, then the dampener period is dynamically set to equal the lot accumulation period. This is not shown in the value that you enter in the Dampener Period field. The last demand in the lot accumulation period is used to determine whether a potential supply date is in the dampener period. If this field is empty, then the value in the Default Dampener Period field in the Manufacturing Setup window applies. The value that you enter in the Dampener Period field must be a date formula, and one day (1D) is the shortest allowed period.';
                }
                field("Dampener Quantity"; "Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerQtyEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions for an existing supply, if the change quantity is lower than the dampener quantity.';
                }
                field(Critical; Critical)
                {
                    ApplicationArea = OrderPromising;
                    ToolTip = 'Specifies if the item is included in availability calculations to promise a shipment date for its parent item.';
                }
                field("Safety Lead Time"; "Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyLeadTimeEnable;
                    ToolTip = 'Specifies a date formula to indicate a safety lead time that can be used as a buffer period for production and other delays.';
                }
                field("Safety Stock Quantity"; "Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyStockQtyEnable;
                    ToolTip = 'Specifies a quantity of stock to have in inventory to protect against supply-and-demand fluctuations during replenishment lead time.';
                }
                group(LotForLotParameters)
                {
                    Caption = 'Lot-for-Lot Parameters';
                    field("Include Inventory"; "Include Inventory")
                    {
                        ApplicationArea = Planning;
                        Enabled = IncludeInventoryEnable;
                        ToolTip = 'Specifies that the inventory quantity is included in the projected available balance when replenishment orders are calculated.';

                        trigger OnValidate()
                        begin
                            EnablePlanningControls
                        end;
                    }
                    field("Lot Accumulation Period"; "Lot Accumulation Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = LotAccumulationPeriodEnable;
                        ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';
                    }
                    field("Rescheduling Period"; "Rescheduling Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = ReschedulingPeriodEnable;
                        ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';
                    }
                }
                group(ReorderPointParameters)
                {
                    Caption = 'Reorder-Point Parameters';
                    group(Control64)
                    {
                        ShowCaption = false;
                        field("Reorder Point"; "Reorder Point")
                        {
                            ApplicationArea = Planning;
                            Enabled = ReorderPointEnable;
                            ToolTip = 'Specifies a stock quantity that sets the inventory below the level that you must replenish the item.';
                        }
                        field("Reorder Quantity"; "Reorder Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = ReorderQtyEnable;
                            ToolTip = 'Specifies a standard lot size quantity to be used for all order proposals.';
                        }
                        field("Maximum Inventory"; "Maximum Inventory")
                        {
                            ApplicationArea = Planning;
                            Enabled = MaximumInventoryEnable;
                            ToolTip = 'Specifies a quantity that you want to use as a maximum inventory level.';
                        }
                    }
                    field("Overflow Level"; "Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Enabled = OverflowLevelEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point, before the system suggests to decrease supply orders.';
                    }
                    field("Time Bucket"; "Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Enabled = TimeBucketEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a time period that defines the recurring planning horizon used with Fixed Reorder Qty. or Maximum Qty. reordering policies.';
                    }
                }
                group(OrderModifiers)
                {
                    Caption = 'Order Modifiers';
                    group(Control61)
                    {
                        ShowCaption = false;
                        field("Minimum Order Quantity"; "Minimum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = MinimumOrderQtyEnable;
                            ToolTip = 'Specifies a minimum allowable quantity for an item order proposal.';
                        }
                        field("Maximum Order Quantity"; "Maximum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = MaximumOrderQtyEnable;
                            ToolTip = 'Specifies a maximum allowable quantity for an item order proposal.';
                        }
                        field("Order Multiple"; "Order Multiple")
                        {
                            ApplicationArea = Planning;
                            Enabled = OrderMultipleEnable;
                            ToolTip = 'Specifies a parameter used by the planning system to modify the quantity of planned supply orders.';
                        }
                    }
                }
            }
            group(ItemTracking)
            {
                Caption = 'Item Tracking';
                field("Item Tracking Code"; "Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    Importance = Promoted;
                    ToolTip = 'Specifies how serial or lot numbers assigned to the item are tracked in the supply chain.';

                    trigger OnValidate()
                    begin
                        SetExpirationCalculationEditable;
                    end;
                }
                field("Serial Nos."; "Serial Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a number series code to assign consecutive serial numbers to items produced.';
                }
                field("Lot Nos."; "Lot Nos.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number series code that will be used when assigning lot numbers.';
                }
                field("Expiration Calculation"; "Expiration Calculation")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ExpirationCalculationEditable;
                    ToolTip = 'Specifies the date formula for calculating the expiration date on the item tracking line. Note: This field will be ignored if the involved item has Require Expiration Date Entry set to Yes on the Item Tracking Code page.';

                    trigger OnValidate()
                    begin
                        Validate("Item Tracking Code");
                    end;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Warehouse Class Code"; "Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse class code for the item.';
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the equipment that warehouse employees must use when handling the item.';
                }
                field("Put-away Template Code"; "Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the put-away template by which the program determines the most appropriate zone and bin for storage of the item after receipt.';
                }
                field("Put-away Unit of Measure Code"; "Put-away Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the item unit of measure in which the program will put the item away.';
                }
                field("Phys Invt Counting Period Code"; "Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the item in a physical inventory.';
                }
                field("Last Phys. Invt. Date"; "Last Phys. Invt. Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date on which you last posted the results of a physical inventory for the item to the item ledger.';
                }
                field("Last Counting Period Update"; "Last Counting Period Update")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the last date on which you calculated the counting period. It is updated when you use the function Calculate Counting Period.';
                }
                field("Next Counting Start Date"; "Next Counting Start Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the starting date of the next counting period.';
                }
                field("Next Counting End Date"; "Next Counting End Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ending date of the next counting period.';
                }
                field("Identifier Code"; "Identifier Code")
                {
                    ApplicationArea = Advanced;
                    Importance = Additional;
                    ToolTip = 'Specifies a unique code for the item in terms that are useful for automatic data capture.';
                }
                field("Use Cross-Docking"; "Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                    ToolTip = 'Specifies if this item can be cross-docked.';
                }
            }
        }
        area(factboxes)
        {
            part(ItemPicture; "Item Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "No." = FIELD("No."),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Location Filter" = FIELD("Location Filter"),
                              "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                              "Variant Filter" = FIELD("Variant Filter");
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(27),
                              "No." = FIELD("No.");
            }
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control132; "Social Listening FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Item),
                              "Source No." = FIELD("No.");
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
                ObsoleteTag = '17.0';
            }
            part(Control134; "Social Listening Setup FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Item),
                              "Source No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
                ObsoleteTag = '17.0';
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ItemActionGroup)
            {
                Caption = 'Item';
                Image = DataEntry;
                action(Attributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attributes';
                    Image = Category;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'View or edit the item''s attributes, such as color, size, or other characteristics that help to describe the item.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Item Attribute Value Editor", Rec);
                        CurrPage.SaveRecord;
                        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData("No.");
                    end;
                }
                action(AdjustInventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Inventory';
                    Enabled = IsInventoriable;
                    Image = InventoryCalculation;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Increase or decrease the item''s inventory quantity manually by entering a new quantity. Adjusting the inventory quantity manually may be relevant after a physical count or if you do not record purchased quantities.';
                    Visible = IsFoundationEnabled;

                    trigger OnAction()
                    var
                        AdjustInventory: Page "Adjust Inventory";
                    begin
                        Commit();
                        AdjustInventory.SetItem("No.");
                        AdjustInventory.RunModal;
                    end;
                }
                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "Item Variants";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';
                }
                action(Identifiers)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Identifiers';
                    Image = BarCode;
                    RunObject = Page "Item Identifiers";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.", "Variant Code", "Unit of Measure Code");
                    ToolTip = 'View a unique identifier for each item that you want warehouse employees to keep track of within the warehouse when using handheld devices. The item identifier can include the item number, the variant code and the unit of measure.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal;
                    end;
                }
            }
            group(PricesandDiscounts)
            {
                Caption = 'Sales Prices & Discounts';
                action("Set Special Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Set up sales prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesPrice: Record "Sales Price";
                    begin
                        SalesPrice.SetRange("Item No.", "No.");
                        Page.Run(Page::"Sales Prices", SalesPrice);
                    end;
                }
                action("Set Special Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Set up sales discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey(Type, Code);
                        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
                        SalesLineDiscount.SetRange(Code, "No.");
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PricesDiscountsOverview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the sales prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        SalesPriceAndLineDiscounts.InitPage(true);
                        SalesPriceAndLineDiscounts.LoadItem(Rec);
                        SalesPriceAndLineDiscounts.RunModal;
                    end;
                }
                action(SalesPriceLists)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up sales prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Price);
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
                action(SalesPriceListsDiscounts)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up sales discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Discount);
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
            }
            group(PurchPricesandDiscounts)
            {
                Caption = 'Purchase Prices & Discounts';
                action(Action86)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'Set up purchase prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';
                }
                action(Action85)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'Set up purchase discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';
                }
                action(PurchPricesDiscountsOverview)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the purchase prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        PurchasesPriceAndLineDisc: Page "Purchases Price and Line Disc.";
                    begin
                        PurchasesPriceAndLineDisc.LoadItem(Rec);
                        PurchasesPriceAndLineDisc.RunModal;
                    end;
                }
                action(PurchPriceLists)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up purchase prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin

                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Price);
                        UpdateSpecialPriceListsTxt(PriceType::Purchase);
                    end;
                }
                action(PurchPriceListsDiscounts)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up purchase discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Discount);
                        UpdateSpecialPriceListsTxt(PriceType::Purchase);
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = (NOT OpenApprovalEntriesExist) AND EnabledApprovalWorkflowsExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedOnly = true;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckItemApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendItemForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedOnly = true;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(RecordId);
                    end;
                }
                group(Flow)
                {
                    Caption = 'Flow';
                    action(CreateFlow)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create a Flow';
                        Image = Flow;
                        Promoted = true;
                        PromotedCategory = Category8;
                        PromotedOnly = true;
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS;

                        trigger OnAction()
                        var
                            FlowServiceManagement: Codeunit "Flow Service Management";
                            FlowTemplateSelector: Page "Flow Template Selector";
                        begin
                            // Opens page 6400 where the user can use filtered templates to create new Flows.
                            FlowTemplateSelector.SetSearchText(FlowServiceManagement.GetItemTemplateFilter);
                            FlowTemplateSelector.Run;
                        end;
                    }
                    action(SeeFlows)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'See my Flows';
                        Image = Flow;
                        Promoted = true;
                        PromotedCategory = Category8;
                        PromotedOnly = true;
                        RunObject = Page "Flow Selector";
                        ToolTip = 'View and configure Power Automate flows that you created.';
                    }
                }
            }
            group(Workflow)
            {
                Caption = 'Workflow';
                action(CreateApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Approval Workflow';
                    Enabled = NOT EnabledApprovalWorkflowsExist;
                    Image = CreateWorkflow;
                    ToolTip = 'Set up an approval workflow for creating or changing items, by going through a few pages that will guide you.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Item Approval WF Setup Wizard");
                    end;
                }
                action(ManageApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manage Approval Workflow';
                    Enabled = EnabledApprovalWorkflowsExist;
                    Image = WorkflowSetup;
                    ToolTip = 'View or edit existing approval workflows for creating or changing items.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        WorkflowManagement.NavigateToWorkflows(DATABASE::Item, EventFilter);
                    end;
                }
            }
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Create Stockkeeping Unit")
                {
                    AccessByPermission = TableData "Stockkeeping Unit" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Stockkeeping Unit';
                    Image = CreateSKU;
                    ToolTip = 'Create an instance of the item at each location that is set up.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        Item.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"Create Stockkeeping Unit", true, false, Item);
                    end;
                }
                action(CalculateCountingPeriod)
                {
                    AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        Item.SetRange("No.", "No.");
                        PhysInvtCountMgt.UpdateItemPhysInvtCount(Item);
                    end;
                }
                action(Templates)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Templates';
                    Image = Template;
                    RunObject = Page "Config Templates";
                    RunPageLink = "Table ID" = CONST(27);
                    ToolTip = 'View or edit item templates.';
                }
                action(CopyItem)
                {
                    AccessByPermission = TableData Item = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Item';
                    Image = Copy;
                    ToolTip = 'Create a copy of the current item.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Copy Item", Rec);
                    end;
                }
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality will be replaced by other templates.';
                    ObsoleteTag = '16.0';

                    trigger OnAction()
                    var
                        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
                    begin
                        ItemTemplMgt.UpdateItemFromTemplate(Rec);
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Ellipsis = true;
                    Image = Save;
                    ToolTip = 'Save the item card as a template that can be reused to create new item cards. Item templates contain preset information to help you fill in fields on item cards.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality will be replaced by other templates.';
                    ObsoleteTag = '16.0';

                    trigger OnAction()
                    var
                        TempItemTemplate: Record "Item Template" temporary;
                    begin
                        TempItemTemplate.SaveAsTemplate(Rec);
                    end;
                }
            }
            action("Requisition Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Requisition Worksheet';
                Image = Worksheet;
                RunObject = Page "Req. Worksheet";
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action("Item Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Item Journal";
                ToolTip = 'Open a list of journals where you can adjust the physical quantity of items on inventory.';
            }
            action("Item Reclassification Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Reclassification Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Item Reclass. Journal";
                ToolTip = 'Change information on item ledger entries, such as dimensions, location codes, bin codes, and serial or lot numbers.';
            }
            action("Item Tracing")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a lot or serial number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
        }
        area(reporting)
        {
            action("Item Turnover")
            {
                Caption = 'Item Turnover';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Item Turnover";
                ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
            }
            action("Item Transaction Detail")
            {
                Caption = 'Item Transaction Detail';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Item Transaction Detail";
                ToolTip = 'View detailed purchase, sales, and adjustment information about the items in your inventory. This report lists transactions by the item that they pertain to. If an item has variants, each variant''s transactions are listed separately.';
            }
            action("Serial Number Status/Aging")
            {
                Caption = 'Serial Number Status/Aging';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Top __ Inventory Items";
                ToolTip = 'View a list of serial-numbered items that are currently in stock. This report includes serial-numbered items along with the purchase date and the number of days the item has been in stock.';
            }
            action("Issue History")
            {
                Caption = 'Issue History';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Issue History";
                ToolTip = 'View figures for items removed from inventory to be used in the production of bills of material during specific periods.';
            }
            action("Item Sales by Customer")
            {
                Caption = 'Item Sales by Customer';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Item Sales by Customer";
                ToolTip = 'View a list of sales for the items that you select. The report lists each item, each customer who bought the item, and the quantity that each customer bought in the specified period.';
            }
            action("Picking List by Item")
            {
                Caption = 'Picking List by Item';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Picking List by Item";
                ToolTip = 'View the picking list by item. Business Central prints items in order by their shelf/bin number to make picking more convenient. For items using the specific costing method, Business Central leaves space for you to write the serial number.';
            }
            action("Sales Order Status")
            {
                Caption = 'Sales Order Status';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Sales Order Status";
                ToolTip = 'View the status of partially filled or unfilled orders so you can determine what effect filling these orders may have on your inventory. NOTE: The Amount Remaining column may include sales taxes and therefore may not match the result of multiplying the remaining amount times the unit price and subtracting the discounts.';
            }
            action("Serial Number Sold History")
            {
                Caption = 'Serial Number Sold History';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Serial Number Sold History";
                ToolTip = 'View or track serial-numbered items to the customers that bought them. The system includes the date of the sale as well as the amount the item was sold for on the report. The report shows the item first followed by the customer that purchased that item.';
            }
            action("Vendor Purchases by Item")
            {
                Caption = 'Vendor Purchases by Item';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Vendor Purchases by Item";
                ToolTip = 'View a list of the items that you purchased and the vendors that you purchased the items from.';
            }
            action("Item/Vendor Catalog")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item/Vendor Catalog';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Item/Vendor Catalog";
                ToolTip = 'View a complete or partial catalog of which vendors offer which items.';
            }
            action("Purchase Order Status")
            {
                Caption = 'Purchase Order Status';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Purchase Order Status";
                ToolTip = 'View outstanding purchase orders, including partial receipts and orders not yet received.';
            }
        }
        area(navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                group(Entries)
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Category5;
                        //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedIsBig = true;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.")
                                      ORDER(Descending);
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        RunObject = Page "Phys. Inventory Ledger Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.");
                        ToolTip = 'View how many units of the item you had in stock at the last physical count.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "Reservation Entries";
                        RunPageLink = "Reservation Status" = CONST(Reservation),
                                      "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("&Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.");
                        ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                    }
                    action("Item &Tracking Entries")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View serial or lot numbers that are assigned to items.';

                        trigger OnAction()
                        var
                            ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                        begin
                            ItemTrackingDocMgt.ShowItemTrackingForEntity(3, '', "No.", '', '');
                        end;
                    }
                    action("&Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Item No." = FIELD("No.");
                        RunPageView = SORTING("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated);
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                    }
                    action("Application Worksheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application Worksheet';
                        Image = ApplicationWorksheet;
                        RunObject = Page "Application Worksheet";
                        RunPageLink = "Item No." = FIELD("No.");
                        ToolTip = 'Edit item applications that are automatically created between item ledger entries during item transactions. Use special functions to manually undo or change item application entries.';
                    }
                    action("Export Item Data")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Item Data';
                        Image = ExportFile;
                        ToolTip = 'Use this function to export item related data to text file (you can attach this file to support requests in case you may have issues with costing calculation).';

                        trigger OnAction()
                        var
                            Item: Record Item;
                            ExportItemData: XMLport "Export Item Data";
                        begin
                            Item.SetRange("No.", "No.");
                            Clear(ExportItemData);
                            ExportItemData.SetTableView(Item);
                            ExportItemData.Run;
                        end;
                    }
                }
            }
            group(Navigation_Item)
            {
                Caption = 'Item';
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(27),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Cross Re&ferences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cross Re&ferences';
                    Image = Change;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Cross Reference Entries";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the item. Cross-references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("Item Re&ferences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Re&ferences';
                    Visible = ItemReferenceVisible;
                    Image = Change;
                    RunObject = Page "Item Reference Entries";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the item. Item references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Units of Measure";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'Select or set up additional text for the description of the item. Extended text can be inserted under the Description field on document lines for the item.';
                }
                action(Translations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("Substituti&ons")
                {
                    ApplicationArea = Suite;
                    Caption = 'Substituti&ons';
                    Image = ItemSubstitution;
                    RunObject = Page "Item Substitution Entry";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View substitute items that are set up to be sold instead of the item.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedOnly = true;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                Enabled = (BlockedFilterApplied and (not Blocked)) or not BlockedFilterApplied;
                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Sales product.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the item table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                Image = ItemAvailability;
                action(ItemsByLocation)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Items b&y Location';
                    Image = ItemAvailbyLoc;
                    ToolTip = 'Show a list of items grouped by location.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Items by Location", Rec);
                    end;
                }
                group(ItemAvailabilityBy)
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("<Action110>")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Rec, ItemAvailFormsMgt.ByEvent);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        RunObject = Page "Item Availability by Variant";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                    }
                    action(Location)
                    {
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        RunObject = Page "Item Availability by Location";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View the actual and projected quantity of the item per location.';
                    }
                    action("BOM Level")
                    {
                        AccessByPermission = TableData "BOM Buffer" = R;
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailFromItem(Rec, ItemAvailFormsMgt.ByBOM);
                        end;
                    }
                    action("Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Unit of Measure';
                        Image = UnitOfMeasure;
                        RunObject = Page "Item Availability by UOM";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View the item''s availability by a unit of measure.';
                    }
                }
                group(StatisticsGroup)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Statistics)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statistics';
                        Image = Statistics;
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                        trigger OnAction()
                        var
                            ItemStatistics: Page "Item Statistics";
                        begin
                            ItemStatistics.SetItem(Rec);
                            ItemStatistics.RunModal;
                        end;
                    }
                    action("Entry Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Entry Statistics';
                        Image = EntryStatistics;
                        RunObject = Page "Item Entry Statistics";
                        RunPageLink = "No." = FIELD("No."),
                                      "Date Filter" = FIELD("Date Filter"),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View statistics for item ledger entries.';
                    }
                    action("T&urnover")
                    {
                        ApplicationArea = Suite;
                        Caption = 'T&urnover';
                        Image = Turnover;
                        RunObject = Page "Item Turnover";
                        RunPageLink = "No." = FIELD("No."),
                                      "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                      "Location Filter" = FIELD("Location Filter"),
                                      "Drop Shipment Filter" = FIELD("Drop Shipment Filter"),
                                      "Variant Filter" = FIELD("Variant Filter");
                        ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
                    }
                }
            }
            group(Purchases)
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action("Ven&dors")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ven&dors';
                    Image = Vendor;
                    RunObject = Page "Item Vendor Catalog";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the list of vendors who can supply the item, and at which lead time.';
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action(Orders)
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Purchase Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing orders for the item.';
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'Open the list of ongoing return orders for the item.';
                }
            }
            group(Sales)
            {
                Caption = 'S&ales';
                Image = Sales;
                action(Action300)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Sales Prepayment Percentages";
                    RunPageLink = "Item No." = FIELD("No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action(Action83)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Sales Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing orders for the item.';
                }
                action(Action163)
                {
                    ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Orders";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", Type, "No.");
                    ToolTip = 'Open the list of ongoing return orders for the item.';
                }
            }
            group(BillOfMaterials)
            {
                Caption = 'Bill of Materials';
                Image = Production;
                action(BOMStructure)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Structure';
                    Image = Hierarchy;
                    ToolTip = 'View which child items are used in an item''s assembly BOM or production BOM. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMStructure: Page "BOM Structure";
                    begin
                        BOMStructure.InitItem(Rec);
                        BOMStructure.Run;
                    end;
                }
                action("Cost Shares")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Cost Shares';
                    Image = CostBudget;
                    ToolTip = 'View how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMCostShares: Page "BOM Cost Shares";
                    begin
                        BOMCostShares.InitItem(Rec);
                        BOMCostShares.Run;
                    end;
                }
                group(Assembly)
                {
                    Caption = 'Assemb&ly';
                    Image = AssemblyBOM;
                    action("Assembly BOM")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Assembly BOM';
                        Image = BOM;
                        RunObject = Page "Assembly BOM";
                        RunPageLink = "Parent Item No." = FIELD("No.");
                        ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';
                    }
                    action("Where-Used")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Where-Used';
                        Image = Track;
                        RunObject = Page "Where-Used List";
                        RunPageLink = Type = CONST(Item),
                                      "No." = FIELD("No.");
                        RunPageView = SORTING(Type, "No.");
                        ToolTip = 'View a list of BOMs in which the item is used.';
                    }
                    action("Calc. Stan&dard Cost")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Calc. Stan&dard Cost';
                        Image = CalculateCost;
                        ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s assembly BOM or production BOM. The unit cost of a parent item must always equals the total of the unit costs of its components, subassemblies, and any resources.';

                        trigger OnAction()
                        begin
                            Clear(CalculateStdCost);
                            CalculateStdCost.CalcItem("No.", true);
                        end;
                    }
                    action("Calc. Unit Price")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Calc. Unit Price';
                        Image = SuggestItemPrice;
                        ToolTip = 'Calculate the unit price based on the unit cost and the profit percentage.';

                        trigger OnAction()
                        begin
                            Clear(CalculateStdCost);
                            CalculateStdCost.CalcAssemblyItemPrice("No.")
                        end;
                    }
                }
                group(Production)
                {
                    Caption = 'Production';
                    Image = Production;
                    action("Production BOM")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production BOM';
                        Image = BOM;
                        RunObject = Page "Production BOM";
                        RunPageLink = "No." = FIELD("Production BOM No.");
                        ToolTip = 'Open the item''s production bill of material to view or edit its components.';
                    }
                    action(Action78)
                    {
                        AccessByPermission = TableData "Production BOM Header" = R;
                        ApplicationArea = Manufacturing;
                        Caption = 'Where-Used';
                        Image = "Where-Used";
                        ToolTip = 'View a list of BOMs in which the item is used.';

                        trigger OnAction()
                        var
                            ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
                        begin
                            ProdBOMWhereUsed.SetItem(Rec, WorkDate);
                            ProdBOMWhereUsed.RunModal;
                        end;
                    }
                    action(Action5)
                    {
                        AccessByPermission = TableData "Production BOM Header" = R;
                        ApplicationArea = Manufacturing;
                        Caption = 'Calc. Stan&dard Cost';
                        Image = CalculateCost;
                        ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s assembly BOM or production BOM. The unit cost of a parent item must always equals the total of the unit costs of its components, subassemblies, and any resources.';

                        trigger OnAction()
                        begin
                            Clear(CalculateStdCost);
                            CalculateStdCost.CalcItem("No.", false);
                        end;
                    }
                }
            }
            group(Navigation_Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("&Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Item Bin Contents";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
                action("Stockkeepin&g Units")
                {
                    ApplicationArea = Planning;
                    Caption = 'Stockkeepin&g Units';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'Open the item''s SKUs to view or edit instances of the item at different locations or with different variants. ';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceItem;
                action("Ser&vice Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Items';
                    Image = ServiceItem;
                    RunObject = Page "Service Items";
                    RunPageLink = "Item No." = FIELD("No.");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View instances of the item as service items, such as machines that you maintain or repair for customers through service orders. ';
                }
                action(Troubleshooting)
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    var
                        TroubleshootingHeader: Record "Troubleshooting Header";
                    begin
                        TroubleshootingHeader.ShowForItem(Rec);
                    end;
                }
                action("Troubleshooting Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Troubleshooting Setup';
                    Image = Troubleshoot;
                    RunObject = Page "Troubleshooting Setup";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or edit your settings for troubleshooting service items.';
                }
            }
            group(Resources)
            {
                Caption = 'Resources';
                Image = Resource;
                action("Resource Skills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = CONST(Item),
                                  "No." = FIELD("No.");
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("Skilled Resources")
                {
                    AccessByPermission = TableData "Service Header" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Skilled Resources';
                    Image = ResourceSkills;
                    ToolTip = 'View a list of all registered resources with information about whether they have the skills required to service the particular service item group, item, or service item.';

                    trigger OnAction()
                    var
                        ResourceSkill: Record "Resource Skill";
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::Item, "No.", Description);
                        SkilledResourceList.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        CreateItemFromTemplate;
        EnableControls;
        if CRMIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
            if "No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
        OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        EventFilter := WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode + '|' +
          WorkflowEventHandling.RunWorkflowOnItemChangedCode;

        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, EventFilter);

        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData("No.");
    end;

    trigger OnInit()
    begin
        InitControls;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertItemUnitOfMeasure;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        EnvironmentInfo: Codeunit "Environment Information";
        ItemReferenceMgt: Codeunit "Item Reference Management";
    begin
        IsFoundationEnabled := ApplicationAreaMgmtFacade.IsFoundationEnabled();
        SetNoFieldVisible();
        IsSaaS := EnvironmentInfo.IsSaaS();
        DescriptionFieldVisible := true;
        SetOverReceiptControlsVisibility();
        ItemReferenceVisible := ItemReferenceMgt.IsEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('ITEM-PRODUCT') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field54=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();

        EnableShowStockOutWarning;

        EnableShowShowEnforcePositivInventory;

        OnAfterOnOpenPage();
    end;

    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SkilledResourceList: Page "Skilled Resource List";
        IsFoundationEnabled: Boolean;
        ShowStockoutWarningDefaultYes: Boolean;
        ShowStockoutWarningDefaultNo: Boolean;
        ShowPreventNegInventoryDefaultYes: Boolean;
        ShowPreventNegInventoryDefaultNo: Boolean;
        SocialListeningSetupVisible: Boolean;
        [InDataSet]
        SocialListeningVisible: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        ProfitEditable: Boolean;
        PriceEditable: Boolean;
        SalesPriceListsText: Text;
        PurchPriceListsText: Text;
        SpecialPricesAndDiscountsTxt: Text;
        CreateNewTxt: Label 'Create New...';
        ViewExistingTxt: Label 'View Existing Prices and Discounts...';
        CreateNewSpecialPriceTxt: Label 'Create New Special Price...';
        CreateNewSpecialDiscountTxt: Label 'Create New Special Discount...';
        SpecialPurchPricesAndDiscountsTxt: Text;

    protected var
        EnabledApprovalWorkflowsExist: Boolean;
        EventFilter: Text;
        NoFieldVisible: Boolean;
        DescriptionFieldVisible: Boolean;
        NewMode: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsSaaS: Boolean;
        IsService: Boolean;
        IsNonInventoriable: Boolean;
        IsInventoriable: Boolean;
        ExpirationCalculationEditable: Boolean;
        OverReceiptAllowed: Boolean;
        [InDataSet]
        ItemReferenceVisible: Boolean;
        ExtendedPriceEnabled: Boolean;
        [InDataSet]
        TimeBucketEnable: Boolean;
        [InDataSet]
        SafetyLeadTimeEnable: Boolean;
        [InDataSet]
        SafetyStockQtyEnable: Boolean;
        [InDataSet]
        ReorderPointEnable: Boolean;
        [InDataSet]
        ReorderQtyEnable: Boolean;
        [InDataSet]
        MaximumInventoryEnable: Boolean;
        [InDataSet]
        MinimumOrderQtyEnable: Boolean;
        [InDataSet]
        MaximumOrderQtyEnable: Boolean;
        [InDataSet]
        OrderMultipleEnable: Boolean;
        [InDataSet]
        IncludeInventoryEnable: Boolean;
        [InDataSet]
        ReschedulingPeriodEnable: Boolean;
        [InDataSet]
        LotAccumulationPeriodEnable: Boolean;
        [InDataSet]
        DampenerPeriodEnable: Boolean;
        [InDataSet]
        DampenerQtyEnable: Boolean;
        [InDataSet]
        OverflowLevelEnable: Boolean;
        [InDataSet]
        StandardCostEnable: Boolean;
        [InDataSet]
        UnitCostEnable: Boolean;
        [InDataSet]
        UnitCostEditable: Boolean;

    procedure EnableControls()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PriceType: Enum "Price Type";
    begin
        IsService := IsServiceType;
        IsNonInventoriable := IsNonInventoriableType;
        IsInventoriable := IsInventoriableType;

        if IsNonInventoriable then
            "Stockout Warning" := "Stockout Warning"::No;

        if Type = Type::Inventory then begin
            ItemLedgerEntry.SetRange("Item No.", "No.");
            UnitCostEditable := ItemLedgerEntry.IsEmpty;
        end else
            UnitCostEditable := true;

        ProfitEditable := "Price/Profit Calculation" <> "Price/Profit Calculation"::"Profit=Price-Cost";
        PriceEditable := "Price/Profit Calculation" <> "Price/Profit Calculation"::"Price=Cost+Profit";

        EnablePlanningControls();
        EnableCostingControls();

        SetSocialListeningFactboxVisibility;

        if ExtendedPriceEnabled then
            UpdateSpecialPriceListsTxt(PriceType::Any)
        else
            UpdateSpecialPricesAndDiscountsTxt;

        SetExpirationCalculationEditable;
    end;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if "No." = '' then
                if DocumentNoVisibility.ItemNoSeriesIsDefault then
                    NewMode := true;
    end;

    local procedure EnableShowStockOutWarning()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        ShowStockoutWarningDefaultYes := SalesSetup."Stockout Warning";
        ShowStockoutWarningDefaultNo := not ShowStockoutWarningDefaultYes;

        EnableShowShowEnforcePositivInventory;
    end;

    local procedure InsertItemUnitOfMeasure()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if "Base Unit of Measure" <> '' then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure."Item No." := "No.";
            ItemUnitOfMeasure.Validate(Code, "Base Unit of Measure");
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert();
        end;
    end;

    local procedure EnableShowShowEnforcePositivInventory()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ShowPreventNegInventoryDefaultYes := InventorySetup."Prevent Negative Inventory";
        ShowPreventNegInventoryDefaultNo := not ShowPreventNegInventoryDefaultYes;
    end;

    protected procedure EnablePlanningControls()
    var
        PlanningGetParam: Codeunit "Planning-Get Parameters";
        TimeBucketEnabled: Boolean;
        SafetyLeadTimeEnabled: Boolean;
        SafetyStockQtyEnabled: Boolean;
        ReorderPointEnabled: Boolean;
        ReorderQtyEnabled: Boolean;
        MaximumInventoryEnabled: Boolean;
        MinimumOrderQtyEnabled: Boolean;
        MaximumOrderQtyEnabled: Boolean;
        OrderMultipleEnabled: Boolean;
        IncludeInventoryEnabled: Boolean;
        ReschedulingPeriodEnabled: Boolean;
        LotAccumulationPeriodEnabled: Boolean;
        DampenerPeriodEnabled: Boolean;
        DampenerQtyEnabled: Boolean;
        OverflowLevelEnabled: Boolean;
    begin
        PlanningGetParam.SetUpPlanningControls("Reordering Policy".AsInteger(), "Include Inventory",
          TimeBucketEnabled, SafetyLeadTimeEnabled, SafetyStockQtyEnabled,
          ReorderPointEnabled, ReorderQtyEnabled, MaximumInventoryEnabled,
          MinimumOrderQtyEnabled, MaximumOrderQtyEnabled, OrderMultipleEnabled, IncludeInventoryEnabled,
          ReschedulingPeriodEnabled, LotAccumulationPeriodEnabled,
          DampenerPeriodEnabled, DampenerQtyEnabled, OverflowLevelEnabled);

        TimeBucketEnable := TimeBucketEnabled;
        SafetyLeadTimeEnable := SafetyLeadTimeEnabled;
        SafetyStockQtyEnable := SafetyStockQtyEnabled;
        ReorderPointEnable := ReorderPointEnabled;
        ReorderQtyEnable := ReorderQtyEnabled;
        MaximumInventoryEnable := MaximumInventoryEnabled;
        MinimumOrderQtyEnable := MinimumOrderQtyEnabled;
        MaximumOrderQtyEnable := MaximumOrderQtyEnabled;
        OrderMultipleEnable := OrderMultipleEnabled;
        IncludeInventoryEnable := IncludeInventoryEnabled;
        ReschedulingPeriodEnable := ReschedulingPeriodEnabled;
        LotAccumulationPeriodEnable := LotAccumulationPeriodEnabled;
        DampenerPeriodEnable := DampenerPeriodEnabled;
        DampenerQtyEnable := DampenerQtyEnabled;
        OverflowLevelEnable := OverflowLevelEnabled;

        OnAfterEnablePlanningControls();
    end;

    protected procedure EnableCostingControls()
    begin
        StandardCostEnable := "Costing Method" = "Costing Method"::Standard;
        UnitCostEnable := "Costing Method" <> "Costing Method"::Standard;
    end;

    [Obsolete('Microsoft Social Engagement has been discontinued.', '17.0')]
    local procedure SetSocialListeningFactboxVisibility()
    var
        SocialListeningMgt: Codeunit "Social Listening Management";
    begin
        SocialListeningMgt.GetItemFactboxVisibility(Rec, SocialListeningSetupVisible, SocialListeningVisible);
    end;

    local procedure InitControls()
    begin
        UnitCostEnable := true;
        StandardCostEnable := true;
        OverflowLevelEnable := true;
        DampenerQtyEnable := true;
        DampenerPeriodEnable := true;
        LotAccumulationPeriodEnable := true;
        ReschedulingPeriodEnable := true;
        IncludeInventoryEnable := true;
        OrderMultipleEnable := true;
        MaximumOrderQtyEnable := true;
        MinimumOrderQtyEnable := true;
        MaximumInventoryEnable := true;
        ReorderQtyEnable := true;
        ReorderPointEnable := true;
        SafetyStockQtyEnable := true;
        SafetyLeadTimeEnable := true;
        TimeBucketEnable := true;
        "Costing Method" := "Costing Method"::FIFO;
        UnitCostEditable := true;

        OnAfterInitControls();
    end;

    [Obsolete('Replaced by the new implementation (V16) of price calculation.', '17.0')]
    local procedure UpdateSpecialPricesAndDiscountsTxt()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        TempPurchPriceLineDiscBuff: Record "Purch. Price Line Disc. Buff." temporary;
    begin
        SpecialPricesAndDiscountsTxt := CreateNewTxt;
        if TempSalesPriceAndLineDiscBuff.ItemHasLines(Rec) then
            SpecialPricesAndDiscountsTxt := ViewExistingTxt;

        SpecialPurchPricesAndDiscountsTxt := CreateNewTxt;
        if TempPurchPriceLineDiscBuff.ItemHasLines(Rec) then
            SpecialPurchPricesAndDiscountsTxt := ViewExistingTxt;
    end;

    local procedure UpdateSpecialPriceListsTxt(PriceType: Enum "Price Type")
    begin
        if PriceType in [PriceType::Any, PriceType::Sale] then
            SalesPriceListsText := GetPriceActionText(PriceType::Sale);
        if PriceType in [PriceType::Any, PriceType::Purchase] then
            PurchPriceListsText := GetPriceActionText(PriceType::Purchase);
    end;

    local procedure GetPriceActionText(PriceType: Enum "Price Type"): Text
    var
        PriceListLine: Record "Price List Line";
        PriceAssetList: Codeunit "Price Asset List";
        PriceUXManagement: Codeunit "Price UX Management";
        AssetType: Enum "Price Asset Type";
        AmountType: Enum "Price Amount Type";
    begin
        PriceAssetList.Add(AssetType::Item, Rec."No.");
        PriceUXManagement.SetPriceListLineFilters(PriceListLine, PriceAssetList, PriceType, AmountType::Any);
        if PriceListLine.IsEmpty then
            exit(CreateNewTxt);
        exit(ViewExistingTxt);
    end;

    local procedure CreateItemFromTemplate()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        OnBeforeCreateItemFromTemplate(NewMode);

        if not NewMode then
            exit;
        NewMode := false;

        if ItemTemplMgt.InsertItemFromTemplate(Item) then begin
            Copy(Item);
            CurrPage.Update;
            OnCreateItemFromTemplateOnAfterCurrPageUpdate(Rec);
        end else
            if ItemTemplMgt.TemplatesAreNotEmpty() then begin
                CurrPage.Close;
                exit;
            end;

        if ApplicationAreaMgmtFacade.IsFoundationEnabled then
            if (Item."No." = '') and InventorySetup.Get then
                Validate("Costing Method", InventorySetup."Default Costing Method");
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ItemNoIsVisible;
    end;

    local procedure SetExpirationCalculationEditable()
    var
        EmptyDateFormula: DateFormula;
    begin
        // allow customers to edit expiration date to remove it if the item has no item tracking code
        ExpirationCalculationEditable := ItemTrackingCodeUseExpirationDates() or ("Expiration Calculation" <> EmptyDateFormula);
    end;

    local procedure SetOverReceiptControlsVisibility()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitControls()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterOnOpenPage()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterEnablePlanningControls()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemFromTemplate(var NewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnAfterCurrPageUpdate(var Item: Record Item)
    begin
    end;
}

