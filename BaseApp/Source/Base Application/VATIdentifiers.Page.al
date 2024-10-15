page 11767 "VAT Identifiers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Identifiers';
    PageType = List;
    SourceTable = "VAT Identifier";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a VAT Identifier.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT Identifier.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220000; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220001; Notes)
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
            action("T&ranslate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'T&ranslate';
                Image = Translation;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "VAT Identifier Translates";
                RunPageLink = "VAT Identifier Code" = FIELD(Code);
                ToolTip = 'Specifies vat identifier translates';
            }
        }
    }
}

