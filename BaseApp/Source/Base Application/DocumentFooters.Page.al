page 31097 "Document Footers"
{
    Caption = 'Document Footers';
    PageType = List;
    SourceTable = "Document Footer";

    layout
    {
        area(content)
        {
            repeater(Control1220005)
            {
                ShowCaption = false;
                field("Language Code"; "Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language to be used on printouts for this document.';
                }
                field("Footer Text"; "Footer Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document footer text for sales or purchase documents.';
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

