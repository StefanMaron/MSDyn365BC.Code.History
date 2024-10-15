page 12154 "Subcontr. Transfer Order"
{
    Caption = 'Subcontr. Transfer Order';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Transfer Header";
    SourceTableView = SORTING("No.")
                      WHERE("Subcontracting Order" = CONST(true));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that you are transferring items from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that you are transferring items to.';
                }
                field("In-Transit Code"; "In-Transit Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the transfer route for transferring items between locations.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the type of transaction that is the source of the transfer entry.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    ToolTip = 'Specifies the number of the source document from which the transfer entry originates.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the posting date of the document.';

                    trigger OnValidate()
                    begin
                        PostingDateOnAfterValidate;
                    end;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Completely Shipped"; "Completely Shipped")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the transfer order is fully shipped.';
                }
                field("Return Order"; "Return Order")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if a component of the subcontracting transfer order is a return.';
                }
            }
            part(TransferLines; "Subcontr.Transfer Ord. Subform")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Document No." = FIELD("No."),
                              "Derived From Line No." = CONST(0);
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                field("Transfer-from Name"; "Transfer-from Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the location that items are transferred from.';
                }
                field("Transfer-from Name 2"; "Transfer-from Name 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an additional part of the name of the location from which items are transferred.';
                }
                field("Transfer-from Address"; "Transfer-from Address")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                }
                field("Transfer-from Address 2"; "Transfer-from Address 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                }
                field("Transfer-from Post Code"; "Transfer-from Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the location that items are transferred from.';
                }
                field("Transfer-from City"; "Transfer-from City")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the city.';
                }
                field("Transfer-from Contact"; "Transfer-from Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the contact person at the transfer-from location.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the items were shipped.';

                    trigger OnValidate()
                    begin
                        ShipmentDateOnAfterValidate;
                    end;
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the time it takes from when the order is shipped from the warehouse to when the order is delivered to the customer''s address.';
                }
                field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the outbound warehouse handling time for the location. The program uses it to calculate date fields on the sales order line.';

                    trigger OnValidate()
                    begin
                        OutboundWhseHandlingTimeOnAfte;
                    end;
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the partial shipment is accepted.';
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                field("Transfer-to Name"; "Transfer-to Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the location that items are transferred to.';
                }
                field("Transfer-to Name 2"; "Transfer-to Name 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the location that items are transferred to.';
                }
                field("Transfer-to Address"; "Transfer-to Address")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the location that items are transferred from.';
                }
                field("Transfer-to Address 2"; "Transfer-to Address 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the location that items are transferred from.';
                }
                field("Transfer-to Post Code"; "Transfer-to Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the location that items are transferred to.';
                }
                field("Transfer-to City"; "Transfer-to City")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the city of the location that items are transferred from.';
                }
                field("Transfer-to Contact"; "Transfer-to Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the contact person at the transfer-to location.';
                }
                field("Receipt Date"; "Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of receipt.';

                    trigger OnValidate()
                    begin
                        ReceiptDateOnAfterValidate;
                    end;
                }
                field("Inbound Whse. Handling Time"; "Inbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the inbound warehouse handling time for the location.';

                    trigger OnValidate()
                    begin
                        InboundWhseHandlingTimeOnAfter;
                    end;
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Transport Reason Code"; "Transport Reason Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the transport reason codes in the Transfer Header table.';
                }
                field("Goods Appearance"; "Goods Appearance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a goods appearance code.';
                }
                field("Gross Weight"; "Gross Weight")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the gross weight of an item in the Transfer Header table.';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Parcel Units"; "Parcel Units")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of packages on a subcontractor order.';
                }
                field(Volume; Volume)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                }
                field("Shipping Notes"; "Shipping Notes")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the product''s shipping notes on a subcontractor order.';
                }
                field("Shipping Starting Date"; "Shipping Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date that the order is expected to ship.';
                }
                field("Shipping Starting Time"; "Shipping Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the time that the order is expected to ship.';
                }
                field("Freight Type"; "Freight Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the freight type that is associated with the documents in the Transfer Header table.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the shipment method.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company that handles the shipment.';

                    trigger OnValidate()
                    begin
                        ShippingAgentCodeOnAfterValida;
                    end;
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the company that handles the shipment.';

                    trigger OnValidate()
                    begin
                        ShippingAgentServiceCodeOnAfte;
                    end;
                }
            }
        }
        area(factboxes)
        {
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(List)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    RunObject = Page "Subcontracting Transfer List";
                    ShortCutKey = 'Shift+Ctrl+L';
                    ToolTip = 'View the list of all documents.';
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Transfer Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistics about the document.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Transfer Order"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or edit comments about the document.';
                }
                action("S&hipments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Transfer Shipments";
                    RunPageLink = "Transfer Order No." = FIELD("No.");
                    ToolTip = 'View the related shipments.';
                }
                action("Re&ceipts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&ceipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Transfer Receipts";
                    RunPageLink = "Transfer Order No." = FIELD("No.");
                    ToolTip = 'View the related receipts.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group(Warehouse)
                {
                    Caption = 'Warehouse';
                    Image = Warehouse;
                    action("Receipt Lines")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Receipt Lines';
                        RunObject = Page "Whse. Receipt Lines";
                        RunPageLink = "Source Type" = CONST(5741),
                                      "Source Subtype" = CONST("1"),
                                      "Source No." = FIELD("No.");
                        RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                        ToolTip = 'View the related receipt lines.';
                    }
                    action("Shipment Lines")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Shipment Lines';
                        RunObject = Page "Whse. Shipment Lines";
                        RunPageLink = "Source Type" = CONST(5741),
                                      "Source Subtype" = CONST("0"),
                                      "Source No." = FIELD("No.");
                        RunPageView = SORTING("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                        ToolTip = 'View the related shipment lines.';
                    }
                    action("Create Receipt")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create Receipt';
                        ToolTip = 'Create a receipt for the order.';

                        trigger OnAction()
                        var
                            GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                        begin
                            GetSourceDocInbound.CreateFromInbndTransferOrder(Rec);
                        end;
                    }
                    action("Create S&hipment")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create S&hipment';
                        ToolTip = 'Create a shipment for the order.';

                        trigger OnAction()
                        var
                            GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                        begin
                            GetSourceDocOutbound.CreateFromOutbndTransferOrder(Rec);
                        end;
                    }
                }
                action("Re&lease")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Release Transfer Document";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document.';
                }
                action("Reo&pen")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Reo&pen';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Reopen the document.';

                    trigger OnAction()
                    var
                        ReleaseTransferDoc: Codeunit "Release Transfer Document";
                    begin
                        ReleaseTransferDoc.Reopen(Rec);
                    end;
                }
                separator(Action1130119)
                {
                }
                action("Calculate Data For Shipping")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate Data For Shipping';
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Calculate data for shipping the order.';

                    trigger OnAction()
                    var
                        SubcontractingMgt: Codeunit SubcontractingManagement;
                    begin
                        CurrPage.SaveRecord;
                        SubcontractingMgt.CalculateHeaderValue(Rec);
                        CurrPage.Update;
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "TransferOrder-Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the document.';
                }
                action("Post and &Print")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Codeunit "TransferOrder-Post + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post the document and also print it.';
                }
            }
            action("&Print")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the transfer order.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintTransferHeader(Rec);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        TestField(Status, Status::Open);
    end;

    local procedure PostingDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure ShipmentDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure OutboundWhseHandlingTimeOnAfte()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure ReceiptDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure InboundWhseHandlingTimeOnAfter()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure ShippingAgentCodeOnAfterValida()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure ShippingAgentServiceCodeOnAfte()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;
}

