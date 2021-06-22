page 6404 "Purchase Document Entity"
{
    Caption = 'workflowPurchaseDocuments', Locked = true;
    DelayedInsert = true;
    SourceTable = "Purchase Header";
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
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(payToVendorNumber; "Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
                }
                field(payToName; "Pay-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Name', Locked = true;
                }
                field(payToName2; "Pay-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Name 2', Locked = true;
                }
                field(payToAddress; "Pay-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Address', Locked = true;
                }
                field(payToAddress2; "Pay-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Address 2', Locked = true;
                }
                field(payToCity; "Pay-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to City', Locked = true;
                }
                field(payToContact; "Pay-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Contact', Locked = true;
                }
                field(yourReference; "Your Reference")
                {
                    ApplicationArea = All;
                    Caption = 'Your Reference', Locked = true;
                }
                field(shipToCode; "Ship-to Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Code', Locked = true;
                }
                field(shipToName; "Ship-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Name', Locked = true;
                }
                field(shipToName2; "Ship-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Name 2', Locked = true;
                }
                field(shipToAddress; "Ship-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Address', Locked = true;
                }
                field(shipToAddress2; "Ship-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Address 2', Locked = true;
                }
                field(shipToCity; "Ship-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to City', Locked = true;
                }
                field(shipToContact; "Ship-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Contact', Locked = true;
                }
                field(orderDate; "Order Date")
                {
                    ApplicationArea = All;
                    Caption = 'Order Date', Locked = true;
                }
                field(postingDate; "Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
                }
                field(expectedReceiptDate; "Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expected Receipt Date', Locked = true;
                }
                field(postingDescription; "Posting Description")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Description', Locked = true;
                }
                field(paymentTermsCode; "Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Due Date', Locked = true;
                }
                field(paymentDiscountPercent; "Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Discount %', Locked = true;
                }
                field(pmtDiscountDate; "Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discount Date', Locked = true;
                }
                field(shipmentMethodCode; "Shipment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Method Code', Locked = true;
                }
                field(locationCode; "Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
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
                field(vendorPostingGroup; "Vendor Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Posting Group', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(currencyFactor; "Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Factor', Locked = true;
                }
                field(pricesIncludingVat; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prices Including VAT', Locked = true;
                }
                field(invoiceDiscCode; "Invoice Disc. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Disc. Code', Locked = true;
                }
                field(languageCode; "Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(purchaserCode; "Purchaser Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchaser Code', Locked = true;
                }
                field(orderClass; "Order Class")
                {
                    ApplicationArea = All;
                    Caption = 'Order Class', Locked = true;
                }
                field(comment; Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(numberPrinted; "No. Printed")
                {
                    ApplicationArea = All;
                    Caption = 'No. Printed', Locked = true;
                }
                field(onHold; "On Hold")
                {
                    ApplicationArea = All;
                    Caption = 'On Hold', Locked = true;
                }
                field(appliesToDocType; "Applies-to Doc. Type")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Doc. Type', Locked = true;
                }
                field(appliesToDocNumber; "Applies-to Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Doc. No.', Locked = true;
                }
                field(balAccountNumber; "Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(recalculateInvoiceDisc; "Recalculate Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Recalculate Invoice Disc.', Locked = true;
                }
                field(receive; Receive)
                {
                    ApplicationArea = All;
                    Caption = 'Receive', Locked = true;
                }
                field(invoice; Invoice)
                {
                    ApplicationArea = All;
                    Caption = 'Invoice', Locked = true;
                }
                field(printPostedDocuments; "Print Posted Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Print Posted Documents', Locked = true;
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
                field(receivingNumber; "Receiving No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receiving No.', Locked = true;
                }
                field(postingNumber; "Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No.', Locked = true;
                }
                field(lastReceivingNumber; "Last Receiving No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Receiving No.', Locked = true;
                }
                field(lastPostingNumber; "Last Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Posting No.', Locked = true;
                }
                field(vendorOrderNumber; "Vendor Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Order No.', Locked = true;
                }
                field(vendorShipmentNumber; "Vendor Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Shipment No.', Locked = true;
                }
                field(vendorInvoiceNumber; "Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Invoice No.', Locked = true;
                }
                field(vendorCrMemoNumber; "Vendor Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Cr. Memo No.', Locked = true;
                }
                field(vatRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(sellToCustomerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
                }
                field(reasonCode; "Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(genBusPostingGroup; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
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
                field(vatCountryRegionCode; "VAT Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Country/Region Code', Locked = true;
                }
                field(buyFromVendorName; "Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor Name', Locked = true;
                }
                field(buyFromVendorName2; "Buy-from Vendor Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor Name 2', Locked = true;
                }
                field(buyFromAddress; "Buy-from Address")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Address', Locked = true;
                }
                field(buyFromAddress2; "Buy-from Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Address 2', Locked = true;
                }
                field(buyFromCity; "Buy-from City")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from City', Locked = true;
                }
                field(buyFromContact; "Buy-from Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Contact', Locked = true;
                }
                field(payToPostCode; "Pay-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Post Code', Locked = true;
                }
                field(payToCounty; "Pay-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to County', Locked = true;
                }
                field(payToCountryRegionCode; "Pay-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Country/Region Code', Locked = true;
                }
                field(buyFromPostCode; "Buy-from Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Post Code', Locked = true;
                }
                field(buyFromCounty; "Buy-from County")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from County', Locked = true;
                }
                field(buyFromCountryRegionCode; "Buy-from Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Country/Region Code', Locked = true;
                }
                field(shipToPostCode; "Ship-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Post Code', Locked = true;
                }
                field(shipToCounty; "Ship-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to County', Locked = true;
                }
                field(shipToCountryRegionCode; "Ship-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Country/Region Code', Locked = true;
                }
                field(balAccountType; "Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(orderAddressCode; "Order Address Code")
                {
                    ApplicationArea = All;
                    Caption = 'Order Address Code', Locked = true;
                }
                field(entryPoint; "Entry Point")
                {
                    ApplicationArea = All;
                    Caption = 'Entry Point', Locked = true;
                }
                field(correction; Correction)
                {
                    ApplicationArea = All;
                    Caption = 'Correction', Locked = true;
                }
                field(documentDate; "Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'Document Date', Locked = true;
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
                field(paymentMethodCode; "Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(numberSeries; "No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(postingNumberSeries; "Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
                }
                field(receivingNumberSeries; "Receiving No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Receiving No. Series', Locked = true;
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
                field(vatBusPostingGroup; "VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Group', Locked = true;
                }
                field(appliesToId; "Applies-to ID")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to ID', Locked = true;
                }
                field(vatBaseDiscountPercent; "VAT Base Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Discount %', Locked = true;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status', Locked = true;
                }
                field(invoiceDiscountCalculation; "Invoice Discount Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Calculation', Locked = true;
                }
                field(invoiceDiscountValue; "Invoice Discount Value")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Value', Locked = true;
                }
                field(sendIcDocument; "Send IC Document")
                {
                    ApplicationArea = All;
                    Caption = 'Send IC Document', Locked = true;
                }
                field(icStatus; "IC Status")
                {
                    ApplicationArea = All;
                    Caption = 'IC Status', Locked = true;
                }
                field(buyFromIcPartnerCode; "Buy-from IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from IC Partner Code', Locked = true;
                }
                field(payToIcPartnerCode; "Pay-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to IC Partner Code', Locked = true;
                }
                field(icDirection; "IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
                }
                field(prepaymentNumber; "Prepayment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment No.', Locked = true;
                }
                field(lastPrepaymentNumber; "Last Prepayment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepayment No.', Locked = true;
                }
                field(prepmtCrMemoNumber; "Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No.', Locked = true;
                }
                field(lastPrepmtCrMemoNumber; "Last Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepmt. Cr. Memo No.', Locked = true;
                }
                field(prepaymentPercent; "Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(prepaymentNumberSeries; "Prepayment No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment No. Series', Locked = true;
                }
                field(compressPrepayment; "Compress Prepayment")
                {
                    ApplicationArea = All;
                    Caption = 'Compress Prepayment', Locked = true;
                }
                field(prepaymentDueDate; "Prepayment Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Due Date', Locked = true;
                }
                field(prepmtCrMemoNumberSeries; "Prepmt. Cr. Memo No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No. Series', Locked = true;
                }
                field(prepmtPostingDescription; "Prepmt. Posting Description")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Posting Description', Locked = true;
                }
                field(prepmtPmtDiscountDate; "Prepmt. Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Pmt. Discount Date', Locked = true;
                }
                field(prepmtPaymentTermsCode; "Prepmt. Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Payment Terms Code', Locked = true;
                }
                field(prepmtPaymentDiscountPercent; "Prepmt. Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Payment Discount %', Locked = true;
                }
                field(quoteNumber; "Quote No.")
                {
                    ApplicationArea = All;
                    Caption = 'Quote No.', Locked = true;
                }
                field(jobQueueStatus; "Job Queue Status")
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Status', Locked = true;
                }
                field(jobQueueEntryId; "Job Queue Entry ID")
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Entry ID', Locked = true;
                }
                field(incomingDocumentEntryNumber; "Incoming Document Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Incoming Document Entry No.', Locked = true;
                }
                field(creditorNumber; "Creditor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Creditor No.', Locked = true;
                }
                field(paymentReference; "Payment Reference")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Reference', Locked = true;
                }
                field(aRcdNotInvExVatLcy; "A. Rcd. Not Inv. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)', Locked = true;
                }
                field(amtRcdNotInvoicedLcy; "Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
                }
                field(dimensionSetId; "Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(invoiceDiscountAmount; "Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Amount', Locked = true;
                }
                field(numberOfArchivedVersions; "No. of Archived Versions")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Archived Versions', Locked = true;
                }
                field(docNumberOccurrence; "Doc. No. Occurrence")
                {
                    ApplicationArea = All;
                    Caption = 'Doc. No. Occurrence', Locked = true;
                }
                field(campaignNumber; "Campaign No.")
                {
                    ApplicationArea = All;
                    Caption = 'Campaign No.', Locked = true;
                }
                field(buyFromContactNumber; "Buy-from Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Contact No.', Locked = true;
                }
                field(payToContactNumber; "Pay-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Contact No.', Locked = true;
                }
                field(responsibilityCenter; "Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(completelyReceived; "Completely Received")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Received', Locked = true;
                }
                field(postingFromWhseRef; "Posting from Whse. Ref.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting from Whse. Ref.', Locked = true;
                }
                field(locationFilter; "Location Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Location Filter', Locked = true;
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
                field(vendorAuthorizationNumber; "Vendor Authorization No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Authorization No.', Locked = true;
                }
                field(returnShipmentNumber; "Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No.', Locked = true;
                }
                field(returnShipmentNumberSeries; "Return Shipment No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No. Series', Locked = true;
                }
                field(ship; Ship)
                {
                    ApplicationArea = All;
                    Caption = 'Ship', Locked = true;
                }
                field(lastReturnShipmentNumber; "Last Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Return Shipment No.', Locked = true;
                }
                field(assignedUserId; "Assigned User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Assigned User ID', Locked = true;
                }
                field(pendingApprovals; "Pending Approvals")
                {
                    ApplicationArea = All;
                    Caption = 'Pending Approvals', Locked = true;
                }
                part(workflowPurchaseDocumentLines; "Purchase Document Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    SubPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No.");
                    EntityName = 'puchaseDocumentLine';
                    EntitySetName = 'purchaseDocumentLines';
                }
            }
        }
    }

    actions
    {
    }
}

