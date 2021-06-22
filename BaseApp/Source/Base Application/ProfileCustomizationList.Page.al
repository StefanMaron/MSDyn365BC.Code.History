page 9190 "Profile Customization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Profile Customizations';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Tenant Profile Page Metadata";

    layout
    {
        area(content)
        {
            repeater(Repeater1)
            {
                ShowCaption = false;
                field("Profile ID"; "Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the profile that the customization has been created for.';
                }
                field("App ID"; "App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile App ID';
                    ToolTip = 'Specifies the ID of the app that provided the profile that this page customization applies to.';
                    Visible = false;
                }
                field("App Name"; ConfPersonalizationMgt.ResolveAppNameFromAppId("App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this page customization applies to, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
                field(PageIdField; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been customized.';
                }
                field(OwnerField; Owner)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Owner';
                    ToolTip = 'Specifies whether the customization was made by a user (Tenant) or provided as part of an extension (System).';
                }
            }
        }
    }

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CannotDeleteExtensionProfileErr: Label 'You cannot delete this profile customization because it comes from an extension.';

    trigger OnDeleteRecord(): Boolean
    var
        myInt: Integer;
    begin
        if Owner <> Owner::Tenant then
            Error(CannotDeleteExtensionProfileErr);
    end;
}

