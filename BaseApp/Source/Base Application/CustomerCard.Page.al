page 21 "Customer Card"
{
    Caption = 'Customer Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,New Document,Approve,Request Approval,Prices & Discounts,Navigate,Customer';
    RefreshOnActivate = true;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the customer''s name. This name will appear on all sales documents for the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies an alternate name that you can use to search for a customer.';
                    Visible = false;
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s intercompany partner code.';
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                    trigger OnDrillDown()
                    begin
                        OpenCustomerLedgerEntries(false);
                    end;
                }
                field("Balance Due (LCY)"; "Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';

                    trigger OnDrillDown()
                    begin
                        OpenCustomerLedgerEntries(true);
                    end;
                }
                field("Credit Limit (LCY)"; "Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';

                    trigger OnValidate()
                    begin
                        SetCreditLimitStyle();
                    end;
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the responsibility center that will administer this customer by default.';
                }
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the service zone that is assigned to the customer.';
                }
                field("Document Sending Profile"; "Document Sending Profile")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the preferred method of sending documents to this customer, so that you do not have to select a sending option every time that you post and send a document to the customer. Sales documents to this customer will be sent using the specified sending profile and will override the default document sending profile.';
                }
                field(TotalSales2; Totals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Sales';
                    Style = Strong;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies your total sales turnover with the customer in the current fiscal year. It is calculated from amounts excluding VAT on all completed and open invoices and credit memos.';
                }
                field("CustSalesLCY - CustProfit - AdjmtCostLCY"; CustSalesLCY - CustProfit - AdjmtCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Costs (LCY)';
                    ToolTip = 'Specifies how much cost you have incurred from the customer in the current fiscal year.';
                }
                field(AdjCustProfit; AdjCustProfit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies how much profit you have made from the customer in the current fiscal year.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies how much profit you have made from the customer in the current fiscal year, expressed as a percentage of the customer''s total sales.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the customer card was last modified.';
                }
                field("Disable Search by Name"; "Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that you can change customer name in the document, because the name is not used in search.';
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(AddressDetails)
                {
                    Caption = 'Address';
                    field(Address; Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                        end;
                    }
                    field(City; City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s city.';
                    }
                    group(Control10)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the customer''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            DisplayMap;
                        end;
                    }
                }
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field("Primary Contact No."; "Primary Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact Code';
                        Importance = Additional;
                        ToolTip = 'Specifies the contact number for the customer.';
                    }
                    field(ContactName; Contact)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact Name';
                        Editable = ContactEditable;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';

                        trigger OnValidate()
                        begin
                            ContactOnAfterValidate;
                        end;
                    }
                    field("Phone No."; "Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s telephone number.';
                    }
                    field(MobilePhoneNo; "Mobile Phone No.")
                    {
                        Caption = 'Mobile Phone No.';
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the customer''s mobile telephone number.';
                    }
                    field("E-Mail"; "E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        ExtendedDatatype = EMail;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer''s email address.';
                    }
                    field("Fax No."; "Fax No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s fax number.';
                    }
                    field("Home Page"; "Home Page")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the customer''s home page address.';
                    }
                    field("Language Code"; "Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the language to be used on printouts for this customer.';
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill-to Customer';
                    Importance = Additional;
                    ToolTip = 'Specifies a different customer who will be invoiced for products that you sell to the customer in the Name field on the customer card.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the customer''s VAT registration number for customers in EU countries/regions.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditCustomerVATReg(Rec);
                    end;
                }
                field("EORI Number"; "EORI Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Economic Operators Registration and Identification number that is used when you exchange information with the customs authorities due to trade into or out of the European Union.';
                    Visible = false;
                }
                field(GLN; GLN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer in connection with electronic document sending.';
                }
                field("Use GLN in Electronic Document"; "Use GLN in Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the GLN is used in electronic documents as a party identification number.';
                }
                field("Copy Sell-to Addr. to Qte From"; "Copy Sell-to Addr. to Qte From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which customer address is inserted on sales quotes that you create for the customer.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field("Invoice Copies"; "Invoice Copies")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                    ToolTip = 'Specifies how many copies of an invoice for the customer will be printed at a time.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Functionality was used by reports 204-207 that are now obsolete';
                    ObsoleteTag = '16.0';
                }
                group(PostingDetails)
                {
                    Caption = 'Posting Details';
                    field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s trade type to link transactions made for this customer with the appropriate general ledger account according to the general posting setup.';
                    }
                    field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer to.';
                    }
                    field("Customer Posting Group"; "Customer Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                    }
                }
                group(PricesandDiscounts)
                {
                    Caption = 'Prices and Discounts';
                    field("Currency Code"; "Currency Code")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the default currency for the customer.';
                    }
                    field("Price Calculation Method"; "Price Calculation Method")
                    {
                        Visible = ExtendedPriceEnabled;
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the default price calculation method.';
                    }
                    field("Customer Price Group"; "Customer Price Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer price group code, which you can use to set up special sales prices in the Sales Prices window.';
                    }
                    field("Customer Disc. Group"; "Customer Disc. Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer discount group code, which you can use as a criterion to set up special discounts in the Sales Line Discounts window.';
                    }
                    field("Allow Line Disc."; "Allow Line Disc.")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies if a sales line discount is calculated when a special sales price is offered according to setup in the Sales Prices window.';
                    }
                    field("Invoice Disc. Code"; "Invoice Disc. Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        NotBlank = true;
                        ToolTip = 'Specifies a code for the invoice discount terms that you have defined for the customer.';
                    }
                    field("Prices Including VAT"; "Prices Including VAT")
                    {
                        ApplicationArea = VAT;
                        Importance = Additional;
                        ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Prepayment %"; "Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    ToolTip = 'Specifies a prepayment percentage that applies to all orders for this customer, regardless of the items or services on the order lines.';
                }
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to apply payments to entries for this customer.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies for direct debit collections if the customer that the payment is collected from is a person or a company.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code that indicates the payment terms that you require of the customer.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how the customer usually submits payment, such as bank transfer or check.';
                }
                field("Reminder Terms Code"; "Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
                }
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies finance charges are calculated for the customer.';
                }
                field("Cash Flow Payment Terms Code"; "Cash Flow Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies a payment term that will be used to calculate cash flow for the customer.';
                }
                field("Print Statements"; "Print Statements")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to include this customer when you print the Statement report.';
                }
                field("Last Statement No."; "Last Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the last statement that was printed for this customer.';
                }
                field("Block Payment Tolerance"; "Block Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the customer is not allowed a payment tolerance.';
                }
                field("Preferred Bank Account Code"; "Preferred Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s bank account that will be used by default when you process refunds to the customer and direct debit collections.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for another shipment address than the customer''s own address, which is entered by default.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies from which location sales to this customer will be processed by default.';
                }
                field("Combine Shipments"; "Combine Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if several orders delivered to the customer can appear on the same sales invoice.';
                }
                field(Reserve; Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies whether items will never, automatically (Always), or optionally be reserved for this customer.';
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the customer accepts partial shipment of orders.';
                }
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipment Method Code"; "Shipment Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Code';
                        Importance = Promoted;
                        ToolTip = 'Specifies which shipment method to use when you ship items to the customer.';
                    }
                    field("Shipping Agent Code"; "Shipping Agent Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent';
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping company is used when you ship items to the customer.';
                    }
                    field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent Service';
                        Importance = Additional;
                        ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                    }
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies a customizable calendar for shipment planning that holds the customer''s working days and holidays.';
                }
                field("Customized Calendar"; format(HasCustomBaseCalendar))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customized Calendar';
                    Editable = false;
                    ToolTip = 'Specifies that you have set up a customized version of a base calendar.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord;
                        TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                Editable = false;
                Visible = FoundationOnly;
                group(Balance)
                {
                    Caption = 'Balance';
                    field("Balance (LCY)2"; "Balance (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Money Owed - Current';
                        ToolTip = 'Specifies the payment amount that the customer owes for completed sales. This value is also known as the customer''s balance.';

                        trigger OnDrillDown()
                        begin
                            OpenCustomerLedgerEntries(false);
                        end;
                    }
                    field(ExpectedCustMoneyOwed; ExpectedMoneyOwed)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Money Owed - Expected';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the payment amount that the customer will owe when ongoing sales invoices and credit memos are completed. The value is calculated asynchronously so there might be a delay in updating this field.';

                        trigger OnDrillDown()
                        begin
                            CustomerMgt.DrillDownMoneyOwedExpected("No.");
                        end;
                    }
                    field(TotalMoneyOwed; TotalMoneyOwed)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Money Owed - Total';
                        Style = Strong;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the payment amount that the customer owes for completed sales plus sales that are still ongoing. The value is calculated asynchronously so there might be a delay in updating this field.';
                    }
                    field(CreditLimit; "Credit Limit (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Credit Limit';
                        ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
                    }
                    field(CalcCreditLimitLCYExpendedPct; CalcCreditLimitLCYExpendedPct)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Usage Of Credit Limit';
                        ExtendedDatatype = Ratio;
                        Style = Attention;
                        StyleExpr = BalanceExhausted;
                        ToolTip = 'Specifies how much of the customer''s payment balance consists of credit.';
                    }
                }
                group(Control108)
                {
                    Caption = 'Payments';
                    field("Balance Due"; OverdueBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(StrSubstNo(OverduePaymentsMsg, Format(WorkDate)));
                        ToolTip = 'Specifies the sum of outstanding payments from the customer.';

                        trigger OnDrillDown()
                        var
                            DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                            CustLedgEntry: Record "Cust. Ledger Entry";
                        begin
                            DtldCustLedgEntry.SetRange("Customer No.", "No.");
                            CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                            CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                            CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                            CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                        end;
                    }
                    field("Payments (LCY)"; "Payments (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payments This Year';
                        ToolTip = 'Specifies the sum of payments received from the customer in the current fiscal year.';
                    }
                    field("CustomerMgt.AvgDaysToPay(""No."")"; AvgDaysToPay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Average Collection Period (Days)';
                        DecimalPlaces = 0 : 1;
                        Importance = Additional;
                        ToolTip = 'Specifies how long the customer typically takes to pay invoices in the current fiscal year. The value is calculated asynchronously so there might be a delay in updating this field.';
                    }
                    field(DaysPaidPastDueDate; DaysPastDueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Average Late Payments (Days)';
                        DecimalPlaces = 0 : 1;
                        Importance = Additional;
                        Style = Attention;
                        StyleExpr = AttentionToPaidDay;
                        ToolTip = 'Specifies the average number of days the customer is late with payments. The value is calculated asynchronously so there might be a delay in updating this field.';
                    }
                }
                group("Sales This Year")
                {
                    Caption = 'Sales This Year';
                    field(AmountOnPostedInvoices; AmountOnPostedInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = StrSubstNo(PostedInvoicesMsg, Format(NoPostedInvoices));
                        ToolTip = 'Specifies your sales to the customer in the current fiscal year based on posted sales invoices. The figure in parenthesis Specifies the number of posted sales invoices.';

                        trigger OnDrillDown()
                        begin
                            CustomerMgt.DrillDownOnPostedInvoices("No.")
                        end;
                    }
                    field(AmountOnCrMemo; AmountOnPostedCrMemos)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = StrSubstNo(CreditMemosMsg, Format(NoPostedCrMemos));
                        ToolTip = 'Specifies your expected refunds to the customer in the current fiscal year based on posted sales credit memos. The figure in parenthesis shows the number of posted sales credit memos.';

                        trigger OnDrillDown()
                        begin
                            CustomerMgt.DrillDownOnPostedCrMemo("No.")
                        end;
                    }
                    field(AmountOnOutstandingInvoices; AmountOnOutstandingInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = StrSubstNo(OutstandingInvoicesMsg, Format(NoOutstandingInvoices));
                        ToolTip = 'Specifies your expected sales to the customer in the current fiscal year based on ongoing sales invoices. The figure in parenthesis shows the number of ongoing sales invoices.';

                        trigger OnDrillDown()
                        begin
                            CustomerMgt.DrillDownOnUnpostedInvoices("No.")
                        end;
                    }
                    field(AmountOnOutstandingCrMemos; AmountOnOutstandingCrMemos)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = StrSubstNo(OutstandingCrMemosMsg, Format(NoOutstandingCrMemos));
                        ToolTip = 'Specifies your refunds to the customer in the current fiscal year based on ongoing sales credit memos. The figure in parenthesis shows the number of ongoing sales credit memos.';

                        trigger OnDrillDown()
                        begin
                            CustomerMgt.DrillDownOnUnpostedCrMemos("No.")
                        end;
                    }
                    field(Totals; Totals)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Sales';
                        Style = Strong;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies your total sales turnover with the customer in the current fiscal year. It is calculated from amounts excluding VAT on all completed and open invoices and credit memos.';
                    }
                    field(CustInvDiscAmountLCY; CustInvDiscAmountLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invoice Discounts';
                        ToolTip = 'Specifies the total of all invoice discounts that you have granted to the customer in the current fiscal year.';
                    }
                }
                part(AgedAccReceivableChart; "Aged Acc. Receivable Chart")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "No." = FIELD("No.");
                }
            }
            part(PriceAndLineDisc; "Sales Pr. & Line Disc. Part")
            {
                ApplicationArea = All;
                Caption = 'Special Prices & Discounts';
                Visible = FoundationOnly and (not LoadOnDemand) and (not ExtendedPriceEnabled);
                SubPageLink = "Sales Code" = FIELD("No."),
                              "Sales Type" = CONST(Customer);
                ObsoleteState = Pending;
                ObsoleteReason = 'This part impairs performance.';
                ObsoleteTag = '16.0';
            }
        }
        area(factboxes)
        {
            part(Control149; "Customer Picture")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = NOT IsOfficeAddin;
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(18),
                              "No." = FIELD("No.");
                Visible = NOT IsOfficeAddin;
            }
            part(Details; "Office Customer Details")
            {
                ApplicationArea = All;
                Caption = 'Details';
                SubPageLink = "No." = FIELD("No.");
                Visible = IsOfficeAddin;
            }
            part(AgedAccReceivableChart2; "Aged Acc. Receivable Chart")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("No.");
                Visible = IsOfficeAddin;
            }
            part(Control39; "CRM Statistics FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("No.");
                Visible = CRMIsCoupledToRecord;
            }
            part(Control35; "Social Listening FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Customer),
                              "Source No." = FIELD("No.");
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
                ObsoleteTag = '17.0';
            }
            part(Control27; "Social Listening Setup FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Customer),
                              "Source No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Microsoft Social Engagement has been discontinued.';
                ObsoleteTag = '17.0';
            }
            part(SalesHistSelltoFactBox; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
            }
            part(SalesHistBilltoFactBox; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                Visible = false;
            }
            part(CustomerStatisticsFactBox; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
            }
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Table ID" = CONST(18),
                              "No." = FIELD("No.");
            }
            part(Control1907829707; "Service Hist. Sell-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                Visible = false;
            }
            part(Control1902613707; "Service Hist. Bill-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                Visible = false;
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
        area(navigation)
        {
            group("&Customer")
            {
                Caption = '&Customer';
                Image = Customer;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(18),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Customer Bank Account List";
                    RunPageLink = "Customer No." = FIELD("No.");
                    ToolTip = 'View or set up the customer''s bank accounts. You can set up any number of bank accounts for each customer.';
                }
                action("Direct Debit Mandates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Direct Debit Mandates';
                    Image = MakeAgreement;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "SEPA Direct Debit Mandates";
                    RunPageLink = "Customer No." = FIELD("No.");
                    ToolTip = 'View the direct-debit mandates that reflect agreements with customers to collect invoice payments from their bank account.';
                }
                action(ShipToAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-&to Addresses';
                    Image = ShipAddress;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Ship-to Address List";
                    RunPageLink = "Customer No." = FIELD("No.");
                    ToolTip = 'View or edit alternate shipping addresses where the customer wants items delivered if different from the regular address.';
                }
                action(Contact)
                {
                    AccessByPermission = TableData Contact = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Category8;
                    ToolTip = 'View or edit detailed information about the contact person at the customer.';

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
                action("Cross Re&ferences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cross Re&ferences';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Cross References";
                    RunPageLink = "Cross-Reference Type" = CONST(Customer),
                                  "Cross-Reference Type No." = FIELD("No.");
                    RunPageView = SORTING("Cross-Reference Type", "Cross-Reference Type No.");
                    ToolTip = 'Set up the customer''s own identification of items that you sell to the customer. Cross-references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("Item References")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item References';
                    Visible = ItemReferenceVisible;
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Item References";
                    RunPageLink = "Reference Type" = CONST(Customer),
                                  "Reference Type No." = FIELD("No.");
                    RunPageView = SORTING("Reference Type", "Reference Type No.");
                    ToolTip = 'Set up the customer''s own identification of items that you sell to the customer. Item references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Customer),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category9;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category9;
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
                action(CustomerReportSelections)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Layouts';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Category8;
                    ToolTip = 'Set up a layout for different types of documents such as invoices, quotes, and credit memos.';

                    trigger OnAction()
                    var
                        CustomReportSelection: Record "Custom Report Selection";
                    begin
                        CustomReportSelection.SetRange("Source Type", DATABASE::Customer);
                        CustomReportSelection.SetRange("Source No.", "No.");
                        PAGE.RunModal(PAGE::"Customer Report Selections", CustomReportSelection);
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dataverse';
                Enabled = (BlockedFilterApplied and (Blocked = Blocked::" ")) or not BlockedFilterApplied;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                action(CRMGotoAccount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Account';
                    Image = CoupledCustomer;
                    ToolTip = 'Open the coupled Dataverse account.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

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
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Send or get updated data to or from Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(RecordId);
                    end;
                }
                action(UpdateStatisticsInCRM)
                {
                    ApplicationArea = Suite;
                    Caption = 'Update Account Statistics';
                    Enabled = CRMIsCoupledToRecord;
                    Image = UpdateXML;
                    ToolTip = 'Send customer statistics data to Dataverse to update the Account Statistics FactBox.';
                    Visible = CRMIntegrationEnabled;

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.CreateOrUpdateCRMAccountStatistics(Rec);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse row.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        Promoted = true;
                        PromotedCategory = Category9;
                        ToolTip = 'Create or modify the coupling to a Dataverse account.';
                        Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

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
                        ToolTip = 'Delete the coupling to a Dataverse account.';
                        Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

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
                    ToolTip = 'View integration synchronization jobs for the customer table.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    RunObject = Page "Customer Ledger Entries";
                    RunPageLink = "Customer No." = FIELD("No.");
                    RunPageView = SORTING("Customer No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action(Action76)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("S&ales")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'S&ales';
                    Image = Sales;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Customer Sales";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'View a summary of customer ledger entries. You select the time interval in the View by field. The Period column on the left contains a series of dates that are determined by the time interval you have selected.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Customer Entry Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'View entry statistics for the record.';
                }
                action("Statistics by C&urrencies")
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics by C&urrencies';
                    Image = Currencies;
                    RunObject = Page "Cust. Stats. by Curr. Lines";
                    RunPageLink = "Customer Filter" = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Date Filter" = FIELD("Date Filter");
                    ToolTip = 'View statistics for customers that use multiple currencies.';
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
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(1, "No.", '', '', '');
                    end;
                }
                separator(Action140)
                {
                }
            }
            group("Prices and Discounts")
            {
                Caption = 'Prices and Discounts';
                action("Invoice &Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice &Discounts';
                    Image = CalculateInvoiceDiscount;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category7;
                    RunObject = Page "Cust. Invoice Discounts";
                    RunPageLink = Code = FIELD("Invoice Disc. Code");
                    ToolTip = 'Set up different discounts that are applied to invoices for the customer. An invoice discount is automatically granted to the customer when the total on a sales invoice exceeds a certain amount.';
                }
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category8;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, "Price Amount Type"::Any);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action PriceLists shows all sales price lists with prices and discounts';
                    ObsoleteTag = '18.0';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, AmountType::Discount);
                    end;
                }
                action(Prices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category7;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or set up different prices for items that you sell to the customer. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesPrice: Record "Sales Price";
                    begin
                        SalesPrice.SetCurrentKey("Sales Type", "Sales Code");
                        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
                        SalesPrice.SetRange("Sales Code", "No.");
                        Page.Run(Page::"Sales Prices", SalesPrice);
                    end;
                }
                action("Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category7;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for items that you sell to the customer. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code");
                        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Customer);
                        SalesLineDiscount.SetRange("Sales Code", "No.");
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action("Prices and Discounts Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    Promoted = true;
                    PromotedCategory = Category7;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View all the sales prices and line discounts that you grant for this customer when certain criteria are met, such as quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        SalesPriceAndLineDiscounts.InitPage(false);
                        SalesPriceAndLineDiscounts.LoadCustomer(Rec);
                        SalesPriceAndLineDiscounts.RunModal;
                    end;
                }
            }
            group(Action82)
            {
                Caption = 'S&ales';
                Image = Sales;
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Sales Prepayment Percentages";
                    RunPageLink = "Sales Type" = CONST(Customer),
                                  "Sales Code" = FIELD("No.");
                    RunPageView = SORTING("Sales Type", "Sales Code");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action("Recurring Sales Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring Sales Lines';
                    Ellipsis = true;
                    Image = CustomerCode;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category5;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Standard Customer Sales Codes";
                    RunPageLink = "Customer No." = FIELD("No.");
                    ToolTip = 'Set up recurring sales lines for the customer, such as a monthly replenishment order, that can quickly be inserted on a sales document for the customer.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action(Quotes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Quotes";
                    RunPageLink = "Sell-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Customer No.");
                    ToolTip = 'View a list of ongoing sales quotes for the customer.';
                }
                action(Invoices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    Image = Invoice;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Invoice List";
                    RunPageLink = "Sell-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Customer No.");
                    ToolTip = 'View a list of ongoing sales invoices for the customer.';
                }
                action(Orders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Order List";
                    RunPageLink = "Sell-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Customer No.");
                    ToolTip = 'View a list of ongoing sales orders for the customer.';
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Sales Return Order List";
                    RunPageLink = "Sell-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Customer No.");
                    ToolTip = 'Open the list of ongoing return orders.';
                }
                group("Issued Documents")
                {
                    Caption = 'Issued Documents';
                    Image = Documents;
                    action("Issued &Reminders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued &Reminders';
                        Image = OrderReminder;
                        RunObject = Page "Issued Reminder List";
                        RunPageLink = "Customer No." = FIELD("No.");
                        RunPageView = SORTING("Customer No.", "Posting Date");
                        ToolTip = 'View the reminders that you have sent to the customer.';
                    }
                    action("Issued &Finance Charge Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Issued &Finance Charge Memos';
                        Image = FinChargeMemo;
                        RunObject = Page "Issued Fin. Charge Memo List";
                        RunPageLink = "Customer No." = FIELD("No.");
                        RunPageView = SORTING("Customer No.", "Posting Date");
                        ToolTip = 'View the finance charge memos that you have sent to the customer.';
                    }
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Sales Orders";
                    RunPageLink = "Sell-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Sell-to Customer No.");
                    ToolTip = 'Open the list of ongoing blanket orders.';
                }
                action("&Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Jobs';
                    Image = Job;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Job List";
                    RunPageLink = "Bill-to Customer No." = FIELD("No.");
                    RunPageView = SORTING("Bill-to Customer No.");
                    ToolTip = 'Open the list of ongoing jobs.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceItem;
                action("Service Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    Image = Document;
                    RunObject = Page "Service Orders";
                    RunPageLink = "Customer No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Customer No.");
                    ToolTip = 'Open the list of ongoing service orders.';
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Customer Service Contracts";
                    RunPageLink = "Customer No." = FIELD("No.");
                    RunPageView = SORTING("Customer No.", "Ship-to Code");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
                action("Service &Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Items';
                    Image = ServiceItem;
                    RunObject = Page "Service Items";
                    RunPageLink = "Customer No." = FIELD("No.");
                    RunPageView = SORTING("Customer No.", "Ship-to Code", "Item No.", "Serial No.");
                    ToolTip = 'View or edit the service items that are registered for the customer.';
                }
            }
        }
        area(creation)
        {
            action(NewBlanketSalesOrder)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Suite;
                Caption = 'Blanket Sales Order';
                Image = BlanketOrder;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Blanket Sales Order";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a blanket sales order for the customer.';
            }
            action(NewSalesQuote)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Quote';
                Image = NewSalesQuote;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Sales Quote";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Offer items or services to a customer.';
                Visible = NOT IsOfficeAddin;
            }
            action(NewSalesInvoice)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoice';
                Image = NewSalesInvoice;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Sales Invoice";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a sales invoice for the customer.';
                Visible = NOT IsOfficeAddin;
            }
            action(NewSalesOrder)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Order';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Sales Order";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a sales order for the customer.';
                Visible = NOT IsOfficeAddin;
            }
            action(NewSalesCreditMemo)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Credit Memo';
                Image = CreditMemo;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Sales Credit Memo";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
                Visible = NOT IsOfficeAddin;
            }
            action(NewSalesQuoteAddin)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Quote';
                Image = NewSalesQuote;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Offer items or services to a customer.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    CreateAndShowNewQuote;
                end;
            }
            action(NewSalesInvoiceAddin)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Invoice';
                Image = NewSalesInvoice;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Create a sales invoice for the customer.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    CreateAndShowNewInvoice;
                end;
            }
            action(NewSalesOrderAddin)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Order';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Create a sales order for the customer.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    CreateAndShowNewOrder;
                end;
            }
            action(NewSalesCreditMemoAddin)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Credit Memo';
                Image = CreditMemo;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    CreateAndShowNewCreditMemo;
                end;
            }
            action(NewSalesReturnOrder)
            {
                AccessByPermission = TableData "Sales Header" = RIM;
                ApplicationArea = SalesReturnOrder;
                Caption = 'Sales Return Order';
                Image = ReturnOrder;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Sales Return Order";
                RunPageLink = "Sell-to Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new sales return order for items or services.';
            }
            action(NewServiceQuote)
            {
                AccessByPermission = TableData "Service Header" = RIM;
                ApplicationArea = Service;
                Caption = 'Service Quote';
                Image = Quote;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Service Quote";
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new service quote for the customer.';
            }
            action(NewServiceInvoice)
            {
                AccessByPermission = TableData "Service Header" = RIM;
                ApplicationArea = Service;
                Caption = 'Service Invoice';
                Image = Invoice;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Service Invoice";
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new service invoice for the customer.';
            }
            action(NewServiceOrder)
            {
                AccessByPermission = TableData "Service Header" = RIM;
                ApplicationArea = Service;
                Caption = 'Service Order';
                Image = Document;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Service Order";
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new service order for the customer.';
            }
            action(NewServiceCreditMemo)
            {
                AccessByPermission = TableData "Service Header" = RIM;
                ApplicationArea = Service;
                Caption = 'Service Credit Memo';
                Image = CreditMemo;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Service Credit Memo";
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new service credit memo for the customer.';
            }
            action(NewReminder)
            {
                AccessByPermission = TableData "Reminder Header" = RIM;
                ApplicationArea = Suite;
                Caption = 'Reminder';
                Image = Reminder;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page Reminder;
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new reminder for the customer.';
            }
            action(NewFinanceChargeMemo)
            {
                AccessByPermission = TableData "Finance Charge Memo Header" = RIM;
                ApplicationArea = Suite;
                Caption = 'Finance Charge Memo';
                Image = FinChargeMemo;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category4;
                RunObject = Page "Finance Charge Memo";
                RunPageLink = "Customer No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new finance charge memo.';
            }
        }
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                Visible = OpenApprovalEntriesExistCurrUser;
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    PromotedCategory = Category5;
                    PromotedOnly = true;
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
                    PromotedCategory = Category5;
                    PromotedOnly = true;
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
            group("Request Approval")
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
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckCustomerApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendCustomerForApproval(Rec);
                        SetWorkFlowEnabled();
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelCustomerApprovalRequest(Rec);
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
                        PromotedCategory = Category6;
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS;

                        trigger OnAction()
                        var
                            FlowServiceManagement: Codeunit "Flow Service Management";
                            FlowTemplateSelector: Page "Flow Template Selector";
                        begin
                            // Opens page 6400 where the user can use filtered templates to create new flows.
                            FlowTemplateSelector.SetSearchText(FlowServiceManagement.GetCustomerTemplateFilter);
                            FlowTemplateSelector.Run;
                        end;
                    }
                    action(SeeFlows)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'See my Flows';
                        Image = Flow;
                        Promoted = true;
                        PromotedCategory = Category6;
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
                    ToolTip = 'Set up an approval workflow for creating or changing customers, by going through a few pages that will guide you.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Cust. Approval WF Setup Wizard");
                        SetWorkFlowEnabled();
                    end;
                }
                action(ManageApprovalWorkflows)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manage Approval Workflows';
                    Enabled = EnabledApprovalWorkflowsExist;
                    Image = WorkflowSetup;
                    ToolTip = 'View or edit existing approval workflows for creating or changing customers.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        WorkflowManagement.NavigateToWorkflows(DATABASE::Customer, WorkFlowEventFilter);
                        SetWorkFlowEnabled();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Templates)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Templates';
                    Image = Template;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'View or edit customer templates.';

                    trigger OnAction()
                    var
                        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
                    begin
                        CustomerTemplMgt.ShowTemplates();
                    end;
                }
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Ellipsis = true;
                    Image = ApplyTemplate;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality will be replaced by other templates.';
                    ObsoleteTag = '16.0';

                    trigger OnAction()
                    var
                        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
                    begin
                        CustomerTemplMgt.UpdateCustomerFromTemplate(Rec);
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Ellipsis = true;
                    Image = Save;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'Save the customer card as a template that can be reused to create new customer cards. Customer templates contain preset information to help you fill fields on customer cards.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This functionality will be replaced by other templates.';
                    ObsoleteTag = '16.0';

                    trigger OnAction()
                    var
                        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
                    begin
                        CustomerTemplMgt.SaveAsTemplate(Rec);
                    end;
                }
                action(MergeDuplicate)
                {
                    AccessByPermission = TableData "Merge Duplicates Buffer" = RIMD;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Merge With';
                    Ellipsis = true;
                    Image = ItemSubstitution;
                    ToolTip = 'Merge two customer records into one. Before merging, review which field values you want to keep or override. The merge action cannot be undone.';

                    trigger OnAction()
                    var
                        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
                    begin
                        TempMergeDuplicatesBuffer.Show(DATABASE::Customer, "No.");
                    end;
                }
            }
            action("Post Cash Receipts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Cash Receipts';
                Ellipsis = true;
                Image = CashReceiptJournal;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Create a cash receipt journal line for the customer, for example, to post a payment receipt.';
            }
            action("Sales Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Journal';
                Image = Journals;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Sales Journal";
                ToolTip = 'Post any sales transaction for the customer.';
            }
            action(PaymentRegistration)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Register Customer Payments';
                Image = Payment;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Payment Registration";
                RunPageLink = "Source No." = FIELD("No.");
                ToolTip = 'Process your customer payments by matching amounts received on your bank account with the related unpaid sales invoices, and then post the payments.';
            }
        }
        area(reporting)
        {
            action("Report Customer Detailed Aging")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer Detailed Aging';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'View a detailed list of each customer''s total payments due, divided into three time periods. The report can be used to decide when to issue reminders, to evaluate a customer''s creditworthiness, or to prepare liquidity analyses.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Customer Detailed Aging", "No.");
                end;
            }
            action("Report Customer - Labels")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Labels';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category9;
                ToolTip = 'View mailing labels with the customers'' names and addresses.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Customer - Labels", "No.");
                end;
            }
            action("Report Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category9;
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Customer - Balance to Date", "No.");
                end;
            }
            action("Report Statement")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statement';
                Image = "Report";
                Promoted = true;
                PromotedCategory = Category8;
                ToolTip = 'View a list of a customer''s transactions for a selected period, for example, to send to the customer at the close of an accounting period. You can choose to have all overdue balances displayed regardless of the period specified, or you can choose to include an aging band.';

                trigger OnAction()
                var
                    ReportSelections: Record "Report Selections";
                    Customer: Record Customer;
                    CustomLayoutReporting: Codeunit "Custom Layout Reporting";
                    RecRef: RecordRef;
                begin
                    RecRef.Open(DATABASE::Customer);
                    CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
                    CustomLayoutReporting.SetTableFilterForReportID(Report::"Standard Statement", "No.");
                    CustomLayoutReporting.ProcessReportData(ReportSelections.Usage::"C.Statement", RecRef, Customer.FieldName("No."),
                      DATABASE::Customer, Customer.FieldName("No."), true);
                end;
            }
            action(BackgroundStatement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Scheduled Statements';
                Image = "Report";
                Promoted = true;
                PromotedCategory = Category8;
                ToolTip = 'Schedule Customer Statements in the Job Queue.';

                trigger OnAction()
                var
                    CustomerLayoutStatement: Codeunit "Customer Layout - Statement";
                begin
                    CustomerLayoutStatement.EnqueueReport;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        if NewMode then
            CreateCustomerFromTemplate
        else
            if FoundationOnly then
                StartBackgroundCalculations();
        ActivateFields;
        SetCreditLimitStyle();

        if CRMIntegrationEnabled or CDSIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
            if "No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
        if AnyWorkflowExists then begin
            CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);
            WorkflowStepInstance.SetRange("Record ID", RecordId);
            ShowWorkflowStatus := not WorkflowStepInstance.IsEmpty();
            if ShowWorkflowStatus then
                CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(RecordId);
            OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
            if OpenApprovalEntriesExist then
                OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecordId)
            else
                OpenApprovalEntriesExistCurrUser := false;
        end;
    end;

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        PrevCountryCode := '*';
        FoundationOnly := ApplicationAreaMgmtFacade.IsFoundationEnabled;

        ContactEditable := true;

        OpenApprovalEntriesExistCurrUser := true;

        CaptionTxt := CurrPage.Caption;
        SetCaption(CaptionTxt);
        CurrPage.Caption(CaptionTxt);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if "No." = '' then
                if DocumentNoVisibility.CustomerNoSeriesIsDefault then
                    NewMode := true;
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        EnvironmentInfo: Codeunit "Environment Information";
        ItemReferenceMgt: Codeunit "Item Reference Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        OfficeManagement: Codeunit "Office Management";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if CRMIntegrationEnabled or CDSIntegrationEnabled then
            if IntegrationTableMapping.Get('CUSTOMER') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field39=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();

        OnBeforeGetSalesPricesAndSalesLineDisc(LoadOnDemand);
        SetNoFieldVisible();

        IsSaaS := EnvironmentInfo.IsSaaS();
        IsOfficeAddin := OfficeManagement.IsAvailable;
        ItemReferenceVisible := ItemReferenceMgt.IsEnabled();
        WorkFlowEventFilter :=
            WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode + '|' +
            WorkflowEventHandling.RunWorkflowOnCustomerChangedCode;
        SetWorkFlowEnabled();
        OnAfterOnOpenPage(Rec, xRec);
    end;

    local procedure StartBackgroundCalculations()
    var
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        Args: Dictionary of [Text, Text];
    begin
        if (BackgroundTaskId <> 0) then
            CurrPage.CancelBackgroundTask(BackgroundTaskId);

        DaysPastDueDate := 0;
        ExpectedMoneyOwed := 0;
        AvgDaysToPay := 0;
        TotalMoneyOwed := 0;
        AttentionToPaidDay := false;
        AmountOnPostedInvoices := 0;
        AmountOnPostedCrMemos := 0;
        AmountOnOutstandingInvoices := 0;
        AmountOnOutstandingCrMemos := 0;
        Totals := 0;
        AdjmtCostLCY := 0;
        AdjCustProfit := 0;
        AdjProfitPct := 0;
        CustInvDiscAmountLCY := 0;
        CustPaymentsLCY := 0;
        CustSalesLCY := 0;
        CustProfit := 0;
        NoPostedInvoices := 0;
        NoPostedCrMemos := 0;
        NoOutstandingInvoices := 0;
        NoOutstandingCrMemos := 0;
        OverdueBalance := 0;

        Args.Add(CustomerCardCalculations.GetCustomerNoLabel(), "No.");
        Args.Add(CustomerCardCalculations.GetFiltersLabel(), GetView());
        Args.Add(CustomerCardCalculations.GetWorkDateLabel(), Format(WorkDate()));

        CurrPage.EnqueueBackgroundTask(BackgroundTaskId, Codeunit::"Customer Card Calculations", Args);

        Session.LogMessage('0000D4Q', StrSubstNo(PageBckGrndTaskStartedTxt, "No."), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CustomerCardServiceCategoryTxt);
    end;


    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CustomerCardCalculations: Codeunit "Customer Card Calculations";
        DictionaryValue: Text;
    begin
        if (TaskId = BackgroundTaskId) then begin
            if Results.Count() = 0 then
                exit;

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAvgDaysPastDueDateLabel(), DictionaryValue) then
                Evaluate(DaysPastDueDate, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetExpectedMoneyOwedLabel(), DictionaryValue) then
                Evaluate(ExpectedMoneyOwed, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAvgDaysToPayLabel(), DictionaryValue) then
                Evaluate(AvgDaysToPay, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAmountOnPostedInvoicesLabel(), DictionaryValue) then
                Evaluate(AmountOnPostedInvoices, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAmountOnPostedCrMemosLabel(), DictionaryValue) then
                Evaluate(AmountOnPostedCrMemos, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAmountOnOutstandingInvoicesLabel(), DictionaryValue) then
                Evaluate(AmountOnOutstandingInvoices, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAmountOnOutstandingCrMemosLabel(), DictionaryValue) then
                Evaluate(AmountOnOutstandingCrMemos, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetTotalsLabel(), DictionaryValue) then
                Evaluate(Totals, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAdjmtCostLCYLabel(), DictionaryValue) then
                Evaluate(AdjmtCostLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAdjCustProfitLabel(), DictionaryValue) then
                Evaluate(AdjCustProfit, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetAdjProfitPctLabel(), DictionaryValue) then
                Evaluate(AdjProfitPct, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetCustInvDiscAmountLCYLabel(), DictionaryValue) then
                Evaluate(CustInvDiscAmountLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetCustPaymentsLCYLabel(), DictionaryValue) then
                Evaluate(CustPaymentsLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetCustSalesLCYLabel(), DictionaryValue) then
                Evaluate(CustSalesLCY, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetCustProfitLabel(), DictionaryValue) then
                Evaluate(CustProfit, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetNoPostedInvoicesLabel(), DictionaryValue) then
                Evaluate(NoPostedInvoices, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetNoPostedCrMemosLabel(), DictionaryValue) then
                Evaluate(NoPostedCrMemos, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetNoOutstandingInvoicesLabel(), DictionaryValue) then
                Evaluate(NoOutstandingInvoices, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetNoOutstandingCrMemosLabel(), DictionaryValue) then
                Evaluate(NoOutstandingCrMemos, DictionaryValue);

            if TryGetDictionaryValueFromKey(Results, CustomerCardCalculations.GetOverdueBalanceLabel(), DictionaryValue) then
                Evaluate(OverdueBalance, DictionaryValue);

            AttentionToPaidDay := DaysPastDueDate > 0;
            TotalMoneyOwed := "Balance (LCY)" + ExpectedMoneyOwed;

            Session.LogMessage('0000D4R', PageBckGrndTaskCompletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CustomerCardServiceCategoryTxt);
        end;
    end;

    var
        CalendarMgmt: Codeunit "Calendar Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CustomerMgt: Codeunit "Customer Mgt.";
        FormatAddress: Codeunit "Format Address";
        StyleTxt: Text;
        [InDataSet]
        ContactEditable: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        NoFieldVisible: Boolean;
        BalanceExhausted: Boolean;
        AttentionToPaidDay: Boolean;
        IsOfficeAddin: Boolean;
        NoPostedInvoices: Integer;
        NoPostedCrMemos: Integer;
        NoOutstandingInvoices: Integer;
        NoOutstandingCrMemos: Integer;
        Totals: Decimal;
        AmountOnPostedInvoices: Decimal;
        AmountOnPostedCrMemos: Decimal;
        AmountOnOutstandingInvoices: Decimal;
        AmountOnOutstandingCrMemos: Decimal;
        AdjmtCostLCY: Decimal;
        AdjCustProfit: Decimal;
        CustProfit: Decimal;
        AdjProfitPct: Decimal;
        CustInvDiscAmountLCY: Decimal;
        CustPaymentsLCY: Decimal;
        CustSalesLCY: Decimal;
        OverdueBalance: Decimal;
        OverduePaymentsMsg: Label 'Overdue Payments as of %1', Comment = 'Overdue Payments as of 27-02-2012';
        DaysPastDueDate: Decimal;
        PostedInvoicesMsg: Label 'Posted Invoices (%1)', Comment = 'Invoices (5)';
        CreditMemosMsg: Label 'Posted Credit Memos (%1)', Comment = 'Credit Memos (3)';
        OutstandingInvoicesMsg: Label 'Ongoing Invoices (%1)', Comment = 'Ongoing Invoices (4)';
        OutstandingCrMemosMsg: Label 'Ongoing Credit Memos (%1)', Comment = 'Ongoing Credit Memos (4)';
        ShowMapLbl: Label 'Show on Map';
        CustomerCardServiceCategoryTxt: Label 'Customer Card', Locked = true;
        PageBckGrndTaskStartedTxt: Label 'Page Background Task to calculate customer statistics for customer %1 started.', Locked = true, Comment = '%1 = Customer No.';
        PageBckGrndTaskCompletedTxt: Label 'Page Background Task to calculate customer statistics completed successfully.', Locked = true;
        ExpectedMoneyOwed: Decimal;
        TotalMoneyOwed: Decimal;
        AvgDaysToPay: Decimal;
        FoundationOnly: Boolean;
        CanCancelApprovalForRecord: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        AnyWorkflowExists: Boolean;
        NewMode: Boolean;
        WorkFlowEventFilter: Text;
        CaptionTxt: Text;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsSaaS: Boolean;
        IsCountyVisible: Boolean;
        [InDataSet]
        ItemReferenceVisible: Boolean;
        StatementFileNameTxt: Label 'Statement', Comment = 'Shortened form of ''Customer Statement''';
        LoadOnDemand: Boolean;
        PrevCountryCode: Code[10];
        BackgroundTaskId: Integer;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure SetWorkFlowEnabled()
    var
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        AnyWorkflowExists := WorkflowManagement.AnyWorkflowExists();
        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::Customer, WorkFlowEventFilter);
    end;

    local procedure ActivateFields()
    begin
        ContactEditable := "Primary Contact No." = '';
        if "Country/Region Code" <> PrevCountryCode then
            IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        PrevCountryCode := "Country/Region Code";
        OnAfterActivateFields(Rec);
    end;

    local procedure SetCreditLimitStyle()
    begin
        StyleTxt := '';
        BalanceExhausted := false;
        if "Credit Limit (LCY)" > 0 then
            BalanceExhausted := "Balance (LCY)" >= "Credit Limit (LCY)";
        if BalanceExhausted then
            StyleTxt := 'Unfavorable';
    end;

    local procedure HasCustomBaseCalendar(): Boolean
    begin
        if "Base Calendar Code" = '' then
            exit(false)
        else
            exit(CalendarMgmt.CustomizedChangesExist(Rec));
    end;

    local procedure ContactOnAfterValidate()
    begin
        ActivateFields;
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.CustomerNoIsVisible;
    end;

    procedure RunReport(ReportNumber: Integer; CustomerNumber: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.SetRange("No.", CustomerNumber);
        REPORT.RunModal(ReportNumber, true, true, Customer);
    end;

    local procedure CreateCustomerFromTemplate()
    var
        Customer: Record Customer;
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        OnBeforeCreateCustomerFromTemplate(NewMode, Customer);

        if not NewMode then
            exit;
        NewMode := false;

        if CustomerTemplMgt.InsertCustomerFromTemplate(Customer) then begin
            VerifyVatRegNo(Customer);
            Copy(Customer);
            CurrPage.Update;
        end else
            if CustomerTemplMgt.TemplatesAreNotEmpty() then
                CurrPage.Close;
    end;

    local procedure VerifyVatRegNo(var Customer: Record Customer)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        EUVATRegistrationNoCheck: Page "EU VAT Registration No Check";
        CustomerRecRef: RecordRef;
    begin
        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled then
            if Customer."Validate EU Vat Reg. No." then begin
                EUVATRegistrationNoCheck.SetRecordRef(Customer);
                Commit();
                EUVATRegistrationNoCheck.RunModal;
                EUVATRegistrationNoCheck.GetRecordRef(CustomerRecRef);
                CustomerRecRef.SetTable(Customer);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterActivateFields(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var Customer: Record Customer; xCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure SetCaption(var InText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromTemplate(var NewMode: Boolean; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesPricesAndSalesLineDisc(var LoadOnDemand: Boolean)
    begin
    end;
}

