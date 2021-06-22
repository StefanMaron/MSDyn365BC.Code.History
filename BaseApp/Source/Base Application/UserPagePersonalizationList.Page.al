page 9191 "User Page Personalization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Personalized Pages';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Metadata";
    SourceTableTemporary = true;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'delete user personalization,User Page Personalizations'; // "Delete User Personalization" is the old name of the page

    layout
    {
        area(content)
        {
            repeater(Control1106000000)
            {
                ShowCaption = false;
                field("User SID"; "User SID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User SID';
                    ToolTip = 'Specifies the security identifier (SID) of the user who did the personalization.';
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user ID of the user who performed the personalization.';
                }
                field("Page ID"; "Page ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page object that has been personalized.';
                }
                field(Description; PageName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Caption';
                    ToolTip = 'Specifies the caption of the page that has been personalized.';
                }
                field("Legacy Personalization"; LegacyPersonalization)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Legacy Personalization';
                    ToolTip = 'Specifies if the personalization was made in the Windows client or the Web client.';
                }
                field(Date; Date)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date of the personalization.';
                    Visible = false;
                }
                field(Time; Time)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Time';
                    ToolTip = 'Specifies the timestamp for the personalization.';
                    Visible = false;
                }
                field(Health; HealthStatus)
                {
                    Caption = 'Health';
                    ApplicationArea = Basic, Suite;
                    StyleExpr = HealthStatusStyleExpr;
                    ToolTip = 'Specifies whether any problems were found with the personalization when diagnostic tests were last run.';
                    Visible = ShowUserDiagnosticsListPart;
                }
            }

            part(UserDiagnosticsListPart; "Designer Diagnostics ListPart")
            {
                Caption = 'Detected Problems';
                ApplicationArea = Basic, Suite;
                Visible = ShowUserDiagnosticsListPart;
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
                ToolTip = 'Runs a series of diagnostic tests on the list of personalizations.';

                trigger OnAction()
                begin
                    ValidatePages();
                    ShowScanCompleteMessage();
                    ShowUserDiagnosticsListPart := true;
                    UpdateUserDiagnosticsListPart();
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
                Visible = ShowUserDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    TempUserMetadata: Record "User Metadata" temporary;
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    DesignerDiagnostics.Reset();
                    DesignerDiagnostics.SetRange(Severity, Severity::Error);

                    TempUserMetadata.Copy(Rec, true);
                    if TempUserMetadata.FindSet() then
                        repeat
                            if UserSidToOperationId.Get(Format(TempUserMetadata."User SID") + Format(TempUserMetadata."Page ID"), OperationId) then begin
                                DesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not DesignerDiagnostics.IsEmpty then
                                    TempUserMetadata.Mark(true);
                            end;
                        until TempUserMetadata.Next() = 0;
                    TempUserMetadata.MarkedOnly(true);
                    CurrPage.SetTableView(TempUserMetadata);
                    UpdateUserDiagnosticsListPart();
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
                    UpdateUserDiagnosticsListPart();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        PageDefinition: Record "Page Metadata";
    begin
        if "Personalization ID" = ExtensionMetadataTxt then
            LegacyPersonalization := false
        else
            LegacyPersonalization := true;

        if PageDefinition.Get("Page ID") then
            PageName := PageDefinition.Caption
        else
            PageName := '';

        HealthStatus := CreatePageDiagnosticsMessageAndSetStyleExpr();
    end;

    trigger OnDeleteRecord(): Boolean
    var
        UserPageMetadata: Record "User Page Metadata";
        UserMetadata: Record "User Metadata";
    begin
        if "Personalization ID" = ExtensionMetadataTxt then begin
            UserPageMetadata.SetFilter("User SID", "User SID");
            UserPageMetadata.SetFilter("Page ID", Format("Page ID"));

            if UserPageMetadata.FindFirst then
                UserPageMetadata.Delete(true);
        end else begin
            UserMetadata.SetFilter("User SID", "User SID");
            UserMetadata.SetFilter("Page ID", Format("Page ID"));
            UserMetadata.SetFilter("Personalization ID", "Personalization ID");

            if UserMetadata.FindFirst then
                UserMetadata.Delete(true);
        end;

        CurrPage.Update(true);
    end;

    trigger OnOpenPage()
    var
        UserMetadata: Record "User Metadata";
        UserPageMetadata: Record "User Page Metadata";
        EmptyGuid: Guid;
    begin
        Reset;

        if not (FilterUserID = EmptyGuid) then begin
            UserMetadata.SetFilter("User SID", FilterUserID);
            UserPageMetadata.SetFilter("User SID", FilterUserID);
        end;

        if UserMetadata.FindSet then
            repeat
                "User SID" := UserMetadata."User SID";
                "Page ID" := UserMetadata."Page ID";
                "Personalization ID" := UserMetadata."Personalization ID";
                Date := UserMetadata.Date;
                Time := UserMetadata.Time;
                Insert;
            until UserMetadata.Next = 0;

        if UserPageMetadata.FindSet then
            repeat
                "User SID" := UserPageMetadata."User SID";
                "Page ID" := UserPageMetadata."Page ID";
                "Personalization ID" := ExtensionMetadataTxt;
                Insert;
            until UserPageMetadata.Next = 0;
    end;

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

    local procedure CountNumberOfUsersWithinFilter(var UserMetadata: Record "User Metadata" temporary) TotalUsers: Integer
    var
        CurrentUserId: Guid;
    begin
        if UserMetadata.FindSet() then begin
            CurrentUserId := UserMetadata."User SID"; // First user may have empty guid, hence we need to especially take care of that one
            TotalUsers += 1;
            repeat
                if CurrentUserId <> UserMetadata."User SID" then begin
                    CurrentUserId := UserMetadata."User SID";
                    TotalUsers += 1;
                end;
            until UserMetadata.Next() = 0;
        end;
    end;

    local procedure ValidatePages()
    var
        UserMetadata: Record "User Metadata" temporary;
        NavDesignerPersonalizationPageCustomizationValidation: DotNet NavDesignerPersonalizationPageCustomizationValidation;
        ValidationProgressDialog: Dialog;
        TotalUsers: Integer;
        CurrentUserNumber: Integer;
        CurrentUserId: Guid;
    begin
        UserMetadata.Copy(Rec, true);
        UserMetadata.CopyFilters(Rec);
        UserMetadata.SetCurrentKey("User SID");
        UserMetadata.SetAscending("User SID", true);
        TotalUsers := CountNumberOfUsersWithinFilter(UserMetadata);

        if UserMetadata.FindSet() then
            repeat
                // We may have multiple profiles in this query, every time we see a new profile, we need to re-create the NavDesignerConfigurationPageCustomizationValidation for that profile
                if (CurrentUserId <> UserMetadata."User SID") or IsNull(NavDesignerPersonalizationPageCustomizationValidation) then begin
                    NavDesignerPersonalizationPageCustomizationValidation := NavDesignerPersonalizationPageCustomizationValidation.Create(UserMetadata."User SID");
                    CurrentUserId := UserMetadata."User SID";
                    ValidationProgressDialog.Open(StrSubstNo(ValidatePageTxt, UserMetadata."User ID", CurrentUserNumber, TotalUsers));
                    CurrentUserNumber += 1;
                end;

                if "Personalization ID" = ExtensionMetadataTxt then
                    ValidatePageForDesignerCustomizationBase(NavDesignerPersonalizationPageCustomizationValidation, UserMetadata);
            until UserMetadata.Next() = 0;
    end;

    local procedure ValidatePageForDesignerCustomizationBase(NavDesignerPageCustomizationValidationBase: dotnet NavDesignerPageCustomizationValidationBase; UserMetadata: Record "User Metadata")
    var
        NavDesignerCompilationResult: dotnet NavDesignerCompilationResult;
        NavDesignerDiagnostic: DotNet NavDesignerDiagnostic;
        OperationId: Guid;
    begin
        // Validate page customization
        NavDesignerCompilationResult := NavDesignerPageCustomizationValidationBase.ValidatePageCustomization(UserMetadata."Page ID");

        OperationId := CreateGuid();
        DesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            DesignerDiagnostics."Diagnostics ID" += 1;
            DesignerDiagnostics.Severity := DesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            DesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(DesignerDiagnostics.Message));
            DesignerDiagnostics.Insert();
        end;

        // Add mapping to page diagnostics
        UserSidToOperationId.Set(Format(UserMetadata."User SID") + Format(UserMetadata."Page ID"), OperationId);
    end;

    local procedure CreatePageDiagnosticsMessageAndSetStyleExpr(): Text
    var
        OperationId: Guid;
    begin
        HealthStatusStyleExpr := 'Favorable';
        if "Personalization ID" <> ExtensionMetadataTxt then
            exit(LegacyPersonalizationsCannotBeScannedTxt);

        if not UserSidToOperationId.Get(Format("User SID") + Format("Page ID"), OperationId) then
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdateUserDiagnosticsListPart();
    end;

    local procedure UpdateUserDiagnosticsListPart()
    var
        OperationId: Guid;
    begin
        if UserSidToOperationId.Get(Format("User SID") + Format("Page ID"), OperationId) then;
        DesignerDiagnostics.Reset();
        DesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.UserDiagnosticsListPart.Page.SetRecords(DesignerDiagnostics);
        CurrPage.UserDiagnosticsListPart.Page.Update(false);
    end;

    procedure SetUserID(UserID: Guid)
    begin
        FilterUserID := UserID;
    end;

    var
        DesignerDiagnostics: record "Designer Diagnostic" temporary;
        ValidatePageTxt: Label 'Scanning page personalizations for %1\%2 of %3 users scanned', Comment = '%1 = user id, %2 and %3 are all whole numbers';
        PageValidationFailedWithErrorsTxt: Label '%1 error(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithWarningsTxt: Label '%1 warning(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedWithInformationalMessagesTxt: Label '%1 informational message(s)', Comment = '%1 = a number from 1 and up';
        PageSuccessfullyValidatedTxt: Label 'OK';
        ScanCompletedWithErrorsMsg: Label 'Scanning complete, %1 error(s) were found.', Comment = '%1 = a number from 1 and up';
        ScanCompletedSuccessfullyMsg: Label 'Scanning complete, no problems were found.';
        LegacyPersonalizationsCannotBeScannedTxt: Label 'Legacy personalization cannot be scanned.';
        ExtensionMetadataTxt: Label 'EXTENSION METADATA', Locked = true;
        HealthStatusStyleExpr: Text;
        HealthStatus: Text;
        UserSidToOperationId: Dictionary of [Text, Guid];
        ShowUserDiagnosticsListPart: Boolean;
        LegacyPersonalization: Boolean;
        PageName: Text;
        FilterUserID: Guid;
        ShowingOnlyErrors: Boolean;
}

