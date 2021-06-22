page 5768 "Warehouse Receipt"
{
    Caption = 'Warehouse Receipt';
    PageType = Document;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Posting,Receipt,Navigate';
    RefreshOnActivate = true;
    SourceTable = "Warehouse Receipt Header";

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
                    ToolTip = 'Specifies the code of the location in which the items are being received.';

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
                    ToolTip = 'Specifies the zone in which the items are being received if you are using directed put-away and pick.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the warehouse receipt.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date of the warehouse receipt.';
                }
                field("Vendor Shipment No."; "Vendor Shipment No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
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
                    ToolTip = 'Specifies the method by which the receipts are sorted.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate;
                    end;
                }
            }
            part(WhseReceiptLines; "Whse. Receipt Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = FIELD("No.");
                SubPageView = SORTING("No.", "Sorting Sequence No.");
            }
        }
        area(factboxes)
        {
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseReceiptLines;
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action(List)
                {
                    ApplicationArea = Location;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        LookupWhseRcptHeader(Rec);
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Whse. Receipt"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posted &Whse. Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted &Whse. Receipts';
                    Image = PostedReceipts;
                    Promoted = true;
                    PromotedCategory = Category7;
                    RunObject = Page "Posted Whse. Receipt List";
                    RunPageLink = "Whse. Receipt No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Receipt No.");
                    ToolTip = 'View the quantity that has been posted as received.';
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
                    ToolTip = 'Retrieve the released source document lines that define which items to receive or ship.';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        GetSourceDocInbound.GetInboundDocs(Rec);
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
                    ToolTip = 'Open the list of released source documents, such as purchase orders, to select the document to receive items for. ';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        GetSourceDocInbound.GetSingleInboundDoc(Rec);
                    end;
                }
                separator(Action24)
                {
                    Caption = '';
                }
                action("Autofill Qty. to Receive")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Receive';
                    Image = AutofillQtyToHandle;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Receive field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToReceive;
                    end;
                }
                action("Delete Qty. to Receive")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Receive';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Receive field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToReceive;
                    end;
                }
                separator(Action40)
                {
                }
                action(CalculateCrossDock)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Cross-Dock';
                    Image = CalculateCrossDock;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Open the Cross-Dock Opportunities window to see details about the lines requesting the item, such as type of document, quantity requested, and due date. This information might help you to decide how much to cross-dock, where to place the items in the cross-dock area, or how to group them.';

                    trigger OnAction()
                    var
                        CrossDockOpp: Record "Whse. Cross-Dock Opportunity";
                        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
                    begin
                        CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', "No.", "Location Code");
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Post Receipt")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost Receipt';
                    Image = PostOrder;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the items as received. A put-away document is created automatically.';

                    trigger OnAction()
                    begin
                        WhsePostRcptYesNo;
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        WhsePostRcptPrintPostedRcpt;
                    end;
                }
                action("Post and Print P&ut-away")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and Print P&ut-away';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+Ctrl+F9';
                    ToolTip = 'Post the items as received and print the put-away document.';

                    trigger OnAction()
                    begin
                        WhsePostRcptPrint;
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
                    WhseDocPrint.PrintRcptHeader(Rec);
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

    local procedure AutofillQtyToReceive()
    begin
        CurrPage.WhseReceiptLines.PAGE.AutofillQtyToReceive;
    end;

    local procedure DeleteQtyToReceive()
    begin
        CurrPage.WhseReceiptLines.PAGE.DeleteQtyToReceive;
    end;

    local procedure WhsePostRcptYesNo()
    begin
        CurrPage.WhseReceiptLines.PAGE.WhsePostRcptYesNo;
    end;

    local procedure WhsePostRcptPrint()
    begin
        CurrPage.WhseReceiptLines.PAGE.WhsePostRcptPrint;
    end;

    local procedure WhsePostRcptPrintPostedRcpt()
    begin
        CurrPage.WhseReceiptLines.PAGE.WhsePostRcptPrintPostedRcpt;
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

