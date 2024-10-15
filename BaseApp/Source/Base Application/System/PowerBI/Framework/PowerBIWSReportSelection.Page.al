namespace System.Integration.PowerBI;

page 6322 "Power BI WS Report Selection"
{
    Caption = 'Power BI Reports Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Power BI Selection Element";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(ElementsRepeater)
            {
                IndentationColumn = IndentationValue;
                IndentationControls = Name;
                ShowAsTree = true;
                Visible = HasReports and not IsErrorMessageVisible;

                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the Power BI report or workspace.';
                    StyleExpr = IndentationValue = 0;
                    Style = Strong;

                    trigger OnDrillDown()
                    begin
                        if Rec.Type <> Rec.Type::"Report" then
                            exit;

                        // Event handler for when the user clicks the report name hyperlink. This automatically selects
                        // and enables the report and closes the window, so the user immediately sees the clicked report
                        // on the parent page.
                        Rec.Enabled := true;

                        // OnDrillDown returns a LookupCancel Action when the page closes.
                        // IsPgclosedOkay is used to tell the caller of this page that inspite of the LookupCancel
                        // the action should be treated like a LookupOk
                        IsPgClosedOkay := true;
                        SaveAndClose();
                    end;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID';
                    Editable = false;
                    Visible = ShowAdditionalFields;
                    ToolTip = 'Specifies the ID of the Power BI report or workspace.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    Editable = false;
                    Visible = ShowAdditionalFields;
                    ToolTip = 'Specifies the type of the line (e.g. workspace or report).';
                }
                field(WorkspaceID; Rec.WorkspaceID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Workspace ID';
                    Editable = false;
                    Visible = ShowAdditionalFields;
                    ToolTip = 'Specifies the ID of the workspace that this record is in (if the record is a workspace, this is the same as the ID).';
                }
                field(WorkspaceName; Rec.WorkspaceName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Workspace Name';
                    Editable = false;
                    Visible = ShowAdditionalFields;
                    ToolTip = 'Specifies the name of the workspace that this record is in (if the record is a workspace, this is the same as the Name).';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this report is enabled to be shown in the given page. This field has no effect for workspaces.';
                    Enabled = IndentationValue <> 0;
                }
            }
            group(NoAvailableReportsGroup)
            {
                ShowCaption = false;
                Visible = not HasReports and not IsErrorMessageVisible;
                label(NoReportsError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'There are no reports available from Power BI.';
                    ToolTip = 'Specifies that the Power BI APIs did not return any report to show.';
                }
            }
            group(ErrorMessageGroup)
            {
                ShowCaption = false;
                Visible = IsErrorMessageVisible;
                field(ErrorMessage; ErrorMessageText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies an error that occurred.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action(EnableReport)
            {
                ApplicationArea = All;
                Caption = 'Enable';
                Enabled = not Rec.Enabled and (Rec.Type = Rec.Type::"Report");
                Gesture = LeftSwipe;
                Image = "Report";
                Scope = Repeater;
                ToolTip = 'Enables the report selection.';

                trigger OnAction()
                begin
                    Rec.Enabled := true;
                    CurrPage.Update();
                end;
            }
            action(DisableReport)
            {
                ApplicationArea = All;
                Caption = 'Disable';
                Enabled = Rec.Enabled and (Rec.Type = Rec.Type::"Report");
                Gesture = RightSwipe;
                Image = "Report";
                Scope = Repeater;
                ToolTip = 'Disables the report selection.';

                trigger OnAction()
                begin
                    Rec.Enabled := false;
                    CurrPage.Update();
                end;
            }
#if not CLEAN23
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh List';
                Image = Refresh;
                ToolTip = 'Update the report list with any newly added reports.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This page should not stay open for long. Refresh is not necessary.';
                ObsoleteTag = '23.0';
                Visible = false;
                trigger OnAction()
                begin
                    IsErrorMessageVisible := false;

                    if not TryLoadReportsList() then
                        ShowLatestErrorMessage();
                end;
            }
#endif
            action(MyOrganization)
            {
                ApplicationArea = All;
                Caption = 'My Organization';
                Image = PowerBI;
                ToolTip = 'Browse content packs that other people in your organization have published.';

                trigger OnAction()
                begin
                    // Opens a new browser tab to Power BI's content pack list, set to the My Organization tab.
                    HyperLink(PowerBIServiceMgt.GetContentPacksMyOrganizationUrl());
                end;
            }
            action(Services)
            {
                ApplicationArea = All;
                Caption = 'Services';
                Image = PowerBI;
                ToolTip = 'Choose content packs from online services that you use.';

                trigger OnAction()
                begin
                    // Opens a new browser tab to AppSource's content pack list, filtered to NAV reports.
                    HyperLink(PowerBIServiceMgt.GetContentPacksServicesUrl());
                end;
            }
#if not CLEAN23
            action(ConnectionInfo)
            {
                ApplicationArea = All;
                Caption = 'Connection Information';
                Image = Setup;
                RunObject = Page "Content Pack Setup Wizard";
                ToolTip = 'Show information for connecting to Power BI content packs.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Instead, follow the Business Central documentation page "Building Power BI Reports to Display Dynamics 365 Business Central Data" available at https://learn.microsoft.com/en-gb/dynamics365/business-central/across-how-use-financials-data-source-powerbi';
                ObsoleteTag = '23.0';
            }
#endif
            action(CleanDeployments)
            {
                ApplicationArea = All;
                Caption = 'Default Reports';
                Image = Setup;
                ToolTip = 'Manage your deployed default reports.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Power BI Deployments");
                    // TODO: Set this button's visibility to equal "IsSaaS" so it's not visible for on-prem, where we won't have OOB uploads anyways.
                end;
            }
        }
        area(Promoted)
        {
#if not CLEAN23
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
                ObsoleteReason = 'This group was empty.';
                ObsoleteState = Pending;
                ObsoleteTag = '23.0';
            }
