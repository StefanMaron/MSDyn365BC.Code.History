#if not CLEAN22
page 9191 "User Page Personalization List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Personalized Pages';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "User Metadata";
    SourceTableTemporary = true;
    ObsoleteReason = 'This page is based on an obsoleted record. Use page 9200 "Personalized Pages" instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    layout
    {
        area(content)
        {
            repeater(Control1106000000)
            {
                ShowCaption = false;
                field("User SID"; Rec."User SID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User SID';
                    ToolTip = 'Specifies the security identifier (SID) of the user who did the personalization.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the user ID of the user who performed the personalization.';
                }
                field("Page ID"; Rec."Page ID")
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
                Visible = ShowUserDiagnosticsListPart and (not ShowingOnlyErrors);
                Image = Filter;
                ToolTip = 'Filter on only page customizations with errors.';

                trigger OnAction()
                var
                    TempUserMetadata: Record "User Metadata" temporary;
                    OperationId: Guid;
                begin
                    ShowingOnlyErrors := true;
                    TempDesignerDiagnostics.Reset();
                    TempDesignerDiagnostics.SetRange(Severity, Severity::Error);

                    TempUserMetadata.Copy(Rec, true);
                    if TempUserMetadata.FindSet() then
                        repeat
                            if UserSidToOperationId.Get(Format(TempUserMetadata."User SID") + Format(TempUserMetadata."Page ID"), OperationId) then begin
                                TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
                                if not TempDesignerDiagnostics.IsEmpty() then
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

            if UserPageMetadata.FindFirst() then
                UserPageMetadata.Delete(true);
        end else begin
            UserMetadata.SetFilter("User SID", "User SID");
            UserMetadata.SetFilter("Page ID", Format("Page ID"));
            UserMetadata.SetFilter("Personalization ID", "Personalization ID");

            if UserMetadata.FindFirst() then
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
        Reset();

        if not (FilterUserID = EmptyGuid) then begin
            UserMetadata.SetFilter("User SID", FilterUserID);
            UserPageMetadata.SetFilter("User SID", FilterUserID);
        end;

        if UserMetadata.FindSet() then
            repeat
                "User SID" := UserMetadata."User SID";
                "Page ID" := UserMetadata."Page ID";
                "Personalization ID" := UserMetadata."Personalization ID";
                Date := UserMetadata.Date;
                Time := UserMetadata.Time;
                if IncludedUser("User SID") then
                    Insert();
            until UserMetadata.Next() = 0;

        if UserPageMetadata.FindSet() then
            repeat
                "User SID" := UserPageMetadata."User SID";
                "Page ID" := UserPageMetadata."Page ID";
                "Personalization ID" := ExtensionMetadataTxt;
                if IncludedUser("User SID") then
                    Insert();
            until UserPageMetadata.Next() = 0;
    end;

    local procedure ShowScanCompleteMessage()
    var
        Errors: Integer;
    begin
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange(Severity, Severity::Error);
        Errors := TempDesignerDiagnostics.Count();

        if Errors > 0 then
            Message(ScanCompletedWithErrorsMsg, Errors)
        else
            Message(ScanCompletedSuccessfullyMsg);
    end;

    local procedure IncludedUser(UserSID: Guid): Boolean
    var
        User: Record User;
        UserSelection: Codeunit "User Selection";
    begin
        UserSelection.HideExternalUsers(User);
        User.SetRange("User Security ID", UserSID);
        exit(not User.IsEmpty);
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
        TempUserMetadata: Record "User Metadata" temporary;
        NavDesignerPersonalizationPageCustomizationValidation: DotNet NavDesignerPersonalizationPageCustomizationValidation;
        ValidationProgressDialog: Dialog;
        TotalUsers: Integer;
        CurrentUserNumber: Integer;
        CurrentUserId: Guid;
    begin
        TempUserMetadata.Copy(Rec, true);
        TempUserMetadata.CopyFilters(Rec);
        TempUserMetadata.SetCurrentKey("User SID");
        TempUserMetadata.SetAscending("User SID", true);
        TotalUsers := CountNumberOfUsersWithinFilter(TempUserMetadata);

        CurrentUserNumber := 0;
        if TempUserMetadata.FindSet() then
            repeat
                // We may have multiple profiles in this query, every time we see a new profile, we need to re-create the NavDesignerConfigurationPageCustomizationValidation for that profile
                if (CurrentUserId <> TempUserMetadata."User SID") or IsNull(NavDesignerPersonalizationPageCustomizationValidation) then begin
                    NavDesignerPersonalizationPageCustomizationValidation := NavDesignerPersonalizationPageCustomizationValidation.Create(TempUserMetadata."User SID");
                    CurrentUserId := TempUserMetadata."User SID";
                    ValidationProgressDialog.Open(StrSubstNo(ValidatePageTxt, TempUserMetadata."User ID", CurrentUserNumber, TotalUsers));
                    CurrentUserNumber += 1;
                end;

                if "Personalization ID" = ExtensionMetadataTxt then
                    ValidatePageForDesignerCustomizationBase(NavDesignerPersonalizationPageCustomizationValidation, TempUserMetadata);
            until TempUserMetadata.Next() = 0;
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
        TempDesignerDiagnostics."Operation ID" := OperationId;
        foreach NavDesignerDiagnostic in NavDesignerCompilationResult.Diagnostics() do begin
            TempDesignerDiagnostics."Diagnostics ID" += 1;
            TempDesignerDiagnostics.Severity := TempDesignerDiagnostics.ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnostic.Severity());
            TempDesignerDiagnostics.Message := CopyStr(NavDesignerDiagnostic.Message(), 1, MaxStrLen(TempDesignerDiagnostics.Message));
            TempDesignerDiagnostics.Insert();
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

        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        TempDesignerDiagnostics.SetRange(Severity, Severity::Error);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Unfavorable';
            exit(StrSubstNo(PageValidationFailedWithErrorsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Severity::Warning);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Ambiguous';
            exit(StrSubstNo(PageSuccessfullyValidatedWithWarningsTxt, TempDesignerDiagnostics.Count()));
        end;
        TempDesignerDiagnostics.SetRange(Severity, Severity::Information);
        if TempDesignerDiagnostics.Count() > 0 then begin
            HealthStatusStyleExpr := 'Favorable';
            exit(StrSubstNo(PageSuccessfullyValidatedWithInformationalMessagesTxt, TempDesignerDiagnostics.Count()));
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
        TempDesignerDiagnostics.Reset();
        TempDesignerDiagnostics.SetRange("Operation ID", OperationId);
        CurrPage.UserDiagnosticsListPart.Page.SetRecords(TempDesignerDiagnostics);
        CurrPage.UserDiagnosticsListPart.Page.Update(false);
    end;

    procedure SetUserID(UserID: Guid)
    begin
        FilterUserID := UserID;
    end;

    var
        TempDesignerDiagnostics: record "Designer Diagnostic" temporary;
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

#endif