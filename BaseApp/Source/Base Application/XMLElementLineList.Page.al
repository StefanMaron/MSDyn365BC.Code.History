page 26588 "XML Element Line List"
{
    Caption = 'XML Element Line List';
    Editable = false;
    PageType = List;
    SourceTable = "XML Element Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Element Name"; "Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element name associated with the XML element line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML element line.';
                }
                field("Element Type"; "Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type associated with the XML element line.';
                }
                field("Data Type"; "Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type associated with the XML element line.';
                }
                field("Link Type"; "Link Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link type associated with the XML element line.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
            }
        }
    }

    actions
    {
    }
}

