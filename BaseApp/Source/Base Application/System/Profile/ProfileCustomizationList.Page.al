namespace System.Environment.Configuration;

using System;
using System.Reflection;
using System.Apps;
using System.Tooling;

page 9190 "Profile Customization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customized Pages';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Tenant Profile Page Metadata";
    AdditionalSearchTerms = 'Page customizations,Profile configurations,Profile customizations,Role customizations';

    layout
    {
        area(content)
        {
            repeater(Repeater1)
            {
                ShowCaption = false;
                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile ID';
                    ToolTip = 'Specifies the profile that the customization has been created for.';
                }
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile App ID';
                    ToolTip = 'Specifies the ID of the app that provided the profile that this page customization applies to.';
                    Visible = false;
                }
                field("App Name"; ExtensionManagement.GetAppName(Rec."App ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profile Source';
                    ToolTip = 'Specifies the origin of the profile that this page customization applies to, which can be either an extension, shown by its name, or a custom profile created by a user.';
                    Visible = false;
                }
                field(PageIdField; Rec."Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been customized.';
                    Lookup = false;
                }
                field(PageCaptionField; PageCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Caption';
                    ToolTip = 'Specifies the caption of the page object that has been customized.';
                    Editable = false;
                }
                field(OwnerField; Rec.Owner)
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
                Visible = ShowProfileDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    TenantProfilePageMetadata: Record "Tenant Profile Page Metadata";
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    TempDesignerDiagnostics.Reset();
                    TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);

                    TenantProfilePageMetadata.CopyFilters(Rec);
                    if TenantProfilePageMetadata.FindSet() then
                        repeat
                            if SystemIdToOperationId.Get(TenantProfilePageMetadata.SystemId, OperationId) then begin
                                TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not TempDesignerDiagnostics.IsEmpty() then
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
                Visible = ShowingOnlyErrors;
                Image = Filter;
                ToolTip = 'Show all page customizations within filter.';

                trigger OnAction()
                begin
                    Rec.ClearMarks();
                    Rec.MarkedOnly(false);
                    ShowingOnlyErrors := false;
                    if Rec.FindFirst() then;
                    UpdateProfileDiagnosticsListPart();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TroubleshootProblems_Promoted; TroubleshootProblems)
                {
                }
                actionref(ShowErrorsAction_Promoted; ShowErrorsAction)
                {
                }
                actionref(ShowAllPagesAction_Promoted; ShowAllPagesAction)
                {
                }
            }
        }
    }

    local procedure ShowScanCompleteMessage()
    var
        Errors: Integer;
    begin
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);
        Errors := TempDesignerDiagnostics.Count();

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
        TotalProfiles := Rec.Count();
        TenantProfilePageMetadata.CopyFilters(Rec);
        TenantProfilePageMetadata.SetCurrentKey("App ID", "Profile ID");
        TenantProfilePageMetadata.SetAscending("App ID", true);
        TenantProfilePageMetadata.SetAscending("Profile ID", true);
        TenantProfilePageMetadata.SetRange(Owner, Rec.Owner::Tenant); // We can only scan user created page customizations
        TotalProfiles := CountNumberOfProfilesWithinFilter(TenantProfilePageMetadata);

        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.DeleteAll();

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
        TempDesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            TempDesignerDiagnostics."Diagnostics ID" += 1;
            TempDesignerDiagnostics.Severity := TempDesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            TempDesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(TempDesignerDiagnostics.Message));
            TempDesignerDiagnostics.Insert();
        end;

        // Add mapping to page diagnostics
        SystemIdToOperationId.Set(TenantProfilePageMetadata.SystemId, OperationId);
    end;

    local procedure CreatePageDiagnosticsMessageAndSetStyleExpr(): Text
    var
        OperationId: Guid;
    begin
        HealthStatusStyleExpr := 'Favorable';
        if Rec.Owner = Rec.Owner::System then
            exit(CustomizationFromExtensionCannotBeScannedTxt);

        if not SystemIdToOperationId.Get(Rec.SystemId, OperationId) then
            exit;

        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Error);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Unfavorable';
            exit(StrSubstNo(PageValidationFailedWithErrorsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Warning);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Ambiguous';
            exit(StrSubstNo(PageSuccessfullyValidatedWithWarningsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Enum::Severity::Information);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Favorable';
            exit(StrSubstNo(PageSuccessfullyValidatedWithInformationalMessagesTxt, TempDesignerDiagnostics.Count()));
        end;
        exit(PageSuccessfullyValidatedTxt)
    end;

    trigger OnAfterGetRecord()
    var
        PageMetadata: Record "Page Metadata";
    begin
        if PageMetadata.Get(Rec."Page ID") then
            PageCaptionText := PageMetadata.Caption
        else
            PageCaptionText := StrSubstNo(PageTxt, Rec."Page ID");

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
        if SystemIdToOperationId.Get(Rec.SystemId, OperationId) then;
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.ProfileDiagnosticsListPart.Page.SetRecords(TempDesignerDiagnostics);
        CurrPage.ProfileDiagnosticsListPart.Page.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec.Owner <> Rec.Owner::Tenant then
            Error(CannotDeleteExtensionProfileErr);
    end;

    var
        TempDesignerDiagnostics: Record "Designer Diagnostic" temporary;
        ExtensionManagement: Codeunit "Extension Management";
        CannotDeleteExtensionProfileErr: Label 'You cannot delete this profile customization because it comes from an extension.';
        PageCaptionText: Text;
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

