page 5737 "Item Reference Entries"
{
    Caption = 'Item Reference Entries';
    DataCaptionFields = "Item No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Reference";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reference Type"; "Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the reference entry.';
                }
                field("Reference Type No."; "Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer number, a vendor number, or a bar code, depending on what you have selected in the Type field.';
                }
                field("Reference No."; "Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the referenced item number. If you enter a reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the reference number on a sales or purchase document.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item linked to this reference. It will override the standard description when entered on an order.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item linked to this reference.';
                    Visible = false;
                }
                field("Discontinue Bar Code"; "Discontinue Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want the program to discontinue a bar code item reference.';
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

