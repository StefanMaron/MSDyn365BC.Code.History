namespace Microsoft.Finance.VAT.Clause;

page 748 "VAT Clause Translations"
{
    Caption = 'VAT Clause Translations';
    DataCaptionFields = "VAT Clause Code";
    PageType = List;
    SourceTable = "VAT Clause Translation";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translation of the VAT clause description. The translated version of the description is displayed as the VAT clause, based on the Language Code setting on the Customer card.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translation of the additional VAT clause description.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control7; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control8; Notes)
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

