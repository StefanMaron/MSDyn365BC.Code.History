page 11797 "User Setup Card"
{
    Caption = 'User Setup Card';
    PageType = Card;
    SourceTable = "User Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';
                }
                field("User Name"; "User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the short name for the user.';
                }
                field("Employee No."; "Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the connectivity between User ID and employee number.';
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
                field("Allow Complete Job"; "Allow Complete Job")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow complete job.';
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
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
                field("Check Whse. Net Change Temp."; "Check Whse. Net Change Temp.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies check whse. net change templates allowed for posting (set in lines) for selected user.';
                }
                field("Allow Item Unapply"; "Allow Item Unapply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the possibillity to allow or not allow item apply.';
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
        area(navigation)
        {
            group("U&ser Check")
            {
                Caption = 'U&ser Check';
                action(Lines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines';
                    Image = SocialSecurityLines;
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
                        UserSetupAdvMgt.SelectDimensionsToCheck(Rec);
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
                ToolTip = 'Allows the user setup card printout.';

                trigger OnAction()
                var
                    UserSetup: Record "User Setup";
                begin
                    UserSetup.Copy(Rec);
                    UserSetup.SetRecFilter;
                    REPORT.RunModal(REPORT::"User Setup List", true, false, UserSetup);
                end;
            }
        }
    }
}

