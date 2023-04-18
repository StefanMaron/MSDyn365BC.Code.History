page 6403 "Sales Document Line Entity"
{
    Caption = 'Sales Document Line Entity', Locked = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(documentType; "Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type', Locked = true;
                }
                field(sellToCustomerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
                }
                field(documentNumber; "Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.', Locked = true;
                }
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.', Locked = true;
                }
                field(type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;

                    trigger OnValidate()
                    begin
                        EntityChanged := true;
                    end;
                }
                field(locationCode; "Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(postingGroup; "Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Group', Locked = true;
                }
                field(shipmentDate; "Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Date', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                    Lookup = false;
                }
                field(description2; "Description 2")
                {
                    ApplicationArea = All;
                    Caption = 'Description 2', Locked = true;
                }
                field(unitOfMeasure; "Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure', Locked = true;
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity', Locked = true;
                }
                field(outstandingQuantity; "Outstanding Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Quantity', Locked = true;
                }
                field(qtyToInvoice; "Qty. to Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Invoice', Locked = true;
                }
                field(qtyToShip; "Qty. to Ship")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Ship', Locked = true;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price', Locked = true;
                }
                field(unitCostLcy; "Unit Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost (LCY)', Locked = true;
                }
                field(vatPercent; "VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT %', Locked = true;
                }
                field(lineDiscountPercent; "Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Line Discount %', Locked = true;
                }
                field(lineDiscountAmount; "Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Discount Amount', Locked = true;
                }
                field(amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
                }
                field(amountIncludingVat; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Including VAT', Locked = true;
                }
                field(allowInvoiceDisc; "Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Invoice Disc.', Locked = true;
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
                field(applToItemEntry; "Appl.-to Item Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Appl.-to Item Entry', Locked = true;
                }
                field(shortcutDimension1Code; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 1 Code', Locked = true;
                }
                field(shortcutDimension2Code; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 2 Code', Locked = true;
                }
                field(customerPriceGroup; "Customer Price Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Price Group', Locked = true;
                }
                field(jobNumber; "Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(workTypeCode; "Work Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'Work Type Code', Locked = true;
                }
                field(recalculateInvoiceDisc; "Recalculate Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Recalculate Invoice Disc.', Locked = true;
                }
                field(outstandingAmount; "Outstanding Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amount', Locked = true;
                }
                field(qtyShippedNotInvoiced; "Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped Not Invoiced', Locked = true;
                }
                field(shippedNotInvoiced; "Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced', Locked = true;
                }
                field(quantityShipped; "Quantity Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Shipped', Locked = true;
                }
                field(quantityInvoiced; "Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced', Locked = true;
                }
                field(shipmentNumber; "Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment No.', Locked = true;
                }
                field(shipmentLineNumber; "Shipment Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Line No.', Locked = true;
                }
                field(profitPercent; "Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Customer No.', Locked = true;
                }
                field(invDiscountAmount; "Inv. Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount Amount', Locked = true;
                }
                field(purchaseOrderNumber; "Purchase Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Order No.', Locked = true;
                }
                field(purchOrderLineNumber; "Purch. Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Order Line No.', Locked = true;
                }
                field(dropShipment; "Drop Shipment")
                {
                    ApplicationArea = All;
                    Caption = 'Drop Shipment', Locked = true;
                }
                field(genBusPostingGroup; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
                }
                field(genProdPostingGroup; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Prod. Posting Group', Locked = true;
                }
                field(vatCalculationType; "VAT Calculation Type")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Calculation Type', Locked = true;
                }
                field(transactionType; "Transaction Type")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Type', Locked = true;
                }
                field(transportMethod; "Transport Method")
                {
                    ApplicationArea = All;
                    Caption = 'Transport Method', Locked = true;
                }
                field(attachedToLineNumber; "Attached to Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Attached to Line No.', Locked = true;
                }
                field(exitPoint; "Exit Point")
                {
                    ApplicationArea = All;
                    Caption = 'Exit Point', Locked = true;
                }
                field("area"; Area)
                {
                    ApplicationArea = All;
                    Caption = 'Area', Locked = true;
                }
                field(transactionSpecification; "Transaction Specification")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Specification', Locked = true;
                }
                field(taxCategory; "Tax Category")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Category', Locked = true;
                }
                field(taxAreaCode; "Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Area Code', Locked = true;
                }
                field(taxLiable; "Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Liable', Locked = true;
                }
                field(taxGroupCode; "Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Code', Locked = true;
                }
                field(vatClauseCode; "VAT Clause Code")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Clause Code', Locked = true;
                }
                field(vatBusPostingGroup; "VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Group', Locked = true;
                }
                field(vatProdPostingGroup; "VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Prod. Posting Group', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(outstandingAmountLcy; "Outstanding Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amount (LCY)', Locked = true;
                }
                field(shippedNotInvoicedLcy; "Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced (LCY)', Locked = true;
                }
                field(shippedNotInvLcyNoVat; "Shipped Not Inv. (LCY) No VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Inv. (LCY) No VAT', Locked = true;
                }
                field(reservedQuantity; "Reserved Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Quantity', Locked = true;
                }
                field(reserve; Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
                }
                field(blanketOrderNumber; "Blanket Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Blanket Order No.', Locked = true;
                }
                field(blanketOrderLineNumber; "Blanket Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Blanket Order Line No.', Locked = true;
                }
                field(vatBaseAmount; "VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount', Locked = true;
                }
                field(unitCost; "Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost', Locked = true;
                }
                field(systemCreatedEntry; "System-Created Entry")
                {
                    ApplicationArea = All;
                    Caption = 'System-Created Entry', Locked = true;
                }
                field(lineAmount; "Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount', Locked = true;
                }
                field(vatDifference; "VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Difference', Locked = true;
                }
                field(invDiscAmountToInvoice; "Inv. Disc. Amount to Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Disc. Amount to Invoice', Locked = true;
                }
                field(vatIdentifier; "VAT Identifier")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Identifier', Locked = true;
                }
                field(icPartnerRefType; "IC Partner Ref. Type")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Ref. Type', Locked = true;
                }
                field(icPartnerReference; "IC Partner Reference")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Reference', Locked = true;
                }
                field(prepaymentPercent; "Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(prepmtLineAmount; "Prepmt. Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Line Amount', Locked = true;
                }
                field(prepmtAmtInv; "Prepmt. Amt. Inv.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amt. Inv.', Locked = true;
                }
                field(prepmtAmtInclVat; "Prepmt. Amt. Incl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amt. Incl. VAT', Locked = true;
                }
                field(prepaymentAmount; "Prepayment Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Amount', Locked = true;
                }
                field(prepmtVatBaseAmt; "Prepmt. VAT Base Amt.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Base Amt.', Locked = true;
                }
                field(prepaymentVatPercent; "Prepayment VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT %', Locked = true;
                }
                field(prepmtVatCalcType; "Prepmt. VAT Calc. Type")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Calc. Type', Locked = true;
                }
                field(prepaymentVatIdentifier; "Prepayment VAT Identifier")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT Identifier', Locked = true;
                }
                field(prepaymentTaxAreaCode; "Prepayment Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Area Code', Locked = true;
                }
                field(prepaymentTaxLiable; "Prepayment Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Liable', Locked = true;
                }
                field(prepaymentTaxGroupCode; "Prepayment Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Group Code', Locked = true;
                }
                field(prepmtAmtToDeduct; "Prepmt Amt to Deduct")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt Amt to Deduct', Locked = true;
                }
                field(prepmtAmtDeducted; "Prepmt Amt Deducted")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt Amt Deducted', Locked = true;
                }
                field(prepaymentLine; "Prepayment Line")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Line', Locked = true;
                }
                field(prepmtAmountInvInclVat; "Prepmt. Amount Inv. Incl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amount Inv. Incl. VAT', Locked = true;
                }
                field(prepmtAmountInvLcy; "Prepmt. Amount Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amount Inv. (LCY)', Locked = true;
                }
                field(icPartnerCode; "IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(prepmtVatAmountInvLcy; "Prepmt. VAT Amount Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Amount Inv. (LCY)', Locked = true;
                }
                field(prepaymentVatDifference; "Prepayment VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT Difference', Locked = true;
                }
                field(prepmtVatDiffToDeduct; "Prepmt VAT Diff. to Deduct")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt VAT Diff. to Deduct', Locked = true;
                }
                field(prepmtVatDiffDeducted; "Prepmt VAT Diff. Deducted")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt VAT Diff. Deducted', Locked = true;
                }
                field(dimensionSetId; "Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(qtyToAssembleToOrder; "Qty. to Assemble to Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Assemble to Order', Locked = true;
                }
                field(qtyToAsmToOrderBase; "Qty. to Asm. to Order (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Asm. to Order (Base)', Locked = true;
                }
                field(atoWhseOutstandingQty; "ATO Whse. Outstanding Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'ATO Whse. Outstanding Qty.', Locked = true;
                }
                field(atoWhseOutstdQtyBase; "ATO Whse. Outstd. Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'ATO Whse. Outstd. Qty. (Base)', Locked = true;
                }
                field(jobTaskNumber; "Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.', Locked = true;
                }
                field(jobContractEntryNumber; "Job Contract Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Contract Entry No.', Locked = true;
                }
                field(postingDate; "Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
                }
                field(deferralCode; "Deferral Code")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Code', Locked = true;
                }
                field(returnsDeferralStartDate; "Returns Deferral Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'Returns Deferral Start Date', Locked = true;
                }
                field(variantCode; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Code', Locked = true;
                }
                field(binCode; "Bin Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bin Code', Locked = true;
                }
                field(qtyPerUnitOfMeasure; "Qty. per Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. per Unit of Measure', Locked = true;
                }
                field(planned; Planned)
                {
                    ApplicationArea = All;
                    Caption = 'Planned', Locked = true;
                }
                field(unitOfMeasureCode; "Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure Code', Locked = true;
                }
                field(quantityBase; "Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity (Base)', Locked = true;
                }
                field(outstandingQtyBase; "Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Qty. (Base)', Locked = true;
                }
                field(qtyToInvoiceBase; "Qty. to Invoice (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Invoice (Base)', Locked = true;
                }
                field(qtyToShipBase; "Qty. to Ship (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Ship (Base)', Locked = true;
                }
                field(qtyShippedNotInvdBase; "Qty. Shipped Not Invd. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped Not Invd. (Base)', Locked = true;
                }
                field(qtyShippedBase; "Qty. Shipped (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped (Base)', Locked = true;
                }
                field(qtyInvoicedBase; "Qty. Invoiced (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Invoiced (Base)', Locked = true;
                }
                field(reservedQtyBase; "Reserved Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. (Base)', Locked = true;
                }
                field(faPostingDate; "FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'FA Posting Date', Locked = true;
                }
                field(depreciationBookCode; "Depreciation Book Code")
                {
                    ApplicationArea = All;
                    Caption = 'Depreciation Book Code', Locked = true;
                }
                field(deprUntilFaPostingDate; "Depr. until FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. until FA Posting Date', Locked = true;
                }
                field(duplicateInDepreciationBook; "Duplicate in Depreciation Book")
                {
                    ApplicationArea = All;
                    Caption = 'Duplicate in Depreciation Book', Locked = true;
                }
                field(useDuplicationList; "Use Duplication List")
                {
                    ApplicationArea = All;
                    Caption = 'Use Duplication List', Locked = true;
                }
                field(responsibilityCenter; "Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(outOfStockSubstitution; "Out-of-Stock Substitution")
                {
                    ApplicationArea = All;
                    Caption = 'Out-of-Stock Substitution', Locked = true;
                }
                field(substitutionAvailable; "Substitution Available")
                {
                    ApplicationArea = All;
                    Caption = 'Substitution Available', Locked = true;
                }
                field(originallyOrderedNumber; "Originally Ordered No.")
                {
                    ApplicationArea = All;
                    Caption = 'Originally Ordered No.', Locked = true;
                }
                field(originallyOrderedVarCode; "Originally Ordered Var. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Originally Ordered Var. Code', Locked = true;
                }
                field(itemReferenceNumber; "Item Reference No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference No.', Locked = true;
                    Tooltip = 'Specifies item reference number.';
                }
                field(itemRefUnitOfMeasure; "Item Reference Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Unit of Measure', Locked = true;
                    Tooltip = 'Specifies item reference unit of measure code.';
                }
                field(itemReferenceType; "Item Reference Type")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Type', Locked = true;
                    Tooltip = 'Specifies item reference type.';
                }
                field(itemReferenceTypeNumber; "Item Reference Type No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Type No.', Locked = true;
                    Tooltip = 'Specifies item reference type number.';
                }
                field(itemCategoryCode; "Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Category Code', Locked = true;
                }
                field(nonstock; Nonstock)
                {
                    ApplicationArea = All;
                    Caption = 'Catalog', Locked = true;
                }
                field(purchasingCode; "Purchasing Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchasing Code', Locked = true;
                }
                field(specialOrder; "Special Order")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order', Locked = true;
                }
                field(specialOrderPurchaseNumber; "Special Order Purchase No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Purchase No.', Locked = true;
                }
                field(specialOrderPurchLineNumber; "Special Order Purch. Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Purch. Line No.', Locked = true;
                }
                field(whseOutstandingQty; "Whse. Outstanding Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty.', Locked = true;
                }
                field(whseOutstandingQtyBase; "Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty. (Base)', Locked = true;
                }
                field(completelyShipped; "Completely Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Shipped', Locked = true;
                }
                field(requestedDeliveryDate; "Requested Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Requested Delivery Date', Locked = true;
                }
                field(promisedDeliveryDate; "Promised Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Promised Delivery Date', Locked = true;
                }
                field(shippingTime; "Shipping Time")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Time', Locked = true;
                }
                field(outboundWhseHandlingTime; "Outbound Whse. Handling Time")
                {
                    ApplicationArea = All;
                    Caption = 'Outbound Whse. Handling Time', Locked = true;
                }
                field(plannedDeliveryDate; "Planned Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Delivery Date', Locked = true;
                }
                field(plannedShipmentDate; "Planned Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Shipment Date', Locked = true;
                }
                field(shippingAgentCode; "Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(shippingAgentServiceCode; "Shipping Agent Service Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Service Code', Locked = true;
                }
                field(allowItemChargeAssignment; "Allow Item Charge Assignment")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Item Charge Assignment', Locked = true;
                }
                field(qtyToAssign; "Qty. to Assign")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Assign', Locked = true;
                }
                field(qtyAssigned; "Qty. Assigned")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Assigned', Locked = true;
                }
                field(returnQtyToReceive; "Return Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Receive', Locked = true;
                }
                field(returnQtyToReceiveBase; "Return Qty. to Receive (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Receive (Base)', Locked = true;
                }
                field(returnQtyRcdNotInvd; "Return Qty. Rcd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Rcd. Not Invd.', Locked = true;
                }
                field(retQtyRcdNotInvdBase; "Ret. Qty. Rcd. Not Invd.(Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Ret. Qty. Rcd. Not Invd.(Base)', Locked = true;
                }
                field(returnRcdNotInvd; "Return Rcd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Rcd. Not Invd.', Locked = true;
                }
                field(returnRcdNotInvdLcy; "Return Rcd. Not Invd. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Rcd. Not Invd. (LCY)', Locked = true;
                }
                field(returnQtyReceived; "Return Qty. Received")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Received', Locked = true;
                }
                field(returnQtyReceivedBase; "Return Qty. Received (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Received (Base)', Locked = true;
                }
                field(applFromItemEntry; "Appl.-from Item Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Appl.-from Item Entry', Locked = true;
                }
                field(bomItemNumber; "BOM Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'BOM Item No.', Locked = true;
                }
                field(returnReceiptNumber; "Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No.', Locked = true;
                }
                field(returnReceiptLineNumber; "Return Receipt Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt Line No.', Locked = true;
                }
                field(returnReasonCode; "Return Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Return Reason Code', Locked = true;
                }
                field(allowLineDisc; "Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Line Disc.', Locked = true;
                }
                field(customerDiscGroup; "Customer Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Disc. Group', Locked = true;
                }
                field(subtype; Subtype)
                {
                    ApplicationArea = All;
                    Caption = 'Subtype', Locked = true;
                }
                field(priceDescription; "Price description")
                {
                    ApplicationArea = All;
                    Caption = 'Price description', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if InsertExtendedText() then
            exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if EntityChanged then
            if InsertExtendedText() then
                exit(false);
    end;

    var
        EntityChanged: Boolean;

    local procedure InsertExtendedText(): Boolean
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, false) then begin
            if SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                Rec.Modify(true)
            else
                Rec.Insert(true);
            Commit();
            TransferExtendedText.InsertSalesExtText(Rec);
            exit(true);
        end;
        exit(false);
    end;
}
