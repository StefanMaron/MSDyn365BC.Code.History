page 11779 "VAT Attribute Codes"
{
    Caption = 'VAT Attribute Codes';
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "VAT Attribute Code";

    layout
    {
        area(content)
        {
            repeater(Control1220007)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT attribute code.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT attribute description.';
                }
                field("XML Code"; "XML Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XML code for VAT statement reporting.';
                }
                field(Coefficient; Coefficient)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies coefficient of vat attribute';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220004; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220002; Notes)
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

