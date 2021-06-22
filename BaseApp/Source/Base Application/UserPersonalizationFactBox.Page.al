page 9821 "User Personalization FactBox"
{
    Caption = 'User Preferences';
    Editable = false;
    PageType = CardPart;
    SourceTable = "User Personalization";

    layout
    {
        area(content)
        {
            field("Profile ID"; "Profile ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Profile';
                ToolTip = 'Specifies the ID of the profile that is associated with the current user.';
            }
            field("Language ID"; "Language ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Language';
                ToolTip = 'Specifies the ID of the language that Microsoft Windows is set up to run for the selected user.';
            }
            field("Locale ID"; "Locale ID")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Locale';
                ToolTip = 'Specifies the ID of the locale that Microsoft Windows is set up to run for the selected user.';
            }
            field(Company; Company)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Company';
                ToolTip = 'Specifies the company that is associated with the user.';
            }
            field("Time Zone"; "Time Zone")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Time Zone';
                ToolTip = 'Specifies the time zone that Microsoft Windows is set up to run for the selected user.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        HideExternalUsers;
    end;

    local procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        CalcFields("License Type");
        SetFilter("License Type", '<>%1', "License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;
}

