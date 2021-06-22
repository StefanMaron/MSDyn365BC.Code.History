page 6407 "Gen. Journal Line Entity"
{
    Caption = 'workflowGenJournalLines', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    PageType = List;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(journalTemplateName; "Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name', Locked = true;
                }
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.', Locked = true;
                }
                field(accountType; "Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Account Type', Locked = true;
                }
                field(accountNumber; "Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Account No.', Locked = true;
                }
                field(postingDate; "Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
                }
                field(documentType; "Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type', Locked = true;
                }
                field(documentNumber; "Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.', Locked = true;
                }
                field(description; Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(vatPercent; "VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT %', Locked = true;
                }
                field(balAccountNumber; "Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(currencyCode; "Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(amount; Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
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
                field(amountLcy; "Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amount (LCY)', Locked = true;
                }
                field(balanceLcy; "Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance (LCY)', Locked = true;
                }
                field(currencyFactor; "Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Factor', Locked = true;
                }
                field(salesPurchLcy; "Sales/Purch. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales/Purch. (LCY)', Locked = true;
                }
                field(profitLcy; "Profit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Profit (LCY)', Locked = true;
                }
                field(invDiscountLcy; "Inv. Discount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount (LCY)', Locked = true;
                }
                field(billToPayToNumber; "Bill-to/Pay-to No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to/Pay-to No.', Locked = true;
                }
                field(postingGroup; "Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Group', Locked = true;
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
                field(salespersPurchCode; "Salespers./Purch. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Salespers./Purch. Code', Locked = true;
                }
                field(sourceCode; "Source Code")
                {
                    ApplicationArea = All;
                    Caption = 'Source Code', Locked = true;
                }
                field(systemCreatedEntry; "System-Created Entry")
                {
                    ApplicationArea = All;
                    Caption = 'System-Created Entry', Locked = true;
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
                field(dueDate; "Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Due Date', Locked = true;
                }
                field(pmtDiscountDate; "Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discount Date', Locked = true;
                }
                field(paymentDiscountPercent; "Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Discount %', Locked = true;
                }
                field(jobNumber; "Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity', Locked = true;
                }
                field(vatAmount; "VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Amount', Locked = true;
                }
                field(vatPosting; "VAT Posting")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Posting', Locked = true;
                }
                field(paymentTermsCode; "Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(appliesToId; "Applies-to ID")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to ID', Locked = true;
                }
                field(businessUnitCode; "Business Unit Code")
                {
                    ApplicationArea = All;
                    Caption = 'Business Unit Code', Locked = true;
                }
                field(journalBatchName; "Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Batch Name', Locked = true;
                }
                field(reasonCode; "Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(recurringMethod; "Recurring Method")
                {
                    ApplicationArea = All;
                    Caption = 'Recurring Method', Locked = true;
                }
                field(expirationDate; "Expiration Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expiration Date', Locked = true;
                }
                field(recurringFrequency; "Recurring Frequency")
                {
                    ApplicationArea = All;
                    Caption = 'Recurring Frequency', Locked = true;
                }
                field(allocatedAmtLcy; "Allocated Amt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Allocated Amt. (LCY)', Locked = true;
                }
                field(genPostingType; "Gen. Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Posting Type', Locked = true;
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
                field(eu3PartyTrade; "EU 3-Party Trade")
                {
                    ApplicationArea = All;
                    Caption = 'EU 3-Party Trade', Locked = true;
                }
                field(allowApplication; "Allow Application")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Application', Locked = true;
                }
                field(balAccountType; "Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(balGenPostingType; "Bal. Gen. Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Posting Type', Locked = true;
                }
                field(balGenBusPostingGroup; "Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Bus. Posting Group', Locked = true;
                }
                field(balGenProdPostingGroup; "Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Prod. Posting Group', Locked = true;
                }
                field(balVatCalculationType; "Bal. VAT Calculation Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Calculation Type', Locked = true;
                }
                field(balVatPercent; "Bal. VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT %', Locked = true;
                }
                field(balVatAmount; "Bal. VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Amount', Locked = true;
                }
                field(bankPaymentType; "Bank Payment Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bank Payment Type', Locked = true;
                }
                field(vatBaseAmount; "VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount', Locked = true;
                }
                field(balVatBaseAmount; "Bal. VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Base Amount', Locked = true;
                }
                field(correction; Correction)
                {
                    ApplicationArea = All;
                    Caption = 'Correction', Locked = true;
                }
                field(checkPrinted; "Check Printed")
                {
                    ApplicationArea = All;
                    Caption = 'Check Printed', Locked = true;
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
                field(sourceType; "Source Type")
                {
                    ApplicationArea = All;
                    Caption = 'Source Type', Locked = true;
                }
                field(sourceNumber; "Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Source No.', Locked = true;
                }
                field(postingNumberSeries; "Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
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
                field(balTaxAreaCode; "Bal. Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Area Code', Locked = true;
                }
                field(balTaxLiable; "Bal. Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Liable', Locked = true;
                }
                field(balTaxGroupCode; "Bal. Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Group Code', Locked = true;
                }
                field(balUseTax; "Bal. Use Tax")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Use Tax', Locked = true;
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
                field(balVatBusPostingGroup; "Bal. VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Bus. Posting Group', Locked = true;
                }
                field(balVatProdPostingGroup; "Bal. VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Prod. Posting Group', Locked = true;
                }
                field(additionalCurrencyPosting; "Additional-Currency Posting")
                {
                    ApplicationArea = All;
                    Caption = 'Additional-Currency Posting', Locked = true;
                }
                field(faAddCurrencyFactor; "FA Add.-Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'FA Add.-Currency Factor', Locked = true;
                }
                field(sourceCurrencyCode; "Source Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Source Currency Code', Locked = true;
                }
                field(sourceCurrencyAmount; "Source Currency Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Currency Amount', Locked = true;
                }
                field(sourceCurrVatBaseAmount; "Source Curr. VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Curr. VAT Base Amount', Locked = true;
                }
                field(sourceCurrVatAmount; "Source Curr. VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Curr. VAT Amount', Locked = true;
                }
                field(vatBaseDiscountPercent; "VAT Base Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Discount %', Locked = true;
                }
                field(vatAmountLcy; "VAT Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Amount (LCY)', Locked = true;
                }
                field(vatBaseAmountLcy; "VAT Base Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount (LCY)', Locked = true;
                }
                field(balVatAmountLcy; "Bal. VAT Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Amount (LCY)', Locked = true;
                }
                field(balVatBaseAmountLcy; "Bal. VAT Base Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Base Amount (LCY)', Locked = true;
                }
                field(reversingEntry; "Reversing Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Reversing Entry', Locked = true;
                }
                field(allowZeroAmountPosting; "Allow Zero-Amount Posting")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Zero-Amount Posting', Locked = true;
                }
                field(shipToOrderAddressCode; "Ship-to/Order Address Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to/Order Address Code', Locked = true;
                }
                field(vatDifference; "VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Difference', Locked = true;
                }
                field(balVatDifference; "Bal. VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Difference', Locked = true;
                }
                field(icPartnerCode; "IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(icDirection; "IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
                }
                field(icPartnerGLAccNumber; "IC Partner G/L Acc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner G/L Acc. No.', Locked = true;
                }
                field(icPartnerTransactionNumber; "IC Partner Transaction No.")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Transaction No.', Locked = true;
                }
                field(sellToBuyFromNumber; "Sell-to/Buy-from No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to/Buy-from No.', Locked = true;
                }
                field(vatRegistrationNumber; "VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(countryRegionCode; "Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code', Locked = true;
                }
                field(prepayment; Prepayment)
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment', Locked = true;
                }
                field(financialVoid; "Financial Void")
                {
                    ApplicationArea = All;
                    Caption = 'Financial Void', Locked = true;
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
                field(paymentMethodCode; "Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(appliesToExtDocNumber; "Applies-to Ext. Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Ext. Doc. No.', Locked = true;
                }
                field(recipientBankAccount; "Recipient Bank Account")
                {
                    ApplicationArea = All;
                    Caption = 'Recipient Bank Account', Locked = true;
                }
                field(messageToRecipient; "Message to Recipient")
                {
                    ApplicationArea = All;
                    Caption = 'Message to Recipient', Locked = true;
                }
                field(exportedToPaymentFile; "Exported to Payment File")
                {
                    ApplicationArea = All;
                    Caption = 'Exported to Payment File', Locked = true;
                }
                field(hasPaymentExportError; "Has Payment Export Error")
                {
                    ApplicationArea = All;
                    Caption = 'Has Payment Export Error', Locked = true;
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
                field(jobQuantity; "Job Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Job Quantity', Locked = true;
                }
                field(jobUnitCostLcy; "Job Unit Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Cost (LCY)', Locked = true;
                }
                field(jobLineDiscountPercent; "Job Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount %', Locked = true;
                }
                field(jobLineDiscAmountLcy; "Job Line Disc. Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Disc. Amount (LCY)', Locked = true;
                }
                field(jobUnitOfMeasureCode; "Job Unit Of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Of Measure Code', Locked = true;
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
                field(jobUnitCost; "Job Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Cost', Locked = true;
                }
                field(jobTotalCost; "Job Total Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Cost', Locked = true;
                }
                field(jobLineDiscountAmount; "Job Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount Amount', Locked = true;
                }
                field(jobLineAmount; "Job Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount', Locked = true;
                }
                field(jobTotalCostLcy; "Job Total Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Cost (LCY)', Locked = true;
                }
                field(jobLineAmountLcy; "Job Line Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount (LCY)', Locked = true;
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
                field(directDebitMandateId; "Direct Debit Mandate ID")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Debit Mandate ID', Locked = true;
                }
                field(dataExchEntryNumber; "Data Exch. Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Data Exch. Entry No.', Locked = true;
                }
                field(payerInformation; "Payer Information")
                {
                    ApplicationArea = All;
                    Caption = 'Payer Information', Locked = true;
                }
                field(transactionInformation; "Transaction Information")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Information', Locked = true;
                }
                field(dataExchLineNumber; "Data Exch. Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Data Exch. Line No.', Locked = true;
                }
                field(appliedAutomatically; "Applied Automatically")
                {
                    ApplicationArea = All;
                    Caption = 'Applied Automatically', Locked = true;
                }
                field(deferralCode; "Deferral Code")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Code', Locked = true;
                }
                field(deferralLineNumber; "Deferral Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Line No.', Locked = true;
                }
                field(campaignNumber; "Campaign No.")
                {
                    ApplicationArea = All;
                    Caption = 'Campaign No.', Locked = true;
                }
                field(prodOrderNumber; "Prod. Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Order No.', Locked = true;
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
                field(numberOfDepreciationDays; "No. of Depreciation Days")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Depreciation Days', Locked = true;
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
                field(faReclassificationEntry; "FA Reclassification Entry")
                {
                    ApplicationArea = All;
                    Caption = 'FA Reclassification Entry', Locked = true;
                }
                field(faErrorEntryNumber; "FA Error Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'FA Error Entry No.', Locked = true;
                }
                field(indexEntry; "Index Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Index Entry', Locked = true;
                }
                field(sourceLineNumber; "Source Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Source Line No.', Locked = true;
                }
                field(comment; Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(checkExported; "Check Exported")
                {
                    ApplicationArea = All;
                    Caption = 'Check Exported', Locked = true;
                }
                field(checkTransmitted; "Check Transmitted")
                {
                    ApplicationArea = All;
                    Caption = 'Check Transmitted', Locked = true;
                }
                field(id; GlobalSystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(accountId; "Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'Account Id', Locked = true;
                }
                field(customerId; "Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Id', Locked = true;
                }
                field(appliesToInvoiceId; "Applies-to Invoice Id")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Invoice Id', Locked = true;
                }
                field(contactGraphId; "Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'Contact Graph Id', Locked = true;
                }
                field(lastModifiedDatetime; "Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified DateTime', Locked = true;
                }
                field(journalBatchId; "Journal Batch Id")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Batch Id', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    var
        GlobalSystemId: Guid;

    trigger OnAfterGetRecord()
    begin
        GlobalSystemId := SystemId;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(GlobalSystemId);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // List type Page does not support exposing SystemId thus GlobalSystemId is used.
        if (not IsNullGuid(GlobalSystemId)) then begin
            SystemId := GlobalSystemId;
            Insert(true, true);
        end
        else begin
            Insert(true);
            GlobalSystemId := SystemId;
        end;

        // Record is inserted thus the table trigger is skipped.
        exit(false);
    end;
}

