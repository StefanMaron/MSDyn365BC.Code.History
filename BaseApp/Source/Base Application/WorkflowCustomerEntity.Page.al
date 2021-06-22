page 6408 "Workflow - Customer Entity"
{
    Caption = 'workflowCustomers', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = Id;
    PageType = List;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(searchName; "Search Name")
                {
                    ApplicationArea = All;
                    Caption = 'Search Name', Locked = true;
                }
                field(name2; "Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Name 2', Locked = true;
                }
                field(address; Address)
                {
                    ApplicationArea = All;
                    Caption = 'Address', Locked = true;
                }
                field(address2; "Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Address 2', Locked = true;
                }
                field(city; City)
                {
                    ApplicationArea = All;
                    Caption = 'City', Locked = true;
                }
                field(contact; Contact)
                {
                    ApplicationArea = All;
                    Caption = 'Contact', Locked = true;
                }
                field(phoneNumber; "Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'Phone No.', Locked = true;
                }
                field(telexNumber; "Telex No.")
                {
                    ApplicationArea = All;
                    Caption = 'Telex No.', Locked = true;
                }
                field(documentSendingProfile; "Document Sending Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Document Sending Profile', Locked = true;
                }
                field(ourAccountNumber; "Our Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Our Account No.', Locked = true;
                }
                field(territoryCode; "Territory Code")
                {
                    ApplicationArea = All;
                    Caption = 'Territory Code', Locked = true;
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
                field(chainName; "Chain Name")
                {
                    ApplicationArea = All;
                    Caption = 'Chain Name', Locked = true;
                }
                field(budgetedAmount; "Budgeted Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted Amount', Locked = true;
                }
                field(creditLimitLcy; "Credit Limit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Limit (LCY)', Locked = true;
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
                field(customerPriceGroup; "Customer Price Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Price Group', Locked = true;
                }
                field(languageCode; "Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(statisticsGroup; "Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Statistics Group', Locked = true;
                }
                field(paymentTermsCode; "Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(finChargeTermsCode; "Fin. Charge Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Fin. Charge Terms Code', Locked = true;
                }
                field(salespersonCode; "Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'Salesperson Code', Locked = true;
                }
                field(shipmentMethodCode; "Shipment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Method Code', Locked = true;
                }
                field(shippingAgentCode; "Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(placeOfExport; "Place of Export")
                {
                    ApplicationArea = All;
                    Caption = 'Place of Export', Locked = true;
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
                field(countryRegionCode; "Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code', Locked = true;
                }
                field(collectionMethod; "Collection Method")
                {
                    ApplicationArea = All;
                    Caption = 'Collection Method', Locked = true;
                }
                field(amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
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
                field(invoiceCopies; "Invoice Copies")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Copies', Locked = true;
                }
                field(lastStatementNumber; "Last Statement No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Statement No.', Locked = true;
                }
                field(printStatements; "Print Statements")
                {
                    ApplicationArea = All;
                    Caption = 'Print Statements', Locked = true;
                }
                field(billToCustomerNumber; "Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Customer No.', Locked = true;
                }
                field(priority; Priority)
                {
                    ApplicationArea = All;
                    Caption = 'Priority', Locked = true;
                }
                field(paymentMethodCode; "Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified Date Time', Locked = true;
                }
                field(lastDateModified; "Last Date Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Date Modified', Locked = true;
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
                field(balance; Balance)
                {
                    ApplicationArea = All;
                    Caption = 'Balance', Locked = true;
                }
                field(balanceLcy; "Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance (LCY)', Locked = true;
                }
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change', Locked = true;
                }
                field(netChangeLcy; "Net Change (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change (LCY)', Locked = true;
                }
                field(salesLcy; "Sales (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales (LCY)', Locked = true;
                }
                field(profitLcy; "Profit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Profit (LCY)', Locked = true;
                }
                field(invDiscountsLcy; "Inv. Discounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discounts (LCY)', Locked = true;
                }
                field(pmtDiscountsLcy; "Pmt. Discounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discounts (LCY)', Locked = true;
                }
                field(balanceDue; "Balance Due")
                {
                    ApplicationArea = All;
                    Caption = 'Balance Due', Locked = true;
                }
                field(balanceDueLcy; "Balance Due (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance Due (LCY)', Locked = true;
                }
                field(payments; Payments)
                {
                    ApplicationArea = All;
                    Caption = 'Payments', Locked = true;
                }
                field(invoiceAmounts; "Invoice Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Amounts', Locked = true;
                }
                field(crMemoAmounts; "Cr. Memo Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Cr. Memo Amounts', Locked = true;
                }
                field(financeChargeMemoAmounts; "Finance Charge Memo Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Finance Charge Memo Amounts', Locked = true;
                }
                field(paymentsLcy; "Payments (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Payments (LCY)', Locked = true;
                }
                field(invAmountsLcy; "Inv. Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Amounts (LCY)', Locked = true;
                }
                field(crMemoAmountsLcy; "Cr. Memo Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Cr. Memo Amounts (LCY)', Locked = true;
                }
                field(finChargeMemoAmountsLcy; "Fin. Charge Memo Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Fin. Charge Memo Amounts (LCY)', Locked = true;
                }
                field(outstandingOrders; "Outstanding Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Orders', Locked = true;
                }
                field(shippedNotInvoiced; "Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced', Locked = true;
                }
                field(applicationMethod; "Application Method")
                {
                    ApplicationArea = All;
                    Caption = 'Application Method', Locked = true;
                }
                field(pricesIncludingVat; "Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prices Including VAT', Locked = true;
                }
                field(locationCode; "Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(faxNumber; "Fax No.")
                {
                    ApplicationArea = All;
                    Caption = 'Fax No.', Locked = true;
                }
                field(telexAnswerBack; "Telex Answer Back")
                {
                    ApplicationArea = All;
                    Caption = 'Telex Answer Back', Locked = true;
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
                field(genBusPostingGroup; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
                }
                field(gln; GLN)
                {
                    ApplicationArea = All;
                    Caption = 'GLN', Locked = true;
                }
                field(postCode; "Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Post Code', Locked = true;
                }
                field(county; County)
                {
                    ApplicationArea = All;
                    Caption = 'County', Locked = true;
                }
                field(debitAmount; "Debit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Debit Amount', Locked = true;
                }
                field(creditAmount; "Credit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Amount', Locked = true;
                }
                field(debitAmountLcy; "Debit Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Debit Amount (LCY)', Locked = true;
                }
                field(creditAmountLcy; "Credit Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Amount (LCY)', Locked = true;
                }
                field(eMail; "E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'E-Mail', Locked = true;
                }
                field(homePage; "Home Page")
                {
                    ApplicationArea = All;
                    Caption = 'Home Page', Locked = true;
                }
                field(reminderTermsCode; "Reminder Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Terms Code', Locked = true;
                }
                field(reminderAmounts; "Reminder Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Amounts', Locked = true;
                }
                field(reminderAmountsLcy; "Reminder Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Amounts (LCY)', Locked = true;
                }
                field(numberSeries; "No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
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
                field(currencyFilter; "Currency Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Filter', Locked = true;
                }
                field(outstandingOrdersLcy; "Outstanding Orders (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Orders (LCY)', Locked = true;
                }
                field(shippedNotInvoicedLcy; "Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced (LCY)', Locked = true;
                }
                field(reserve; Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
                }
                field(blockPaymentTolerance; "Block Payment Tolerance")
                {
                    ApplicationArea = All;
                    Caption = 'Block Payment Tolerance', Locked = true;
                }
                field(pmtDiscToleranceLcy; "Pmt. Disc. Tolerance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Disc. Tolerance (LCY)', Locked = true;
                }
                field(pmtToleranceLcy; "Pmt. Tolerance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Tolerance (LCY)', Locked = true;
                }
                field(icPartnerCode; "IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(refunds; Refunds)
                {
                    ApplicationArea = All;
                    Caption = 'Refunds', Locked = true;
                }
                field(refundsLcy; "Refunds (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Refunds (LCY)', Locked = true;
                }
                field(otherAmounts; "Other Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Other Amounts', Locked = true;
                }
                field(otherAmountsLcy; "Other Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Other Amounts (LCY)', Locked = true;
                }
                field(prepaymentPercent; "Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(outstandingInvoicesLcy; "Outstanding Invoices (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices (LCY)', Locked = true;
                }
                field(outstandingInvoices; "Outstanding Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices', Locked = true;
                }
                field(billToNumberOfArchivedDoc; "Bill-to No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to No. Of Archived Doc.', Locked = true;
                }
                field(sellToNumberOfArchivedDoc; "Sell-to No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to No. Of Archived Doc.', Locked = true;
                }
                field(partnerType; "Partner Type")
                {
                    ApplicationArea = All;
                    Caption = 'Partner Type', Locked = true;
                }
                field(image; Image)
                {
                    ApplicationArea = All;
                    Caption = 'Image', Locked = true;
                }
                field(preferredBankAccountCode; "Preferred Bank Account Code")
                {
                    ApplicationArea = All;
                    Caption = 'Preferred Bank Account Code', Locked = true;
                }
                field(cashFlowPaymentTermsCode; "Cash Flow Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Cash Flow Payment Terms Code', Locked = true;
                }
                field(primaryContactNumber; "Primary Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Primary Contact No.', Locked = true;
                }
                field(contactType; "Contact Type")
                {
                    ApplicationArea = All;
                    Caption = 'Contact Type', Locked = true;
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
                field(shippingTime; "Shipping Time")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Time', Locked = true;
                }
                field(shippingAgentServiceCode; "Shipping Agent Service Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Service Code', Locked = true;
                }
                field(serviceZoneCode; "Service Zone Code")
                {
                    ApplicationArea = All;
                    Caption = 'Service Zone Code', Locked = true;
                }
                field(contractGainLossAmount; "Contract Gain/Loss Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Contract Gain/Loss Amount', Locked = true;
                }
                field(shipToFilter; "Ship-to Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Filter', Locked = true;
                }
                field(outstandingServOrdersLcy; "Outstanding Serv. Orders (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Serv. Orders (LCY)', Locked = true;
                }
                field(servShippedNotInvoicedLcy; "Serv Shipped Not Invoiced(LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Serv Shipped Not Invoiced(LCY)', Locked = true;
                }
                field(outstandingServInvoicesLcy; "Outstanding Serv.Invoices(LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Serv.Invoices(LCY)', Locked = true;
                }
                field(allowLineDisc; "Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Line Disc.', Locked = true;
                }
                field(numberOfQuotes; "No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Quotes', Locked = true;
                }
                field(numberOfBlanketOrders; "No. of Blanket Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Blanket Orders', Locked = true;
                }
                field(numberOfOrders; "No. of Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Orders', Locked = true;
                }
                field(numberOfInvoices; "No. of Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Invoices', Locked = true;
                }
                field(numberOfReturnOrders; "No. of Return Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Return Orders', Locked = true;
                }
                field(numberOfCreditMemos; "No. of Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Credit Memos', Locked = true;
                }
                field(numberOfPstdShipments; "No. of Pstd. Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Shipments', Locked = true;
                }
                field(numberOfPstdInvoices; "No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Invoices', Locked = true;
                }
                field(numberOfPstdReturnReceipts; "No. of Pstd. Return Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Return Receipts', Locked = true;
                }
                field(numberOfPstdCreditMemos; "No. of Pstd. Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Credit Memos', Locked = true;
                }
                field(numberOfShipToAddresses; "No. of Ship-to Addresses")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Ship-to Addresses', Locked = true;
                }
                field(billToNumberOfQuotes; "Bill-To No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Quotes', Locked = true;
                }
                field(billToNumberOfBlanketOrders; "Bill-To No. of Blanket Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Blanket Orders', Locked = true;
                }
                field(billToNumberOfOrders; "Bill-To No. of Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Orders', Locked = true;
                }
                field(billToNumberOfInvoices; "Bill-To No. of Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Invoices', Locked = true;
                }
                field(billToNumberOfReturnOrders; "Bill-To No. of Return Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Return Orders', Locked = true;
                }
                field(billToNumberOfCreditMemos; "Bill-To No. of Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Credit Memos', Locked = true;
                }
                field(billToNumberOfPstdShipments; "Bill-To No. of Pstd. Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Pstd. Shipments', Locked = true;
                }
                field(billToNumberOfPstdInvoices; "Bill-To No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Pstd. Invoices', Locked = true;
                }
                field(billToNumberOfPstdReturnR; "Bill-To No. of Pstd. Return R.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Pstd. Return R.', Locked = true;
                }
                field(billToNumberOfPstdCrMemos; "Bill-To No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-To No. of Pstd. Cr. Memos', Locked = true;
                }
                field(baseCalendarCode; "Base Calendar Code")
                {
                    ApplicationArea = All;
                    Caption = 'Base Calendar Code', Locked = true;
                }
                field(copySellToAddrToQteFrom; "Copy Sell-to Addr. to Qte From")
                {
                    ApplicationArea = All;
                    Caption = 'Copy Sell-to Addr. to Qte From', Locked = true;
                }
                field(validateEuVatRegNumber; "Validate EU Vat Reg. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Validate EU Vat Reg. No.', Locked = true;
                }
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(currencyId; "Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Id', Locked = true;
                }
                field(paymentTermsId; "Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Id', Locked = true;
                }
                field(shipmentMethodId; "Shipment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Method Id', Locked = true;
                }
                field(paymentMethodId; "Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Id', Locked = true;
                }
                field(taxAreaId; "Tax Area ID")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Area ID', Locked = true;
                }
                field(contactId; "Contact ID")
                {
                    ApplicationArea = All;
                    Caption = 'Contact ID', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

