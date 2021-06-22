page 7390 "Posted Invt. Put-away"
{
    Caption = 'Posted Invt. Put-away';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Posted Invt. Put-away Header";

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
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the posted inventory put-away occurred.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Destination No."; "Destination No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaption("Destination Type", "Source Document", 0));
                    Editable = false;
                    ToolTip = 'Specifies the number or the code of the customer, vendor, location, item, family, or sales order linked to the posted inventory put-away.';
                }
                field("WMSMgt.GetDestinationName(""Destination Type"",""Destination No."")"; WMSMgt.GetDestinationName("Destination Type", "Destination No."))
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaption("Destination Type", "Source Document", 1));
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of a put-away of items that has been posted in one of the warehouses.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date from the inventory put-away.';
                }
                field("Expected Receipt Date"; "Expected Receipt Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date on which the receipt of the items on the posted inventory put-away was expected.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaption("Destination Type", "Source Document", 2));
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("External Document No.2"; "External Document No.2")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaption("Destination Type", "Source Document", 3));
                    ToolTip = 'Specifies an additional part of the document number that refers to the customer''s or vendor''s numbering system.';
                }
            }
            part(WhseActivityLines; "Posted Invt. Put-away Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = FIELD("No.");
                SubPageView = SORTING("No.", "Sorting Sequence No.");
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
            group("Put-&away")
            {
                Caption = 'Put-&away';
                Image = CreatePutAway;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Posted Invt. Put-Away"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Warehouse;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update;
    end;

    var
        WMSMgt: Codeunit "WMS Management";
}

