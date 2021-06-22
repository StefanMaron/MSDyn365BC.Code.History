page 9198 "Profile Import Result List"
{
    PageType = List;
    Caption = 'Detailed Results';
    SourceTable = "Profile Designer Diagnostic";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(repeater)
            {
                field("Profile ID"; "Profile ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an ID that is used to identify the profile (role). There can be more than one profile with the same ID if they come from different extensions.';
                }
                field(Severity; Severity)
                {
                    ApplicationArea = All;
                    width = 5;
                    ToolTip = 'Specifies the severity of this diagnostics message.';
                }
                field(Message; Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the diagnostics message from the compiler.';
                }
                field(ApplicationNameField; ApplicationName)
                {
                    Caption = 'Source';
                    Editable = false;
                    Visible = false; // Too much clutter to show by default but allow admin to show this if necessary to distinguish between profiles
                    ApplicationArea = All;
                    ToolTip = 'Specifies the origin of this profile, which can be either an extension, shown by its name, or a custom profile created by a user.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ApplicationName := ConfPersonalizationMgt.ResolveAppNameFromAppId("Profile App ID");
    end;

    var
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        ApplicationName: Text;
}
