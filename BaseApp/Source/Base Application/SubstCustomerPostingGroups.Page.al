#if not CLEAN18
page 11781 "Subst. Customer Posting Groups"
{
    Caption = 'Subst. Customer Posting Groups (Obsolete)';
    DataCaptionFields = "Parent Cust. Posting Group";
    PageType = List;
    SourceTable = "Subst. Customer Posting Group";
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
                field("Customer Posting Group"; "Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customerÍs market type to link business transakcions to.';
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


#endif