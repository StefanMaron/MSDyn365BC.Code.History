page 9062 "User Security Activities"
{
    Caption = 'User Security Activities';
    Editable = false;
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "User Security Status";

    layout
    {
        area(content)
        {
            cuegroup("Intelligent Cloud")
            {
                Caption = 'Intelligent Cloud';
                Visible = ShowIntelligentCloud;

                actions
                {
                    action("Learn More")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Learn More';
                        Image = TileInfo;
                        RunPageMode = View;
                        ToolTip = ' Learn more about the Intelligent Cloud and how it can help your business.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudLearnMoreUrl);
                        end;
                    }
                    action("Intelligent Cloud Insights")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Intelligent Cloud Insights';
                        Image = TileCloud;
                        RunPageMode = View;
                        ToolTip = 'View your Intelligent Cloud insights.';

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudInsightsUrl);
                        end;
                    }
                }
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field("Users - To review"; "Users - To review")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users - To review';
                    DrillDownPageID = "User Security Status List";
                    Editable = false;
                    ToolTip = 'Specifies new users who have not yet been reviewed by an administrator.';
                }
                field("Users - Without Subscriptions"; UsersWithoutSubscriptions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users - Without Subscription Plans';
                    DrillDownPageID = "User Security Status List";
                    Editable = false;
                    ToolTip = 'Specifies users without subscription to use Business Central.';
                    Visible = SoftwareAsAService;
                }
                field("Users - Not Group Members"; "Users - Not Group Members")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users - Not Group Members';
                    DrillDownPageID = "User Security Status List";
                    Editable = false;
                    ToolTip = 'Specifies users who have not yet been reviewed by an administrator.';
                    Visible = SoftwareAsAService;
                }
                field(NumberOfPlans; NumberOfPlans)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of plans';
                    ToolTip = 'Specifies the number of plans.';
                    Visible = SoftwareAsAService;

                    trigger OnDrillDown()
                    begin
                        if not SoftwareAsAService then
                            exit;
                        PAGE.Run(PAGE::Plans)
                    end;
                }
            }
            cuegroup("Data Privacy")
            {
                Caption = 'Data Privacy';
                field(UnclassifiedFields; UnclassifiedFields)
                {
                    ApplicationArea = All;
                    Caption = 'Fields Missing Data Sensitivity';
                    ToolTip = 'Specifies the number fields with Data Sensitivity set to unclassified.';

                    trigger OnDrillDown()
                    var
                        DataSensitivity: Record "Data Sensitivity";
                    begin
                        DataSensitivity.SetRange("Company Name", CompanyName);
                        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
                        PAGE.Run(PAGE::"Data Classification Worksheet", DataSensitivity);
                    end;
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; "CDS Integration Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowDataIntegrationCues;
                }
                field("Coupled Data Synch Errors"; "Coupled Data Synch Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                }
            }
            usercontrol(SATAsyncLoader; SatisfactionSurveyAsync)
            {
                ApplicationArea = Basic, Suite;
                trigger ResponseReceived(Status: Integer; Response: Text)
                var
                    SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
                begin
                    SatisfactionSurveyMgt.TryShowSurvey(Status, Response);
                end;

                trigger ControlAddInReady();
                begin
                    IsAddInReady := true;
                    CheckIfSurveyEnabled();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
    begin
        RoleCenterNotificationMgt.HideEvaluationNotificationAfterStartingTrial;
    end;

    trigger OnOpenPage()
    var
        UserSecurityStatus: Record "User Security Status";
        DataSensitivity: Record "Data Sensitivity";
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        EnvironmentInfo: Codeunit "Environment Information";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS;
        if SoftwareAsAService then
            NumberOfPlans := GetNumberOfPlans;
        UserSecurityStatus.LoadUsers;
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        UnclassifiedFields := DataSensitivity.Count();

        RoleCenterNotificationMgt.ShowNotifications;
        ConfPersonalizationMgt.RaiseOnOpenRoleCenterEvent;
        ShowIntelligentCloud := not SoftwareAsAService;
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMConnectionSetup.IsEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();

        if PageNotifier.IsAvailable then begin
            PageNotifier := PageNotifier.Create;
            PageNotifier.NotifyPageReady;
        end;
    end;

    trigger OnAfterGetRecord()
    var
        UserSecurityStatus: Record "User Security Status";
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        UsersWithoutSubscriptions := 0;

        if UserSecurityStatus.FindSet() then
            repeat
                if UserSecurityStatus."User Security ID" <> '00000000-0000-0000-0000-000000000000' then
                    if not AzureADPlan.DoesUserHavePlans(UserSecurityStatus."User Security ID") then
                        UsersWithoutSubscriptions := UsersWithoutSubscriptions + 1;
            until UserSecurityStatus.Next() = 0;
    end;

    var
        [RunOnClient]
        [WithEvents]
        PageNotifier: DotNet PageNotifier;
        SoftwareAsAService: Boolean;
        NumberOfPlans: Integer;
        UnclassifiedFields: Integer;
        ShowIntelligentCloud: Boolean;
        ShowD365SIntegrationCues: Boolean;
        ShowDataIntegrationCues: Boolean;
        IsAddInReady: Boolean;
        IsPageReady: Boolean;
        UsersWithoutSubscriptions: Integer;

    local procedure GetNumberOfPlans(): Integer
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        if not SoftwareAsAService then
            exit(0);
        exit(AzureADPlan.GetAvailablePlansCount());
    end;

    trigger PageNotifier::PageReady()
    begin
        IsPageReady := true;
        CheckIfSurveyEnabled();
    end;

    local procedure CheckIfSurveyEnabled()
    var
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
        CheckUrl: Text;
    begin
        if not IsAddInReady then
            exit;
        if not IsPageReady then
            exit;
        if not SatisfactionSurveyMgt.DeactivateSurvey() then
            exit;
        if not SatisfactionSurveyMgt.TryGetCheckUrl(CheckUrl) then
            exit;
        CurrPage.SATAsyncLoader.SendRequest(CheckUrl, SatisfactionSurveyMgt.GetRequestTimeoutAsync());
    end;
}

