page 76 "Resource Card"
{
    Caption = 'Resource Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Resource,Navigate,Prices,Planning';
    RefreshOnActivate = true;
    SourceTable = Resource;

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the resource.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the resource is a person or a machine.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the base unit used to measure the resource, such as hour, piece, or kilometer.';
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Resource Group No."; "Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the resource group that this resource is assigned to.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date of the most recent change of information in the Resource Card window.';
                }
                field("Use Time Sheet"; "Use Time Sheet")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if a resource uses a time sheet to record time allocated to various tasks.';
                }
                field("Time Sheet Owner User ID"; "Time Sheet Owner User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the owner of the time sheet.';
                }
                field("Time Sheet Approver User ID"; "Time Sheet Approver User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the approver of the time sheet.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Price/Profit Calculation"; "Price/Profit Calculation")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this resource.';
                }
                field("Profit %"; "Profit %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the profit margin that you want to sell the resource at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Default Deferral Template Code"; "Default Deferral Template Code")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
                field("Automatic Ext. Texts"; "Automatic Ext. Texts")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that an Extended Text Header will be added on sales or purchase documents for this resource.';
                }
                field("IC Partner Purch. G/L Acc. No."; "IC Partner Purch. G/L Acc. No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the intercompany g/l account number in your partner''s company that the amount for this resource is posted to.';
                }
            }
            group("Personal Data")
            {
                Caption = 'Personal Data';
                field("Job Title"; "Job Title")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person''s job title.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the address or location of the resource, if applicable.';
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies additional address information.';
                }
                field(City; City)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the city of the resource''s address.';
                }
                group(Control47)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; County)
                    {
                        ApplicationArea = Jobs;
                        ToolTip = 'Specifies a special region, to which the resource belongs.';
                    }
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the postal code.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                    end;
                }
                field("Social Security No."; "Social Security No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person''s social security number or the machine''s serial number.';
                }
                field(Education; Education)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the training, education, or certification level of the person.';
                }
                field("Contract Class"; "Contract Class")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the contract class for the person.';
                }
                field("Employment Date"; "Employment Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the person began working for you or the date when the machine was placed in service.';
                }
            }
        }
        area(factboxes)
        {
            part(Control39; "Resource Picture")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("No.");
            }
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(156),
                              "No." = FIELD("No.");
            }
            part(Control1906609707; "Resource Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("No."),
                              "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                              "Chargeable Filter" = FIELD("Chargeable Filter"),
                              "Service Zone Filter" = FIELD("Service Zone Filter");
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
            group("&Resource")
            {
                Caption = '&Resource';
                Image = Resource;
                action(Statistics)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Resource Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(156),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Picture")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Picture';
                    Image = Picture;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Resource Picture";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View or add a picture of the resource or, for example, the company''s logo.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = CONST(Resource),
                                  "No." = FIELD("No.");
                    RunPageView = SORTING("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View the extended description that is set up.';
                }
                action("Units of Measure")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Resource Units of Measure";
                    RunPageLink = "Resource No." = FIELD("No.");
                    ToolTip = 'View or edit the units of measure that are set up for the resource.';
                }
                action("S&kills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'S&kills';
                    Image = Skills;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = CONST(Resource),
                                  "No." = FIELD("No.");
                    ToolTip = 'View the assignment of skills to the resource. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                separator(Action34)
                {
                    Caption = '';
                }
                action("Resource L&ocations")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource L&ocations';
                    Image = Resource;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Resource Locations";
                    RunPageLink = "Resource No." = FIELD("No.");
                    RunPageView = SORTING("Resource No.");
                    ToolTip = 'View where resources are located or assign resources to locations.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Resource),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    Promoted = true;
                    PromotedCategory = Category4;
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
                action("Online Map")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Online Map';
                    Image = Map;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        DisplayMap;
                    end;
                }
                separator(Action69)
                {
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Sales product.';

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
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

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
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

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
                    ToolTip = 'View integration synchronization jobs for the resource table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(RecordId);
                    end;
                }
            }
            group("&Prices")
            {
                Caption = '&Prices';
                Image = Price;
                action(Costs)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Costs';
                    Image = ResourceCosts;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Resource Costs";
                    RunPageLink = Type = CONST(Resource),
                                  Code = FIELD("No.");
                    ToolTip = 'View or change detailed information about costs for the resource.';
                }
                action(Prices)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Prices';
                    Image = Price;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Resource Prices";
                    RunPageLink = Type = CONST(Resource),
                                  Code = FIELD("No.");
                    ToolTip = 'View or edit prices for the resource.';
                }
            }
            group("Plan&ning")
            {
                Caption = 'Plan&ning';
                Image = Planning;
                action("Resource &Capacity")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Capacity';
                    Image = Capacity;
                    Promoted = true;
                    PromotedCategory = Category7;
                    RunObject = Page "Resource Capacity";
                    RunPageOnRec = true;
                    ToolTip = 'View this job''s resource capacity.';
                }
                action("Resource &Allocated per Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource &Allocated per Job';
                    Image = ViewJob;
                    RunObject = Page "Resource Allocated per Job";
                    RunPageLink = "Resource Filter" = FIELD("No.");
                    ToolTip = 'View this job''s resource allocation.';
                }
                action("Resource Allocated per Service &Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Allocated per Service &Order';
                    Image = ViewServiceOrder;
                    RunObject = Page "Res. Alloc. per Service Order";
                    RunPageLink = "Resource Filter" = FIELD("No.");
                    ToolTip = 'View the service order allocations of the resource.';
                }
                action("Resource A&vailability")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resource A&vailability';
                    Image = Calendar;
                    Promoted = true;
                    PromotedCategory = Category7;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = FIELD("No."),
                                  "Base Unit of Measure" = FIELD("Base Unit of Measure"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to jobs on order, the quantity allocated to service orders, the capacity assigned to jobs on quote, and the resource availability.';
                }
            }
            group(Service)
            {
                Caption = 'Service';
                Image = ServiceZone;
                action("Service &Zones")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Zones';
                    Image = ServiceZone;
                    RunObject = Page "Resource Service Zones";
                    RunPageLink = "Resource No." = FIELD("No.");
                    ToolTip = 'View the different service zones that you can assign to customers and resources. When you allocate a resource to a service task that is to be performed at the customer site, you can select a resource that is located in the same service zone as the customer.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = ResourceLedger;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Resource Ledger Entries";
                    RunPageLink = "Resource No." = FIELD("No.");
                    RunPageView = SORTING("Resource No.")
                                  ORDER(Descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(reporting)
        {
            action("Resource Statistics")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Statistics';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Resource Statistics";
                ToolTip = 'View detailed, historical information for the resource.';
            }
            action("Resource Usage")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Usage';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Resource Usage";
                ToolTip = 'View the resource utilization that has taken place. The report includes the resource capacity, quantity of usage, and the remaining balance.';
            }
            action("Resource - Cost Breakdown")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Cost Breakdown';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Resource - Cost Breakdown";
                ToolTip = 'View the direct unit costs and the total direct costs for each resource. Only usage postings are considered in this report. Resource usage can be posted in the resource journal or the job journal.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateTimeSheets)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create Time Sheets';
                    Ellipsis = true;
                    Image = NewTimesheet;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create new time sheets for the resource.';

                    trigger OnAction()
                    begin
                        CreateTimeSheets;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CRMIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
            if "No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
    end;

    trigger OnOpenPage()
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        SetNoFieldVisible;
        IsCountyVisible := FormatAddress.UseCounty("Country/Region Code");
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        FormatAddress: Codeunit "Format Address";
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        NoFieldVisible: Boolean;
        IsCountyVisible: Boolean;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ResourceNoIsVisible;
    end;
}

