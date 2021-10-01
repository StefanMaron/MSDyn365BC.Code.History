#if not CLEAN19
page 9173 "User Personalization List"
{
    Caption = 'User Settings';
    CardPageID = "User Personalization Card";
    Editable = false;
    PageType = List;
    SourceTable = "User Personalization";
    SourceTableView = sorting("User ID") order(ascending);
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2149387'; 
    AboutTitle = 'About user settings';
    AboutText = 'User settings control the look and feel of the user interface the next time the users log in. Each user can also make their own choices in their My Settings page, unless you restrict their permissions.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Use page "User Settings List" instead';
    ObsoleteTag = '19.0';

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
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user’s unique identifier.';
                    DrillDown = false;
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
                }
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the ID of the profile that is associated with the current user.';
                    Editable = false;
                    Lookup = false;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Role" will be used to show the caption associated to the Profile ID';
                    ObsoleteTag = '18.0';

                    trigger OnValidate()
                    var
                        MySettings: Codeunit "My Settings";
                    begin
                        MySettings.SetExperienceToEssential("Profile ID");
                    end;
                }
                field("Language"; Rec."Language Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Language';
                    ToolTip = 'Specifies the language in which Business Central will display. Users can change this on the My Settings page.';
                }
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Language ID';
                    ToolTip = 'Specifies the ID of the language that Microsoft Windows is set up to run for the selected user.';
                    BlankZero = true;
                    Editable = false;
                    Lookup = false;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Language" will be used to show the language name instead of the "Language ID"';
                    ObsoleteTag = '18.0';
                }
                field(Region; Rec.Region)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Region';
                    Importance = Additional;
                    ToolTip = 'Specifies the region setting for the user. The region defines display formats, for example, for dates, numbering, symbols, and currency. Users can change this on the My Settings page.';
                }
                field("Locale ID"; Rec."Locale ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Locale ID';
                    ToolTip = 'Specifies the ID of the locale that Microsoft Windows is set up to run for the selected user.';
                    BlankZero = true;
                    Editable = false;
                    Lookup = false;
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'The field "Region" will be used to show the region name instead of the "Locale ID"';
                    ObsoleteTag = '18.0';
                }
                field("Time Zone"; Rec."Time Zone")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time Zone';
                    ToolTip = 'Specifies the time zone for the user. Users can change this on the My Settings page.';
                    Visible = false;
                }
                field(Company; Rec.Company)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the user works in. Unless restricted by permissions, users can change this on the My Settings page.';
                    Lookup = false;
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
        MySettings: Codeunit "My Settings";
    begin
        MySettings.CheckPermissions(Rec);
        MySettings.HideExternalUsers(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        MySettings: Codeunit "My Settings";
    begin
        if MySettings.IsRestartRequiredIfChangeIsForCurrentUser() and (CloseAction <> ACTION::Cancel) then
            MySettings.RestartSession();
    end;
}
#endif