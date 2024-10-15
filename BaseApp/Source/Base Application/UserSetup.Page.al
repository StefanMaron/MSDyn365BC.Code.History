#if not CLEAN19
page 119 "User Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Setup';
    PageType = List;
    SourceTable = "User Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post to the company.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post to the company.';
                }
                field("Allow Deferral Posting From"; Rec."Allow Deferral Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post deferrals to the company.';
                }
                field("Allow Deferral Posting To"; Rec."Allow Deferral Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post deferrals to the company.';
                }
                field("Register Time"; Rec."Register Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to register the user''s time usage defined as the time spent from when the user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded.';
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the salesperson or purchaser for the user.';
                }
                field("Sales Resp. Ctr. Filter"; Rec."Sales Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Purchase Resp. Ctr. Filter"; Rec."Purchase Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Service Resp. Ctr. Filter"; Rec."Service Resp. Ctr. Filter")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the responsibility center you want to assign to the user. The user will only be able to see service documents for the responsibility center specified in the field. This responsibility center will also be the default responsibility center when the user creates new service documents.';
                }
                field("Time Sheet Admin."; Rec."Time Sheet Admin.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a user is a time sheet administrator. A time sheet administrator can access any time sheet and then edit, change, or delete it.';
                }
                field("Check Payment Orders"; Rec."Check Payment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check payment orders allowed for posting (set in lines) for selected user.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field("Check Bank Statements"; Rec."Check Bank Statements")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check Bank Statemsnts allowed for posting (set in lines) for selected user.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
                    ObsoleteTag = '19.0';
                    Visible = false;
                }
                field(Email; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s email address.';
                }
                field(PhoneNo; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s phone number.';
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
        area(navigation)
        {
            group("U&ser Check")
            {
                Caption = 'U&ser Check';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '19.0';
            }
        }

        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                ObsoleteTag = '19.0';
            }
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
            }
        }
    }

    trigger OnOpenPage()
    begin
        HideExternalUsers();
    end;
}

#endif