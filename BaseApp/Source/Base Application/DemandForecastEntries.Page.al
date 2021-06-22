page 99000922 "Demand Forecast Entries"
{
    Caption = 'Demand Forecast Entries';
    DelayedInsert = true;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Production Forecast Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Production Forecast Name"; "Production Forecast Name")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the name of the demand forecast to which the entry belongs.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the item identification number of the entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of your forecast.';
                }
                field("Forecast Quantity (Base)"; "Forecast Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the entry stated, in base units of measure.';
                }
                field("Forecast Date"; "Forecast Date")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the date of the demand forecast to which the entry belongs.';
                }
                field("Forecast Quantity"; "Forecast Quantity")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the quantities you have entered in the demand forecast within the selected time interval.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the valid number of units that the unit of measure code represents for the demand forecast entry.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the code for the location that is linked to the entry.';
                }
                field("Component Forecast"; "Component Forecast")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies that the forecast entry is for a component item.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Planning;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Production Forecast Name" := xRec."Production Forecast Name";
        "Item No." := xRec."Item No.";
        "Forecast Date" := xRec."Forecast Date";
    end;
}

