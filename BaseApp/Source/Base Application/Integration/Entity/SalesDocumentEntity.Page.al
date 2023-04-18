page 6402 "Sales Document Entity"
{
    Caption = 'workflowSalesDocuments', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    SourceTable = "Sales Header";
    PageType = List;

    layout
    {
        area(content)
        {
            group(General)
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
                field(sellToCustomerNumber; "Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Customer No.', Locked = true;
                }
                field(billToName; "Bill-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Name', Locked = true;
                }
                field(billToName2; "Bill-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Name 2', Locked = true;
                }
                field(billToAddress; "Bill-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Address', Locked = true;
                }
                field(billToAddress2; "Bill-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Address 2', Locked = true;
                }
                field(billToCity; "Bill-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to City', Locked = true;
                }
                field(billToContact; "Bill-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Contact', Locked = true;
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
                field(shipmentDate; "Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Date', Locked = true;
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
                field(customerPostingGroup; "Customer Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Posting Group', Locked = true;
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
                field(customerPriceGroup; "Customer Price Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Price Group', Locked = true;
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
                field(customerDiscGroup; "Customer Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Disc. Group', Locked = true;
                }
                field(languageCode; "Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(salespersonCode; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'Salesperson Code', Locked = true;
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
                field(ship; Ship)
                {
                    ApplicationArea = All;
                    Caption = 'Ship', Locked = true;
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
                field(amountIncludingVAT; "Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Including VAT', Locked = true;
                }
                field(shippingNumber; "Shipping No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping No.', Locked = true;
                }
                field(postingNumber; "Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No.', Locked = true;
                }
                field(lastShippingNumber; "Last Shipping No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Shipping No.', Locked = true;
                }
                field(lastPostingNumber; "Last Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Posting No.', Locked = true;
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
                field(premptCrMemoNumber; "Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No.', Locked = true;
                }
                field(lastPremtCrMemoNumber; "Last Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepmt. Cr. Memo No.', Locked = true;
                }
                field(vatRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(combineShipments; "Combine Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'Combine Shipments', Locked = true;
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
                field(eu3PartyTrade; "EU 3-Party Trade")
                {
                    ApplicationArea = All;
                    Caption = 'EU 3-Party Trade', Locked = true;
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
                field(sellToCustomerName; "Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer Name', Locked = true;
                }
                field(sellToCustomerName2; "Sell-to Customer Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer Name 2', Locked = true;
                }
                field(sellToAddress; "Sell-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Address', Locked = true;
                }
                field(sellToAddress2; "Sell-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Address 2', Locked = true;
                }
                field(sellToCity; "Sell-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to City', Locked = true;
                }
                field(sellToContact; "Sell-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Contact', Locked = true;
                }
                field(billToPostCode; "Bill-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Post Code', Locked = true;
                }
                field(billToCounty; "Bill-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to County', Locked = true;
                }
                field(billToCountryRegionCode; "Bill-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Country/Region Code', Locked = true;
                }
                field(sellToPostCode; "Sell-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Post Code', Locked = true;
                }
                field(sellToCounty; "Sell-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to County', Locked = true;
                }
                field(sellToCountryRegionCode; "Sell-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Country/Region Code', Locked = true;
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
                field(exitPoint; "Exit Point")
                {
                    ApplicationArea = All;
                    Caption = 'Exit Point', Locked = true;
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
                field(externalDocumentNumber; "External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'External Document No.', Locked = true;
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
                field(shippingAgentCode; "Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(packageTrackingNumber; "Package Tracking No.")
                {
                    ApplicationArea = All;
                    Caption = 'Package Tracking No.', Locked = true;
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
                field(shippingNumberSeries; "Shipping No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping No. Series', Locked = true;
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
                field(reserve; Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
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
                field(sellToIcPartnerCode; "Sell-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to IC Partner Code', Locked = true;
                }
                field(billToIcPartnerCode; "Bill-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to IC Partner Code', Locked = true;
                }
                field(icDirection; "IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
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
                field(quoteValidUntilDate; "Quote Valid Until Date")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Valid Until Date', Locked = true;
                }
                field(quoteSentToCustomer; "Quote Sent to Customer")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Sent to Customer', Locked = true;
                }
                field(quoteAccepted; "Quote Accepted")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Accepted', Locked = true;
                }
                field(quoteAcceptedDate; "Quote Accepted Date")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Accepted Date', Locked = true;
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
                field(workDescription; "Work Description")
                {
                    ApplicationArea = All;
                    Caption = 'Work Description', Locked = true;
                }
                field(amountShippedNotInvoicedInclVat; "Amt. Ship. Not Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT', Locked = true;
                }
                field(amountShippedNotInvoiced; "Amt. Ship. Not Inv. (LCY) Base")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Shipped Not Invoiced (LCY)', Locked = true;
                }
                field(dimensionSetId; "Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(paymentServiceSetId; "Payment Service Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Service Set ID', Locked = true;
                }
                field(directDebitMandateId; "Direct Debit Mandate ID")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Debit Mandate ID', Locked = true;
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
                field(sellToContactNumber; "Sell-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Contact No.', Locked = true;
                }
                field(billToContactNumber; "Bill-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Contact No.', Locked = true;
                }
                field(opportunityNumber; "Opportunity No.")
                {
                    ApplicationArea = All;
                    Caption = 'Opportunity No.', Locked = true;
                }
                field(responsibilityCenter; "Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(shippingAdvice; "Shipping Advice")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Advice', Locked = true;
                }
                field(shippedNotInvoiced; "Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced', Locked = true;
                }
                field(completelyShipped; "Completely Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Shipped', Locked = true;
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
                field(shipped; Shipped)
                {
                    ApplicationArea = All;
                    Caption = 'Shipped', Locked = true;
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
                field(shippingAgentServiceCode; "Shipping Agent Service Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Service Code', Locked = true;
                }
                field(lateOrderShipping; "Late Order Shipping")
                {
                    ApplicationArea = All;
                    Caption = 'Late Order Shipping', Locked = true;
                }
                field(receive; Receive)
                {
                    ApplicationArea = All;
                    Caption = 'Receive', Locked = true;
                }
                field(returnReceiptNumber; "Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No.', Locked = true;
                }
                field(returnReceiptNumberSeries; "Return Receipt No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No. Series', Locked = true;
                }
                field(lastReturnReceiptNumber; "Last Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Return Receipt No.', Locked = true;
                }
                field(allowLineDisc; "Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Line Disc.', Locked = true;
                }
                field(getShipmentUsed; "Get Shipment Used")
                {
                    ApplicationArea = All;
                    Caption = 'Get Shipment Used', Locked = true;
                }

                field(assignedUserId; "Assigned User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Assigned User ID', Locked = true;
                }
                part(workflowSalesDocumentLines; "Sales Document Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    SubPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No.");
                    EntityName = 'line';
                    EntitySetName = 'lines';
                }
            }
        }
    }

    actions
    {
    }
}

