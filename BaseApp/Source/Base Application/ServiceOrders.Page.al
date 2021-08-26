page 9318 "Service Orders"
{
    ApplicationArea = Service;
    Caption = 'Service Orders';
    CardPageID = "Service Order";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Warehouse,Posting,Print/Send,Order,Navigate';
    SourceTable = "Service Header";
    SourceTableView = WHERE("Document Type" = CONST(Order));
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Order Time"; "Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
                field("Response Date"; "Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
                }
                field("Response Time"; "Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when work on the order starts, that is, when the service order status changes from Pending, to In Process.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field("Release Status"; "Release Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if items in the Service Lines window are ready to be handled in warehouse activities.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Notify Customer"; "Notify Customer")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
                    Visible = false;
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this service order.';
                    Visible = false;
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                    Visible = false;
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies when the invoice is due.';
                    Visible = false;
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
                    Visible = false;
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = false;
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies information about whether the customer will accept a partial shipment of the order.';
                    Visible = false;
                }
                field("Warning Status"; "Warning Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time warning status for the order.';
                    Visible = false;
                }
                field("Allocated Hours"; "Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
                    Visible = false;
                }
                field("Expected Finishing Date"; "Expected Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service on the order is expected to be finished.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
                    Visible = false;
                }
                field("Finishing Date"; "Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
                    Visible = false;
                }
                field("Service Time (Hours)"; "Service Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total time in hours that the service specified in the order has taken.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("&Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the customer.';
                }
                action("&Dimensions")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("Email &Queue")
                {
                    ApplicationArea = Service;
                    Caption = 'Email &Queue';
                    Image = Email;
                    RunObject = Page "Service Email Queue";
                    RunPageLink = "Document Type" = CONST("Service Order"),
                                  "Document No." = FIELD("No.");
                    RunPageView = SORTING("Document Type", "Document No.");
                    ToolTip = 'View the list of emails that are waiting to be sent automatically to notify customers about their service item.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category7;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Header"),
                                  "Table Subtype" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  Type = CONST(General);
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Action17)
            {
                Caption = 'Statistics';
                Image = Statistics;
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OpenOrderStatistics();
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("S&hipments")
                {
                    ApplicationArea = Service;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Posted Service Shipments";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View related posted service shipments.';
                }
                action(Invoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    Image = Invoice;
                    Promoted = true;
                    PromotedCategory = Category8;
                    RunObject = Page "Posted Service Invoices";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View a list of ongoing sales invoices for the order.';
                }
            }
            group("W&arehouse")
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Warehouse Shipment Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Shipment Lines';
                    Image = ShipmentLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = CONST(5902),
                                  "Source Subtype" = FIELD("Document Type"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse shipments for the document, in advanced warehouse configurations.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        ServDocLog: Record "Service Document Log";
                    begin
                        ServDocLog.ShowServDocLog(Rec);
                    end;
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("&Job Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Job Ledger Entries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Service Order No." = FIELD("No.");
                    RunPageView = SORTING("Service Order No.", "Posting Date")
                                  WHERE("Entry Type" = CONST(Usage));
                    ToolTip = 'View all the job ledger entries that result from posting transactions in the service document that involve a job.';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Service;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        ReportPrint: Codeunit "Test Report-Print";
                    begin
                        ReportPrint.PrintServiceHeader(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Service;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostYesNo.PostDocument(ServHeader);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Service;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostYesNo.PreviewDocument(ServHeader);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ServPostPrint: Codeunit "Service-Post+Print";
                    begin
                        ServHeader.Get("Document Type", "No.");
                        ServPostPrint.PostDocument(ServHeader);
                    end;
                }
                action(PostBatch)
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        Clear(ServHeader);
                        ServHeader.CopyFilters(Rec);
                        ServHeader.SetRange(Status, ServHeader.Status::Finished);
                        REPORT.RunModal(REPORT::"Batch Post Service Orders", true, true, ServHeader);
                        CurrPage.Update(false);
                    end;
                }
                action("&Print")
                {
                    ApplicationArea = Service;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Category6;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        DocPrint: Codeunit "Document-Print";
                    begin
                        CurrPage.Update(true);
                        DocPrint.PrintServiceHeader(Rec);
                    end;
                }
            }
            group(Action13)
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Release to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Release to Ship';
                    Image = ReleaseShipment;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Signal to warehouse workers that the service item is ready to be picked and shipped to the customer''s address.';

                    trigger OnAction()
                    var
                        ReleaseServiceDocument: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDocument.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Reactivate the service order after it has been released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseServiceDocument: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDocument.PerformManualReopen(Rec);
                    end;
                }
                action("Create Whse Shipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Shipment';
                    Image = NewShipment;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Prepare to pick and ship the service item.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        GetSourceDocOutbound.CreateFromServiceOrder(Rec);
                        if not Find('=><') then
                            Init;
                    end;
                }
            }
            action("Delete Invoiced Orders")
            {
                ApplicationArea = Service;
                Caption = 'Delete Invoiced Orders';
                Image = Delete;
                RunObject = Report "Delete Invoiced Service Orders";
                ToolTip = 'Delete orders that were not automatically deleted after completion. For example, when several sales orders were completed by a single invoice.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;

        CopyCustomerFilter;
    end;

    var
        ServHeader: Record "Service Header";
}

