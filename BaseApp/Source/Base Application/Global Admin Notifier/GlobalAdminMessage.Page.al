/// <summary>
/// The page displays a warning message to users with the Global Administrator role but without a Business Central license.
/// </summary>
/// <remarks>This page is not supposed to be referenced in extensions.</remarks>
page 1459 "Global Admin Message"
{
    PageType = NavigatePage;
    Extensible = false;
    Caption = ' '; // Do not show the caption

    layout
    {
        area(Content)
        {
            group(IconGroup)
            {
                Enabled = false;
                ShowCaption = false;
                Visible = IconVisible;

                field(Icon; MediaResources."Media Reference")
                {
                    ApplicationArea = All;
                    Enabled = false;
                    ShowCaption = false;
                    ToolTip = ' '; // Do not show tooltip
                }
            }

            label(Title)
            {
                ApplicationArea = All;
                Caption = 'You have signed in as Global Administrator';
                Style = Strong;
            }

            label(FirstLine)
            {
                ApplicationArea = All;
                Caption = 'As a Global Administrator without a license for Business Central you can only manage user information and export data.';
            }

            label(SecondLine)
            {
                ApplicationArea = All;
                Caption = 'The Global Administrator role does not provide access to business capabilities, such as creating documents or installing extensions. To use other Business Central capabilities, you must be assigned to a license that will give you the permissions you need.';
            }

            field(LearnMore; LearnMoreTxt)
            {
                ApplicationArea = All;
                Caption = ' '; // Added because of CodeCop
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Go to the official documentation to learn more.';

                trigger OnDrillDown()
                begin
                    HyperLink('https://go.microsoft.com/fwlink/?linkid=2121503');

                    SendTraceTag('0000C0V', 'Global Admin Notification', Verbosity::Normal, 'User opened Global Admin documentation.', DataClassification::SystemMetadata);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Ok)
            {
                ApplicationArea = All;
                Caption = 'Got it!';
                Image = Info;
                InFooterBar = true;
                ToolTip = 'Close the page.';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }

        }
    }

    trigger OnInit()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        // Load icon
        if MediaRepository.Get('AssistedSetupInfo-NoText.png', Format(ClientTypeManagement.GetCurrentClientType())) then
            if MediaResources.Get(MediaRepository."Media Resources Ref") then
                IconVisible := true;
    end;

    var
        MediaRepository: Record "Media Repository";
        MediaResources: Record "Media Resources";
        LearnMoreTxt: Label 'Learn more';
        IconVisible: Boolean;
}