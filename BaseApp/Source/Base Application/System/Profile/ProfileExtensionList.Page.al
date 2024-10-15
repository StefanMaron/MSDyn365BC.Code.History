namespace System.Environment.Configuration;

using System.Apps;

page 9169 "Profile Extension List"
{
    Caption = 'Profile Extensions';
    PageType = List;
    SourceTable = "Tenant Profile Extension";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ProfileIdField; Rec."Base Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile ID';
                    ToolTip = 'Specifies the ID of the profile that this profile extension is applied to.';
                }
                field(BaseProfileAppNameField; ExtensionManagement.GetAppName(Rec."Base Profile App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Base Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this profile extension applies to, which can be either an extension (as indicated by its name) or a custom profile created by a user (indicated as user-created).';
                }
                field(AppNameField; ExtensionManagement.GetAppName(Rec."App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Extension Source';
                    ToolTip = 'Specifies that the profile extension was either made by users (indicated as user-created) or it is part of an installed extension (indicated by the extension name).';
                    Visible = false;
                }
            }
        }
    }

    var
        ExtensionManagement: Codeunit "Extension Management";
}
