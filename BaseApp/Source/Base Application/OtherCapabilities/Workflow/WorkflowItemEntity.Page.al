page 6409 "Workflow - Item Entity"
{
    Caption = 'workflowItems', Locked = true;
    DelayedInsert = true;
    SourceTable = Item;
    PageType = List;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(number2; "No. 2")
                {
                    ApplicationArea = All;
                    Caption = 'No. 2', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(searchDescription; "Search Description")
                {
                    ApplicationArea = All;
                    Caption = 'Search Description', Locked = true;
                }
                field(description2; "Description 2")
                {
                    ApplicationArea = All;
                    Caption = 'Description 2', Locked = true;
                }
                field(assemblyBom; "Assembly BOM")
                {
                    ApplicationArea = All;
                    Caption = 'Assembly BOM', Locked = true;
                }
                field(baseUnitOfMeasure; "Base Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Base Unit of Measure', Locked = true;
                }
                field(priceUnitConversion; "Price Unit Conversion")
                {
                    ApplicationArea = All;
                    Caption = 'Price Unit Conversion', Locked = true;
                }
                field(type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                }
                field(inventoryPostingGroup; "Inventory Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Posting Group', Locked = true;
                }
                field(shelfNumber; "Shelf No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shelf No.', Locked = true;
                }
                field(itemDiscGroup; "Item Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Item Disc. Group', Locked = true;
                }
                field(allowInvoiceDisc; "Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Invoice Disc.', Locked = true;
                }
                field(statisticsGroup; "Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Statistics Group', Locked = true;
                }
                field(commissionGroup; "Commission Group")
                {
                    ApplicationArea = All;
                    Caption = 'Commission Group', Locked = true;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price', Locked = true;
                }
                field(priceProfitCalculation; "Price/Profit Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Price/Profit Calculation', Locked = true;
                }
                field(profitPercent; "Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(costingMethod; "Costing Method")
                {
                    ApplicationArea = All;
                    Caption = 'Costing Method', Locked = true;
                }
                field(unitCost; "Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost', Locked = true;
                }
                field(standardCost; "Standard Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Standard Cost', Locked = true;
                }
                field(lastDirectCost; "Last Direct Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Last Direct Cost', Locked = true;
                }
                field(indirectCostPercent; "Indirect Cost %")
                {
                    ApplicationArea = All;
                    Caption = 'Indirect Cost %', Locked = true;
                }
                field(costIsAdjusted; "Cost is Adjusted")
                {
                    ApplicationArea = All;
                    Caption = 'Cost is Adjusted', Locked = true;
                }
                field(allowOnlineAdjustment; "Allow Online Adjustment")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Online Adjustment', Locked = true;
                }
                field(vendorNumber; "Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor No.', Locked = true;
                }
                field(vendorItemNumber; "Vendor Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Item No.', Locked = true;
                }
                field(leadTimeCalculation; "Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(reorderPoint; "Reorder Point")
                {
                    ApplicationArea = All;
                    Caption = 'Reorder Point', Locked = true;
                }
                field(maximumInventory; "Maximum Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum Inventory', Locked = true;
                }
                field(reorderQuantity; "Reorder Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reorder Quantity', Locked = true;
                }
                field(alternativeItemNumber; "Alternative Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Alternative Item No.', Locked = true;
                }
                field(unitListPrice; "Unit List Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit List Price', Locked = true;
                }
                field(dutyDuePercent; "Duty Due %")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Due %', Locked = true;
                }
                field(dutyCode; "Duty Code")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Code', Locked = true;
                }
                field(grossWeight; "Gross Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Gross Weight', Locked = true;
                }
                field(netWeight; "Net Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Net Weight', Locked = true;
                }
                field(unitsPerParcel; "Units per Parcel")
                {
                    ApplicationArea = All;
                    Caption = 'Units per Parcel', Locked = true;
                }
                field(unitVolume; "Unit Volume")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Volume', Locked = true;
                }
                field(durability; Durability)
                {
                    ApplicationArea = All;
                    Caption = 'Durability', Locked = true;
                }
                field(freightType; "Freight Type")
                {
                    ApplicationArea = All;
                    Caption = 'Freight Type', Locked = true;
                }
                field(tariffNumber; "Tariff No.")
                {
                    ApplicationArea = All;
                    Caption = 'Tariff No.', Locked = true;
                }
                field(dutyUnitConversion; "Duty Unit Conversion")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Unit Conversion', Locked = true;
                }
                field(countryRegionPurchasedCode; "Country/Region Purchased Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Purchased Code', Locked = true;
                }
                field(budgetQuantity; "Budget Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Budget Quantity', Locked = true;
                }
                field(budgetedAmount; "Budgeted Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted Amount', Locked = true;
                }
                field(budgetProfit; "Budget Profit")
                {
                    ApplicationArea = All;
                    Caption = 'Budget Profit', Locked = true;
                }
                field(comment; Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(blocked; Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                }
                field(costIsPostedToGL; "Cost is Posted to G/L")
                {
                    ApplicationArea = All;
                    Caption = 'Cost is Posted to G/L', Locked = true;
                }
                field(blockReason; "Block Reason")
                {
                    ApplicationArea = All;
                    Caption = 'Block Reason', Locked = true;
                }
                field(lastDatetimeModified; "Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last DateTime Modified', Locked = true;
                }
                field(lastDateModified; "Last Date Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Date Modified', Locked = true;
                }
                field(lastTimeModified; "Last Time Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Time Modified', Locked = true;
                }
                field(dateFilter; "Date Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Date Filter', Locked = true;
                }
                field(globalDimension1Filter; "Global Dimension 1 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Filter', Locked = true;
                }
                field(globalDimension2Filter; "Global Dimension 2 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Filter', Locked = true;
                }
                field(locationFilter; "Location Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Location Filter', Locked = true;
                }
                field(inventory; Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory', Locked = true;
                }
                field(netInvoicedQty; "Net Invoiced Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Net Invoiced Qty.', Locked = true;
                }
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change', Locked = true;
                }
                field(purchasesQty; "Purchases (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (Qty.)', Locked = true;
                }
                field(salesQty; "Sales (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales (Qty.)', Locked = true;
                }
                field(positiveAdjmtQty; "Positive Adjmt. (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Positive Adjmt. (Qty.)', Locked = true;
                }
                field(negativeAdjmtQty; "Negative Adjmt. (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Negative Adjmt. (Qty.)', Locked = true;
                }
                field(purchasesLcy; "Purchases (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (LCY)', Locked = true;
                }
                field(salesLcy; "Sales (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales (LCY)', Locked = true;
                }
                field(positiveAdjmtLcy; "Positive Adjmt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Positive Adjmt. (LCY)', Locked = true;
                }
                field(negativeAdjmtLcy; "Negative Adjmt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Negative Adjmt. (LCY)', Locked = true;
                }
                field(cogsLcy; "COGS (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'COGS (LCY)', Locked = true;
                }
                field(qtyOnPurchOrder; "Qty. on Purch. Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Purch. Order', Locked = true;
                }
                field(qtyOnSalesOrder; "Qty. on Sales Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Sales Order', Locked = true;
                }
                field(priceIncludesVat; "Price Includes VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Price Includes VAT', Locked = true;
                }
                field(dropShipmentFilter; "Drop Shipment Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Drop Shipment Filter', Locked = true;
                }
                field(vatBusPostingGrPrice; "VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Gr. (Price)', Locked = true;
                }
                field(genProdPostingGroup; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Prod. Posting Group', Locked = true;
                }
                field(picture; Picture)
                {
                    ApplicationArea = All;
                    Caption = 'Picture', Locked = true;
                }
                field(transferredQty; "Transferred (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Transferred (Qty.)', Locked = true;
                }
                field(transferredLcy; "Transferred (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Transferred (LCY)', Locked = true;
                }
                field(countryRegionOfOriginCode; "Country/Region of Origin Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region of Origin Code', Locked = true;
                }
                field(automaticExtTexts; "Automatic Ext. Texts")
                {
                    ApplicationArea = All;
                    Caption = 'Automatic Ext. Texts', Locked = true;
                }
                field(numberSeries; "No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(taxGroupCode; "Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Code', Locked = true;
                }
                field(vatProdPostingGroup; "VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Prod. Posting Group', Locked = true;
                }
                field(reserve; Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
                }
                field(reservedQtyOnInventory; "Reserved Qty. on Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Inventory', Locked = true;
                }
                field(reservedQtyOnPurchOrders; "Reserved Qty. on Purch. Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Purch. Orders', Locked = true;
                }
                field(reservedQtyOnSalesOrders; "Reserved Qty. on Sales Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Sales Orders', Locked = true;
                }
                field(globalDimension1Code; "Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Code', Locked = true;
                }
                field(globalDimension2Code; "Global Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Code', Locked = true;
                }
                field(resQtyOnOutboundTransfer; "Res. Qty. on Outbound Transfer")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Outbound Transfer', Locked = true;
                }
                field(resQtyOnInboundTransfer; "Res. Qty. on Inbound Transfer")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Inbound Transfer', Locked = true;
                }
                field(resQtyOnSalesReturns; "Res. Qty. on Sales Returns")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Sales Returns', Locked = true;
                }
                field(resQtyOnPurchReturns; "Res. Qty. on Purch. Returns")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Purch. Returns', Locked = true;
                }
                field(stockoutWarning; "Stockout Warning")
                {
                    ApplicationArea = All;
                    Caption = 'Stockout Warning', Locked = true;
                }
                field(preventNegativeInventory; "Prevent Negative Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Prevent Negative Inventory', Locked = true;
                }
                field(costOfOpenProductionOrders; "Cost of Open Production Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Cost of Open Production Orders', Locked = true;
                }
                field(applicationWkshUserId; "Application Wksh. User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Application Wksh. User ID', Locked = true;
                }
                field(assemblyPolicy; "Assembly Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Assembly Policy', Locked = true;
                }
                field(resQtyOnAssemblyOrder; "Res. Qty. on Assembly Order")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Assembly Order', Locked = true;
                }
                field(resQtyOnAsmComp; "Res. Qty. on  Asm. Comp.")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on  Asm. Comp.', Locked = true;
                }
                field(qtyOnAssemblyOrder; "Qty. on Assembly Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Assembly Order', Locked = true;
                }
                field(qtyOnAsmComponent; "Qty. on Asm. Component")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Asm. Component', Locked = true;
                }
                field(qtyOnJobOrder; "Qty. on Job Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Job Order', Locked = true;
                }
                field(resQtyOnJobOrder; "Res. Qty. on Job Order")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Job Order', Locked = true;
                }
                field(gtin; GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'GTIN', Locked = true;
                }
                field(defaultDeferralTemplateCode; "Default Deferral Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Default Deferral Template Code', Locked = true;
                }
                field(lowLevelCode; "Low-Level Code")
                {
                    ApplicationArea = All;
                    Caption = 'Low-Level Code', Locked = true;
                }
                field(lotSize; "Lot Size")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Size', Locked = true;
                }
                field(serialNos; "Serial Nos.")
                {
                    ApplicationArea = All;
                    Caption = 'Serial Nos.', Locked = true;
                }
                field(lastUnitCostCalcDate; "Last Unit Cost Calc. Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Unit Cost Calc. Date', Locked = true;
                }
                field(rolledUpMaterialCost; "Rolled-up Material Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Material Cost', Locked = true;
                }
                field(rolledUpCapacityCost; "Rolled-up Capacity Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Capacity Cost', Locked = true;
                }
                field(scrapPercent; "Scrap %")
                {
                    ApplicationArea = All;
                    Caption = 'Scrap %', Locked = true;
                }
                field(inventoryValueZero; "Inventory Value Zero")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Value Zero', Locked = true;
                }
                field(discreteOrderQuantity; "Discrete Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Discrete Order Quantity', Locked = true;
                }
                field(minimumOrderQuantity; "Minimum Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Minimum Order Quantity', Locked = true;
                }
                field(maximumOrderQuantity; "Maximum Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum Order Quantity', Locked = true;
                }
                field(safetyStockQuantity; "Safety Stock Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Stock Quantity', Locked = true;
                }
                field(orderMultiple; "Order Multiple")
                {
                    ApplicationArea = All;
                    Caption = 'Order Multiple', Locked = true;
                }
                field(safetyLeadTime; "Safety Lead Time")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Lead Time', Locked = true;
                }
                field(flushingMethod; "Flushing Method")
                {
                    ApplicationArea = All;
                    Caption = 'Flushing Method', Locked = true;
                }
                field(replenishmentSystem; "Replenishment System")
                {
                    ApplicationArea = All;
                    Caption = 'Replenishment System', Locked = true;
                }
                field(scheduledReceiptQty; "Scheduled Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Scheduled Receipt (Qty.)', Locked = true;
                }
                field(scheduledNeedQty; "Scheduled Need (Qty.)")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Use the field ''qtyOnComponentLines'' instead';
                    ObsoleteTag = '18.0';
                    ApplicationArea = All;
                    Caption = 'Scheduled Need (Qty.)', Locked = true;
                }
                field(roundingPrecision; "Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'Rounding Precision', Locked = true;
                }
                field(binFilter; "Bin Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Bin Filter', Locked = true;
                }
                field(variantFilter; "Variant Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Filter', Locked = true;
                }
                field(salesUnitOfMeasure; "Sales Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Unit of Measure', Locked = true;
                }
                field(purchUnitOfMeasure; "Purch. Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Unit of Measure', Locked = true;
                }
                field(timeBucket; "Time Bucket")
                {
                    ApplicationArea = All;
                    Caption = 'Time Bucket', Locked = true;
                }
                field(reservedQtyOnProdOrder; "Reserved Qty. on Prod. Order")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Prod. Order', Locked = true;
                }
                field(resQtyOnProdOrderComp; "Res. Qty. on Prod. Order Comp.")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Prod. Order Comp.', Locked = true;
                }
                field(resQtyOnReqLine; "Res. Qty. on Req. Line")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Req. Line', Locked = true;
                }
                field(reorderingPolicy; "Reordering Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Reordering Policy', Locked = true;
                }
                field(includeInventory; "Include Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Include Inventory', Locked = true;
                }
                field(manufacturingPolicy; "Manufacturing Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Manufacturing Policy', Locked = true;
                }
                field(reschedulingPeriod; "Rescheduling Period")
                {
                    ApplicationArea = All;
                    Caption = 'Rescheduling Period', Locked = true;
                }
                field(lotAccumulationPeriod; "Lot Accumulation Period")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Accumulation Period', Locked = true;
                }
                field(dampenerPeriod; "Dampener Period")
                {
                    ApplicationArea = All;
                    Caption = 'Dampener Period', Locked = true;
                }
                field(dampenerQuantity; "Dampener Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Dampener Quantity', Locked = true;
                }
                field(overflowLevel; "Overflow Level")
                {
                    ApplicationArea = All;
                    Caption = 'Overflow Level', Locked = true;
                }
                field(planningTransferShipQty; "Planning Transfer Ship. (Qty).")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Transfer Ship. (Qty).', Locked = true;
                }
                field(planningWorksheetQty; "Planning Worksheet (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Worksheet (Qty.)', Locked = true;
                }
                field(stockkeepingUnitExists; "Stockkeeping Unit Exists")
                {
                    ApplicationArea = All;
                    Caption = 'Stockkeeping Unit Exists', Locked = true;
                }
                field(manufacturerCode; "Manufacturer Code")
                {
                    ApplicationArea = All;
                    Caption = 'Manufacturer Code', Locked = true;
                }
                field(itemCategoryCode; "Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Category Code', Locked = true;
                }
                field(createdFromNonstockItem; "Created From Nonstock Item")
                {
                    ApplicationArea = All;
                    Caption = 'Created From Catalog Item', Locked = true;
                }
                field(substitutesExist; "Substitutes Exist")
                {
                    ApplicationArea = All;
                    Caption = 'Substitutes Exist', Locked = true;
                }
                field(qtyInTransit; "Qty. in Transit")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. in Transit', Locked = true;
                }
                field(transOrdReceiptQty; "Trans. Ord. Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Trans. Ord. Receipt (Qty.)', Locked = true;
                }
                field(transOrdShipmentQty; "Trans. Ord. Shipment (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Trans. Ord. Shipment (Qty.)', Locked = true;
                }
                field(qtyAssignedToShip; "Qty. Assigned to ship")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Assigned to ship', Locked = true;
                }
                field(qtyPicked; "Qty. Picked")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Picked', Locked = true;
                }
                field(serviceItemGroup; "Service Item Group")
                {
                    ApplicationArea = All;
                    Caption = 'Service Item Group', Locked = true;
                }
                field(qtyOnServiceOrder; "Qty. on Service Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Service Order', Locked = true;
                }
                field(resQtyOnServiceOrders; "Res. Qty. on Service Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Service Orders', Locked = true;
                }
                field(itemTrackingCode; "Item Tracking Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Tracking Code', Locked = true;
                }
                field(lotNos; "Lot Nos.")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Nos.', Locked = true;
                }
                field(expirationCalculation; "Expiration Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Expiration Calculation', Locked = true;
                }
                field(lotNumberFilter; "Lot No. Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Lot No. Filter', Locked = true;
                }
                field(serialNumberFilter; "Serial No. Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Serial No. Filter', Locked = true;
                }
                field(qtyOnPurchReturn; "Qty. on Purch. Return")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Purch. Return', Locked = true;
                }
                field(qtyOnSalesReturn; "Qty. on Sales Return")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Sales Return', Locked = true;
                }
                field(numberOfSubstitutes; "No. of Substitutes")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Substitutes', Locked = true;
                }
                field(warehouseClassCode; "Warehouse Class Code")
                {
                    ApplicationArea = All;
                    Caption = 'Warehouse Class Code', Locked = true;
                }
                field(specialEquipmentCode; "Special Equipment Code")
                {
                    ApplicationArea = All;
                    Caption = 'Special Equipment Code', Locked = true;
                }
                field(putAwayTemplateCode; "Put-away Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Put-away Template Code', Locked = true;
                }
                field(putAwayUnitOfMeasureCode; "Put-away Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Put-away Unit of Measure Code', Locked = true;
                }
                field(physInvtCountingPeriodCode; "Phys Invt Counting Period Code")
                {
                    ApplicationArea = All;
                    Caption = 'Phys Invt Counting Period Code', Locked = true;
                }
                field(lastCountingPeriodUpdate; "Last Counting Period Update")
                {
                    ApplicationArea = All;
                    Caption = 'Last Counting Period Update', Locked = true;
                }
                field(lastPhysInvtDate; "Last Phys. Invt. Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Phys. Invt. Date', Locked = true;
                }
                field(useCrossDocking; "Use Cross-Docking")
                {
                    ApplicationArea = All;
                    Caption = 'Use Cross-Docking', Locked = true;
                }
                field(nextCountingStartDate; "Next Counting Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'Next Counting Start Date', Locked = true;
                }
                field(nextCountingEndDate; "Next Counting End Date")
                {
                    ApplicationArea = All;
                    Caption = 'Next Counting End Date', Locked = true;
                }
                field(identifierCode; "Identifier Code")
                {
                    ApplicationArea = All;
                    Caption = 'Identifier Code', Locked = true;
                }
                field(unitOfMeasureId; "Unit of Measure Id")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure Id', Locked = true;
                }
                field(taxGroupId; "Tax Group Id")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Id', Locked = true;
                }
                field(routingNumber; "Routing No.")
                {
                    ApplicationArea = All;
                    Caption = 'Routing No.', Locked = true;
                }
                field(productionBomNumber; "Production BOM No.")
                {
                    ApplicationArea = All;
                    Caption = 'Production BOM No.', Locked = true;
                }
                field(singleLevelMaterialCost; "Single-Level Material Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Material Cost', Locked = true;
                }
                field(singleLevelCapacityCost; "Single-Level Capacity Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Capacity Cost', Locked = true;
                }
                field(singleLevelSubcontrdCost; "Single-Level Subcontrd. Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Subcontrd. Cost', Locked = true;
                }
                field(singleLevelCapOvhdCost; "Single-Level Cap. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Cap. Ovhd Cost', Locked = true;
                }
                field(singleLevelMfgOvhdCost; "Single-Level Mfg. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Mfg. Ovhd Cost', Locked = true;
                }
                field(overheadRate; "Overhead Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Overhead Rate', Locked = true;
                }
                field(rolledUpSubcontractedCost; "Rolled-up Subcontracted Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Subcontracted Cost', Locked = true;
                }
                field(rolledUpMfgOvhdCost; "Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Mfg. Ovhd Cost', Locked = true;
                }
                field(rolledUpCapOverheadCost; "Rolled-up Cap. Overhead Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Cap. Overhead Cost', Locked = true;
                }
                field(planningIssuesQty; "Planning Issues (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Issues (Qty.)', Locked = true;
                }
                field(planningReceiptQty; "Planning Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Receipt (Qty.)', Locked = true;
                }
                field(plannedOrderReceiptQty; "Planned Order Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Order Receipt (Qty.)', Locked = true;
                }
                field(fpOrderReceiptQty; "FP Order Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'FP Order Receipt (Qty.)', Locked = true;
                }
                field(relOrderReceiptQty; "Rel. Order Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Rel. Order Receipt (Qty.)', Locked = true;
                }
                field(planningReleaseQty; "Planning Release (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Release (Qty.)', Locked = true;
                }
                field(plannedOrderReleaseQty; "Planned Order Release (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Order Release (Qty.)', Locked = true;
                }
                field(purchReqReceiptQty; "Purch. Req. Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Req. Receipt (Qty.)', Locked = true;
                }
                field(purchReqReleaseQty; "Purch. Req. Release (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Req. Release (Qty.)', Locked = true;
                }
                field(orderTrackingPolicy; "Order Tracking Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Order Tracking Policy', Locked = true;
                }
                field(prodForecastQuantityBase; "Prod. Forecast Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Forecast Quantity (Base)', Locked = true;
                }
                field(productionForecastName; "Production Forecast Name")
                {
                    ApplicationArea = All;
                    Caption = 'Demand Forecast Name', Locked = true;
                }
                field(componentForecast; "Component Forecast")
                {
                    ApplicationArea = All;
                    Caption = 'Component Forecast', Locked = true;
                }
                field(qtyOnProdOrder; "Qty. on Prod. Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Prod. Order', Locked = true;
                }
                field(qtyOnComponentLines; "Qty. on Component Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Component Lines', Locked = true;
                }
                field(critical; Critical)
                {
                    ApplicationArea = All;
                    Caption = 'Critical', Locked = true;
                }
                field(commonItemNumber; "Common Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Common Item No.', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

