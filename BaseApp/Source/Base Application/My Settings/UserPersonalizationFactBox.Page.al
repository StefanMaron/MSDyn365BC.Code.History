#if not CLEAN19
page 9821 "User Personalization FactBox"
{
    Caption = 'User Settings';
    Editable = false;
    PageType = CardPart;
    SourceTable = "User Personalization";
    ObsoleteState = Pending;
    ObsoleteReason = 'Please use "User Settings Factbox" instead.';
    ObsoleteTag = '19.0';

    layout
    {
        area(content)
        {
            field(Role; Rec.Role)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Role';
                ToolTip = 'Specifies the user role that defines the user’s default Role Center and role-specific customizations. Unless restricted by permissions, users can change their role on the My Settings page.';
            }
            field("Language"; Rec."Language Name")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Language';
                ToolTip = 'Specifies the language in which Business Central will display. Users can change this on the My Settings page.';
            }
            field(Region; Rec.Region)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Region';
                Importance = Additional;
                ToolTip = 'Specifies the region setting for the user. The region defines display formats, for example, for dates, numbering, symbols, and currency. Users can change this on the My Settings page.';
            }
            field("Profile ID"; Rec."Profile ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Profile';
                ToolTip = 'Specifies the ID of the profile that is associated with the current user.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The field "Role" will be used to show the caption associated to the Profile ID';
                ObsoleteTag = '19.0';
            }
            field("Language ID"; Rec."Language ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Language';
                ToolTip = 'Specifies the ID of the language that Microsoft Windows is set up to run for the selected user.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The field "Language" will be used to show the language name instead of the "Language ID"';
                ObsoleteTag = '19.0';
            }
            field("Locale ID"; Rec."Locale ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Locale';
                ToolTip = 'Specifies the ID of the locale that Microsoft Windows is set up to run for the selected user.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The field "Region" will be used to show the region name instead of the "Locale ID"';
                ObsoleteTag = '19.0';
            }
            field(Company; Rec.Company)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Company';
                ToolTip = 'Specifies the company that is associated with the user.';
            }
            field("Time Zone"; Rec."Time Zone")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Time Zone';
                ToolTip = 'Specifies the time zone that Microsoft Windows is set up to run for the selected user.';
            }
            field(CalloutsEnabled; UserCallouts.AreCalloutsEnabled(Rec."User SID"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Teaching Tips';
                ToolTip = 'Specifies whether to display short messages that inform, remind, or teach you about important fields and actions when you open a page.';
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
        MySettings.HideExternalUsers(Rec);
    end;

    var
        UserCallouts: Record "User Callouts";
}
#endif

