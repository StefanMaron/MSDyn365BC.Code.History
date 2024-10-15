#if not CLEAN17
page 31096 "Commodity Setup"
{
    Caption = 'Commodity Setup (Obsolete)';
    DataCaptionFields = "Commodity Code";
    PageType = List;
    SourceTable = "Commodity Setup";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Commodity Code"; "Commodity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies code from reverse charge and control report.';
                    Visible = false;
                }
                field("Valid From"; "Valid From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date for commodity limit amount setup.';
                }
                field("Valid To"; "Valid To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date for commodity limit amount setup.';
                }
                field("Commodity Limit Amount LCY"; "Commodity Limit Amount LCY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the commodidty limit in LCY. For amounts above the limit has to be used reverse charge.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220008; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220009; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }
}
#endif