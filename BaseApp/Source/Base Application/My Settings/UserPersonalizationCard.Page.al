#if not CLEAN19
page 9172 "User Personalization Card"
{
    Caption = 'User Settings Card';
    AdditionalSearchTerms = 'User Personalization Card,User Preferences Card';
    DataCaptionExpression = Rec."User ID";
    DelayedInsert = true;
    PageType = Card;
    SourceTable = "User Personalization";
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2149387';
    AboutTitle = 'About user setting details';
    AboutText = 'Here, you manage an individual user''s settings. If a setting is left blank, a default value is provided when the user signs in.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Use page "User Settings" instead';
    ObsoleteTag = '19.0'; 

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user’s unique identifier.';
                    DrillDown = false;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable() then
                            if MySettings.EditUserID(Rec) then
                                CurrPage.Update();
                    end;
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the user’s full name.';
                    Editable = false;
                    Visible = false;
                }
                field(Role; Rec.Role)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Role';
                    ToolTip = 'Specifies the user role that defines the user’s default Role Center and role-specific customizations. Unless restricted by permissions, users can change their role on the My Settings page.';

                    trigger OnAssistEdit()
                    var
                    begin
                        if CurrPage.Editable() then
                            MySettings.EditProfileID(Rec);
                    end;
                }
                field(ProfileID; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    DrillDown = false;
                    Editable = false;
                    LookupPageID = "Profile List";
                    ToolTip = 'Specifies the ID of the profile that is associated with the current user.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Role" will be used to show the caption associated to the Profile ID';
                    ObsoleteTag = '18.0';

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable() then
                            MySettings.EditProfileID(Rec);
                    end;
                }
                field("Language"; Rec."Language Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Language';
                    ToolTip = 'Specifies the language in which Business Central will display. Users can change this on the My Settings page.';

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable() then
                            MySettings.EditLanguage(Rec);
                    end;
                }
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Language ID';
                    ToolTip = 'Specifies the ID of the language that Microsoft Windows is set up to run for the selected user.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Language" will be used to show the language name instead of the "Language ID"';
                    ObsoleteTag = '18.0';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MySettings.EditLanguage(Rec);
                    end;

                    trigger OnValidate()
                    begin
                        MySettings.ValidateLanguageID(Rec);
                    end;
                }
                field(Region; Rec.Region)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Region';
                    ToolTip = 'Specifies the region setting for the user. The region defines display formats, for example, for dates, numbering, symbols, and currency. Users can change this on the My Settings page.';

                    trigger OnAssistEdit()
                    begin
                        if CurrPage.Editable() then
                            MySettings.EditRegion(Rec);
                    end;
                }
                field("Locale ID"; Rec."Locale ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Locale ID';
                    TableRelation = "Windows Language"."Language ID";
                    ToolTip = 'Specifies the ID of the locale that Microsoft Windows is set up to run for the selected user.';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Region" will be used to show the region name instead of the "Locale ID"';
                    ObsoleteTag = '18.0';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        MySettings.EditRegion(Rec);
                    end;

                    trigger OnValidate()
                    begin
                        MySettings.ValidateRegionID(Rec)
                    end;
                }
                field("Time Zone"; Rec."Time Zone")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Zone';
                    ToolTip = 'Specifies the time zone for the user. Users can change this on the My Settings page.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(ConfPersMgt.LookupTimeZone(Text))
                    end;

                    trigger OnValidate()
                    begin
                        MySettings.ValidateTimeZone(Rec);
                    end;
                }
                field(Company; Rec.Company)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the user works in. Unless restricted by permissions, users can change this on the My Settings page.';
                }
                field(CalloutsEnabled; CalloutsEnabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Teaching Tips';
                    ToolTip = 'Specifies whether to display short messages that inform, remind, or teach you about important fields and actions when you open a page.';

                    trigger OnValidate()
                    begin
                        UserCallouts.SwitchCalloutsEnabledValue(Rec."User SID");
                    end;
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
            action(PersonalizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Personalized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that the user has personalized.';
                trigger OnAction()
                var
                    UserPagePersonalizationList: page "User Page Personalization List";
                begin
                    UserPagePersonalizationList.SetUserID(Rec."User SID");
                    UserPagePersonalizationList.RunModal();
                end;
            }
            action(CustomizedPages)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customized Pages';
                Image = Link;
                ToolTip = 'View the list of pages that have been customized for the user role.';
                trigger OnAction()
                var
                    TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
                begin
                    TenantProfilePageMetadata.SetFilter("Profile ID", Rec."Profile ID");
                    Page.RunModal(Page::"Profile Customization List", TenantProfilePageMetadata);
                end;
            }
            group("User &Personalization")
            {
                Caption = 'User &Personalization';
                Image = Grid;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'List action is redundant';
                ObsoleteTag = '18.0';

                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View or edit a list of all users who have personalized their user interface by customizing one or more pages.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'List action is redundant';
                    ObsoleteTag = '19.0';

                    trigger OnAction()
                    var
                        UserPersList: Page "User Personalization List";
                    begin
                        UserPersList.LookupMode := true;
                        UserPersList.SetRecord(Rec);
                        if UserPersList.RunModal() = Action::LookupOK then
                            UserPersList.GetRecord(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&lear Personalized Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&lear Personalized Pages';
                    Image = Cancel;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Delete all personalizations made by the specified user across display targets.';

                    trigger OnAction()
                    begin
                        ConfPersMgt.ClearUserPersonalization(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalloutsEnabled := UserCallouts.AreCalloutsEnabled(Rec."User SID");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.TestField("User SID");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField("User SID");
    end;

    trigger OnOpenPage()
    begin
        MySettings.CheckPermissions(Rec);
        MySettings.HideExternalUsers(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if MySettings.IsRestartRequiredIfChangeIsForCurrentUser() and (CloseAction <> ACTION::Cancel) then
            MySettings.RestartSession();
    end;

    var
        UserCallouts: Record "User Callouts";
        MySettings: Codeunit "My Settings";
        ConfPersMgt: Codeunit "Conf./Personalization Mgt.";
        CalloutsEnabled: Boolean;

    [Obsolete('Use method "SetExperienceToEssential" from codeunit "My Settings" instead.', '19.0')]
    procedure SetExperienceToEssential(SelectedProfileID: Text[30])
    begin
        MySettings.SetExperienceToEssential(SelectedProfileID);
    end;
}
#endif