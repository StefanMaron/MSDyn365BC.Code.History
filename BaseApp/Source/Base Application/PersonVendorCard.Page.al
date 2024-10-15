page 17360 "Person Vendor Card"
{
    Caption = 'Person Vendor Card';
    PageType = Card;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = Vendor;
    SourceTableView = WHERE("Vendor Type" = CONST(Person));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person''s VAT registration number. ';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    begin
                        DtldVendLedgEntry.SetFilter("Vendor No.", "No.");
                        CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                        CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                        CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                        VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                    end;
                }
                field(Payments; Payments)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Amounts"; "Invoice Amounts")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was last modified.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Phone No.2"; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the person''s email address.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the web site.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                }
                field("Our Account No."; "Our Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Default Bank Code"; "Default Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default bank code associated with the vendor.';
                }
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to apply payments to entries for this vendor.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
            }
            group(Agreements)
            {
                Caption = 'Agreements';
                field("Agreement Posting"; "Agreement Posting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement posting associated with the vendor.';
                }
                field("Agreement Nos."; "Agreement Nos.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the vendor.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ven&dor")
            {
                Caption = 'Ven&dor';
                Image = Vendor;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Vendor),
                                  "No." = FIELD("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(23),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                }
                action("&Agreements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Agreements';
                    Image = Agreement;
                    RunObject = Page "Vendor Agreements";
                    RunPageLink = "Vendor No." = FIELD("No.");
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = FIELD("No.");
                }
                separator(Action11)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                }
            }
        }
    }
}

