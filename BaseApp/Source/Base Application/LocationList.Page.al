page 15 "Location List"
{
    AdditionalSearchTerms = 'warehouse setup,inventory setup';
    ApplicationArea = Location;
    Caption = 'Locations';
    CardPageID = "Location Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Navigate';
    SourceTable = Location;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name or address of the location.';
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
        area(navigation)
        {
            group("&Location")
            {
                Caption = '&Location';
                Image = Warehouse;
                action("&Resource Locations")
                {
                    ApplicationArea = Location;
                    Caption = '&Resource Locations';
                    Image = Resource;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Resource Locations";
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about where resources are located. In this window, you can assign resources to locations.';
                }
                action("&Zones")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Zones';
                    Image = Zones;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page Zones;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to structure your bins under zones.';
                }
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use in your warehouse to hold items.';
                }
            }
        }
        area(creation)
        {
            action("Transfer Order")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Order';
                Image = Document;
                Promoted = true;
                PromotedCategory = New;
                RunObject = Page "Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Prepare to transfer items to another location.';
            }
        }
        area(processing)
        {
            action("Create Warehouse location")
            {
                ApplicationArea = Warehouse;
                Caption = 'Create Warehouse location';
                Image = NewWarehouse;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Report "Create Warehouse Location";
                ToolTip = 'Enable the inventory location to use zones and bins to operate as a warehouse location. The batch job creates initial warehouse entries for the warehouse adjustment bin for all items that have inventory in the location. It is necessary to perform a physical inventory after this batch job is finished so that these initial entries can be balanced by posting warehouse physical inventory entries.';
            }
        }
        area(reporting)
        {
            action("Inventory - Inbound Transfer")
            {
                ApplicationArea = Location;
                Caption = 'Inventory - Inbound Transfer';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Inventory - Inbound Transfer";
                ToolTip = 'View the list of inbound transfers to the location.';
            }
            action(Action1907283206)
            {
                ApplicationArea = Location;
                Caption = 'Transfer Order';
                Image = Document;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Transfer Order";
                ToolTip = 'Prepare to transfer items to another location.';
            }
            action("Transfer Shipment")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Shipment';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Transfer Shipment";
                ToolTip = 'View the list of posted outbound transfers from the location.';
            }
            action("Transfer Receipt")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Receipt';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Transfer Receipt";
                ToolTip = 'View the list of posted inbound transfers to the location.';
            }
            action("Items with Negative Inventory")
            {
                ApplicationArea = Location;
                Caption = 'Items with Negative Inventory';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                PromotedOnly = true;
                RunObject = Report "Items with Negative Inventory";
                ToolTip = 'View a list of items with negative inventory.';
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        Loc: Record Location;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Loc);
        exit(SelectionFilterManagement.GetSelectionFilterForLocation(Loc));
    end;
}

