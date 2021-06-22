page 6304 "Power BI Report Selection"
{
    Caption = 'Power BI Reports Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Manage,Get Reports';
    SourceTable = "Power BI Report Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Visible = HasReports AND NOT IsErrorMessageVisible AND NOT IsUrlFieldVisible;
                field(ReportName; ReportName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the report.';

                    trigger OnDrillDown()
                    begin
                        // Event handler for when the user clicks the report name hyperlink. This automatically selects
                        // and enables the report and closes the window, so the user immediately sees the clicked report
                        // on the parent page.
                        Enabled := true;

                        // OnDrillDown returns a LookupCancel Action when the page closes.
                        // IsPgclosedOkay is used to tell the caller of this page that inspite of the LookupCancel
                        // the action should be treated like a LookupOk
                        IsPgClosedOkay := true;
                        SaveAndClose;
                    end;
                }
                field(Enabled; Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the report selection is enabled.';
                }
            }
            group(Control6)
            {
                ShowCaption = false;
                Visible = NOT HasReports AND NOT IsErrorMessageVisible AND NOT IsUrlFieldVisible;
                label(NoReportsError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'There are no reports available from Power BI.';
                    ToolTip = 'Specifies that the user needs to select Power BI reports.';
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                Visible = IsErrorMessageVisible AND NOT IsUrlFieldVisible;
                field(ErrorMessage; ErrorMessageText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies an error that occurred.';
                }
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = IsUrlFieldVisible;
                field(ErrorLink; ErrorUrlText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = TRUE;
                    ToolTip = 'Specifies an error that occurred and how to resolve it.';

                    trigger OnDrillDown()
                    begin
                        HyperLink(ErrorUrlPath);
                    end;
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
                Enabled = NOT Enabled;
                Gesture = LeftSwipe;
                Image = "Report";
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Enables the report selection.';

                trigger OnAction()
                begin
                    Enabled := true;
                    CurrPage.Update;
                end;
            }
            action(DisableReport)
            {
                ApplicationArea = All;
                Caption = 'Disable';
                Enabled = Enabled;
                Gesture = RightSwipe;
                Image = "Report";
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Disables the report selection.';

                trigger OnAction()
                begin
                    Enabled := false;
                    CurrPage.Update;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh List';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Update the report list with any newly added reports.';

                trigger OnAction()
                begin
                    IsErrorMessageVisible := false;
                    IsUrlFieldVisible := false;

                    if not TryLoadReportsList then
                        ShowLatestErrorMessage();
                end;
            }
            action(MyOrganization)
            {
                ApplicationArea = All;
                Caption = 'My Organization';
                Image = PowerBI;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedOnly = true;
                ToolTip = 'Browse content packs that other people in your organization have published.';

                trigger OnAction()
                begin
                    // Opens a new browser tab to Power BI's content pack list, set to the My Organization tab.
                    HyperLink(PowerBIServiceMgt.GetContentPacksMyOrganizationUrl);
                end;
            }
            action(Services)
            {
                ApplicationArea = All;
                Caption = 'Services';
                Image = PowerBI;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedOnly = true;
                ToolTip = 'Choose content packs from online services that you use.';

                trigger OnAction()
                begin
                    // Opens a new browser tab to AppSource's content pack list, filtered to NAV reports.
                    HyperLink(PowerBIServiceMgt.GetContentPacksServicesUrl);
                end;
            }
            action(ConnectionInfo)
            {
                ApplicationArea = All;
                Caption = 'Connection Information';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Category5;
                PromotedOnly = true;
                RunObject = Page "Content Pack Setup Wizard";
                ToolTip = 'Show information for connecting to Power BI content packs.';
                Visible = NOT IsSaaS;
            }
            action(CleanDeployments)
            {
                ApplicationArea = All;
                Caption = 'Default Reports';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                ToolTip = 'Manage your deployed default reports.';

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"Power BI Deployments");
                    // TODO: Set this button's visibility to equal "IsSaaS" so it's not visible for on-prem, where we won't have OOB uploads anyways.
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not TryLoadReportsList then
            ShowLatestErrorMessage();

        IsSaaS := AzureADMgt.IsSaaS;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        SaveAndClose;
    end;

    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        Context: Text[30];
        NameFilter: Text;
        IsPgClosedOkay: Boolean;
        IsSaaS: Boolean;
        HasReports: Boolean;
        IsErrorMessageVisible: Boolean;
        IsUrlFieldVisible: Boolean;
        ErrorMessageText: Text;
        ErrorUrlText: Text;
        ErrorUrlPath: Text;
        FailedToLoadReportListTelemetryErr: Label 'PowerBIReportSelection failed to load reports. Error message: %1', Locked = true;

    procedure SetContext(ParentContext: Text[30])
    begin
        // Sets the ID of the parent page that reports are being selected for.
        Context := ParentContext;
    end;

    procedure SetNameFilter(ParentFilter: Text)
    begin
        // Sets the value to filter report names by.
        // This should be called by the parent page before opening this page.
        NameFilter := ParentFilter;
    end;

    local procedure FilterReports()
    begin
        // Filters the report collection by name, if the parent page has provided a value to filter by.
        // This filter will display any report that has the value anywhere in the name, case insensitive.
        if NameFilter <> '' then
            SetFilter(ReportName, '%1', '@*' + NameFilter + '*');
    end;

    [TryFunction]
    local procedure TryLoadReportsList()
    var
        ExceptionMessage: Text;
        ExceptionDetails: Text;
    begin
        // Clears and retrieves a list of all reports in the user's Power BI account.
        Reset;
        DeleteAll();
        PowerBIServiceMgt.GetReports(Rec, ExceptionMessage, ExceptionDetails, Context);

        HasReports := not IsEmpty;
        if IsEmpty then
            Insert; // Hack to prevent empty list error.

        // Set sort order, scrollbar position, and filters.
        SetCurrentKey(ReportName);
        FindFirst;
        FilterReports;
    end;

    local procedure SaveAndClose()
    var
        PowerBiReportConfiguration: Record "Power BI Report Configuration";
        TempPowerBiReportBuffer: Record "Power BI Report Buffer" temporary;
    begin
        // use a temp buffer record for saving to not disturb the position, filters, etc. of the source table
        // ShareTable = TRUE makes a shallow copy of the record, which is OK since no modifications are made to the records themselves
        TempPowerBiReportBuffer.Copy(Rec, true);

        // Clear out all old records before re-adding (easiest way to remove invalid rows, e.g. deleted reports).
        PowerBiReportConfiguration.SetFilter("User Security ID", UserSecurityId);
        PowerBiReportConfiguration.SetFilter(Context, Context);
        PowerBiReportConfiguration.DeleteAll();
        PowerBiReportConfiguration.Reset();

        TempPowerBiReportBuffer.SetRange(Enabled, true);
        if TempPowerBiReportBuffer.Find('-') then
            repeat
                PowerBiReportConfiguration.Init();
                PowerBiReportConfiguration."User Security ID" := UserSecurityId;
                PowerBiReportConfiguration."Report ID" := TempPowerBiReportBuffer.ReportID;
                PowerBiReportConfiguration.Context := Context;
                PowerBiReportConfiguration.Validate(ReportEmbedUrl, TempPowerBiReportBuffer.ReportEmbedUrl);
                PowerBiReportConfiguration.Insert();
            until TempPowerBiReportBuffer.Next = 0;

        IsPgClosedOkay := true;
        CurrPage.Close;
    end;

    procedure IsPageClosedOkay(): Boolean
    begin
        exit(IsPgClosedOkay);
    end;

    local procedure ShowLatestErrorMessage()
    var
        TextToShow: Text;
    begin
        TextToShow := GetLastErrorText();

        // Dealing with 401 Unauthorized error URL, per page 6303.
        if TextToShow = PowerBIServiceMgt.GetUnauthorizedErrorText then begin
            ErrorUrlText := TextToShow;
            ErrorUrlPath := PowerBIServiceMgt.GetPowerBIUrl;
            IsUrlFieldVisible := true;
        end else begin
            if TextToShow = '' then
                TextToShow := PowerBIServiceMgt.GetGenericError;

            ErrorMessageText := TextToShow;
            IsErrorMessageVisible := true;
        end;

        SendTraceTag('0000BKG', PowerBIServiceMgt.GetPowerBiTelemetryCategory(), Verbosity::Warning,
            StrSubstNo(FailedToLoadReportListTelemetryErr, GetLastErrorText), DataClassification::CustomerContent);
    end;
}

