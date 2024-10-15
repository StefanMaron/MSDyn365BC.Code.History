page 11740 "Cash Desk Users"
{
    Caption = 'Cash Desk Users (Obsolete)';
    DataCaptionFields = "Cash Desk No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Cash Desk User";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    layout
    {
        area(content)
        {
            repeater(Control1220008)
            {
                ShowCaption = false;
                field("Cash Desk No."; "Cash Desk No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Cash Desk List";
                    ToolTip = 'Specifies Cash Desk Code for assigning rights. Specifies options: issue or post.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user associated with the entry.';
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the short name for the user.';
                }
                field(Create; Create)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the user has rights for creating cash desk document.';
                }
                field(Issue; Issue)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the user has rights for issuing cash desk document.';
                }
                field(Post; Post)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the user has rights for posting cash desk document.';
                }
                field("Post EET Only"; "Post EET Only")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the user has the right to post only the documents that are marked as "EET Transaction" = Yes.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                    ObsoleteTag = '18.0';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220001; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1220000; Notes)
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

