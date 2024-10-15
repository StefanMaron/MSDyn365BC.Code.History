#if not CLEAN18
page 900 "Assembly Order"
{
    Caption = 'Assembly Order';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Release,Warehouse,Posting,Print,Navigate,Order';
    RefreshOnActivate = true;
    SourceTable = "Assembly Header";
    SourceTableView = SORTING("Document Type", "No.")
                      ORDER(Ascending)
                      WHERE("Document Type" = CONST(Order));

    layout
    {
        area(content)
        {
            group(Control2)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Assembly;
                    AssistEdit = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ShowMandatory = true;
                    TableRelation = Item."No." WHERE("Assembly BOM" = CONST(true));
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(Quantity; Quantity)
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        Importance = Promoted;
                        BlankZero = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord;
                        end;
                    }
                    field("Quantity to Assemble"; "Quantity to Assemble")
                    {
                        ApplicationArea = Assembly;
                        Importance = Promoted;
                        ToolTip = 'Specifies how many of the assembly item units you want to partially post. To post the full quantity on the assembly order, leave the field unchanged.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord;
                        end;
                    }
                    field("Unit of Measure Code"; "Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                        trigger OnValidate()
                        begin
                            CurrPage.SaveRecord;
                        end;
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Assembly;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the assembly order is posted.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Assembly;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                    end;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Remaining Quantity"; "Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                }
                field("Assembled Quantity"; "Assembled Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item are posted as assembled output.';
                }
                field("Reserved Quantity"; "Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the assembly item are reserved for this assembly order header.';
                    Visible = false;
                }
                field("Assemble to Order"; "Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order is linked to a sales order, which indicates that the item is assembled to order.';

                    trigger OnDrillDown()
                    begin
                        ShowAsmToOrder;
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the document is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                }
            }
            part(Lines; "Assembly Order Subform")
            {
                ApplicationArea = Assembly;
                Caption = 'Lines';
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                    end;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                    end;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = IsAsmToOrderEditable;
                    ToolTip = 'Specifies the bin the assembly item is posted to as output and from where it is taken to storage or shipped if it is assembled to a sales order.';

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord;
                    end;
                }
                field("Indirect Cost %"; "Indirect Cost %")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
                    Visible = false;
                }
                field("Overhead Rate"; "Overhead Rate")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the indirect cost of the assembly item as an absolute amount.';
                    Visible = false;
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Assembly;
                    Editable = IsUnitCostEditable;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the total unit cost of the assembly order.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for the Gen. Bus. Posting Group that applies to the entry.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Advanced Localization Pack for Czech.';
                    ObsoleteTag = '18.0';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
        }
        area(factboxes)
        {
            part(Control11; "Assembly Item - Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = FIELD("Item No.");
            }
            part(Control44; "Component - Item FactBox")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
            }
            part(Control43; "Component - Resource Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = FIELD("No.");
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control9; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Item Availability by")
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;
                action("Event")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Event';
                    Image = "Event";
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByEvent);
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Period';
                    Image = Period;
                    ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByPeriod);
                    end;
                }
                action(Variant)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant';
                    Image = ItemVariant;
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByVariant);
                    end;
                }
                action(Location)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Location';
                    Image = Warehouse;
                    ToolTip = 'View the actual and projected quantity of the item per location.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByLocation);
                    end;
                }
                action(Lot)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot';
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                    ToolTip = 'View the current and projected quantity of the item in each lot.';
                }
                action("BOM Level")
                {
                    ApplicationArea = Assembly;
                    Caption = 'BOM Level';
                    Image = BOMLevel;
                    ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                    trigger OnAction()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromAsmHeader(Rec, ItemAvailFormsMgt.ByBOM);
                    end;
                }
            }
            group(General)
            {
                Caption = 'General';
                Image = AssemblyBOM;
                action("Assembly BOM")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly BOM';
                    Image = AssemblyBOM;
                    Promoted = true;
                    PromotedCategory = Category8;
                    ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';

                    trigger OnAction()
                    begin
                        ShowAssemblyList;
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action("Item Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category8;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category9;
                    RunObject = Page "Assembly Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                Image = Statistics;
                action(Action14)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category9;
                    PromotedIsBig = true;
                    RunPageOnRec = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        ShowStatistics;
                    end;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Pick Lines/Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines/Movement Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Source Type" = CONST(901),
                                  "Source Subtype" = CONST("1"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk");
                    ToolTip = 'View the related picks or movements.';
                }
                action("Registered P&ick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered P&ick Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Source Type" = CONST(901),
                                  "Source Subtype" = CONST("1"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    ToolTip = 'View the list of warehouse picks that have been made for the order.';
                }
                action("Registered Invt. Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Invt. Movement Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Reg. Invt. Movement Lines";
                    RunPageLink = "Source Type" = CONST(901),
                                  "Source Subtype" = CONST("1"),
                                  "Source No." = FIELD("No.");
                    RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
                    ToolTip = 'View the list of inventory movements that have been made for the order.';
                }
                action("Asm.-to-Order Whse. Shpt. Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Asm.-to-Order Whse. Shpt. Line';
                    Enabled = NOT IsAsmToOrderEditable;
                    Image = ShipmentLines;
                    ToolTip = 'View the list of warehouse shipment lines that exist for sales orders that are linked to this assembly order as assemble-to-order links. ';

                    trigger OnAction()
                    var
                        ATOLink: Record "Assemble-to-Order Link";
                        WhseShptLine: Record "Warehouse Shipment Line";
                    begin
                        TestField("Assemble to Order", true);
                        ATOLink.Get("Document Type", "No.");
                        WhseShptLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Assemble to Order");
                        WhseShptLine.SetRange("Source Type", DATABASE::"Sales Line");
                        WhseShptLine.SetRange("Source Subtype", ATOLink."Document Type");
                        WhseShptLine.SetRange("Source No.", ATOLink."Document No.");
                        WhseShptLine.SetRange("Source Line No.", ATOLink."Document Line No.");
                        WhseShptLine.SetRange("Assemble to Order", true);
                        PAGE.RunModal(PAGE::"Asm.-to-Order Whse. Shpt. Line", WhseShptLine);
                    end;
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                group(Entries)
                {
                    Caption = 'Entries';
                    Image = Entries;
                    action("Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Ledger Entries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                    }
                    action("Capacity Ledger Entries")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Capacity Ledger Entries';
                        Image = CapacityLedger;
                        RunObject = Page "Capacity Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                    }
                    action("Resource Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Ledger Entries';
                        Image = ResourceLedger;
                        RunObject = Page "Resource Ledger Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the ledger entries for the resource.';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Order Type" = CONST(Assembly),
                                      "Order No." = FIELD("No.");
                        RunPageView = SORTING("Order Type", "Order No.");
                        ToolTip = 'View the value entries of the item on the document or journal line.';
                    }
                    action("Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Source Type" = FILTER(83 | 901),
                                      "Source Subtype" = FILTER("1" | "6"),
                                      "Source No." = FIELD("No.");
                        RunPageView = SORTING("Source Type", "Source Subtype", "Source No.");
                        ToolTip = 'View completed warehouse activities related to the document.';
                    }
                    action("Reservation Entries")
                    {
                        AccessByPermission = TableData Item = R;
                        ApplicationArea = Reservation;
                        Caption = 'Reservation Entries';
                        Image = ReservationLedger;
                        ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                        trigger OnAction()
                        begin
                            ShowReservationEntries(true);
                        end;
                    }
                }
                action("Posted Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Posted Assembly Orders';
                    Image = PostedOrder;
                    RunObject = Page "Posted Assembly Orders";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View completed assembly orders.';
                }
            }
            separator(Action52)
            {
            }
        }
        area(processing)
        {
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                separator(Action49)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
                    begin
                        ReleaseAssemblyDoc.Reopen(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ShowAvailability)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Availability';
                    Image = ItemAvailbyLoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View how many of the assembly order quantity can be assembled by the due date based on availability of the required components. This is shown in the Able to Assemble field. ';

                    trigger OnAction()
                    begin
                        ShowAvailability;
                    end;
                }
                action("Refresh availability warnings")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Refresh Availability';
                    Image = RefreshLines;
                    ToolTip = 'Check items availability and refresh warnings';

                    trigger OnAction()
                    begin
                        UpdateWarningOnLines()
                    end;
                }
                action("Update Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Unit Cost';
                    Enabled = IsUnitCostEditable;
                    Image = UpdateUnitCost;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Update the cost of the parent item per changes to the assembly BOM.';

                    trigger OnAction()
                    begin
                        UpdateUnitCost;
                    end;
                }
                action("Refresh Lines")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Refresh Lines';
                    Image = RefreshLines;
                    ToolTip = 'Update information on the lines according to changes that you made on the header.';

                    trigger OnAction()
                    begin
                        RefreshBOM;
                        CurrPage.Update();
                    end;
                }
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Ellipsis = true;
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        ShowReservation();
                    end;
                }
                action("Copy Document")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Copy Document';
                    Image = CopyDocument;
                    ToolTip = 'Copy document lines and header information from another sales document to this document. You can copy a posted sales invoice into a new sales invoice to quickly create a similar document.';

                    trigger OnAction()
                    var
                        CopyAssemblyDocument: Report "Copy Assembly Document";
                    begin
                        CopyAssemblyDocument.SetAssemblyHeader(Rec);
                        CopyAssemblyDocument.RunModal;
                        if Get("Document Type", "No.") then;
                    end;
                }
                separator(Action53)
                {
                }
            }
            group(Action80)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Create Inventor&y Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Movement';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Create an inventory movement to handle items on the document according to a basic warehouse configuration.';

                    trigger OnAction()
                    var
                        ATOMovementsCreated: Integer;
                        TotalATOMovementsToBeCreated: Integer;
                    begin
                        CreateInvtMovement(false, false, false, ATOMovementsCreated, TotalATOMovementsToBeCreated);
                    end;
                }
                action("Create Warehouse Pick")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Pick';
                    Image = CreateWarehousePick;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Prepare to create warehouse picks for the lines on the order. When you have selected options and you run the function, a warehouse pick document are created for the assembly order components.';

                    trigger OnAction()
                    begin
                        CreatePick(true, UserId, 0, false, false, false);
                    end;
                }
                action("Order &Tracking")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        ShowTracking();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Assembly;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Enabled = IsAsmToOrderEditable;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Assembly-Post (Yes/No)", Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Assembly Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Print)
            {
                Caption = 'Print';
                Image = Print;
                action("Order")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Order';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Print the assembly order.';

                    trigger OnAction()
                    var
                        DocPrint: Codeunit "Document-Print";
                    begin
                        DocPrint.PrintAsmHeader(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsUnitCostEditable := not IsStandardCostItem;
        IsAsmToOrderEditable := not IsAsmToOrder;
        UpdateWarningOnLines();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
    begin
        TestField("Assemble to Order", false);
        if (Quantity <> 0) and ItemExists("Item No.") then begin
            Commit();
            if not AssemblyHeaderReserve.DeleteLineConfirm(Rec) then
                exit(false);
            AssemblyHeaderReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnOpenPage()
    begin
        IsUnitCostEditable := true;
        IsAsmToOrderEditable := true;
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";

    protected var
        [InDataSet]
        IsUnitCostEditable: Boolean;
        [InDataSet]
        IsAsmToOrderEditable: Boolean;
}

#endif