#endif
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(EnableReport_Promoted; EnableReport)
                {
                }
                actionref(DisableReport_Promoted; DisableReport)
                {
                }
                actionref(CleanDeployments_Promoted; CleanDeployments)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Get Reports', Comment = 'Generated from the PromotedActionCategories property index 4.';

#if not CLEAN23
                actionref(Refresh_Promoted; Refresh)
                {
                    ObsoleteReason = 'Action removed.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '23.0';
                    Visible = false;
                }
#endif
                actionref(MyOrganization_Promoted; MyOrganization)
                {
                }
                actionref(Services_Promoted; Services)
                {
                }
#if not CLEAN23
                actionref(ConnectionInfo_Promoted; ConnectionInfo)
                {
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Instead, follow the Business Central documentation page "Building Power BI Reports to Display Dynamics 365 Business Central Data" available at https://learn.microsoft.com/en-gb/dynamics365/business-central/across-how-use-financials-data-source-powerbi';
                    ObsoleteTag = '23.0';
                }
#endif
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not TryLoadReportsList() then
            ShowLatestErrorMessage();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        OriginalFilterGroup: Integer;
        OriginalFilter: Text;
    begin
        // If we are doing a cross-column search, always include the workspaces (e.g. for search in the page)
        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(-1);
        OriginalFilter := Rec.GetFilters();

        if OriginalFilter <> '' then
            Rec.SetRange(Type, Rec.Type::Workspace);

        Rec.FilterGroup(OriginalFilterGroup);

        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.Next(Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Type of
            Rec.Type::"Report":
                IndentationValue := 1;
            Rec.Type::Workspace:
                IndentationValue := 0;
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction in [Action::LookupOK, Action::OK]) or IsPageClosedOkay() then
            SaveAndClose();
    end;

    var
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBIWorkspaceMgt: Codeunit "Power BI Workspace Mgt.";
        PageContext: Text[30];
        IndentationValue: Integer;
        IsPgClosedOkay: Boolean;
        HasReports: Boolean;
        IsErrorMessageVisible: Boolean;
        ShowAdditionalFields: Boolean; // This value is always false, but dynamic visibility of fields enables testability
        ErrorMessageText: Text;
        FailedToLoadReportListTelemetryErr: Label 'PowerBIReportSelection failed to load reports. Error message: %1', Locked = true;
#if not CLEAN21
        FailedToInsertReportTelemetryMsg: Label 'Failed to insert report in buffer (has null id: %1).', Locked = true;
