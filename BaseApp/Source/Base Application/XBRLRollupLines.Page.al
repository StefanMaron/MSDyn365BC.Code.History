#if not CLEAN20
page 587 "XBRL Rollup Lines"
{
    Caption = 'XBRL Rollup Lines';
    PageType = List;
    SourceTable = "XBRL Rollup Line";
    ObsoleteReason = 'XBRL feature will be discontinued';
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("From XBRL Taxonomy Line No."; Rec."From XBRL Taxonomy Line No.")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the number of the XBRL line from which this XBRL line is rolled up.';
                }
                field("From XBRL Taxonomy Line Name"; Rec."From XBRL Taxonomy Line Name")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the name of the XBRL line from which this XBRL line is rolled up.';
                    Visible = false;
                }
                field("From XBRL Taxonomy Line Label"; Rec."From XBRL Taxonomy Line Label")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the label of the XBRL line from which this XBRL line is rolled up.';
                }
                field(Weight; Weight)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the label of the XBRL line from which this XBRL line is rolled up.';
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
    }

    trigger OnOpenPage()
    var
        XBRLDeprecationNotification: Codeunit "XBRL Deprecation Notification";
    begin
        XBRLDeprecationNotification.Show();
    end;

}


#endif