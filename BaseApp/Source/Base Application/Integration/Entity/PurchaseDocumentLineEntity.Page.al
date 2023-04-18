page 6405 "Purchase Document Line Entity"
{
    Caption = 'Purchase Document Line Entity', Locked = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Purchase Line";

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
                field(buyFromVendorNumber; "Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor No.', Locked = true;
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
                field(expectedReceiptDate; "Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expected Receipt Date', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
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
                field(qtyToReceive; "Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Receive', Locked = true;
                }
                field(directUnitCost; "Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Unit Cost', Locked = true;
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
                field(unitPriceLcy; "Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price (LCY)', Locked = true;
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
                field(jobNumber; "Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(indirectCostPercent; "Indirect Cost %")
                {
                    ApplicationArea = All;
                    Caption = 'Indirect Cost %', Locked = true;
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
                field(qtyRcdNotInvoiced; "Qty. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Rcd. Not Invoiced', Locked = true;
                }
                field(amtRcdNotInvoiced; "Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced', Locked = true;
                }
                field(quantityReceived; "Quantity Received")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Received', Locked = true;
                }
                field(quantityInvoiced; "Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced', Locked = true;
                }
                field(receiptNumber; "Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receipt No.', Locked = true;
                }
                field(receiptLineNumber; "Receipt Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receipt Line No.', Locked = true;
                }
                field(profitPercent; "Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(payToVendorNumber; "Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
                }
                field(invDiscountAmount; "Inv. Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount Amount', Locked = true;
                }
                field(vendorItemNumber; "Vendor Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Item No.', Locked = true;
                }
                field(salesOrderNumber; "Sales Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order No.', Locked = true;
                }
                field(salesOrderLineNumber; "Sales Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order Line No.', Locked = true;
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
                field(entryPoint; "Entry Point")
                {
                    ApplicationArea = All;
                    Caption = 'Entry Point', Locked = true;
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
                field(useTax; "Use Tax")
                {
                    ApplicationArea = All;
                    Caption = 'Use Tax', Locked = true;
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
                field(amtRcdNotInvoicedLcy; "Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
                }
                field(reservedQuantity; "Reserved Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Quantity', Locked = true;
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
                field(outstandingAmtExVatLcy; "Outstanding Amt. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amt. Ex. VAT (LCY)', Locked = true;
                }
                field(aRcdNotInvExVatLcy; "A. Rcd. Not Inv. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)', Locked = true;
                }
                field(dimensionSetId; "Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(jobTaskNumber; "Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.', Locked = true;
                }
                field(jobLineType; "Job Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Type', Locked = true;
                }
                field(jobUnitPrice; "Job Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Price', Locked = true;
                }
                field(jobTotalPrice; "Job Total Price")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Price', Locked = true;
                }
                field(jobLineAmount; "Job Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount', Locked = true;
                }
                field(jobLineDiscountAmount; "Job Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount Amount', Locked = true;
                }
                field(jobLineDiscountPercent; "Job Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount %', Locked = true;
                }
                field(jobUnitPriceLcy; "Job Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Price (LCY)', Locked = true;
                }
                field(jobTotalPriceLcy; "Job Total Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Price (LCY)', Locked = true;
                }
                field(jobLineAmountLcy; "Job Line Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount (LCY)', Locked = true;
                }
                field(jobLineDiscAmountLcy; "Job Line Disc. Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Disc. Amount (LCY)', Locked = true;
                }
                field(jobCurrencyFactor; "Job Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Job Currency Factor', Locked = true;
                }
                field(jobCurrencyCode; "Job Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Job Currency Code', Locked = true;
                }
                field(jobPlanningLineNumber; "Job Planning Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Planning Line No.', Locked = true;
                }
                field(jobRemainingQty; "Job Remaining Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Remaining Qty.', Locked = true;
                }
                field(jobRemainingQtyBase; "Job Remaining Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Remaining Qty. (Base)', Locked = true;
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
                field(prodOrderNumber; "Prod. Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Order No.', Locked = true;
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
                field(qtyToReceiveBase; "Qty. to Receive (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Receive (Base)', Locked = true;
                }
                field(qtyRcdNotInvoicedBase; "Qty. Rcd. Not Invoiced (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Rcd. Not Invoiced (Base)', Locked = true;
                }
                field(qtyReceivedBase; "Qty. Received (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Received (Base)', Locked = true;
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
                field(faPostingType; "FA Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'FA Posting Type', Locked = true;
                }
                field(depreciationBookCode; "Depreciation Book Code")
                {
                    ApplicationArea = All;
                    Caption = 'Depreciation Book Code', Locked = true;
                }
                field(salvageValue; "Salvage Value")
                {
                    ApplicationArea = All;
                    Caption = 'Salvage Value', Locked = true;
                }
                field(deprUntilFaPostingDate; "Depr. until FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. until FA Posting Date', Locked = true;
                }
                field(deprAcquisitionCost; "Depr. Acquisition Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. Acquisition Cost', Locked = true;
                }
                field(maintenanceCode; "Maintenance Code")
                {
                    ApplicationArea = All;
                    Caption = 'Maintenance Code', Locked = true;
                }
                field(insuranceNumber; "Insurance No.")
                {
                    ApplicationArea = All;
                    Caption = 'Insurance No.', Locked = true;
                }
                field(budgetedFaNumber; "Budgeted FA No.")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted FA No.', Locked = true;
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
                field(specialOrderSalesNumber; "Special Order Sales No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Sales No.', Locked = true;
                }
                field(specialOrderSalesLineNumber; "Special Order Sales Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Sales Line No.', Locked = true;
                }
                field(whseOutstandingQtyBase; "Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty. (Base)', Locked = true;
                }
                field(completelyReceived; "Completely Received")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Received', Locked = true;
                }
                field(requestedReceiptDate; "Requested Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Requested Receipt Date', Locked = true;
                }
                field(promisedReceiptDate; "Promised Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Promised Receipt Date', Locked = true;
                }
                field(leadTimeCalculation; "Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(inboundWhseHandlingTime; "Inbound Whse. Handling Time")
                {
                    ApplicationArea = All;
                    Caption = 'Inbound Whse. Handling Time', Locked = true;
                }
                field(plannedReceiptDate; "Planned Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Receipt Date', Locked = true;
                }
                field(orderDate; "Order Date")
                {
                    ApplicationArea = All;
                    Caption = 'Order Date', Locked = true;
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
                field(returnQtyToShip; "Return Qty. to Ship")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Ship', Locked = true;
                }
                field(returnQtyToShipBase; "Return Qty. to Ship (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Ship (Base)', Locked = true;
                }
                field(returnQtyShippedNotInvd; "Return Qty. Shipped Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped Not Invd.', Locked = true;
                }
                field(retQtyShpdNotInvdBase; "Ret. Qty. Shpd Not Invd.(Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Ret. Qty. Shpd Not Invd.(Base)', Locked = true;
                }
                field(returnShpdNotInvd; "Return Shpd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shpd. Not Invd.', Locked = true;
                }
                field(returnShpdNotInvdLcy; "Return Shpd. Not Invd. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shpd. Not Invd. (LCY)', Locked = true;
                }
                field(returnQtyShipped; "Return Qty. Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped', Locked = true;
                }
                field(returnQtyShippedBase; "Return Qty. Shipped (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped (Base)', Locked = true;
                }
                field(returnShipmentNumber; "Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No.', Locked = true;
                }
                field(returnShipmentLineNumber; "Return Shipment Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment Line No.', Locked = true;
                }
                field(returnReasonCode; "Return Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Return Reason Code', Locked = true;
                }
                field(subtype; Subtype)
                {
                    ApplicationArea = All;
                    Caption = 'Subtype', Locked = true;
                }
                field(routingNumber; "Routing No.")
                {
                    ApplicationArea = All;
                    Caption = 'Routing No.', Locked = true;
                }
                field(operationNumber; "Operation No.")
                {
                    ApplicationArea = All;
                    Caption = 'Operation No.', Locked = true;
                }
                field(workCenterNumber; "Work Center No.")
                {
                    ApplicationArea = All;
                    Caption = 'Work Center No.', Locked = true;
                }
                field(finished; Finished)
                {
                    ApplicationArea = All;
                    Caption = 'Finished', Locked = true;
                }
                field(prodOrderLineNumber; "Prod. Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Order Line No.', Locked = true;
                }
                field(overheadRate; "Overhead Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Overhead Rate', Locked = true;
                }
                field(mpsOrder; "MPS Order")
                {
                    ApplicationArea = All;
                    Caption = 'MPS Order', Locked = true;
                }
                field(planningFlexibility; "Planning Flexibility")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Flexibility', Locked = true;
                }
                field(safetyLeadTime; "Safety Lead Time")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Lead Time', Locked = true;
                }
                field(routingReferenceNumber; "Routing Reference No.")
                {
                    ApplicationArea = All;
                    Caption = 'Routing Reference No.', Locked = true;
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
        PurchaseLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.PurchCheckIfAnyExtText(Rec, false) then begin
            if PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                Rec.Modify(true)
            else
                Rec.Insert(true);
            Commit();
            TransferExtendedText.InsertPurchExtText(Rec);
            exit(true);
        end;
        exit(false);
    end;
}
