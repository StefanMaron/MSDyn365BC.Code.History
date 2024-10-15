namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;

page 9317 "Service Quotes"
{
    ApplicationArea = Service;
    Caption = 'Service Quotes';
    CardPageID = "Service Quote";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Header";
    SourceTableView = where("Document Type" = const(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
                    Visible = false;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this service order.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                    Visible = false;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies when the invoice is due.';
                    Visible = false;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = false;
                }
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time warning status for the order.';
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
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
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
                action("&Dimensions")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        Rec.OpenStatistics();
                    end;
                }
                action("Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = 'Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the customer.';
                }
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
            }
        }
        area(processing)
        {
            action("Make &Order")
            {
                ApplicationArea = Service;
                Caption = 'Make &Order';
                Image = MakeOrder;
                ToolTip = 'Convert the service quote to a service order. The service order will contain the service quote number.';

                trigger OnAction()
                begin
                    CurrPage.Update();
                    CODEUNIT.Run(CODEUNIT::"Serv-Quote to Order (Yes/No)", Rec);
                    CurrPage.Update();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Make &Order_Promoted"; "Make &Order")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                group(Category_Quote)
                {
                    Caption = 'Quote';

                    actionref("&Dimensions_Promoted"; "&Dimensions")
                    {
                    }
                    actionref(Statistics_Promoted; Statistics)
                    {
                    }
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref("Service Document Lo&g_Promoted"; "Service Document Lo&g")
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        Rec.CopyCustomerFilter();
    end;
}

