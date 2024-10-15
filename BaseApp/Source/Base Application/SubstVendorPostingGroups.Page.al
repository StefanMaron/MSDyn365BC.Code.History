page 11782 "Subst. Vendor Posting Groups"
{
    Caption = 'Subst. Vendor Posting Groups (Obsolete)';
    DataCaptionFields = "Parent Vend. Posting Group";
    PageType = List;
    SourceTable = "Subst. Vendor Posting Group";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220004)
            {
                ShowCaption = false;
                field("Vendor Posting Group"; "Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220002; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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

