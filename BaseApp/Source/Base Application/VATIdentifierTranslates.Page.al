page 11768 "VAT Identifier Translates"
{
    Caption = 'VAT Identifier Translates';
    DataCaptionFields = "VAT Identifier Code";
    PageType = List;
    SourceTable = "VAT Identifier Translate";
    ObsoleteState = Pending;
    ObsoleteReason = 'The enhanced functionality of VAT Identifier will be removed and this page should not be used. (Obsolete::Removed in release 01.2021)';

    layout
    {
        area(content)
        {
            repeater(Control1220006)
            {
                ShowCaption = false;
                field("VAT Identifier Code"; "VAT Identifier Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for a VAT Identifier.You can enter a maximum of 10 characters, both numbers and letters.';
                    Visible = false;
                }
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language to be used on printouts for this document.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the VAT identifier translates.';
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
    }
}

