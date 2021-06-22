page 27 "Vendor List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendors';
    CardPageID = "Vendor Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,New Document,Vendor,Navigate';
    QueryCategory = 'Vendor List';
    RefreshOnActivate = true;
    SourceTable = Vendor;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s name. You can enter a maximum of 30 characters, both numbers and letters.';
                }
                field("Name 2"; "Name 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s telephone number.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s fax number.';
                    Visible = false;
                }
                field("IC Partner Code"; "IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the vendor''s intercompany partner code.';
                    Visible = false;
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor.';
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s trade type to link transactions made for this vendor with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; "Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code that is inserted by default when you create purchase documents or journal lines for the vendor.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a vendor that is declared insolvent or an item that is placed in quarantine.';
                    Visible = false;
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the vendor card was last modified.';
                    Visible = false;
                }
                field("Application Method"; "Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to apply payments to entries for this vendor.';
                    Visible = false;
                }
                field("Location Code2"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
                    Visible = false;
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Lead Time Calculation"; "Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                    Visible = false;
                }
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customizable calendar for delivery planning that holds the vendor''s working days and holidays.';
                    Visible = false;
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all completed purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    begin
                        OpenVendorLedgerEntries(false);
                    end;
                }
                field("Balance Due (LCY)"; "Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your unpaid purchases from the vendor in the current fiscal year. It is calculated from amounts excluding VAT on all open purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    begin
                        OpenVendorLedgerEntries(true);
                    end;
                }
                field("Payments (LCY)"; "Payments (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of payments paid to the vendor.';
                }
            }
        }
        area(factboxes)
        {
            part("Power BI Report FactBox"; "Power BI Report FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Power BI Reports';
                Visible = PowerBIVisible;
            }
            part(Control14; "Social Listening FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Vendor),
                              "Source No." = FIELD("No.");
                Visible = SocialListeningVisible;
            }
            part(Control15; "Social Listening Setup FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Source Type" = CONST(Vendor),
                              "Source No." = FIELD("No.");
                UpdatePropagation = Both;
                Visible = SocialListeningSetupVisible;
            }
            part(VendorDetailsFactBox; "Vendor Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                Visible = false;
            }
            part(VendorStatisticsFactBox; "Vendor Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
            }
            part(VendorHistBuyFromFactBox; "Vendor Hist. Buy-from FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
            }
            part(VendorHistPayToFactBox; "Vendor Hist. Pay-to FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = FIELD("No."),
                              "Currency Filter" = FIELD("Currency Filter"),
                              "Date Filter" = FIELD("Date Filter"),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                Visible = false;
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
            group("Ven&dor")
            {
                Caption = 'Ven&dor';
                Image = Vendor;
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action(DimensionsSingle)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Category5;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(23),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action(DimensionsMultiple)
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Category5;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Vend: Record Vendor;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Vend);
                            DefaultDimMultiple.SetMultiRecord(Vend, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    ToolTip = 'Open the list of the vendor''s bank accounts';
                }
                action("C&ontact")
                {
                    AccessByPermission = TableData Contact = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'View or edit detailed information about the contact person at the vendor.';

                    trigger OnAction()
                    begin
                        ShowContact;
                    end;
                }
                separator(Action55)
                {
                }
                action(OrderAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    ToolTip = 'View or edit alternate addresses for the vendor.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Vendor),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Cross Re&ferences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cross Re&ferences';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Cross References";
                    RunPageLink = "Cross-Reference Type" = CONST(Vendor),
                                  "Cross-Reference Type No." = FIELD("No.");
                    RunPageView = SORTING("Cross-Reference Type", "Cross-Reference Type No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the selected item. Cross-references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(RecordId);
                    end;
                }
            }
            group("&Purchases")
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action(Items)
                {
                    ApplicationArea = Planning;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Vendor Item Catalog";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.");
                    ToolTip = 'Open the list of items that you trade in.';
                }
                action("Invoice &Discounts")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Invoice &Discounts';
                    Image = CalculateInvoiceDiscount;
                    RunObject = Page "Vend. Invoice Discounts";
                    RunPageLink = Code = FIELD("Invoice Disc. Code");
                    ToolTip = 'Set up different discounts that are applied to invoices for the vendor. An invoice discount is automatically granted to the vendor when the total on a sales invoice exceeds a certain amount.';
                }
                action(Prices)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Prices';
                    Image = Price;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.");
                    ToolTip = 'View or set up different prices for items that you buy from the vendor. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Line Discounts")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.");
                    ToolTip = 'View or set up different discounts for items that you buy from the vendor. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action("Recurring Purchase Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring Purchase Lines';
                    Image = CodesList;
                    RunObject = Page "Standard Vendor Purchase Codes";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    ToolTip = 'View or edit recurring purchase lines for the vendor.';
                }
                action("Mapping Text to Account")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Mapping Text to Account';
                    Image = MapAccounts;
                    RunObject = Page "Text-to-Account Mapping Wksh.";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    ToolTip = 'Page mapping text to account';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Administration;
                action(Quotes)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Purchase Quotes";
                    RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View a list of ongoing sales quotes.';
                }
                action(Orders)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Orders';
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Purchase Order List";
                    RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View a list of ongoing purchase orders for the vendor.';
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Purchase Return Order List";
                    RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'Open the list of ongoing return orders.';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Purchase Orders";
                    RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'Open the list of ongoing blanket orders.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Advanced;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = FIELD("No.");
                    RunPageView = SORTING("Vendor No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Purchases)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Purchases';
                    Image = Purchase;
                    RunObject = Page "Vendor Purchases";
                    RunPageLink = "No." = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter");
                    ToolTip = 'Shows a summary of vendor ledger entries. You select the time interval in the View by field. The Period column on the left contains a series of dates that are determined by the time interval you have selected.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
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
                    RunObject = Page "Vend. Stats. by Curr. Lines";
                    RunPageLink = "Vendor Filter" = FIELD("No."),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Date Filter" = FIELD("Date Filter");
                    ToolTip = 'View statistics for vendors that use multiple currencies.';
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
                        ItemTrackingDocMgt.ShowItemTrackingForMasterData(2, "No.", '', '', '', '', '');
                    end;
                }
            }
        }
        area(creation)
        {
            action(NewBlanketPurchaseOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Blanket Purchase Order';
                Image = BlanketOrder;
                RunObject = Page "Blanket Purchase Order";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new blanket purchase order for the vendor.';
            }
            action(NewPurchaseQuote)
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Quote';
                Image = Quote;
                RunObject = Page "Purchase Quote";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase quote for the vendor.';
            }
            action(NewPurchaseInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoice';
                Image = NewPurchaseInvoice;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Purchase Invoice";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase invoice for items or services.';
            }
            action(NewPurchaseOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Order';
                Image = Document;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Purchase Order";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase order.';
            }
            action(NewPurchaseCrMemo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memo';
                Image = CreditMemo;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "Purchase Credit Memo";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase credit memo to revert a posted purchase invoice.';
            }
            action(NewPurchaseReturnOrder)
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Purchase Return Order';
                Image = ReturnOrder;
                RunObject = Page "Purchase Return Order";
                RunPageLink = "Buy-from Vendor No." = FIELD("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase return order for the vendor.';
            }
        }
        area(processing)
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist AND CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckVendorApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendVendorForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord OR CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelVendorApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(RecordId);
                    end;
                }
            }
            action("Payment Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journal';
                Image = PaymentJournal;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "Payment Journal";
                ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
            }
            action("Purchase Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Journal';
                Image = Journals;
                Promoted = true;
                PromotedCategory = Category6;
                RunObject = Page "Purchase Journal";
                ToolTip = 'Post any purchase transaction for the vendor. ';
            }
            action(ApplyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Template';
                Ellipsis = true;
                Image = ApplyTemplate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Apply a template to update one or more entities with your standard settings for a certain type of entity.';

                trigger OnAction()
                var
                    Vendor: Record Vendor;
                    MiniVendorTemplate: Record "Mini Vendor Template";
                begin
                    CurrPage.SetSelectionFilter(Vendor);
                    MiniVendorTemplate.UpdateVendorsFromTemplate(Vendor);
                end;
            }
            action(PayVendor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pay Vendor';
                Image = SuggestVendorPayments;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Vendor Ledger Entries";
                RunPageLink = "Vendor No." = FIELD("No."),
                              "Remaining Amount" = FILTER(< 0),
                              "Applies-to ID" = FILTER(''),
                              "Document Type" = FILTER(Invoice);
                ToolTip = 'Opens vendor ledger entries for the selected vendor with invoices that have not been paid yet.';
            }
            group(Display)
            {
                Caption = 'Display';
                action(ReportFactBoxVisibility)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show/Hide Power BI Reports';
                    Image = "Report";
                    ToolTip = 'Select if the Power BI FactBox is visible or not.';

                    trigger OnAction()
                    begin
                        // save visibility value into the table
                        CurrPage."Power BI Report FactBox".PAGE.SetFactBoxVisibility(PowerBIVisible);
                    end;
                }
            }
            group(OCR)
            {
                Caption = 'OCR';
                action(Resync)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resync all Vendors';
                    Image = CopyFromChartOfAccounts;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Synchronize vendors and vendor bank accounts with the OCR service.';
                    Visible = ResyncVisible;

                    trigger OnAction()
                    begin
                        ReadSoftOCRMasterDataSync.SyncMasterData(true, false);
                    end;
                }
            }
        }
        area(reporting)
        {
            group(General)
            {
                Caption = 'General';
                Image = "Report";
                action("Vendor - List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - List';
                    Image = "Report";
                    RunObject = Report "Vendor - List";
                    ToolTip = 'View various kinds of basic information for vendors, such as vendor posting group, discount and payment information, priority level and the vendor''s default currency, and the vendor''s current balance (in LCY). The report can be used, for example, to maintain the information in the Vendor table.';
                }
                action("Vendor Register")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Register';
                    Image = "Report";
                    RunObject = Report "Vendor Register";
                    ToolTip = 'View vendor ledger entries that have been posted in connection with a general ledger register. The entries are divided into, and sorted according to, G/L registers. By using a filter, you can select exactly the entries in the registers that you need to see. The report can be used to document the contents of the various registers for internal or external audits.';
                }
                action("Vendor Item Catalog")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor Item Catalog';
                    Image = "Report";
                    RunObject = Report "Vendor Item Catalog";
                    ToolTip = 'View a list of the items that your vendors supply.';
                }
                action("Vendor - Labels")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Labels';
                    Image = "Report";
                    RunObject = Report "Vendor - Labels";
                    ToolTip = 'View mailing labels with the vendors'' names and addresses.';
                }
                action("Vendor - Top 10 List")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor - Top 10 List';
                    Image = "Report";
                    RunObject = Report "Vendor - Top 10 List";
                    ToolTip = 'View a list of the vendors from whom you purchase the most or to whom you owe the most.';
                }
            }
            group(Action5)
            {
                Caption = 'Orders';
                Image = "Report";
                action("Vendor - Order Summary")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Order Summary';
                    Image = "Report";
                    RunObject = Report "Vendor - Order Summary";
                    ToolTip = 'View the order detail (the quantity not yet received) for each vendor in three periods of 30 days each, starting from a selected date. There are also columns with orders before and after the three periods and a column with the total order detail for each vendor. The report can be used to analyze a company''s expected purchase volume.';
                }
                action("Vendor - Order Detail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Order Detail';
                    Image = "Report";
                    RunObject = Report "Vendor - Order Detail";
                    ToolTip = 'View a list of items that have been ordered, but not yet received, from each vendor. The order amounts are totaled for each vendor and for the entire list. The report can be used, for example, to obtain an overview of purchases over the short term or to analyze possible receipt problems.';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                Image = Purchase;
                action("Vendor - Purchase List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Purchase List';
                    Image = "Report";
                    RunObject = Report "Vendor - Purchase List";
                    ToolTip = 'View a list of vendor purchases for a selected period.';
                }
                action("Vendor/Item Purchases")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor/Item Purchases';
                    Image = "Report";
                    RunObject = Report "Vendor/Item Purchases";
                    ToolTip = 'View a list of item entries for each vendor in a selected period.';
                }
                action("Purchase Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Statistics';
                    Image = "Report";
                    RunObject = Report "Purchase Statistics";
                    ToolTip = 'View a list of amounts for purchases, invoice discount and payment discount in $ for each vendor.';
                }
            }
            group("Financial Management")
            {
                Caption = 'Financial Management';
                Image = "Report";
                action("Payments on Hold")
                {
                    ApplicationArea = Suite;
                    Caption = 'Payments on Hold';
                    Image = "Report";
                    RunObject = Report "Payments on Hold";
                    ToolTip = 'View a list of all vendor ledger entries on which the On Hold field is marked.';
                }
                action("Vendor - Summary Aging")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Summary Aging';
                    Image = "Report";
                    RunObject = Report "Vendor - Summary Aging";
                    ToolTip = 'View, print, or save a summary of the payables owed to each vendor, divided into three time periods.';
                }
                action("Aged Accounts Payable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts Payable';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Payable";
                    ToolTip = 'View a list of aged remaining balances for each vendor.';
                }
                action("Vendor - Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Balance to Date';
                    Image = "Report";
                    RunObject = Report "Vendor - Balance to Date";
                    ToolTip = 'View, print, or save a detail balance to date for selected vendors.';
                }
                action("Vendor - Trial Balance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor - Trial Balance';
                    Image = "Report";
                    RunObject = Report "Vendor - Trial Balance";
                    ToolTip = 'View the beginning and ending balance for vendors with entries within a specified period. The report can be used to verify that the balance for a vendor posting group is equal to the balance on the corresponding general ledger account on a certain date.';
                }
                action("Vendor - Detail Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Detail Trial Balance';
                    Image = "Report";
                    RunObject = Report "Vendor - Detail Trial Balance";
                    ToolTip = 'View a detail trial balance for selected vendors.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SocialListeningMgt: Codeunit "Social Listening Management";
    begin
        if SocialListeningSetupVisible then
            SocialListeningMgt.GetVendFactboxVisibility(Rec, SocialListeningSetupVisible, SocialListeningVisible);

        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        // Contextual Power BI FactBox: send data to filter the report in the FactBox
        CurrPage."Power BI Report FactBox".PAGE.SetCurrentListSelection("No.", false, PowerBIVisible);
    end;

    trigger OnInit()
    begin
        SetVendorNoVisibilityOnFactBoxes;
        CurrPage."Power BI Report FactBox".PAGE.InitFactBox(CurrPage.ObjectId(false), CurrPage.Caption, PowerBIVisible);
    end;

    trigger OnOpenPage()
    var
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        SetFilter("Date Filter", '..%1', WorkDate);
        with SocialListeningSetup do
            SocialListeningSetupVisible := Get and "Show on Customers" and "Accept License Agreement" and ("Solution ID" <> '');
        ResyncVisible := ReadSoftOCRMasterDataSync.IsSyncEnabled;
    end;

    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        [InDataSet]
        SocialListeningSetupVisible: Boolean;
        [InDataSet]
        SocialListeningVisible: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        PowerBIVisible: Boolean;
        ResyncVisible: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Vend: Record Vendor;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Vend);
        exit(SelectionFilterManagement.GetSelectionFilterForVendor(Vend));
    end;

    procedure SetSelection(var Vend: Record Vendor)
    begin
        CurrPage.SetSelectionFilter(Vend);
    end;

    local procedure SetVendorNoVisibilityOnFactBoxes()
    begin
        CurrPage.VendorDetailsFactBox.PAGE.SetVendorNoVisibility(false);
        CurrPage.VendorHistBuyFromFactBox.PAGE.SetVendorNoVisibility(false);
        CurrPage.VendorHistPayToFactBox.PAGE.SetVendorNoVisibility(false);
        CurrPage.VendorStatisticsFactBox.PAGE.SetVendorNoVisibility(false);
    end;
}

