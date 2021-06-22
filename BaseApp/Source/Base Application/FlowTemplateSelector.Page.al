page 6400 "Flow Template Selector"
{
    ApplicationArea = Suite;
    Caption = 'Select an Existing Flow Template';
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            grid(Control7)
            {
                ShowCaption = false;
                group(Control8)
                {
                    ShowCaption = false;
                    group(Control11)
                    {
                        ShowCaption = false;
                        Visible = IsUserReadyForFlow and not IsErrorMessageVisible;

                        field(EnvironmentNameText; EnvironmentNameText)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group(Control4)
                    {
                        ShowCaption = false;
                        Visible = IsUserReadyForFlow and not IsErrorMessageVisible;

                        field(SearchFilter; SearchText)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Search Filter';
                            ToolTip = 'Specifies a search filter on the templates.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if AddInReady then
                                    CurrPage.FlowAddin.LoadTemplates(FlowServiceManagement.GetFlowEnvironmentID, SearchText,
                                      FlowServiceManagement.GetFlowTemplatePageSize, FlowServiceManagement.GetFlowTemplateDestinationDetails);
                            end;
                        }
                        usercontrol(FlowAddin; "Microsoft.Dynamics.Nav.Client.FlowIntegration")
                        {
                            ApplicationArea = Basic, Suite;

                            trigger ControlAddInReady()
                            begin
                                CurrPage.FlowAddin.Initialize(
                                  FlowServiceManagement.GetFlowUrl, FlowServiceManagement.GetLocale,
                                  AzureAdMgt.GetAccessToken(FlowServiceManagement.GetFlowServiceResourceUrl(), FlowServiceManagement.GetFlowResourceName, false)
                                );

                                LoadTemplates;

                                AddInReady := true;
                            end;

                            trigger ErrorOccurred(error: Text; description: Text)
                            var
                                Company: Record Company;
                                ActivityLog: Record "Activity Log";
                            begin
                                Company.Get(CompanyName); // Dummy record to attach to activity log
                                ActivityLog.LogActivityForUser(
                                  Company.RecordId, ActivityLog.Status::Failed, 'Microsoft Flow', description, error, UserId);
                                ShowErrorMessage(FlowServiceManagement.GetGenericError);
                            end;

                            trigger Refresh()
                            begin
                                if AddInReady then
                                    LoadTemplates;
                            end;
                        }
                    }
                    group(Control5)
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
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        UrlHelper: Codeunit "Url Helper";
    begin
        if UrlHelper.IsPPE then begin
            ShowErrorMessage(FlowServiceManagement.GetFlowPPEError);
            exit;
        end;

        IsErrorMessageVisible := false;
        if not TryInitialize then
            ShowErrorMessage(GetLastErrorText);
        if not FlowServiceManagement.IsUserReadyForFlow then
            Error('');
        IsUserReadyForFlow := true;
        if SearchText = '' then
            SearchText := FlowServiceManagement.GetTemplateFilter;
        SetSearchText(SearchText);

        if not FlowServiceManagement.HasUserSelectedFlowEnvironment then
            FlowServiceManagement.SetSelectedFlowEnvironmentIDToDefault;
    end;

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        FlowServiceManagement: Codeunit "Flow Service Management";
        SearchText: Text;
        ErrorMessageText: Text;
        IsErrorMessageVisible: Boolean;
        IsUserReadyForFlow: Boolean;
        AddInReady: Boolean;
        EnvironmentNameText: Text;

    procedure SetSearchText(Search: Text)
    begin
        if Search = '' then
            Search := FlowServiceManagement.GetTemplateFilter;
        SearchText := Search;
    end;

    local procedure LoadTemplates()
    begin
        EnvironmentNameText := FlowServiceManagement.GetSelectedFlowEnvironmentName;
        CurrPage.FlowAddin.LoadTemplates(FlowServiceManagement.GetFlowEnvironmentID, SearchText,
          FlowServiceManagement.GetFlowTemplatePageSize, FlowServiceManagement.GetFlowTemplateDestinationDetails);
        CurrPage.Update;
    end;

    [TryFunction]
    local procedure TryInitialize()
    begin
        IsUserReadyForFlow := FlowServiceManagement.IsUserReadyForFlow;

        if not IsUserReadyForFlow then begin
            if AzureAdMgt.IsSaaS then
                Error(FlowServiceManagement.GetGenericError);
            if not TryGetAccessTokenForFlowService then
                ShowErrorMessage(GetLastErrorText);
            CurrPage.Update;
        end;
    end;

    [TryFunction]
    local procedure TryGetAccessTokenForFlowService()
    begin
        AzureAdMgt.GetAccessToken(FlowServiceManagement.GetFlowServiceResourceUrl(), FlowServiceManagement.GetFlowResourceName, true)
    end;

    local procedure ShowErrorMessage(TextToShow: Text)
    begin
        IsErrorMessageVisible := true;
        IsUserReadyForFlow := false;
        if TextToShow = '' then
            TextToShow := FlowServiceManagement.GetGenericError;
        ErrorMessageText := TextToShow;
        CurrPage.Update;
    end;
}

