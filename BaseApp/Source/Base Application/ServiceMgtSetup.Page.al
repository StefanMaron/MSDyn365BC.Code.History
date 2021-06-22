page 5919 "Service Mgt. Setup"
{
    ApplicationArea = Service;
    Caption = 'Service Management Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Service Mgt. Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("First Warning Within (Hours)"; "First Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the first warning about the response time approaching for a service order. The working calendar and the default service hours are used to calculate when to send the warnings within the general service hours of your company.';
                }
                field("Send First Warning To"; "Send First Warning To")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email address that will be used to send the first warning about the response time for a service order that is approaching.';
                }
                field("Second Warning Within (Hours)"; "Second Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the second warning about the response time approaching for a service order.';
                }
                field("Send Second Warning To"; "Send Second Warning To")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email address that will be used to send the second warning about the response time for a service order that is approaching.';
                }
                field("Third Warning Within (Hours)"; "Third Warning Within (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours before the program sends the third warning about the response time approaching for a service order.';
                }
                field("Send Third Warning To"; "Send Third Warning To")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email address that will be used to send the third warning about the response time for a service order that is approaching.';
                }
                field("Serv. Job Responsibility Code"; "Serv. Job Responsibility Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for job responsibilities that is set up for service management work. When you assign customers to service orders, the program selects the contact with this job responsibility from among the contacts assigned to the customer.';
                }
                field("Next Service Calc. Method"; "Next Service Calc. Method")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how you want the program to recalculate the next planned service date for service items in service contracts. Planned: The next planned service date is recalculated by adding the value in the Service Period field for the service item to the previous next planned service date. Also, when the last service actually took place is disregarded. Actual: The next planned service date is recalculated by adding the service period for the service item to the value in the Posting Date field of the last posted service order that belongs to the service contract and includes that service item.';
                }
                field("Service Order Starting Fee"; "Service Order Starting Fee")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for a service order starting fee.';
                }
                field("Shipment on Invoice"; "Shipment on Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that if you post a manually created invoice, a posted shipment will be created in addition to a posted invoice.';
                }
                field("One Service Item Line/Order"; "One Service Item Line/Order")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you can enter only one service item line for each service order.';
                }
                field("Link Service to Service Item"; "Link Service to Service Item")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that service lines for resources and items must be linked to a service item line. The value that you specify is entered as the link when a service order is created, but you can change it on the order manually.';
                }
                field("Resource Skills Option"; "Resource Skills Option")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to identify resource skills in your company when you allocate resources to service items.';
                }
                field("Service Zones Option"; "Service Zones Option")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to identify service zones in your company when you allocate resources to service items.';
                }
                field("Fault Reporting Level"; "Fault Reporting Level")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the level of fault reporting that your company uses in service management.';
                }
                field("Base Calendar Code"; "Base Calendar Code")
                {
                    ApplicationArea = Service;
                    DrillDown = true;
                    ToolTip = 'Specifies a customizable calendar for service planning that holds the service department''s working days and holidays. Choose the field to select another base calendars or to set up a customized calendar for your service department.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord;
                        TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
                }
                field("Copy Comments Order to Invoice"; "Copy Comments Order to Invoice")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies whether to copy comments from service orders to service invoices.';
                }
                field("Copy Comments Order to Shpt."; "Copy Comments Order to Shpt.")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies whether to copy comments from service orders to shipments.';
                }
                field("Logo Position on Documents"; "Logo Position on Documents")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the position of your company logo on your business letters and documents, such as service invoices and service shipments.';
                }
                field("Copy Time Sheet to Order"; "Copy Time Sheet to Order")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if approved time sheet lines are copied to the related service order. Select this field to make sure that time usage registered on approved time sheet lines is posted with the related service order.';
                }
                field("Skip Manual Reservation"; "Skip Manual Reservation")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the reservation confirmation message is not shown on service lines. This is useful to avoid noise when you are processing many lines.';
                }
                field("Copy Line Descr. to G/L Entry"; "Copy Line Descr. to G/L Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies that the description on document lines of type G/L Account will be carried to the resulting general ledger entries.';
                }
            }
            group("Mandatory Fields")
            {
                Caption = 'Mandatory Fields';
                field("Service Order Type Mandatory"; "Service Order Type Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a service order must have a service order type assigned before the order can be posted.';
                }
                field("Service Order Start Mandatory"; "Service Order Start Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the Starting Date and Starting Time fields on a service order must be filled in before you can post the service order.';
                }
                field("Service Order Finish Mandatory"; "Service Order Finish Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the Finishing Date and Finishing Time fields on a service order must be filled in before you can post the service order.';
                }
                field("Contract Rsp. Time Mandatory"; "Contract Rsp. Time Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the Response Time (Hours) field must be filled on service contract lines before you can convert a quote to a contract.';
                }
                field("Unit of Measure Mandatory"; "Unit of Measure Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if you must select a unit of measure for all operations that deal with service items.';
                }
                field("Fault Reason Code Mandatory"; "Fault Reason Code Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the Fault Reason Code field must be filled in before you can post the service order.';
                }
                field("Work Type Code Mandatory"; "Work Type Code Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the Work Type Code field with type Resource must be filled in before you can post the service order.';
                }
                field("Salesperson Mandatory"; "Salesperson Mandatory")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you must fill in the Salesperson Code field on the headers of service orders, invoices, credit memos, and service contracts.';
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                field("Default Response Time (Hours)"; "Default Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time, in hours, required to start service, either on a service order or on a service item line.';
                }
                field("Warranty Disc. % (Parts)"; "Warranty Disc. % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default warranty discount percentage on spare parts. The program uses this value to set warranty discounts on parts on service item lines.';
                }
                field("Warranty Disc. % (Labor)"; "Warranty Disc. % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default warranty discount percentage on labor. The program uses this value to set warranty discounts on labor on service item lines.';
                }
                field("Default Warranty Duration"; "Default Warranty Duration")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default duration for warranty discounts on service items.';
                }
            }
            group(Contracts)
            {
                Caption = 'Contracts';
                field("Contract Serv. Ord.  Max. Days"; "Contract Serv. Ord.  Max. Days")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum number of days you can use as the date range each time you run the Create Contract Service Orders batch job.';
                }
                field("Use Contract Cancel Reason"; "Use Contract Cancel Reason")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a reason code is entered when you cancel a service contract.';
                }
                field("Register Contract Changes"; "Register Contract Changes")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want the program to log changes to service contracts in the Contract Change Log table.';
                }
                field("Contract Inv. Line Text Code"; "Contract Inv. Line Text Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
                }
                field("Contract Line Inv. Text Code"; "Contract Line Inv. Text Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
                }
                field("Contract Inv. Period Text Code"; "Contract Inv. Period Text Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the standard text entered in the Description field on the line in a contract invoice.';
                }
                field("Contract Credit Line Text Code"; "Contract Credit Line Text Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the standard text that entered in the Description field on the line in a contract credit memo.';
                }
                field("Contract Value Calc. Method"; "Contract Value Calc. Method")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the method to use for calculating the default contract value of service items when they are created. None: A default value is not calculated. Based on Unit Price: Value = Sales Unit Price x Contract Value % divided by 100. Based on Unit Cost: Value = Sales Unit Cost x Contract Value % divided by 100.';
                }
                field("Contract Value %"; "Contract Value %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage used to calculate the default contract value of a service item when it is created.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Service Item Nos."; "Service Item Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service items.';
                }
                field("Service Quote Nos."; "Service Quote Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service quotes.';
                }
                field("Service Order Nos."; "Service Order Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service orders.';
                }
                field("Service Invoice Nos."; "Service Invoice Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to invoices.';
                }
                field("Posted Service Invoice Nos."; "Posted Service Invoice Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service invoices when they are posted.';
                }
                field("Service Credit Memo Nos."; "Service Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service credit memos.';
                }
                field("Posted Serv. Credit Memo Nos."; "Posted Serv. Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service credit memos when they are posted.';
                }
                field("Posted Service Shipment Nos."; "Posted Service Shipment Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to shipments when they are posted.';
                }
                field("Loaner Nos."; "Loaner Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to loaners.';
                }
                field("Troubleshooting Nos."; "Troubleshooting Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to troubleshooting guidelines.';
                }
                field("Service Contract Nos."; "Service Contract Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to service contracts.';
                }
                field("Contract Template Nos."; "Contract Template Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to contract templates.';
                }
                field("Contract Invoice Nos."; "Contract Invoice Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to invoices created for service contracts.';
                }
                field("Contract Credit Memo Nos."; "Contract Credit Memo Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign numbers to credit memos for service contracts.';
                }
                field("Prepaid Posting Document Nos."; "Prepaid Posting Document Nos.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number series code that will be used to assign a document number to the journal lines.';
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
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;
    end;

    var
        CalendarMgmt: Codeunit "Calendar Management";
}

