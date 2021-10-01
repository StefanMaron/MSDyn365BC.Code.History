page 5703 "Location Card"
{
    Caption = 'Location Card';
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Location';
    SourceTable = Location;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name or address of the location.';
                }
                field("Use As In-Transit"; Rec."Use As In-Transit")
                {
                    ApplicationArea = Location;
                    Editable = EditInTransit;
                    ToolTip = 'Specifies that this location is an in-transit location.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(AddressDetails)
                {
                    Caption = 'Address';
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the location address.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the city of the location.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Location;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = TRUE;
                        ToolTip = 'Specifies the address of the location on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update();
                            Rec.DisplayMap();
                        end;
                    }
                }
                group(ContactDetails)
                {
                    Caption = 'Contact';
                    field(Contact; Rec.Contact)
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the name of the contact person at the location';
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = Location;
                        Importance = Promoted;
                        ToolTip = 'Specifies the telephone number of the location.';
                    }
                    field("Fax No."; Rec."Fax No.")
                    {
                        ApplicationArea = Location;
                        Importance = Additional;
                        ToolTip = 'Specifies the fax number of the location.';
                    }
                    field("E-Mail"; Rec."E-Mail")
                    {
                        ApplicationArea = Location;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the location.';
                    }
                    field("Home Page"; Rec."Home Page")
                    {
                        ApplicationArea = Location;
                        ToolTip = 'Specifies the location''s web site.';
                    }
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                field("Require Receive"; Rec."Require Receive")
                {
                    ApplicationArea = Warehouse;
                    Enabled = RequireReceiveEnable;
                    ToolTip = 'Specifies if the location requires a receipt document when receiving items.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Require Shipment"; Rec."Require Shipment")
                {
                    ApplicationArea = Warehouse;
                    Enabled = RequireShipmentEnable;
                    ToolTip = 'Specifies if the location requires a shipment document when shipping items.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Require Put-away"; Rec."Require Put-away")
                {
                    ApplicationArea = Warehouse;
                    Enabled = RequirePutAwayEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the location requires a dedicated warehouse activity when putting items away.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Use Put-away Worksheet"; Rec."Use Put-away Worksheet")
                {
                    ApplicationArea = Warehouse;
                    Enabled = UsePutAwayWorksheetEnable;
                    ToolTip = 'Specifies if put-aways for posted warehouse receipts must be created with the put-away worksheet. If the check box is not selected, put-aways are created directly when you post a warehouse receipt.';
                }
                field("Require Pick"; Rec."Require Pick")
                {
                    ApplicationArea = Warehouse;
                    Enabled = RequirePickEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the location requires a dedicated warehouse activity when picking items.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Bin Mandatory"; Rec."Bin Mandatory")
                {
                    ApplicationArea = Warehouse;
                    Enabled = BinMandatoryEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the location requires that a bin code is specified on all item transactions.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Directed Put-away and Pick"; Rec."Directed Put-away and Pick")
                {
                    ApplicationArea = Warehouse;
                    Enabled = DirectedPutawayandPickEnable;
                    ToolTip = 'Specifies if the location requires advanced warehouse functionality, such as calculated bin suggestion.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Use ADCS"; "Use ADCS")
                {
                    ApplicationArea = Warehouse;
                    Enabled = UseADCSEnable;
                    ToolTip = 'Specifies the automatic data capture system that warehouse employees must use to keep track of items within the warehouse.';
                    Visible = false;
                }
                field("Default Bin Selection"; Rec."Default Bin Selection")
                {
                    ApplicationArea = Warehouse;
                    Enabled = DefaultBinSelectionEnable;
                    ToolTip = 'Specifies the method used to select the default bin.';
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Enabled = OutboundWhseHandlingTimeEnable;
                    ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Enabled = InboundWhseHandlingTimeEnable;
                    ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Warehouse;
                    Enabled = BaseCalendarCodeEnable;
                    ToolTip = 'Specifies a customizable calendar for planning that holds the location''s working days and holidays.';
                }
                field("Customized Calendar"; format(CalendarMgmt.CustomizedChangesExist(Rec)))
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customized Calendar';
                    Editable = false;
                    ToolTip = 'Specifies if the location has a customized calendar with working days that are different from those in the company''s base calendar.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord;
                        Rec.TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
                }
                field("Use Cross-Docking"; Rec."Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    Enabled = UseCrossDockingEnable;
                    ToolTip = 'Specifies if the location supports movement of items directly from the receiving dock to the shipping dock.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Cross-Dock Due Date Calc."; Rec."Cross-Dock Due Date Calc.")
                {
                    ApplicationArea = Warehouse;
                    Enabled = CrossDockDueDateCalcEnable;
                    ToolTip = 'Specifies the cross-dock due date calculation.';
                }
            }
            group(Bins)
            {
                Caption = 'Bins';
                group(Receipt)
                {
                    Caption = 'Receipt';
                    field("Receipt Bin Code"; Rec."Receipt Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = ReceiptBinCodeEnable;
                        Importance = Promoted;
                        ToolTip = 'Specifies the default receipt bin code.';
                    }
                }
                group(Shipment)
                {
                    Caption = 'Shipment';
                    field("Shipment Bin Code"; Rec."Shipment Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = ShipmentBinCodeEnable;
                        Importance = Promoted;
                        ToolTip = 'Specifies the default shipment bin code.';
                    }
                }
                group(Production)
                {
                    Caption = 'Production';
                    field("Open Shop Floor Bin Code"; Rec."Open Shop Floor Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = OpenShopFloorBinCodeEnable;
                        ToolTip = 'Specifies the bin that functions as the default open shop floor bin.';
                    }
                    field("To-Production Bin Code"; Rec."To-Production Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = ToProductionBinCodeEnable;
                        ToolTip = 'Specifies the bin in the production area where components picked for production are placed by default, before they can be consumed.';
                    }
                    field("From-Production Bin Code"; Rec."From-Production Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = FromProductionBinCodeEnable;
                        ToolTip = 'Specifies the bin in the production area, where finished end items are taken from by default, when the process involves warehouse activity.';
                    }
                }
                group(Adjustment)
                {
                    Caption = 'Adjustment';
                    field("Adjustment Bin Code"; Rec."Adjustment Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = AdjustmentBinCodeEnable;
                        ToolTip = 'Specifies the code of the bin in which you record observed differences in inventory quantities.';
                    }
                }
                group("Cross-Dock")
                {
                    Caption = 'Cross-Dock';
                    field("Cross-Dock Bin Code"; Rec."Cross-Dock Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = CrossDockBinCodeEnable;
                        ToolTip = 'Specifies the bin code that is used by default for the receipt of items to be cross-docked.';
                    }
                }
                group(Assembly)
                {
                    Caption = 'Assembly';
                    field("To-Assembly Bin Code"; Rec."To-Assembly Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = ToAssemblyBinCodeEnable;
                        ToolTip = 'Specifies the bin in the assembly area where components are placed by default before they can be consumed in assembly.';
                    }
                    field("From-Assembly Bin Code"; Rec."From-Assembly Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = FromAssemblyBinCodeEnable;
                        ToolTip = 'Specifies the bin in the assembly area where finished assembly items are posted to when they are assembled to stock.';
                    }
                    field("Asm.-to-Order Shpt. Bin Code"; Rec."Asm.-to-Order Shpt. Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = AssemblyShipmentBinCodeEnable;
                        ToolTip = 'Specifies the bin where finished assembly items are posted to when they are assembled to a linked sales order.';
                    }
                }
            }
            group("Bin Policies")
            {
                Caption = 'Bin Policies';
                field("Special Equipment"; Rec."Special Equipment")
                {
                    ApplicationArea = Warehouse;
                    Enabled = SpecialEquipmentEnable;
                    ToolTip = 'Specifies where the program will first looks for special equipment designated for warehouse activities.';
                }
                field("Bin Capacity Policy"; Rec."Bin Capacity Policy")
                {
                    ApplicationArea = Warehouse;
                    Enabled = BinCapacityPolicyEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies how bins are automatically filled, according to their capacity.';
                }
                field("Allow Breakbulk"; Rec."Allow Breakbulk")
                {
                    ApplicationArea = Warehouse;
                    Enabled = AllowBreakbulkEnable;
                    ToolTip = 'Specifies that an order can be fulfilled with items stored in alternate units of measure, if an item stored in the requested unit of measure is not found.';
                }
                group("Put-away")
                {
                    Caption = 'Put-away';
                    field("Put-away Template Code"; Rec."Put-away Template Code")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = PutAwayTemplateCodeEnable;
                        ToolTip = 'Specifies the put-away template to be used at this location.';
                    }
                    field("Always Create Put-away Line"; Rec."Always Create Put-away Line")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = AlwaysCreatePutawayLineEnable;
                        ToolTip = 'Specifies that a put-away line is created, even if an appropriate zone and bin in which to place the items cannot be found.';
                    }
                }
                group(Pick)
                {
                    Caption = 'Pick';
                    field("Always Create Pick Line"; Rec."Always Create Pick Line")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = AlwaysCreatePickLineEnable;
                        ToolTip = 'Specifies that a pick line is created, even if an appropriate zone and bin from which to pick the item cannot be found.';
                    }
                    field("Pick According to FEFO"; Rec."Pick According to FEFO")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = PickAccordingToFEFOEnable;
                        Importance = Promoted;
                        ToolTip = 'Specifies whether to use the First-Expired-First-Out (FEFO) method to determine which items to pick, according to expiration dates.';
                    }
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
                    PromotedCategory = Process;
                    RunObject = Page Zones;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about zones that you use at this location to structure your bins.';
                }
                action("&Bins")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bins';
                    Image = Bins;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Bins;
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'View or edit information about bins that you use at this location to hold items.';
                }
                action("Inventory Posting Setup")
                {
                    ApplicationArea = Location;
                    Caption = 'Inventory Posting Setup';
                    Image = PostedInventoryPick;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    RunObject = Page "Inventory Posting Setup";
                    RunPageLink = "Location Code" = FIELD(Code);
                    ToolTip = 'Set up links between inventory posting groups, inventory locations, and general ledger accounts to define where transactions for inventory items are recorded in the general ledger.';
                }
                action("Online Map")
                {
                    ApplicationArea = Location;
                    Caption = 'Online Map';
                    Image = Map;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    ToolTip = 'View the address on an online map.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateEnabled();
        TransitValidation;
    end;

    trigger OnInit()
    begin
        UseCrossDockingEnable := true;
        UsePutAwayWorksheetEnable := true;
        BinMandatoryEnable := true;
        RequireShipmentEnable := true;
        RequireReceiveEnable := true;
        RequirePutAwayEnable := true;
        RequirePickEnable := true;
        DefaultBinSelectionEnable := true;
        UseADCSEnable := true;
        DirectedPutawayandPickEnable := true;
        CrossDockBinCodeEnable := true;
        PickAccordingToFEFOEnable := true;
        AdjustmentBinCodeEnable := true;
        ShipmentBinCodeEnable := true;
        ReceiptBinCodeEnable := true;
        FromProductionBinCodeEnable := true;
        ToProductionBinCodeEnable := true;
        OpenShopFloorBinCodeEnable := true;
        ToAssemblyBinCodeEnable := true;
        FromAssemblyBinCodeEnable := true;
        AssemblyShipmentBinCodeEnable := true;
        CrossDockDueDateCalcEnable := true;
        AlwaysCreatePutawayLineEnable := true;
        AlwaysCreatePickLineEnable := true;
        PutAwayTemplateCodeEnable := true;
        AllowBreakbulkEnable := true;
        SpecialEquipmentEnable := true;
        BinCapacityPolicyEnable := true;
        BaseCalendarCodeEnable := true;
        InboundWhseHandlingTimeEnable := true;
        OutboundWhseHandlingTimeEnable := true;
        EditInTransit := true;
    end;

    var
        CalendarMgmt: Codeunit "Calendar Management";
        [InDataSet]
        OutboundWhseHandlingTimeEnable: Boolean;
        [InDataSet]
        InboundWhseHandlingTimeEnable: Boolean;
        [InDataSet]
        BaseCalendarCodeEnable: Boolean;
        [InDataSet]
        BinCapacityPolicyEnable: Boolean;
        [InDataSet]
        SpecialEquipmentEnable: Boolean;
        [InDataSet]
        AllowBreakbulkEnable: Boolean;
        [InDataSet]
        PutAwayTemplateCodeEnable: Boolean;
        [InDataSet]
        AlwaysCreatePickLineEnable: Boolean;
        [InDataSet]
        AlwaysCreatePutawayLineEnable: Boolean;
        [InDataSet]
        CrossDockDueDateCalcEnable: Boolean;
        [InDataSet]
        OpenShopFloorBinCodeEnable: Boolean;
        [InDataSet]
        ToProductionBinCodeEnable: Boolean;
        [InDataSet]
        FromProductionBinCodeEnable: Boolean;
        [InDataSet]
        ReceiptBinCodeEnable: Boolean;
        [InDataSet]
        ShipmentBinCodeEnable: Boolean;
        [InDataSet]
        AdjustmentBinCodeEnable: Boolean;
        [InDataSet]
        ToAssemblyBinCodeEnable: Boolean;
        [InDataSet]
        FromAssemblyBinCodeEnable: Boolean;
        AssemblyShipmentBinCodeEnable: Boolean;
        [InDataSet]
        PickAccordingToFEFOEnable: Boolean;
        [InDataSet]
        CrossDockBinCodeEnable: Boolean;
        [InDataSet]
        DirectedPutawayandPickEnable: Boolean;
        [InDataSet]
        UseADCSEnable: Boolean;
        [InDataSet]
        DefaultBinSelectionEnable: Boolean;
        [InDataSet]
        RequirePickEnable: Boolean;
        [InDataSet]
        RequirePutAwayEnable: Boolean;
        [InDataSet]
        RequireReceiveEnable: Boolean;
        [InDataSet]
        RequireShipmentEnable: Boolean;
        [InDataSet]
        BinMandatoryEnable: Boolean;
        [InDataSet]
        UsePutAwayWorksheetEnable: Boolean;
        [InDataSet]
        UseCrossDockingEnable: Boolean;
        [InDataSet]
        EditInTransit: Boolean;
        ShowMapLbl: Label 'Show on Map';

    procedure UpdateEnabled()
    begin
        RequirePickEnable := not Rec."Use As In-Transit" and not Rec."Directed Put-away and Pick";
        RequirePutAwayEnable := not Rec."Use As In-Transit" and not Rec."Directed Put-away and Pick";
        RequireReceiveEnable := not Rec."Use As In-Transit" and not Rec."Directed Put-away and Pick";
        RequireShipmentEnable := not Rec."Use As In-Transit" and not Rec."Directed Put-away and Pick";
        OutboundWhseHandlingTimeEnable := not Rec."Use As In-Transit";
        InboundWhseHandlingTimeEnable := not Rec."Use As In-Transit";
        BinMandatoryEnable := not Rec."Use As In-Transit" and not Rec."Directed Put-away and Pick";
        DirectedPutawayandPickEnable := not Rec."Use As In-Transit" and Rec."Bin Mandatory";
        BaseCalendarCodeEnable := not Rec."Use As In-Transit";

        BinCapacityPolicyEnable := Rec."Directed Put-away and Pick";
        SpecialEquipmentEnable := Rec."Directed Put-away and Pick";
        AllowBreakbulkEnable := Rec."Directed Put-away and Pick";
        PutAwayTemplateCodeEnable := Rec."Directed Put-away and Pick";
        UsePutAwayWorksheetEnable :=
          Rec."Directed Put-away and Pick" or (Rec."Require Put-away" and Rec."Require Receive" and not Rec."Use As In-Transit");
        AlwaysCreatePickLineEnable := Rec."Directed Put-away and Pick";
        AlwaysCreatePutawayLineEnable := Rec."Directed Put-away and Pick";

        UseCrossDockingEnable :=
            not Rec."Use As In-Transit" and Rec."Require Receive" and Rec."Require Shipment" and Rec."Require Put-away" and Rec."Require Pick";
        CrossDockDueDateCalcEnable := Rec."Use Cross-Docking";

        OpenShopFloorBinCodeEnable := Rec."Bin Mandatory";
        ToProductionBinCodeEnable := Rec."Bin Mandatory";
        FromProductionBinCodeEnable := Rec."Bin Mandatory";
        ReceiptBinCodeEnable := Rec."Bin Mandatory" and Rec."Require Receive";
        ShipmentBinCodeEnable := Rec."Bin Mandatory" and Rec."Require Shipment";
        AdjustmentBinCodeEnable := Rec."Directed Put-away and Pick";
        CrossDockBinCodeEnable := Rec."Bin Mandatory" and Rec."Use Cross-Docking";
        ToAssemblyBinCodeEnable := Rec."Bin Mandatory";
        FromAssemblyBinCodeEnable := Rec."Bin Mandatory";
        AssemblyShipmentBinCodeEnable := Rec."Bin Mandatory" and not ShipmentBinCodeEnable;
        DefaultBinSelectionEnable := Rec."Bin Mandatory" and not Rec."Directed Put-away and Pick";
        UseADCSEnable := not Rec."Use As In-Transit" and Rec."Directed Put-away and Pick";
        PickAccordingToFEFOEnable := Rec."Require Pick" and Rec."Bin Mandatory";
    end;

    local procedure TransitValidation()
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.SetRange("In-Transit Code", Code);
        EditInTransit := TransferHeader.IsEmpty;
    end;
}

