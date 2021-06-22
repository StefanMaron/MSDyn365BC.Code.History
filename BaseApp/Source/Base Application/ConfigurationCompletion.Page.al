page 8638 "Configuration Completion"
{
    Caption = 'Configuration Completion';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Setup';
    ShowFilter = false;
    SourceTable = "Config. Setup";

    layout
    {
        area(content)
        {
            group("Complete Setup")
            {
                Caption = 'Complete Setup';
                group(Control6)
                {
                    ShowCaption = false;
                    label(BeforeSetupCloseMessage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you have finished setting up the company, select the profile that you want to use as your default, and then choose the OK button to close the page. Then restart the Business Central client to apply the changes.';
                        ToolTip = 'Specifies how to finish setting up your company.';
                    }
                    field("Your Profile Code"; YourProfileCode)
                    {
                        ApplicationArea = Basic, Suite;
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the profile code for your configuration solution and package.';

                        trigger OnAssistEdit()
                        var
                            AllProfileTable: Record "All Profile";
                        begin
                            if PAGE.RunModal(PAGE::"Available Roles", AllProfileTable) = ACTION::LookupOK then begin
                                YourProfileCode := AllProfileTable."Profile ID";
                                "Your Profile Code" := AllProfileTable."Profile ID";
                                "Your Profile App ID" := AllProfileTable."App ID";
                                "Your Profile Scope" := AllProfileTable.Scope;
                            end;
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Setup)
            {
                Caption = 'Setup';
            }
            action(Users)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                Image = User;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page Users;
                ToolTip = 'View or edit users that will be configured in the database.';
            }
            action("Users Personalization")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users Personalization';
                Image = UserSetup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                RunObject = Page "User Personalization List";
                ToolTip = 'View or edit UI changes that will be configured in the database.';
            }
        }
    }

    trigger OnClosePage()
    begin
        SelectDefaultRoleCenter("Your Profile Code", "Your Profile App ID", "Your Profile Scope");
    end;

    trigger OnInit()
    begin
        YourProfileCode := "Your Profile Code";
    end;

    var
        YourProfileCode: Code[30];
}

