#if not CLEAN22
namespace System.Automation;

using Microsoft.Utilities;
using System.Azure.Identity;
using System.Environment;
using System.Integration.PowerBI;
using System.Utilities;

page 6401 "Flow Selector"
{
    ApplicationArea = Suite;
    Caption = 'Manage Power Automate Flows';
    Editable = false;
    LinksAllowed = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This funcionality has been moved to Power Automate menu';
    ObsoleteTag = '22.0';
    layout
    {
        area(content)
        {
            grid(Control10)
            {
                ShowCaption = false;
                Visible = IsUserReadyForFlow and not IsErrorMessageVisible;
                field(EnvironmentNameText; EnvironmentNameText)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                }
            }
            group(Control3)
            {
                ShowCaption = false;
                Visible = IsUserReadyForFlow and not IsErrorMessageVisible;
                usercontrol(FlowAddin; FlowIntegration)
                {
                    ApplicationArea = Basic, Suite;

                    trigger ControlAddInReady()
                    begin
                        InitializeAddIn();
                    end;

                    trigger ErrorOccurred(error: Text; description: Text)
                    var
                        Company: Record Company;
                        ActivityLog: Record "Activity Log";
                    begin
                        Company.Get(CompanyName); // Dummy record to attach to activity log
                        ActivityLog.LogActivityForUser(
                          Company.RecordId, ActivityLog.Status::Failed, 'Power Automate', description, error, UserId);
                        ShowErrorMessage(FlowServiceManagement.GetGenericError());
                    end;

                    trigger Refresh()
                    begin
                        if AddInReady then
                            LoadFlows();
                    end;
                }
            }
            group(Control4)
            {
                ShowCaption = false;
                Visible = IsErrorMessageVisible;
                field(ErrorMessageText; ErrorMessageText)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenMyFlows)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Power Automate';
                Image = Flow;
                ToolTip = 'View and configure flows on the Power Automate website.';
                Visible = not IsPPE;

                trigger OnAction()
                begin
                    HyperLink(FlowServiceManagement.GetFlowManageUrl());
                end;
            }
            action(SelectFlowUserEnvironment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Environment';
                Image = CheckList;
                ToolTip = 'Select your Power Automate environment.';
                Visible = not IsPPE;

                trigger OnAction()
                var
                    FlowUserEnvironmentConfig: Record "Flow User Environment Config";
                    TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
                    FlowUserEnvSelection: Page "Flow User Env. Selection";
                begin
                    TempFlowUserEnvironmentBuffer.Reset();
                    FlowServiceManagement.GetEnvironments(TempFlowUserEnvironmentBuffer);
                    FlowUserEnvSelection.SetFlowEnvironmentBuffer(TempFlowUserEnvironmentBuffer);
                    FlowUserEnvSelection.LookupMode(true);

                    if FlowUserEnvSelection.RunModal() <> ACTION::LookupOK then
                        exit;

                    TempFlowUserEnvironmentBuffer.Reset();
                    TempFlowUserEnvironmentBuffer.SetRange(Enabled, true);

                    // Remove any previous selection since user did not select anything
                    if not TempFlowUserEnvironmentBuffer.FindFirst() then begin
                        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
                            FlowUserEnvironmentConfig.Delete();
                        exit;
                    end;

                    FlowServiceManagement.SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer);
                    LoadFlows();
                end;
            }
            action(ConnectionInfo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Connection Information';
                Image = Setup;
                RunObject = Page "Content Pack Setup Wizard";
                ToolTip = 'Show information for connecting to Power BI content packs.';
                Visible = not IsPPE;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';
                actionref(OpenMyFlows_Promoted; OpenMyFlows)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Configuration', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(SelectFlowUserEnvironment_Promoted; SelectFlowUserEnvironment)
                {
                }
                actionref(ConnectionInfo_Promoted; ConnectionInfo)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        IsPPE := UrlHelper.IsPPE();
        if IsPPE then begin
            ShowErrorMessage(FlowServiceManagement.GetFlowPPEError());
            exit;
        end;

        IsErrorMessageVisible := false;
        if not TryInitialize() then
            ShowErrorMessage(GetLastErrorText);
        if not FlowServiceManagement.IsUserReadyForFlow() then
            Error('');
        IsUserReadyForFlow := true;

        if not FlowServiceManagement.HasUserSelectedFlowEnvironment() then
            FlowServiceManagement.SetSelectedFlowEnvironmentIDToDefault();

        IsSaaS := EnvironmentInfo.IsSaaS();
    end;

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        FlowServiceManagement: Codeunit "Flow Service Management";
        EnvironmentInfo: Codeunit "Environment Information";
        IsErrorMessageVisible: Boolean;
        ErrorMessageText: Text;
        IsUserReadyForFlow: Boolean;
        AddInReady: Boolean;
        EnvironmentNameText: Text;
        IsSaaS: Boolean;
        IsPPE: Boolean;

    local procedure Initialize()
    begin
        IsUserReadyForFlow := FlowServiceManagement.IsUserReadyForFlow();

        if not IsUserReadyForFlow then begin
            if EnvironmentInfo.IsSaaS() then
                Error(FlowServiceManagement.GetGenericError());
            if not TryGetAccessTokenForFlowService() then
                ShowErrorMessage(GetLastErrorText);
            CurrPage.Update();
        end;
    end;

    local procedure LoadFlows()
    begin
        EnvironmentNameText := FlowServiceManagement.GetSelectedFlowEnvironmentName();
        CurrPage.FlowAddin.LoadFlows(FlowServiceManagement.GetFlowEnvironmentID());
        CurrPage.Update();
    end;

    [TryFunction]
    local procedure TryInitialize()
    begin
        Initialize();
    end;

    [NonDebuggable]
    [TryFunction]
    local procedure TryGetAccessTokenForFlowService()
    begin
        AzureAdMgt.GetAccessToken(FlowServiceManagement.GetFlowServiceResourceUrl(), FlowServiceManagement.GetFlowResourceName(), true)
    end;

    local procedure ShowErrorMessage(TextToShow: Text)
    begin
        IsErrorMessageVisible := true;
        IsUserReadyForFlow := false;
        if TextToShow = '' then
            TextToShow := FlowServiceManagement.GetGenericError();
        ErrorMessageText := TextToShow;
        CurrPage.Update();
    end;

    [NonDebuggable]
    local procedure InitializeAddIn()
    begin
        CurrPage.FlowAddin.Initialize(
            FlowServiceManagement.GetFlowUrl(), FlowServiceManagement.GetLocale(),
            AzureAdMgt.GetAccessToken(FlowServiceManagement.GetFlowServiceResourceUrl(), FlowServiceManagement.GetFlowResourceName(), false)
        );

        LoadFlows();

        AddInReady := true;
    end;
}
#endif
