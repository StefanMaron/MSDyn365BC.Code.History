namespace Microsoft.Warehouse.ADCS;

page 7706 "Item Identifiers"
{
    Caption = 'Item Identifiers';
    DataCaptionFields = "Item No.";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Item Identifier";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies a unique code for a particular item in terms that are useful for automatic data capture.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ADCS;
                    Editable = false;
                    ToolTip = 'Specifies the number of the item to be identified by the identifier code on the line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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

