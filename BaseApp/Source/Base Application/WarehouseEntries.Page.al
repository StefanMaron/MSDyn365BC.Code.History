page 7318 "Warehouse Entries"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Entries';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Warehouse Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the entry type, which can be Negative Adjmt., Positive Adjmt., or Movement.';
                }
                field("Journal Batch Name"; "Journal Batch Name")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                    Visible = false;
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the warehouse document line or warehouse journal line that was registered.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location to which the entry is linked.';
                    Visible = false;
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number.';
                    Visible = false;
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the lot number assigned to the warehouse entry.';
                    Visible = false;
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expiration date of the serial number.';
                    Visible = false;
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone to which the entry is linked.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item in the entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the warehouse entry.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of units of the item in the warehouse entry.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the entry, in the base unit of measure.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure that are in the unit of measure specified for the item on the line.';
                    Visible = false;
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the table number that is the source of the entry line, for example, 39 for a purchase line, 37 for a sales line.';
                    Visible = false;
                }
                field("Source Subtype"; "Source Subtype")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source subtype of the document to which the warehouse entry line relates.';
                    Visible = false;
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; "Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Source Line No."; "Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                }
                field("Source Subline No."; "Source Subline No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source subline number of the document from which the entry originates.';
                    Visible = false;
                }
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("No. Series"; "No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                    Visible = false;
                }
                field(Cubage; Cubage)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the total cubage of the items on the warehouse entry line.';
                    Visible = false;
                }
                field(Weight; Weight)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field("Journal Template Name"; "Journal Template Name")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
                    Visible = false;
                }
                field("Whse. Document Type"; "Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of the document from which this entry originated.';
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document from which this entry originated.';
                }
                field("Registering Date"; "Registering Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date the entry was registered.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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
    }
}

