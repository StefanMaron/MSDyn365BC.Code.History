page 9190 "Profile Customization List"
{
    Caption = 'Profile Customizations';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
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
                    Caption = 'Profile App Name';
                    ToolTip = 'Specifies the name of the app that provided the profile that this page customization applies to.';
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
                    ToolTip = 'Specifies whether the profile customization was user-made or provided as part of an extension.';
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

