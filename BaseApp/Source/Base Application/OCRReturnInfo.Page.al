page 15000101 "OCR Return Info"
{
    // MBS Navision NO - OCR Payment

    Caption = 'OCR Return Info';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Warning; Warning)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a warning is sent from the recipient''s bank to the recipient.';
                }
                field("Warning text"; "Warning text")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the warning text that is used if the Warning field is set to Other.';
                }
            }
        }
    }

    actions
    {
    }
}

