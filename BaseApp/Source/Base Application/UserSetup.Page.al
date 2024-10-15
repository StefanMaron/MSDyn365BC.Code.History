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
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the connectivity between User ID and employee number.';
                    Visible = false;
                }
                field("Allow Posting From"; "Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post to the company.';
                }
                field("Allow Posting To"; "Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post to the company.';
                }
                field("Allow VAT Posting From"; "Allow VAT Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest VAT date on which the user is allowed to post to the company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Allow VAT Posting To"; "Allow VAT Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last VAT date on which the user is allowed to post to the company.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Register Time"; "Register Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to register the user''s time usage defined as the time spent from when the user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the salesperson or purchaser for the user.';
                }
                field("Sales Resp. Ctr. Filter"; "Sales Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Purchase Resp. Ctr. Filter"; "Purchase Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Service Resp. Ctr. Filter"; "Service Resp. Ctr. Filter")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the responsibility center you want to assign to the user. The user will only be able to see service documents for the responsibility center specified in the field. This responsibility center will also be the default responsibility center when the user creates new service documents.';
                }
                field("Time Sheet Admin."; "Time Sheet Admin.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a user is a time sheet administrator. A time sheet administrator can access any time sheet and then edit, change, or delete it.';
                }
                field("Allow Item Unapply"; "Allow Item Unapply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow item apply.';
                    Visible = false;
                }
                field("Cash Resp. Ctr. Filter"; "Cash Resp. Ctr. Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies cash resp. ctr. Filter';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
                    ObsoleteTag = '17.0';
                    Visible = false;
                }
                field("Check Payment Orders"; "Check Payment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check payment orders allowed for posting (set in lines) for selected user.';
                }
                field("Check Bank Statements"; "Check Bank Statements")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check Bank Statemsnts allowed for posting (set in lines) for selected user.';
                }
                field("Check Document Date(work date)"; "Check Document Date(work date)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check document date (work date) allowed for posting (set in lines).';
                }
                field("Check Document Date(sys. date)"; "Check Document Date(sys. date)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check document date (system date) allowed for posting (set in lines).';
                }
                field("Check Posting Date (work date)"; "Check Posting Date (work date)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check posting date (work date) allowed for posting (set in lines).';
                }
                field("Check Posting Date (sys. date)"; "Check Posting Date (sys. date)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check posting date (system date) allowed for posting (set in lines).';
                }
                field("Check Bank Accounts"; "Check Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check Bank Accounts allowed for posting (set in lines) for selected user.';
                }
                field("Check Journal Templates"; "Check Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check journal templates allowed for posting (set in lines) for selected user.';
                }
                field("Check Dimension Values"; "Check Dimension Values")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check Dimension Values allowed for posting (set in lines).';
                }
                field("Allow Posting to Closed Period"; "Allow Posting to Closed Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow posting to closed period.';
                }
                field("Allow Complete Job"; "Allow Complete Job")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow complete job.';
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the short name for the user.';
                }
                field("Check Location Code"; "Check Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check location code allowed for posting (set in lines) for selected user.';
                }
                field("Check Release Location Code"; "Check Release Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check release location code allowed for posting (set in lines) for selected user.';
                }
                field("Check Whse. Net Change Temp."; "Check Whse. Net Change Temp.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check whse. net change templates allowed for posting (set in lines) for selected user.';
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
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = Card;
                    RunObject = Page "User Setup Card";
                    RunPageLink = "User ID" = FIELD("User ID");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Specifies the user setup card.';
                }
                action(Lines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines';
                    Image = SetupLines;
                    RunObject = Page "User Setup Lines";
                    RunPageLink = "User ID" = FIELD("User ID");
                    ToolTip = 'Specifies the lines for another user setup.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'Specifies the dimensions related to the user.';

                    trigger OnAction()
                    var
                        UserSetupAdvMgt: Codeunit "User Setup Adv. Management";
                    begin
                        UserSetupAdvMgt.SelectDimensionsToCheck(Rec); // NAVCZ
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Copy User Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy User Setup';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Allows to copy user setup from user to another user.';

                    trigger OnAction()
                    var
                        CopyUserSetup: Report "Copy User Setup";
                    begin
                        // NAVCZ
                        CopyUserSetup.SetFromUserId("User ID");
                        CopyUserSetup.RunModal;
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Pr&int")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pr&int';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open the report for user setup.';

                trigger OnAction()
                var
                    UserSetup: Record "User Setup";
                begin
                    // NAVCZ
                    if UserSetup.Get("User ID") then begin
                        UserSetup.SetRecFilter;
                        REPORT.RunModal(REPORT::"User Setup List", true, false, UserSetup);
                    end;
                    // NAVCZ
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        HideExternalUsers;
    end;
}

