page 5881 "Phys. Invt. Recording Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Phys. Invt. Record Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was counted when taking the physical inventory.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the additional description of the item.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location where the item was counted during taking the physical inventory.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin where the item was counted while performing the physical inventory.';
                    Visible = false;
                }
                field("Use Item Tracking"; "Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    Editable = true;
                    ToolTip = 'Specifies if it is necessary to record the item using serial numbers or lot numbers.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the serial number of the entered item.';
                }
                field("Lot No."; "Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number of the entered item.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item of the physical inventory recording line.';
                }
                field("Quantity (Base)"; "Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field(Recorded; Recorded)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if a value was entered in Quantity of the physical inventory recording line.';
                }
                field("Date Recorded"; "Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                    Visible = false;
                }
                field("Time Recorded"; "Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when the physical inventory was taken.';
                    Visible = false;
                }
                field("Person Recorded"; "Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who performed the physical inventory.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyLineAction)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Copy Line';
                    ToolTip = 'Copy Line.';

                    trigger OnAction()
                    begin
                        CopyLine;
                    end;
                }
            }
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action("Serial No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Serial No." = FIELD("Serial No.");
                    ToolTip = 'Show Serial No. Information Card.';
                }
                action("Lot No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Lot No." = FIELD("Lot No.");
                    ToolTip = 'Show Lot No. Information Card.';
                }
            }
        }
    }

    var
        CopyPhysInvtRecording: Report "Copy Phys. Invt. Recording";

    procedure CopyLine()
    begin
        CopyPhysInvtRecording.SetPhysInvtRecordLine(Rec);
        CopyPhysInvtRecording.RunModal;
        Clear(CopyPhysInvtRecording);
    end;
}

