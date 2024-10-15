page 7330 "Posted Whse. Receipt"
{
    Caption = 'Posted Whse. Receipt';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Posted Whse. Receipt Header";

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
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location where the items were received.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the code of the zone on this posted receipt header.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Document Status"; "Document Status")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the status of the posted warehouse receipt.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the receipt.';
                }
                field("Vendor Shipment No."; "Vendor Shipment No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s shipment number. It is inserted in the corresponding field on the source document during posting.';
                }
                field("Whse. Receipt No."; "Whse. Receipt No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the warehouse receipt that the posted warehouse receipt concerns.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
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
            }
            part(PostedWhseRcptLines; "Posted Whse. Receipt Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = FIELD("No.");
                SubPageView = SORTING("No.", "Line No.");
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        LookupPostedWhseRcptHeader(Rec);
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Posted Whse. Receipt"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Put-away Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Lines';
                    Image = PutawayLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = CONST(Receipt),
                                  "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  WHERE("Activity Type" = CONST("Put-away"));
                    ToolTip = ' View the related put-aways.';
                }
                action("Registered Put-away Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Put-away Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Whse. Document Type" = CONST(Receipt),
                                  "Whse. Document No." = FIELD("No.");
                    RunPageView = SORTING("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
                                  WHERE("Activity Type" = CONST("Put-away"));
                    ToolTip = 'View the list of completed put-away activities.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Put-away")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Put-away';
                    Ellipsis = true;
                    Image = CreatePutAway;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Create warehouse put-away for the received items. ';

                    trigger OnAction()
                    begin
                        CurrPage.Update(true);
                        CurrPage.PostedWhseRcptLines.PAGE.PutAwayCreate;
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
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseDocPrint.PrintPostedRcptHeader(Rec);
                end;
            }
        }
        area(reporting)
        {
            action("Put-away List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Put-away List';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Put-away List";
                ToolTip = 'View or print a detailed list of items that must be put away.';
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(FindFirstAllowedRec(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(FindNextAllowedRec(Steps));
    end;

    trigger OnOpenPage()
    begin
        ErrorIfUserIsNotWhseEmployee;
    end;

    var
        WhseDocPrint: Codeunit "Warehouse Document-Print";
}

