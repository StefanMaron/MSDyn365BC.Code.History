page 7384 "Registered Invt. Movement"
{
    Caption = 'Registered Invt. Movement';
    Editable = false;
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Registered Invt. Movement Hdr.";

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
                    ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Hdr. table.';
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    OptionCaption = ' ,,,,,,,,,,,Prod. Consumption,,,,,,,,,Assembly Consumption';
                    ToolTip = 'Specifies the type of document that the line relates to.';
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
                    ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Hdr. table.';
                }
                field("WMSMgt.GetDestinationName(""Destination Type"",""Destination No."")"; WMSMgt.GetDestinationName("Destination Type", "Destination No."))
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaption("Destination Type", "Source Document", 1));
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the destination for the registered inventory movement.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the same as the field with the same name in the Registered Whse. Activity Hdr. table.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
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
            part(WhseActivityLines; "Reg. Invt. Movement Subform")
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
            group("&Movement")
            {
                Caption = '&Movement';
                Image = CreateMovement;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Registered Invt. Movement"),
                                  Type = CONST(" "),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
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

