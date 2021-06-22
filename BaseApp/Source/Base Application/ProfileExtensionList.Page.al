page 9169 "Profile Extension List"
{
    Caption = 'Profile Extensions';
    PageType = List;
    SourceTable = "Tenant Profile Extension";
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ProfileIdField; "Base Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile ID';
                    ToolTip = 'Specifies the ID of the profile that this profile extension is applied to.';
                }
                field(BaseProfileAppNameField; ConfPersonalizationMgt.ResolveAppNameFromAppId("Base Profile App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile Extension Name';
                    ToolTip = 'Specifies the name of the extension that provided the profile.';
                }
                field(AppNameField; ConfPersonalizationMgt.ResolveAppNameFromAppId("App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of the extension that provided the extension for the profile.';
                    Visible = false;
                }
            }
        }
    }

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CanOnlyDeleteOwnedProfilesErr: Label 'You can only delete Profile Extensions that are user-created.';

    trigger OnDeleteRecord(): Boolean
    begin
        if not IsNullGuid("App ID") then
            Error(CanOnlyDeleteOwnedProfilesErr);
    end;

}
