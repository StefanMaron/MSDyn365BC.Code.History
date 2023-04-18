page 5981 "Service Item List"
{
    ApplicationArea = Service;
    Caption = 'Service Items';
    CardPageID = "Service Item Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Service Item";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of this item.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to the service item.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the item that the service item is linked to.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of this item.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns this item.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an alternate description to search for the service item.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the service item.';
                    Visible = false;
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service priority for this item.';
                    Visible = false;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last service on this item.';
                    Visible = false;
                }
                field("Service Contracts"; Rec."Service Contracts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that this service item is associated with one or more service contracts/quotes.';
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the vendor for this item.';
                    Visible = false;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the vendor name for this item.';
                    Visible = false;
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this item was installed at the customer''s site.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Service Item")
            {
                Caption = '&Service Item';
                Image = ServiceItem;
                action("Com&ponent List")
                {
                    ApplicationArea = Service;
                    Caption = 'Com&ponent List';
                    Image = Components;
                    RunObject = Page "Service Item Component List";
                    RunPageLink = Active = CONST(true),
                                  "Parent Service Item No." = FIELD("No.");
                    RunPageView = SORTING(Active, "Parent Service Item No.", "Line No.");
                    ToolTip = 'View the list of components in the service item.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("&Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = '&Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(5940),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            ServiceItem: Record "Service Item";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(ServiceItem);
                            DefaultDimMultiple.SetMultiRecord(ServiceItem, FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action59)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        RunObject = Page "Service Item Statistics";
                        RunPageLink = "No." = FIELD("No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Service Item Trendscape";
                        RunPageLink = "No." = FIELD("No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                group(Troubleshooting)
                {
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    action("Troubleshooting Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting Setup';
                        Image = Troubleshoot;
                        RunObject = Page "Troubleshooting Setup";
                        RunPageLink = Type = CONST("Service Item"),
                                      "No." = FIELD("No.");
                        ToolTip = 'View or edit your settings for troubleshooting service items.';
                    }
                    action(Action3)
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting';
                        Image = Troubleshoot;
                        ToolTip = 'View or edit information about technical problems with a service item.';

                        trigger OnAction()
                        var
                            TroubleshootingHeader: Record "Troubleshooting Header";
                        begin
                            TroubleshootingHeader.ShowForServItem(Rec);
                        end;
                    }
                }
                action("Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = CONST("Service Item"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("S&killed Resources")
                {
                    ApplicationArea = Service;
                    Caption = 'S&killed Resources';
                    Image = ResourceSkills;
                    ToolTip = 'View the list of resources that have the skills required to handle service items.';

                    trigger OnAction()
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::"Service Item", "No.", Description);
                        SkilledResourceList.RunModal();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Item"),
                                  "Table Subtype" = CONST("0"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                group("S&ervice Orders")
                {
                    Caption = 'S&ervice Orders';
                    Image = "Order";
                    action("&Item Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Service Item Lines";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action("&Service Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Service Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                group("Service Shi&pments")
                {
                    Caption = 'Service Shi&pments';
                    Image = Shipment;
                    action(Action67)
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Posted Shpt. Item Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action(Action68)
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Posted Serv. Shpt. Line List";
                        RunPageLink = "Service Item No." = FIELD("No.");
                        RunPageView = SORTING("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = FIELD("No.");
                    RunPageView = SORTING("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Item Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Lo&g';
                    Image = Log;
                    RunObject = Page "Service Item Log";
                    RunPageLink = "Service Item No." = FIELD("No.");
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = FIELD("No."),
                                  "Service Order No." = FIELD("Service Order Filter"),
                                  "Service Contract No." = FIELD("Contract Filter"),
                                  "Posting Date" = FIELD("Date Filter");
                    RunPageView = SORTING("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = FIELD("No.");
                    RunPageView = SORTING("Service Item No. (Serviced)", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                action("New Item")
                {
                    ApplicationArea = Service;
                    Caption = 'New Item';
                    Image = NewItem;
                    RunObject = Page "Item Card";
                    RunPageMode = Create;
                    ToolTip = 'Create an item card based on the stockkeeping unit.';
                }
            }
        }
        area(reporting)
        {
            action("Service Item")
            {
                ApplicationArea = Service;
                Caption = 'Service Item';
                Image = "Report";
                RunObject = Report "Service Items";
                ToolTip = 'Create a new service item.';
            }
            action("Service Item Label")
            {
                ApplicationArea = Service;
                Caption = 'Service Item Label';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Item Line Labels";
                ToolTip = 'View the list of service items on service orders. The report shows the order number, service item number, serial number, and the name of the item.';
            }
            action("Service Item Resource usage")
            {
                ApplicationArea = Service;
                Caption = 'Service Item Resource usage';
                Image = "Report";
                RunObject = Report "Service Item - Resource Usage";
                ToolTip = 'View details about the total use of service items, both cost and amount, profit amount, and profit percentage.';
            }
            action("Service Item Out of Warranty")
            {
                ApplicationArea = Service;
                Caption = 'Service Item Out of Warranty';
                Image = "Report";
                RunObject = Report "Service Items Out of Warranty";
                ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

#if not CLEAN22
                actionref("New Item_Promoted"; "New Item")
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action is being demoted based on overall low usage.';
                    ObsoleteTag = '22.0';
                }
#endif
            }
            group(Category_Process)
            {
                Caption = 'Process';

            }
            group(Category_Item)
            {
                Caption = 'Item';

                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("&Dimensions-Single_Promoted"; "&Dimensions-Single")
                    {
                    }
                }
                actionref(Action59_Promoted; Action59)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("S&killed Resources_Promoted"; "S&killed Resources")
                {
                }
                actionref("Resource Skills_Promoted"; "Resource Skills")
                {
                }
                actionref("Ser&vice Contracts_Promoted"; "Ser&vice Contracts")
                {
                }
            }
            group(Category_Troubleshooting)
            {
                Caption = 'Troubleshooting';

                actionref(Action3_Promoted; Action3)
                {
                }
                actionref("Troubleshooting Setup_Promoted"; "Troubleshooting Setup")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Service Item_Promoted"; "Service Item")
                {
                }
                actionref("Service Item Resource usage_Promoted"; "Service Item Resource usage")
                {
                }
                actionref("Service Item Out of Warranty_Promoted"; "Service Item Out of Warranty")
                {
                }
            }
        }
    }

    var
        ResourceSkill: Record "Resource Skill";
        SkilledResourceList: Page "Skilled Resource List";
}

