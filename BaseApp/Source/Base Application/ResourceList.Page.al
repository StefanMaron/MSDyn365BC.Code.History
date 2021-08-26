page 77 "Resource List"
{
    AdditionalSearchTerms = 'capacity,job,project';
    ApplicationArea = Jobs;
    Caption = 'Resources';
    CardPageID = "Resource Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Resource,Navigate,Prices & Discounts';
    SourceTable = Resource;
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
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of the resource.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether the resource is a person or a machine.';
                }
                field("Base Unit of Measure"; "Base Unit of Measure")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the base unit used to measure the resource, such as hour, piece, or kilometer.';
                }
                field("Resource Group No."; "Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the resource group that this resource is assigned to.';
                    Visible = false;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
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
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Privacy Blocked"; "Privacy Blocked")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Search Name"; "Search Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Default Deferral Template Code"; "Default Deferral Template Code")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Default Deferral Template';
                    ToolTip = 'Specifies the default template that governs how to defer revenues and expenses to the periods when they occurred.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1906609707; "Resource Statistics FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("No."),
                              "Chargeable Filter" = FIELD("Chargeable Filter"),
                              "Service Zone Filter" = FIELD("Service Zone Filter"),
                              "Unit of Measure Filter" = FIELD("Unit of Measure Filter");
                Visible = true;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = FIELD("No."),
                              "Chargeable Filter" = FIELD("Chargeable Filter"),
                              "Service Zone Filter" = FIELD("Service Zone Filter"),
                              "Unit of Measure Filter" = FIELD("Unit of Measure Filter");
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
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
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
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Category4;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(156),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Category4;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Res: Record Resource;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Res);
                            DefaultDimMultiple.SetMultiRecord(Res, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action("&Picture")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Resource Picture";
                    RunPageLink = "No." = FIELD("No.");
                    ToolTip = 'View or add a picture of the resource or, for example, the company''s logo.';
                }
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Resource Units of Measure";
                    RunPageLink = "Resource No." = FIELD("No.");
                    ToolTip = 'View or edit the units of measure that are set up for the resource.';
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                Enabled = (BlockedFilterApplied and (not Blocked)) or not BlockedFilterApplied;
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
                        Resource: Record Resource;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        ResourceRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Resource);
                        Resource.Next;

                        if Resource.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Resource.RecordId)
                        else begin
                            ResourceRecordRef.GetTable(Resource);
                            CRMIntegrationManagement.UpdateMultipleNow(ResourceRecordRef);
                        end
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
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            Resource: Record Resource;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Resource);
                            RecRef.GetTable(Resource);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
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
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or change detailed information about costs for the resource.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';
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
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View or edit prices for the resource.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';
                }
                action(PurchPriceLists)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Purchase Prices';
                    Image = ResourceCosts;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or change detailed information about costs for the resource.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Any);
                    end;
                }
                action(SalesPriceLists)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sales Prices';
                    Image = LineDiscount;
                    Promoted = true;
                    PromotedCategory = Category6;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or edit prices for the resource.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any);
                    end;
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
                    RunObject = Page "Resource Capacity";
                    RunPageOnRec = true;
                    ToolTip = 'View this job''s resource capacity.';
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
                    PromotedCategory = Category5;
                    RunObject = Page "Resource Availability";
                    RunPageLink = "No." = FIELD("No."),
                                  "Unit of Measure Filter" = FIELD("Unit of Measure Filter"),
                                  "Chargeable Filter" = FIELD("Chargeable Filter");
                    ToolTip = 'View a summary of resource capacities, the quantity of resource hours allocated to jobs on order, the quantity allocated to service orders, the capacity assigned to jobs on quote, and the resource availability.';
                }
            }
        }
        area(creation)
        {
            action("New Resource Group")
            {
                ApplicationArea = Jobs;
                Caption = 'New Resource Group';
                Image = NewResourceGroup;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Resource Groups";
                RunPageMode = Create;
                ToolTip = 'Create a new resource.';
            }
        }
        area(reporting)
        {
            action("Resource - List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - List';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource - List";
                ToolTip = 'View the list of resources.';
            }
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
            action("Resource - Price List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Price List';
                Image = "Report";
                Visible = not ExtendedPriceEnabled;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Resource - Price List";
                ToolTip = 'Specifies a list of unit prices for the selected resources. By default, a unit price is based on the price in the Resource Prices window. If there is no valid alternative price, then the unit price from the resource card is used. The report can be used by the company''s salespeople or sent to customers.';
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                ObsoleteTag = '17.0';
            }
            action("Res. Price List")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource - Price List';
                Image = "Report";
                Visible = ExtendedPriceEnabled;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Res. Price List";
                ToolTip = 'Specifies a list of unit prices for the selected resources. By default, a unit price is based on the price in the Resource Prices window. If there is no valid alternative price, then the unit price from the resource card is used. The report can be used by the company''s salespeople or sent to customers.';
            }
            action("Resource Register")
            {
                ApplicationArea = Jobs;
                Caption = 'Resource Register';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Resource Register";
                ToolTip = 'View a list of all the resource registers. Every time a resource entry is posted, a register is created. Every register shows the first and last entry numbers of its entries. You can use the information in a resource register to document when entries were posted.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Time Sheets")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create Time Sheets';
                    Ellipsis = true;
                    Image = NewTimesheet;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create new time sheets for the selected resource.';

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
        CRMIsCoupledToRecord := CRMIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(RecordId);
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled;
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('RESOURCE-PRODUCT') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field38=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Resource: Record Resource;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Resource);
        exit(SelectionFilterManagement.GetSelectionFilterForResource(Resource));
    end;

    procedure SetSelection(var Resource: Record Resource)
    begin
        CurrPage.SetSelectionFilter(Resource);
    end;
}

