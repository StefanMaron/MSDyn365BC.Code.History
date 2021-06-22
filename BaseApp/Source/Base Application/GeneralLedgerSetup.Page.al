page 118 "General Ledger Setup"
{
    AdditionalSearchTerms = 'finance setup,general ledger setup,g/l setup';
    ApplicationArea = Basic, Suite;
    Caption = 'General Ledger Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,General,Posting,VAT,Bank,Journal Templates';
    SourceTable = "General Ledger Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Allow Posting From"; "Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which posting to the company books is allowed.';
                }
                field("Allow Posting To"; "Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which posting to the company books is allowed.';
                }
                field("Register Time"; "Register Time")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to register users'' time usage defined as the time spent from when a user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded. This setting can be overruled per user by filling in the Register Time field in the User Setup window.';
                }
                field("Local Address Format"; "Local Address Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format in which addresses must appear on printouts.';
                }
                field("Local Cont. Addr. Format"; "Local Cont. Addr. Format")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
                }
                field("Inv. Rounding Precision (LCY)"; "Inv. Rounding Precision (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the size of the interval to be used when rounding invoice amounts in LCY. Examples: 1.00: Round to whole numbers (no decimals - divisible by 1.00), 0.05: Round to a number divisible by 0.05, 0.01: No rounding (ordinary currency decimals). On the Currencies page, you specify how to round invoices in foreign currencies.';
                }
                field("Inv. Rounding Type (LCY)"; "Inv. Rounding Type (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to round invoice amounts. The contents of this field determine whether the invoice amount to be rounded will be rounded up or down to the nearest interval as specified in the Invoice Rounding Precision field. If you select Nearest, digits that are higher than or equal to 5 will be rounded up, and digits that are lower than or equal to 5 will be rounded down.';
                }
                field(AmountRoundingPrecision; "Amount Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Rounding Precision (LCY)';
                    ToolTip = 'Specifies the size of the interval to be used when rounding amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. Amounts will be rounded to the nearest digit. Example: To have amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how amounts in foreign currencies are rounded.';
                }
                field(AmountDecimalPlaces; "Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount Decimal Places (LCY)';
                    ToolTip = 'Specifies the number of decimal places that are shown for amounts in LCY. This covers amounts created with all types of transactions and is useful to avoid inconsistencies when viewing or summing different amounts. The default setting, 2:2, specifies that all amounts in LCY are shown with a minimum of 2 decimal places and a maximum of 2 decimal places. You can also enter a fixed number, such as 2, which also means that amounts are shown with two decimals. On the Currencies page, you specify how many decimal places to show for amounts in foreign currencies.';
                }
                field(UnitAmountRoundingPrecision; "Unit-Amount Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Rounding Precision (LCY)';
                    ToolTip = 'Specifies the size of the interval to be used when rounding unit amounts, item or resource prices per unit, in LCY. Amounts will be rounded to the nearest digit. Example: To have unit amounts rounded to whole numbers, enter 1.00 in this field. In this case, amounts less than 0.5 will be rounded down and amounts greater than or equal to 0.5 will be rounded up. On the Currencies page, you specify how unit amounts in foreign currencies are rounded.';
                }
                field(UnitAmountDecimalPlaces; "Unit-Amount Decimal Places")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit-Amount Decimal Places (LCY)';
                    ToolTip = 'Specifies the number of decimal places that are shown for unit amounts, item or resource prices per unit, in LCY. The default setting, 2:5, specifies that unit amounts will be shown with a minimum of two decimal places and a maximum of five decimal places. You can also enter a fixed number, such as 2, to specify that all unit amounts are shown with two decimal places. On the Currencies page, you specify how many decimal places to show for unit amounts in foreign currencies.';
                }
                field("Allow G/L Acc. Deletion Before"; "Allow G/L Acc. Deletion Before")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if and when general ledger accounts can be deleted. If you enter a date, G/L accounts with entries on or after this date can be deleted only after confirmation by the user.';
                }
                field("Check G/L Account Usage"; "Check G/L Account Usage")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you want the program to protect G/L accounts that are used in setup tables from being deleted.';
                }
                field("EMU Currency"; "EMU Currency")
                {
                    ApplicationArea = BasicEU;
                    Importance = Additional;
                    ToolTip = 'Specifies if LCY is an EMU (Economic and Monetary Union) currency.';
                }
                field("LCY Code"; "LCY Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the local currency.';
                }
                field("Local Currency Symbol"; "Local Currency Symbol")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the symbol for the local currency that you want to appear on checks and charts, such as $ for USD.';
                }
                field("Local Currency Description"; "Local Currency Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the local currency.';
                }
                field("Pmt. Disc. Excl. VAT"; "Pmt. Disc. Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if the payment discount is calculated based on amounts including or excluding VAT.';
                }
                field("Adjust for Payment Disc."; "Adjust for Payment Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to recalculate tax amounts when you post payments that trigger payment discounts.';
                }
                field("Unrealized VAT"; "Unrealized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
                }
                field("Prepayment Unrealized VAT"; "Prepayment Unrealized VAT")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to handle unrealized VAT on prepayments.';
                }
                field("Max. VAT Difference Allowed"; "Max. VAT Difference Allowed")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the maximum VAT correction amount allowed for the local currency. For example, if you enter 5 in this field for British Pounds, then you can correct VAT amounts by up to five pounds.';
                }
                field("Tax Invoice Renaming Threshold"; "Tax Invoice Renaming Threshold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that if the amount on a sales invoice or a service invoice exceeds the threshold, then the name of the document is changed to include the words "Tax Invoice", as required by the tax authorities.';
                }
                field("VAT Rounding Type"; "VAT Rounding Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the program will round VAT when calculated for the local currency. When you enter an Amount Including VAT in a document, the system first calculates and rounds the Amount Excluding VAT, and then calculates by subtraction the VAT Amount because the total amount has to match the Amount Including VAT entered manually. In that case, the VAT Rounding Type does not apply as the Amount Excluding VAT is already rounded using the Amount Rounding Precision.';
                }
                field("Bank Account Nos."; "Bank Account Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bank accounts.';
                }
                field("Bill-to/Sell-to VAT Calc."; "Bill-to/Sell-to VAT Calc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies where the VAT Bus. Posting Group code on an order or invoice is copied from. Bill-to/Pay-to No.: The VAT Bus. Posting Group code on sales invoices and orders is copied from the Bill-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Pay-to Vendor field. Sell-to/Buy-from No. : The VAT Bus. Posting Group code on sales invoices and orders is copied from the Sell-to Customer field. The VAT Bus. Posting Group code on purchase invoices and orders is copied from the Buy-from Vendor field.';
                }
                field("Print VAT specification in LCY"; "Print VAT specification in LCY")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that an extra VAT specification in local currency will be included on documents in a foreign currency. This can be used to make tax audits easier when reconciling VAT payables to invoices.';
                }
                field("Use Legacy G/L Entry Locking"; "Use Legacy G/L Entry Locking")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the G/L Entry table should be locked during sales, purchase, and service posting to improve performance in multiuser environments. Consider this setting if: You encounter deadlock situations because your solution relies on G/L Entry table locking. You have selected the Automatic Cost Posting check box in the Inventory Setup window.';
                }
                field("Show Amounts"; "Show Amounts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies which type of amounts are shown in journals and in ledger entries windows. Amount Only: The Amount and Amount (LCY) fields are shown. Debit/Credit Only: The Debit Amount, Debit Amount (LCY), Credit Amount, and Credit Amount (LCY) fields are shown. All Amounts: All amount fields are shown. ';
                }
                field(SEPANonEuroExport; "SEPA Non-Euro Export")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to use SEPA export for journal lines with currencies different from Euro.';
                }
                field(SEPAExportWoBankAccData; "SEPA Export w/o Bank Acc. Data")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies if it is possible to use SEPA direct debit export by filling in the Bank Branch No. and Bank Account No. fields instead of the IBAN and SWIFT No. fields on the bank account and customer bank account cards.';
                }
            }
            group(Control1900309501)
            {
                Caption = 'Dimensions';
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for a global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 3 Code"; "Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 3, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 4 Code"; "Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 4, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 5 Code"; "Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 5, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 6 Code"; "Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 6, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 7 Code"; "Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 7, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
                field("Shortcut Dimension 8 Code"; "Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 8, whose dimension values you can then enter directly on journals and sales or purchase lines.';
                }
            }
            group("Background Posting")
            {
                Caption = 'Background Posting';
                field("Post with Job Queue"; "Post with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post general ledger documents in the background.';
                }
                field("Post & Print with Job Queue"; "Post & Print with Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you use job queues to post and print general ledger documents in the background.';
                }
                field("Job Queue Category Code"; "Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the category of the job queue that you want to associate with background posting.';
                }
                field("Notify On Success"; "Notify On Success")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a notification is sent when posting and printing is successfully completed.';
                }
                field("Report Output Type"; "Report Output Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the output of the report that will be scheduled with a job queue entry when the Post and Print with Job Queue check box is selected.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Acc. Sched. for Balance Sheet"; "Acc. Sched. for Balance Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which account schedule name that is used to generate the Balance Sheet report.';
                }
                field("Acc. Sched. for Income Stmt."; "Acc. Sched. for Income Stmt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which account schedule name that is used to generate the Income Statement report.';
                }
                field("Acc. Sched. for Cash Flow Stmt"; "Acc. Sched. for Cash Flow Stmt")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which account schedule name that is used to generate the Cash Flow Statement report.';
                }
                field("Acc. Sched. for Retained Earn."; "Acc. Sched. for Retained Earn.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which account schedule name that is used to generate the Retained Earnings report.';
                }
                field("Additional Reporting Currency"; "Additional Reporting Currency")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that will be used as an additional reporting currency.';

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        Confirmed: Boolean;
                    begin
                        if "Additional Reporting Currency" <> xRec."Additional Reporting Currency" then begin
                            if "Additional Reporting Currency" = '' then
                                Confirmed := ConfirmManagement.GetResponseOrDefault(Text002, true)
                            else
                                Confirmed := ConfirmManagement.GetResponseOrDefault(Text003, true);
                            if not Confirmed then
                                Error('');
                        end;
                    end;
                }
                field("VAT Exchange Rate Adjustment"; "VAT Exchange Rate Adjustment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the accounts set up for VAT posting in the VAT Posting Setup window will be adjusted for exchange rate fluctuations.';
                }
            }
            group(Application)
            {
                Caption = 'Application';
                field("Appln. Rounding Precision"; "Appln. Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rounding difference that will be allowed when you apply entries in LCY to entries in a different currency.';
                }
                field("Pmt. Disc. Tolerance Warning"; "Pmt. Disc. Tolerance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning will appear every time an application occurs between the dates specified in the Payment Discount Date field and the Pmt. Disc. Tolerance Date field in the General Ledger Setup window.';
                }
                field("Pmt. Disc. Tolerance Posting"; "Pmt. Disc. Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: The payment discount tolerance is posted to a special general ledger account set up for payment tolerance. Payment Discount Amount: The payment discount tolerance is posted as a payment discount.';
                }
                field("Payment Discount Grace Period"; "Payment Discount Grace Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of days that a payment or refund can pass the payment discount due date and still receive payment discount.';

                    trigger OnValidate()
                    var
                        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            PaymentToleranceMgt.CalcGracePeriodCVLedgEntry("Payment Discount Grace Period");
                    end;
                }
                field("Payment Tolerance Warning"; "Payment Tolerance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning will appear when an application has a balance within the tolerance specified in the Max. Payment Tolerance field in the General Ledger Setup window.';
                }
                field("Payment Tolerance Posting"; "Payment Tolerance Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting method that is used when posting a payment tolerance. Payment Tolerance Accounts: Posts the payment tolerance to a special general ledger account set up for payment tolerance. Payment Discount Amount: Posts the payment tolerance as a payment discount.';
                }
                field("Payment Tolerance %"; "Payment Tolerance %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage that a payment or refund is allowed to be less than the amount on the related invoice or credit memo.';
                }
                field("Max. Payment Tolerance Amount"; "Max. Payment Tolerance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum allowed amount that a payment or refund can differ from the amount on the related invoice or credit memo.';
                }
            }
            group("Payroll Transaction Import")
            {
                Caption = 'Payroll Transaction Import';
                Visible = false;
                field("Payroll Trans. Import Format"; "Payroll Trans. Import Format")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the format of the payroll transaction file that can be imported into the General Journal window.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ChangeGlobalDimensions)
                {
                    AccessByPermission = TableData Dimension = M;
                    ApplicationArea = Dimensions;
                    Caption = 'Change Global Dimensions';
                    Ellipsis = true;
                    Image = ChangeDimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Change Global Dimensions";
                    ToolTip = 'Change one or both of the global dimensions.';
                }
                action("Change Payment &Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Change Payment &Tolerance';
                    Image = ChangePaymentTolerance;
                    ToolTip = 'Change the maximum payment tolerance and/or the payment tolerance percentage.';

                    trigger OnAction()
                    var
                        Currency: Record Currency;
                        ChangePmtTol: Report "Change Payment Tolerance";
                    begin
                        Currency.Init;
                        ChangePmtTol.SetCurrency(Currency);
                        ChangePmtTol.RunModal;
                    end;
                }
            }
        }
        area(navigation)
        {
            action("Accounting Periods")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Accounting Periods';
                Image = AccountingPeriods;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Accounting Periods";
                ToolTip = 'Set up the number of accounting periods, such as 12 monthly periods, within the fiscal year and specify which period is the start of the new fiscal year.';
            }
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page Dimensions;
                ToolTip = 'Set up dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action("User Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Setup';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "User Setup";
                ToolTip = 'Set up users to restrict access to post to the general ledger.';
            }
            action("Cash Flow Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Cash Flow Setup';
                Image = CashFlowSetup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "Cash Flow Setup";
                ToolTip = 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
            }
            action("Bank Export/Import Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Export/Import Setup';
                Image = ImportExport;
                Promoted = true;
                PromotedCategory = Category7;
                PromotedIsBig = true;
                RunObject = Page "Bank Export/Import Setup";
                ToolTip = 'Set up the formats for exporting vendor payments and for importing bank statements.';
            }
            group("General Ledger Posting")
            {
                Caption = 'General Ledger Posting';
                action("General Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Posting Setup';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "General Posting Setup";
                    ToolTip = 'Set up combinations of general business and general product posting groups by specifying account numbers for posting of sales and purchase transactions.';
                }
                action("Gen. Business Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Business Posting Groups';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Gen. Business Posting Groups";
                    ToolTip = 'Set up the trade-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
                }
                action("Gen. Product Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gen. Product Posting Groups';
                    Image = GeneralPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Gen. Product Posting Groups";
                    ToolTip = 'Set up the item-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
                }
            }
            group("VAT Posting")
            {
                Caption = 'VAT Posting';
                action("VAT Posting Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Posting Setup';
                    Image = VATPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Posting Setup";
                    ToolTip = 'Set up how tax must be posted to the general ledger.';
                }
                action("VAT Business Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Business Posting Groups';
                    Image = VATPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Business Posting Groups";
                    ToolTip = 'Set up the trade-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action("VAT Product Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Product Posting Groups';
                    Image = VATPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Product Posting Groups";
                    ToolTip = 'Set up the item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
                }
                action("VAT Report Setup")
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Report Setup';
                    Image = VATPostingSetup;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Report Setup";
                    ToolTip = 'Set up number series and options for the report that you periodically send to the authorities to declare your VAT.';
                }
            }
            group("Bank Posting")
            {
                Caption = 'Bank Posting';
                action("Bank Account Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Posting Groups';
                    Image = BankAccount;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    RunObject = Page "Bank Account Posting Groups";
                    ToolTip = 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
                }
            }
            group("Journal Templates")
            {
                Caption = 'Journal Templates';
                action("General Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Templates';
                    Image = JournalSetup;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    RunObject = Page "General Journal Templates";
                    ToolTip = 'Set up templates for the journals that you use for bookkeeping tasks. Templates allow you to work in a journal window that is designed for a specific purpose.';
                }
                action("VAT Statement Templates")
                {
                    ApplicationArea = VAT;
                    Caption = 'VAT Statement Templates';
                    Image = VATStatement;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    RunObject = Page "VAT Statement Templates";
                    ToolTip = 'Set up the reports that you use to settle VAT and report to the customs and tax authorities.';
                }
                action("Intrastat Templates")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Intrastat Templates';
                    Image = Template;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    RunObject = Page "Intrastat Journal Templates";
                    ToolTip = 'Define how you want to set up and keep track of journals to report Intrastat.';
                }
            }
        }
    }

    trigger OnClosePage()
    var
        SessionSettings: SessionSettings;
    begin
        if IsShortcutDimensionModified then
            SessionSettings.RequestSessionUpdate(false);
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
        xGeneralLedgerSetup := Rec;
    end;

    var
        Text001: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';
        Text002: Label 'If you delete the additional reporting currency, future general ledger entries are posted in LCY only. Deleting the additional reporting currency does not affect already posted general ledger entries.\\Are you sure that you want to delete the additional reporting currency?';
        Text003: Label 'If you change the additional reporting currency, future general ledger entries are posted in the new reporting currency and in LCY. To enable the additional reporting currency, a batch job opens, and running the batch job recalculates already posted general ledger entries in the new additional reporting currency.\Entries will be deleted in the Analysis View if it is unblocked, and an update will be necessary.\\Are you sure that you want to change the additional reporting currency?';
        xGeneralLedgerSetup: Record "General Ledger Setup";

    local procedure IsShortcutDimensionModified(): Boolean
    begin
        exit(
          ("Shortcut Dimension 1 Code" <> xGeneralLedgerSetup."Shortcut Dimension 1 Code") or
          ("Shortcut Dimension 2 Code" <> xGeneralLedgerSetup."Shortcut Dimension 2 Code") or
          ("Shortcut Dimension 3 Code" <> xGeneralLedgerSetup."Shortcut Dimension 3 Code") or
          ("Shortcut Dimension 4 Code" <> xGeneralLedgerSetup."Shortcut Dimension 4 Code") or
          ("Shortcut Dimension 5 Code" <> xGeneralLedgerSetup."Shortcut Dimension 5 Code") or
          ("Shortcut Dimension 6 Code" <> xGeneralLedgerSetup."Shortcut Dimension 6 Code") or
          ("Shortcut Dimension 7 Code" <> xGeneralLedgerSetup."Shortcut Dimension 7 Code") or
          ("Shortcut Dimension 8 Code" <> xGeneralLedgerSetup."Shortcut Dimension 8 Code"));
    end;
}

