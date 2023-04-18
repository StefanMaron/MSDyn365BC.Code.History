#if not CLEAN20
page 590 "XBRL Taxonomy Labels"
{
    Caption = 'XBRL Taxonomy Labels';
    PageType = List;
    SourceTable = "XBRL Taxonomy Label";
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
                field("XML Language Identifier"; Rec."XML Language Identifier")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies a one or two-letter abbreviation code for the language of the label. There is no connection to the Windows Language ID code.';
                }
                field("Windows Language ID"; Rec."Windows Language ID")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the ID of the Windows language associated with the language code you have set up in this line.';
                    Visible = false;
                }
                field("Windows Language Name"; Rec."Windows Language Name")
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies if you enter an ID in the Windows Language ID field.';
                    Visible = false;
                }
                field(Label; Label)
                {
                    ApplicationArea = XBRL;
                    ToolTip = 'Specifies the user-readable element of the taxonomy.';
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