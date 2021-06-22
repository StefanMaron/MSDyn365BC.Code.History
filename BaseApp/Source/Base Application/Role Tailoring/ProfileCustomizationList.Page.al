page 9190 "Profile Customization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customized Pages';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Tenant Profile Page Metadata";
    AdditionalSearchTerms = 'Profile Customizations';

    layout
    {
        area(content)
        {
            repeater(Repeater1)
            {
                ShowCaption = false;
                field("Profile ID"; "Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the profile that the customization has been created for.';
                }
                field("App ID"; "App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile App ID';
                    ToolTip = 'Specifies the ID of the app that provided the profile that this page customization applies to.';
                    Visible = false;
                }
                field("App Name"; ConfPersonalizationMgt.ResolveAppNameFromAppId("App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this page customization applies to, which can be either an extension, shown by its name, or a custom profile created by a user.';
                    Visible = false;
                }
                field(PageIdField; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been customized.';
                    Lookup = false;
                }
                field(PageCaptionField; PageCaption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Caption';
                    ToolTip = 'Specifies the caption of the page object that has been customized.';
                    Editable = false;
                }
                field(OwnerField; Owner)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Owner';
                    ToolTip = 'Specifies whether the customization was made by a user (Tenant) or provided as part of an extension (System).';
                }
                field(Health; HealthStatus)
                {
                    Caption = 'Health';
                    ApplicationArea = Basic, Suite;
                    StyleExpr = HealthStatusStyleExpr;
                    ToolTip = 'Specifies whether any problems were found with the customization when diagnostic tests were last run.';
                    Visible = ShowProfileDiagnosticsListPart;
                    Editable = false;
                }
            }

            part(ProfileDiagnosticsListPart; "Designer Diagnostics ListPart")
            {
                Caption = 'Detected Problems';
                ApplicationArea = Basic, Suite;
                Visible = ShowProfileDiagnosticsListPart;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TroubleshootProblems)
            {
                Caption = 'Troubleshoot';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Image = Troubleshoot;
                ToolTip = 'Runs a series of diagnostic tests on the list of customizations.';

                trigger OnAction()
                begin
                    ValidatePages();
                    ShowScanCompleteMessage();
                    ShowProfileDiagnosticsListPart := true;
                end;
            }

            action(ShowErrorsAction)
            {
                Caption = 'Show only errors';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = ShowProfileDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    DesignerDiagnostics.Reset();
                    DesignerDiagnostics.SetRange(Severity, Severity::Error);

                    TenantProfilePageMetadata.CopyFilters(Rec);
                    if TenantProfilePageMetadata.FindSet() then
                        repeat
                            if SystemIdToOperationId.Get(TenantProfilePageMetadata.SystemId, OperationId) then begin
                                DesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not DesignerDiagnostics.IsEmpty then
                                    TenantProfilePageMetadata.Mark(true);
                            end;
                        until TenantProfilePageMetadata.Next() = 0;

                    TenantProfilePageMetadata.MarkedOnly(true);
                    CurrPage.SetTableView(TenantProfilePageMetadata);
                    UpdateProfileDiagnosticsListPart();
                end;
            }

            action(ShowAllPagesAction)
            {
                Caption = 'Show all';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = ShowingOnlyErrors;
                Image = Filter;
                ToolTip = 'Show all page customizations within filter.';

                trigger OnAction()
                begin
                    ClearMarks();
                    MarkedOnly(false);
                    ShowingOnlyErrors := false;
                    if FindFirst() then;
                    UpdateProfileDiagnosticsListPart();
                end;
            }
        }
    }

    local procedure ShowScanCompleteMessage()
    var
        Errors: Integer;
    begin
        DesignerDiagnostics.Reset();
        DesignerDiagnostics.SetRange(Severity, Severity::Error);
        Errors := DesignerDiagnostics.Count();

        if Errors > 0 then
            Message(ScanCompletedWithErrorsMsg, Errors)
        else
            Message(ScanCompletedSuccessfullyMsg);
    end;

    local procedure CountNumberOfProfilesWithinFilter(var TenantProfilePageMetadata: Record "Tenant Profile Page Metadata") TotalProfiles: Integer
    var
        CurrentProfileId: Code[30];
        CurrentAppId: Guid;
    begin
        if TenantProfilePageMetadata.FindSet() then
            repeat
                if (CurrentProfileId <> TenantProfilePageMetadata."Profile ID") or (CurrentAppId <> TenantProfilePageMetadata."App ID") then begin
                    CurrentProfileId := TenantProfilePageMetadata."Profile ID";
                    CurrentAppId := TenantProfilePageMetadata."App ID";
                    TotalProfiles += 1;
                end;
            until TenantProfilePageMetadata.Next() = 0;
    end;

    local procedure ValidatePages()
    var
        TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
        NavDesignerConfigurationPageCustomizationValidation: DotNet NavDesignerConfigurationPageCustomizationValidation;
        ValidationProgressDialog: Dialog;
        TotalProfiles: Integer;
        CurrentProfileNumber: Integer;
        CurrentProfileId: Code[30];
        CurrentAppId: Guid;
    begin
        TotalProfiles := Count();
        TenantProfilePageMetadata.CopyFilters(Rec);
        TenantProfilePageMetadata.SetCurrentKey("App ID", "Profile ID");
        TenantProfilePageMetadata.SetAscending("App ID", true);
        TenantProfilePageMetadata.SetAscending("Profile ID", true);
        TenantProfilePageMetadata.SetRange(Owner, Owner::Tenant); // We can only scan user created page customizations
        TotalProfiles := CountNumberOfProfilesWithinFilter(TenantProfilePageMetadata);

        DesignerDiagnostics.Reset();
        DesignerDiagnostics.DeleteAll();

        if TenantProfilePageMetadata.FindSet() then
            repeat
                // We may have multiple profiles in this query, every time we see a new profile, we need to re-create the NavDesignerConfigurationPageCustomizationValidation for that profile
                if (CurrentProfileId <> TenantProfilePageMetadata."Profile ID") or (CurrentAppId <> TenantProfilePageMetadata."App ID") then begin
                    NavDesignerConfigurationPageCustomizationValidation := NavDesignerConfigurationPageCustomizationValidation.Create(TenantProfilePageMetadata."Profile ID", TenantProfilePageMetadata."App ID");
                    CurrentProfileId := TenantProfilePageMetadata."Profile ID";
                    CurrentAppId := TenantProfilePageMetadata."App ID";
                    ValidationProgressDialog.Open(StrSubstNo(ValidatePageTxt, TenantProfilePageMetadata."Profile ID", CurrentProfileNumber, TotalProfiles));
                    CurrentProfileNumber += 1;
                end;

                ValidatePageForDesignerCustomizationBase(NavDesignerConfigurationPageCustomizationValidation, TenantProfilePageMetadata);
            until TenantProfilePageMetadata.Next() = 0;
    end;

    local procedure ValidatePageForDesignerCustomizationBase(NavDesignerPageCustomizationValidationBase: dotnet NavDesignerPageCustomizationValidationBase; TenantProfilePageMetadata: record "Tenant Profile Page Metadata")
    var
        NavDesignerCompilationResult: dotnet NavDesignerCompilationResult;
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
        OperationId: Guid;
    begin
        // Validate page customization
        NavDesignerCompilationResult := NavDesignerPageCustomizationValidationBase.ValidatePageCustomization(TenantProfilePageMetadata."Page ID");

        OperationId := CreateGuid();
        DesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            DesignerDiagnostics."Diagnostics ID" += 1;
            DesignerDiagnostics.Severity := DesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            DesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(DesignerDiagnostics.Message));
            DesignerDiagnostics.Insert();
        end;

        // Add mapping to page diagnostics
        SystemIdToOperationId.Set(TenantProfilePageMetadata.SystemId, OperationId);
    end;

    local procedure CreatePageDiagnosticsMessageAndSetStyleExpr(): Text
    var
        OperationId: Guid;
    begin
        HealthStatusStyleExpr := 'Favorable';
        if Owner = Owner::System then
            exit(CustomizationFromExtensionCannotBeScannedTxt);

        if not SystemIdToOperationId.Get(SystemId, OperationId) then
            exit;

        DesignerDiagnostics.Reset();
        DesignerDiagnostics.SetRange("Operation ID", OperationId);
        DesignerDiagnostics.SetRange(Severity, Severity::Error);
        if DesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Unfavorable';
            exit(StrSubstNo(PageValidationFailedWithErrorsTxt, DesignerDiagnostics.Count()));
        end;
        DesignerDiagnostics.SetRange(Severity, Severity::Warning);
        if DesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Ambiguous';
            exit(StrSubstNo(PageSuccessfullyValidatedWithWarningsTxt, DesignerDiagnostics.Count()));
        end;
        DesignerDiagnostics.SetRange(Severity, Severity::Information);
        if DesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Favorable';
            exit(StrSubstNo(PageSuccessfullyValidatedWithInformationalMessagesTxt, DesignerDiagnostics.Count()));
        end;
        exit(PageSuccessfullyValidatedTxt)
    end;

    trigger OnAfterGetRecord()
    var
        PageMetadata: Record "Page Metadata";
    begin
        if PageMetadata.Get("Page ID") then
            PageCaption := PageMetadata.Caption
        else
            PageCaption := StrSubstNo(PageTxt, "Page ID");

        HealthStatus := CreatePageDiagnosticsMessageAndSetStyleExpr();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateProfileDiagnosticsListPart();
    end;

    local procedure UpdateProfileDiagnosticsListPart()
    var
        OperationId: Guid;
    begin
        if SystemIdToOperationId.Get(SystemId, OperationId) then;
        DesignerDiagnostics.Reset();
        DesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.ProfileDiagnosticsListPart.Page.SetRecords(DesignerDiagnostics);
        CurrPage.ProfileDiagnosticsListPart.Page.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Owner <> Owner::Tenant then
            Error(CannotDeleteExtensionProfileErr);
    end;

    var
        DesignerDiagnostics: Record "Designer Diagnostic" temporary;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        CannotDeleteExtensionProfileErr: Label 'You cannot delete this profile customization because it comes from an extension.';
        PageCaption: Text;
        ValidatePageTxt: Label 'Scanning page customizations for %1\%2 of %3 profiles scanned', Comment = '%1 = profile id, %2 and %3 are all whole numbers';
        PageTxt: Label 'Page %1', Comment = '%1 is a whole number, ex. 10';
        PageValidationFailedWithErrorsTxt: Label '%1 error(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithWarningsTxt: Label '%1 warning(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithInformationalMessagesTxt: Label '%1 informational message(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedTxt: Label 'OK';
        ScanCompletedWithErrorsMsg: Label 'Scanning complete, %1 error(s) were found.', Comment = '%1 = a number from 1 and up';
        ScanCompletedSuccessfullyMsg: Label 'Scanning complete, no problems were found.';
        CustomizationFromExtensionCannotBeScannedTxt: Label 'Customization provided by extension cannot be scanned.';
        HealthStatusStyleExpr: Text;
        HealthStatus: Text;
        SystemIdToOperationId: Dictionary of [Guid, Guid];
        ShowProfileDiagnosticsListPart: Boolean;
        ShowingOnlyErrors: Boolean;
}