#endif

    procedure SetContext(ParentContext: Text[30])
    begin
        // Sets the ID of the parent page that reports are being selected for.
        PageContext := ParentContext;
    end;

    [TryFunction]
    local procedure TryLoadReportsList()
    begin
        // Clears and retrieves a list of all reports in the user's Power BI account.
        Rec.Reset();
        Rec.DeleteAll();
        PowerBIWorkspaceMgt.GetReportsAndWorkspaces(Rec, PageContext);

        if Rec.IsEmpty then begin
            HasReports := false;
            Rec.Insert(); // Hack to prevent empty list error.
        end else begin
            HasReports := true;

            // Set sort order, scrollbar position, and filters.
            Rec.SetCurrentKey(WorkspaceID, Type, Name); // Ensures the workspaces 
            Rec.FindFirst();
        end;
    end;

    local procedure SaveAndClose()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIContextSettings: Record "Power BI Context Settings";
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
    begin
        // Use a temp buffer record for saving to not disturb the position of the source table
        TempPowerBISelectionElement.Copy(Rec, true);

        PowerBIDisplayedElement.SetRange(UserSID, UserSecurityId());
        PowerBIDisplayedElement.SetRange(Context, PageContext);
        PowerBIDisplayedElement.DeleteAll(true);
        PowerBIDisplayedElement.Reset();

        TempPowerBISelectionElement.SetRange(Enabled, true);
        if TempPowerBISelectionElement.Find('-') then
            repeat
                if TempPowerBISelectionElement.Type = TempPowerBISelectionElement.Type::"Report" then begin
                    PowerBIDisplayedElement.Init();
                    PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(TempPowerBISelectionElement.ID);
                    PowerBIDisplayedElement.UserSID := UserSecurityId();
                    PowerBIDisplayedElement.ElementType := TempPowerBISelectionElement.Type;
                    PowerBIDisplayedElement.ElementName := TempPowerBISelectionElement.Name;
                    PowerBIDisplayedElement.Context := PageContext;
                    PowerBIDisplayedElement.ElementEmbedUrl := TempPowerBISelectionElement.EmbedUrl;
                    PowerBIDisplayedElement.WorkspaceName := TempPowerBISelectionElement.WorkspaceName;
                    PowerBIDisplayedElement.WorkspaceID := TempPowerBISelectionElement.WorkspaceID;
                    PowerBIDisplayedElement.ShowPanesInNormalMode := false;
                    PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
                    PowerBIDisplayedElement.Insert(true);
                end
            until TempPowerBISelectionElement.Next() = 0;

        if not PowerBIDisplayedElement.Get(UserSecurityId(), PageContext, Rec.ID, Rec.Type) then begin
            PowerBIDisplayedElement.SetRange(UserSID, UserSecurityId());
            PowerBIDisplayedElement.SetRange(Context, PageContext);
            if not PowerBIDisplayedElement.FindFirst() then
                Clear(PowerBIDisplayedElement);
        end;

        PowerBIContextSettings.CreateOrUpdateSelectedElement(PowerBIDisplayedElement);

        IsPgClosedOkay := true;
        CurrPage.Close();
    end;

    procedure IsPageClosedOkay(): Boolean
    begin
        exit(IsPgClosedOkay);
    end;

    local procedure ShowLatestErrorMessage()
    begin
        ErrorMessageText := GetLastErrorText();
        if ErrorMessageText = '' then
            ErrorMessageText := PowerBIServiceMgt.GetGenericError();

        IsErrorMessageVisible := true;
        Session.LogMessage('0000F5B', StrSubstNo(FailedToLoadReportListTelemetryErr, GetLastErrorText(true)), Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
    end;

#if not CLEAN21
    [Obsolete('Use the page builtin function GetRecord instead.', '21.0')]
    [Scope('OnPrem')]
    procedure GetSelectedReports(var TempPowerBIReportBuffer: Record "Power BI Report Buffer" temporary)
    var
        TempPowerBISelectionElement: Record "Power BI Selection Element" temporary;
    begin
        TempPowerBIReportBuffer.Reset();
        TempPowerBIReportBuffer.DeleteAll();

        TempPowerBISelectionElement.Copy(Rec, true);
        TempPowerBISelectionElement.Reset();
        TempPowerBISelectionElement.SetRange(Enabled, true);
        TempPowerBISelectionElement.SetRange(Type, TempPowerBISelectionElement.Type::"Report");

        if TempPowerBISelectionElement.FindSet() then
            repeat
                TempPowerBIReportBuffer.Init();

                TempPowerBIReportBuffer.ReportID := TempPowerBISelectionElement.ID;
                TempPowerBIReportBuffer.ReportName := CopyStr(TempPowerBISelectionElement.Name, 1, MaxStrLen(TempPowerBIReportBuffer.ReportName));
                TempPowerBIReportBuffer.Enabled := TempPowerBISelectionElement.Enabled;
                TempPowerBIReportBuffer.ReportEmbedUrl := TempPowerBISelectionElement.EmbedUrl;
                TempPowerBIReportBuffer."Workspace ID" := TempPowerBISelectionElement.WorkspaceID;
                TempPowerBIReportBuffer."Workspace Name" := TempPowerBISelectionElement.WorkspaceName;

                if not TempPowerBIReportBuffer.Insert() then
                    Session.LogMessage('0000FDQ', StrSubstNo(FailedToInsertReportTelemetryMsg, IsNullGuid(TempPowerBIReportBuffer.ReportID)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBIServiceMgt.GetPowerBiTelemetryCategory());
            until TempPowerBISelectionElement.Next() = 0;

        if TempPowerBIReportBuffer.Get(Rec.ID) then;
    end;
#endif
}

