page 5785 "Warehouse Activity Lines"
{
    Caption = 'Warehouse Activity Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Activity Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Action Type"; "Action Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the action type for the warehouse activity line.';
                    Visible = false;
                }
                field("Activity Type"; "Activity Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of warehouse activity for the line.';
                    Visible = false;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Line No."; "Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse activity line.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of source document to which the warehouse activity line relates, such as sales, purchase, and production.';
                    Visible = false;
                }
                field("Source Subtype"; "Source Subtype")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source subtype of the document related to the warehouse request.';
                    Visible = false;
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
                    ToolTip = 'Specifies the source subline number.';
                    Visible = false;
                }
                field("Source Document"; "Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location where the activity occurs.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity per unit of measure of the item on the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item on the line.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, such as received, put-away, or assigned.';
                }
                field("Qty. (Base)"; "Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item to be handled, in the base unit of measure.';
                }
                field("Qty. Outstanding"; "Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items that have not yet been handled for this warehouse activity line.';
                }
                field("Qty. Outstanding (Base)"; "Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items, expressed in the base unit of measure, that have not yet been handled for this warehouse activity line.';
                }
                field("Qty. to Handle"; "Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many units to handle in this warehouse activity.';
                }
                field("Qty. to Handle (Base)"; "Qty. to Handle (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items to be handled in this warehouse activity.';
                }
                field("Qty. Handled"; "Qty. Handled")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                }
                field("Qty. Handled (Base)"; "Qty. Handled (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of items on the line that have been handled in this warehouse activity.';
                }
                field("Special Equipment Code"; "Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
                    Visible = false;
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shipping advice, which informs whether partial deliveries are acceptable.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity must be completed.';
                }
                field("Whse. Document Type"; "Whse. Document Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of warehouse document from which the line originated.';
                    Visible = false;
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the warehouse document that is the basis for the action on the line.';
                    Visible = false;
                }
                field("Whse. Document Line No."; "Whse. Document Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line in the warehouse document that is the basis for the action on the line.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        ShowActivityDoc;
                    end;
                }
                action("Show &Whse. Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show &Whse. Document';
                    Image = ViewOrder;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View the related warehouse document.';

                    trigger OnAction()
                    begin
                        ShowWhseDoc;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.Caption := FormCaption;
    end;

    var
        Text000: Label 'Warehouse Put-away Lines';
        Text001: Label 'Warehouse Pick Lines';
        Text002: Label 'Warehouse Movement Lines';
        Text003: Label 'Warehouse Activity Lines';
        Text004: Label 'Inventory Put-away Lines';
        Text005: Label 'Inventory Pick Lines';

    local procedure FormCaption(): Text[250]
    begin
        case "Activity Type" of
            "Activity Type"::"Put-away":
                exit(Text000);
            "Activity Type"::Pick:
                exit(Text001);
            "Activity Type"::Movement:
                exit(Text002);
            "Activity Type"::"Invt. Put-away":
                exit(Text004);
            "Activity Type"::"Invt. Pick":
                exit(Text005);
            else
                exit(Text003);
        end;
    end;
}

