page 7335 "Warehouse Shipment"
{
    Caption = 'Warehouse Shipment';
    PageType = Document;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Release,Posting,Shipment';
    RefreshOnActivate = true;
    SourceTable = "Warehouse Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location from which the items are being shipped.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord;
                        LookupLocation(Rec);
                        CurrPage.Update(true);
                    end;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone on this shipment header.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the progress level of warehouse handling on lines in the warehouse shipment.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the shipment and is filled in by the program.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a posting date. If you enter a date, the posting date of the source documents is updated during posting.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; "Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; "Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; "Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the shipments are sorted.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate;
                    end;
                }
            }
            part(WhseShptLines; "Whse. Shipment Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = FIELD("No.");
                SubPageView = SORTING("No.", "Sorting Sequence No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseShptLines;
                SubPageLink = "No." = FIELD("Item No.");
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
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        LookupWhseShptHeader(Rec);
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category7;
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
                    Promoted = true;
                    PromotedCategory = Process;
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
                action("Posted &Whse. Shipments")
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
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Use Filters to Get Src. Docs.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Use Filters to Get Src. Docs.';
                    Ellipsis = true;
                    Image = UseFilters;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'retrieve the released source document lines that define which items to receive or ship.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        TestField(Status, Status::Open);
                        GetSourceDocOutbound.GetOutboundDocs(Rec);
                    end;
                }
                action("Get Source Documents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Get Source Documents';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Open the list of released source documents, such as sales orders, to select the document to ship items for. ';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        TestField(Status, Status::Open);
                        GetSourceDocOutbound.GetSingleOutboundDoc(Rec);
                    end;
                }
                separator(Action44)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedOnly = true;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        ReleaseWhseShptDoc.Reopen(Rec);
                    end;
                }
                separator(Action17)
                {
                }
                action("Autofill Qty. to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Ship';
                    Image = AutofillQtyToHandle;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Ship field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle;
                    end;
                }
                action("Delete Qty. to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Ship';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Ship field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle;
                    end;
                }
                separator(Action51)
                {
                }
                action("Create Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a warehouse pick for the items to be shipped.';

                    trigger OnAction()
                    begin
                        CurrPage.Update(true);
                        CurrPage.WhseShptLines.PAGE.PickCreate;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost Shipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost Shipment';
                    Ellipsis = true;
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the items as shipped. Related pick documents are registered automatically.';

                    trigger OnAction()
                    begin
                        PostShipmentYesNo;
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostShipmentPrintYesNo;
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseDocPrint.PrintShptHeader(Rec);
                end;
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

    var
        WhseDocPrint: Codeunit "Warehouse Document-Print";

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseShptLines.PAGE.AutofillQtyToHandle;
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseShptLines.PAGE.DeleteQtyToHandle;
    end;

    local procedure PostShipmentYesNo()
    begin
        CurrPage.WhseShptLines.PAGE.PostShipmentYesNo;
    end;

    local procedure PostShipmentPrintYesNo()
    begin
        CurrPage.WhseShptLines.PAGE.PostShipmentPrintYesNo;
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

