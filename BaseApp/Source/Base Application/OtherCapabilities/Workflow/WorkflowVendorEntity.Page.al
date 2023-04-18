page 6410 "Workflow - Vendor Entity"
{
    Caption = 'workflowVendors', Locked = true;
    DelayedInsert = true;
    SourceTable = Vendor;
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
                field(budgetedAmount; "Budgeted Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted Amount', Locked = true;
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
                field(purchaserCode; "Purchaser Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchaser Code', Locked = true;
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
                field(invoiceDiscCode; "Invoice Disc. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Disc. Code', Locked = true;
                }
                field(countryRegionCode; "Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code', Locked = true;
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
                field(payToVendorNumber; "Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
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
                field(purchasesLcy; "Purchases (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (LCY)', Locked = true;
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
                field(amtRcdNotInvoiced; "Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced', Locked = true;
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
                field(amtRcdNotInvoicedLcy; "Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
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
                field(outstandingInvoices; "Outstanding Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices', Locked = true;
                }
                field(outstandingInvoicesLcy; "Outstanding Invoices (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices (LCY)', Locked = true;
                }
                field(payToNumberOfArchivedDoc; "Pay-to No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. Of Archived Doc.', Locked = true;
                }
                field(buyFromNumberOfArchivedDoc; "Buy-from No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from No. Of Archived Doc.', Locked = true;
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
                field(creditorNumber; "Creditor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Creditor No.', Locked = true;
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
                field(responsibilityCenter; "Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(locationCode; "Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(leadTimeCalculation; "Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(numberOfPstdReceipts; "No. of Pstd. Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Receipts', Locked = true;
                }
                field(numberOfPstdInvoices; "No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Invoices', Locked = true;
                }
                field(numberOfPstdReturnShipments; "No. of Pstd. Return Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Return Shipments', Locked = true;
                }
                field(numberOfPstdCreditMemos; "No. of Pstd. Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Credit Memos', Locked = true;
                }
                field(payToNumberOfOrders; "Pay-to No. of Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Orders', Locked = true;
                }
                field(payToNumberOfInvoices; "Pay-to No. of Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Invoices', Locked = true;
                }
                field(payToNumberOfReturnOrders; "Pay-to No. of Return Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Return Orders', Locked = true;
                }
                field(payToNumberOfCreditMemos; "Pay-to No. of Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Credit Memos', Locked = true;
                }
                field(payToNumberOfPstdReceipts; "Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Receipts', Locked = true;
                }
                field(payToNumberOfPstdInvoices; "Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Invoices', Locked = true;
                }
                field(payToNumberOfPstdReturnS; "Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Return S.', Locked = true;
                }
                field(payToNumberOfPstdCrMemos; "Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Cr. Memos', Locked = true;
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
                field(numberOfOrderAddresses; "No. of Order Addresses")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Order Addresses', Locked = true;
                }
                field(payToNumberOfQuotes; "Pay-to No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Quotes', Locked = true;
                }
                field(payToNumberOfBlanketOrders; "Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Blanket Orders', Locked = true;
                }
                field(numberOfIncomingDocuments; "No. of Incoming Documents")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Incoming Documents', Locked = true;
                }
                field(baseCalendarCode; "Base Calendar Code")
                {
                    ApplicationArea = All;
                    Caption = 'Base Calendar Code', Locked = true;
                }
                field(documentSendingProfile; "Document Sending Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Document Sending Profile', Locked = true;
                }
                field(validateEuVatRegNumber; "Validate EU Vat Reg. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Validate EU Vat Reg. No.', Locked = true;
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
                field(paymentMethodId; "Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Id', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

