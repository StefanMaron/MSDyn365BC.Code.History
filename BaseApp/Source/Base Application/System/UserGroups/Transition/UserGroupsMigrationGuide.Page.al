#if not CLEAN22
namespace System.Security.AccessControl;

using System.Apps;
using System.Environment;
using System.Telemetry;
using System.Utilities;

page 9045 "User Groups Migration Guide"
{
    Caption = 'User Groups Migration Guide';
    PageType = NavigatePage;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    ShowFilter = false;
    Extensible = true;
    SaveValues = true;
    ApplicationArea = All;
    SourceTable = "User Group";
    ObsoleteState = Pending;
    ObsoleteReason = '[220_UserGroups] User groups functionality is deprecated. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    ObsoleteTag = '22.0';

    layout
    {
        area(Content)
        {
            group(Banner)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinishVisible;
                field(TopBanner; MediaResourcesStandard."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(BannerDone)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinishVisible;
                field(TopBannerDone; MediaResourcesDone."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }

            group(Intro)
            {
                ShowCaption = false;
                Visible = CurrentPage = CurrentPage::Introduction;

                group(Intro1)
                {
                    ShowCaption = false;
                    InstructionalText = 'Welcome to the User Groups Migration guide. This guide will help you to stop using user groups for managing user permissions. User groups will be removed in a future release.';
                }
                group(Intro2)
                {
                    ShowCaption = false;
                    InstructionalText = 'On the next step you''ll specify how to convert your user groups. Afterward, your user groups will be removed.';
                }
                group(Intro3)
                {
                    ShowCaption = false;
                    InstructionalText = 'If you regret removing user groups, you can turn off the ''Convert user group permissions'' feature switch on the Feature Management page. You''ll have to manually recreate your user groups.';
                }
                group(IntroWarning)
                {
                    Visible = Has3rdPartyExtensions;
                    ShowCaption = false;

                    field(IntroWarning1; ThirdPartyExtensionsWarningTxt)
                    {
                        Style = Attention;
                        ShowCaption = false;
                    }

                    field(ConfirmationField; ConfirmedRiskAcknowledgement)
                    {
                        ApplicationArea = All;
                        Caption = 'I understand and want to continue.';
                        ToolTip = 'Specifies that you understand that continuing this guide may have unintentional consequences for third party extensions.';

                        trigger OnValidate()
                        var
                            Telemetry: Codeunit Telemetry;
                        begin
                            UpdateControls();
                            Telemetry.LogMessage('0000JQ6', StrSubstNo(AcknowledgingTheRiskTelemetryTxt, ConfirmedRiskAcknowledgement), Verbosity::Normal, DataClassification::SystemMetadata);
                        end;
                    }
                }
            }
            group(GroupMigrationActionSelection)
            {
                Caption = 'Select user group migration action';
                Visible = CurrentPage = CurrentPage::"Group Migration Action Selection";

                group(GroupMigrationInfo1)
                {
                    ShowCaption = false;
                    InstructionalText = 'Specify how to convert the permissions that are assigned to each user group.';
                }
                group(GroupMigrationInfo2)
                {
                    Caption = 'Assign permissions to members';
                    InstructionalText = 'Assign permissions directly to the users and remove their user group assignments. This is the recommended option in most cases.';
                }
                group(GroupMigrationInfo3)
                {
                    Caption = 'Convert to a permission set';
                    InstructionalText = 'Continue to use the same group of permissions that you''d specified for your user group. Combine the permissions from the user groups into a new permission set. The new permission set is assigned to all members of the user group.';
                }

                repeater("User Groups")
                {
                    field(Code; Rec.Code)
                    {
                        Editable = false;
                        Caption = 'User Group Code';
                        ToolTip = 'Specifies the code of the user group.';

                        trigger OnDrillDown()
                        var
                            UserGroupPermissionSet: Record "User Group Permission Set";
                            UserGroupPermissionSets: Page "User Group Permission Sets";
                        begin
                            UserGroupPermissionSet.SetRange("User Group Code", Rec.Code);
                            UserGroupPermissionSets.SetTableView(UserGroupPermissionSet);
                            UserGroupPermissionSets.Run();
                        end;
                    }
                    field(Name; Rec.Name)
                    {
                        Editable = false;
                        Caption = 'User Group Name';
                        ToolTip = 'Specifies the name of the user group.';
                    }
                    field(GroupMigrationAction; GroupMigrationOption)
                    {
                        Editable = true;
                        Caption = 'Action';
                        ToolTip = 'Select the appropriate action for user group migration.';
                        OptionCaption = 'Assign permissions to members,Convert to a permission set';

                        trigger OnValidate()
                        begin
                            if GroupMigrationOption = GroupMigrationOption::Convert then begin
                                if not UserGroupsToConvert.Contains(Rec.Code) then
                                    UserGroupsToConvert.Add(Rec.Code);
                            end else
                                if UserGroupsToConvert.Contains(Rec.Code) then
                                    UserGroupsToConvert.Remove(Rec.Code);
                        end;
                    }
                }
            }
            group(Conclusion)
            {
                Visible = CurrentPage = CurrentPage::Conclusion;
                ShowCaption = false;
                InstructionalText = 'All done. Click Finish to close the guide.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Skip)
            {
                Caption = 'Skip';
                Visible = SkipVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep();
                end;
            }
            action(Previous)
            {
                Caption = 'Previous';
                Visible = PreviousVisible;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    PreviousPage();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                Enabled = NextEnabled;
                Visible = NextVisible;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextPage();
                end;
            }
            action(MigrateUserGroups)
            {
                Caption = 'Next';
                Visible = CurrentPage = CurrentPage::"Group Migration Action Selection";
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    UpgradeUserGroups: Codeunit "Upgrade User Groups";
                begin
                    UpgradeUserGroups.MigrateUserGroups(UserGroupsToConvert);
                    NextPage();
                end;
            }
            action(Finish)
            {
                Caption = 'Finish';
                Visible = FinishVisible;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishGuide();
                end;
            }
        }
    }

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        UserGroupsToConvert: List of [Code[20]];
        Pages: List of [Enum "User Grp. Migration Guide Page"];
        SkipTo: Dictionary of [Enum "User Grp. Migration Guide Page", Enum "User Grp. Migration Guide Page"];
        HideNext: List of [Enum "User Grp. Migration Guide Page"];
        CurrentPage: Enum "User Grp. Migration Guide Page";
        PrevPage: Enum "User Grp. Migration Guide Page";
        PreviousVisible: Boolean;
        SkipVisible: Boolean;
        NextEnabled: Boolean;
        NextVisible: Boolean;
        FinishVisible: Boolean;
        TopBannerVisible: Boolean;
        ConfirmedRiskAcknowledgement: Boolean;
        Has3rdPartyExtensions: Boolean;
        GroupMigrationOption: Option Skip,Convert;
        ThirdPartyExtensionsWarningTxt: Label 'You may have some extensions in your system that still require the user groups functionality to be enabled.';
        AcknowledgingTheRiskTelemetryTxt: Label 'Acknowledging the risk of affecting 3rd party extensions during user group migration: %1', Locked = true;

    trigger OnOpenPage()
    var
        PublishedApplication: Record "Published Application";
    begin
        PublishedApplication.SetFilter(Publisher, '<>%1', 'Microsoft');
        if not PublishedApplication.IsEmpty() then
            Has3rdPartyExtensions := true;

        InitGuide();
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;

    end;

    local procedure UpdateControls()
    begin
        SkipVisible := SkipTo.ContainsKey(CurrentPage);
        PreviousVisible := (Pages.IndexOf(CurrentPage) > 1) and (Pages.IndexOf(CurrentPage) < Pages.Count());
        NextEnabled := Pages.IndexOf(CurrentPage) < Pages.Count();
        NextVisible := (not HideNext.Contains(CurrentPage)) and (Pages.IndexOf(CurrentPage) < Pages.Count());
        FinishVisible := Pages.IndexOf(CurrentPage) = Pages.Count();

        if Has3rdPartyExtensions then
            NextEnabled := NextEnabled and ConfirmedRiskAcknowledgement;

        OnAfterUpdateControls(CurrentPage);
    end;

    local procedure PreviousPage()
    begin
        if PrevPage <> PrevPage::Blank then begin
            CurrentPage := PrevPage;
            PrevPage := PrevPage::Blank;
        end else
            Pages.Get(Pages.IndexOf(CurrentPage) - 1, CurrentPage);
        UpdateControls();
    end;

    local procedure NextStep()
    begin
        PrevPage := CurrentPage;
        SkipTo.Get(CurrentPage, CurrentPage);
        UpdateControls();
    end;

    protected procedure NextPage()
    begin
        Pages.Get(Pages.IndexOf(CurrentPage) + 1, CurrentPage);
        UpdateControls();
    end;

    local procedure FinishGuide()
    begin
        CurrPage.Close();
    end;

    local procedure InitGuide()
    begin
        LoadPages();
        Pages.Get(1, CurrentPage);
        UpdateControls();
    end;

    local procedure LoadPages()
    begin
        Pages.Add(CurrentPage::Introduction);
        Pages.Add(CurrentPage::"Group Migration Action Selection");
        Pages.Add(CurrentPage::Conclusion);

        HideNext.Add(CurrentPage::"Group Migration Action Selection");

        OnAfterLoadPages(Pages, SkipTo, HideNext);
    end;

    /// <summary>
    /// Use this event to add new pages to the guide.
    /// </summary>
    /// <param name="Pages">The list of pages that make up the guide.</param>
    /// <param name="SkipTo">A dictionary which defines which pages allow skipping to another page. The dictionary key is the page from which you can skip, the value is the page to which you can skip.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadPages(var GuidePages: List of [Enum "User Grp. Migration Guide Page"]; var SkipTo: Dictionary of [Enum "User Grp. Migration Guide Page", Enum "User Grp. Migration Guide Page"]; var HideNext: List of [Enum "User Grp. Migration Guide Page"])
    begin
    end;

    /// <summary>
    /// Use this event to set the visibility of pages in the guide.
    /// </summary>
    /// <param name="CurrentPage">The current page of the guide.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateControls(CurrentPage: Enum "User Grp. Migration Guide Page");
    begin
    end;
}
#endif