/// <summary> 
/// This page is meant to inform users that importing and applying Configuration packages may affect the system's performance.
/// </summary>
/// <remarks>This page is not meant to be used by extensions.</remarks>
page 8637 "Config. Package Warning"
{
    Caption = ' ';
    PageType = NavigatePage;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(TopBanner)
            {
                Enabled = false;
                ShowCaption = false;
                Visible = TopBannerVisible;
                field(Icon; MediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ShowCaption = false;
                    Tooltip = ' ';
                }
            }
            group(Import)
            {
                Visible = IsImportContext;
                group(ImportMessage)
                {
                    Caption = 'You are about to import a large configuration package.';
                    ShowCaption = true;
                    InstructionalText = 'Using configuration packages to import large amounts of data can impact performance and prevent all users from using Business Central during the process.';
                }

                label("Consider using the following ways to migrate a large amount of data:")
                {
                    ApplicationArea = All;
                }
                label(" - Data Migration from Excel.")
                {
                    ApplicationArea = All;
                }
                label(" - Edit in Excel.")
                {
                    ApplicationArea = All;
                }
            }
            group(Apply)
            {
                Visible = not IsImportContext;
                group(ApplyMessage)
                {
                    Caption = 'You are about to apply a big configuration package.';
                    ShowCaption = true;
                    InstructionalText = 'Using configuration packages to apply large amounts of data can impact performance and prevent all users from using Business Central during the process.';
                }

                label("Consider applying the package outside of the regular business hours.")
                {
                    ApplicationArea = All;
                }
                label("You may also want to contact your partner for assistance with this process.")
                {
                    ApplicationArea = All;
                }
            }
            field(ConfirmationField; Confirmation)
            {
                ApplicationArea = All;
                Caption = 'I understand, and want to continue.';
                ToolTip = 'Specifies that you understand that using configuration packages to migrate large amounts of data can have a negative impact on performance.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Ok)
            {
                ApplicationArea = All;
                Caption = 'OK';
                Enabled = Confirmation;
                InFooterBar = true;
                Image = Approve;
                ToolTip = 'Migrate a large amount of data in a configuration package.';

                trigger OnAction()
                begin
                    IsAcknowledged := true;
                    CurrPage.Close();
                end;
            }

            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                InFooterBar = true;
                ToolTip = 'Cancel the import or application of a large amount of data from a configuration file.';

                trigger OnAction()
                begin
                    IsAcknowledged := false;
                    CurrPage.Close();
                end;
            }

        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    local procedure LoadTopBanners()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if MediaRepository.Get('AssistedSetupInfo-NoText.png', Format(ClientTypeManagement.GetCurrentClientType())) then
            if MediaResources.Get(MediaRepository."Media Resources Ref") then
                TopBannerVisible := MediaResources."Media Reference".HasValue;
    end;

    internal procedure GetAction(): Action
    begin
        if IsAcknowledged then
            exit(Action::OK);

        exit(Action::Cancel);
    end;

    internal procedure SwitchContextToImport()
    begin
        IsImportContext := true;
    end;

    internal procedure SwitchContextToApply()
    begin
        IsImportContext := false;
    end;

    var
        MediaRepository: Record "Media Repository";
        MediaResources: Record "Media Resources";
        TopBannerVisible: Boolean;
        [InDataSet]
        Confirmation: Boolean;
        IsAcknowledged: Boolean;
        IsImportContext: Boolean;
}