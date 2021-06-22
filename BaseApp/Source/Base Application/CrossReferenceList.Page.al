page 5724 "Cross Reference List"
{
    Caption = 'Cross Reference List';
    PageType = List;
    SourceTable = "Item Cross Reference";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Cross-Reference No."; "Cross-Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cross-referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the cross-reference number on a sales or purchase document.';
                }
                field("Cross-Reference Type"; "Cross-Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the cross-reference entry.';
                }
                field("Cross-Reference Type No."; "Cross-Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer number, a vendor number, or a bar code, depending on what you have selected in the Type field.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number on the item card from which you opened the Item Cross Reference Entries window.';
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
                field("Discontinue Bar Code"; "Discontinue Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want the program to discontinue a bar code cross reference.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item that is linked to this cross reference.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item that is linked to this cross reference.';
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
}

