page 11 "Shipment Methods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Shipment Methods';
    PageType = List;
    SourceTable = "Shipment Method";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the shipment method.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the shipment method.';
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
        area(processing)
        {
            action("T&ranslation")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslation';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Shipment Method Translations";
                RunPageLink = "Shipment Method" = FIELD(Code);
                ToolTip = 'Describe the shipment method in different languages. The translated descriptions appear on quotes, orders, invoices, and credit memos, based on the shipment method code and the language code on the document.';
            }
        }
    }
}

