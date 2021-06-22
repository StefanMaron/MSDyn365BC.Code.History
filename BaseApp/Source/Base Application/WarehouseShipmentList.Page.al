page 7339 "Warehouse Shipment List"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Shipments';
    CardPageID = "Warehouse Shipment";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Shipment Header";
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
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location from which the items are being shipped.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the shipments are sorted.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the shipment and is filled in by the program.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone on this shipment header.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the progress level of warehouse handling on lines in the warehouse shipment.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a posting date. If you enter a date, the posting date of the source documents is updated during posting.';
                    Visible = false;
                }
                field("Assignment Date"; "Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                    Visible = false;
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                    Visible = false;
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                    Visible = false;
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
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
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Whse. Shipment"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = CONST(Shipment),
                                  "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  WHERE("Activity Type" = CONST(Pick));
                    ToolTip = 'View the related picks.';
                }
                action("Registered P&ick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered P&ick Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
                                  WHERE("Whse. Document Type" = CONST(Shipment));
                    ToolTip = 'View the list of warehouse picks that have been made for the order.';
                }
                action("Posted &Warehouse Shipments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted &Warehouse Shipments';
                    Image = PostedReceipt;
                    RunObject = Page "Posted Whse. Shipment List";
                    RunPageLink = "Whse. Shipment No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Shipment No.");
                    ToolTip = 'View the quantity that has been posted as shipped.';
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Warehouse Shipment", Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. When a document is released, it will be included in all availability calculations from the expected receipt date of the items. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        CurrPage.Update(true);
                        if Status = Status::Open then
                            ReleaseWhseShptDoc.Release(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        ReleaseWhseShptDoc.Reopen(Rec);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        ErrorIfUserIsNotWhseEmployee;
        FilterGroup(2); // set group of filters user cannot change
        SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        FilterGroup(0); // set filter group back to standard
    end;
}

