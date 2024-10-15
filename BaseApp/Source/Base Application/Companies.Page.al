page 357 Companies
{
    ApplicationArea = Basic, Suite;
    Caption = 'Companies';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Company;
    UsageCategory = Lists;
    Permissions = tabledata "Company Information" = r;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
#if not CLEAN18
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced New field named CompanyNameVar';
                    ObsoleteTag = '18.0';
                    Caption = 'Name';
                    Editable = PageInEditmode;
                    Enabled = false;
                    Visible = false;
                    ToolTip = 'Specifies the name of a company that has been created in the current database.';
                    trigger OnValidate()
                    begin

                        if (CompanyNameVar <> xRec.Name) and (xRec.Name <> '') then
                            if SoftwareAsAService then
                                Error(RenameNotAllowedErr, FieldCaption("Display Name"));
                        Validate(Name, CompanyNameVar);
                    end;

                }
#endif
                field(CompanyNameVar; CompanyNameVar)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = PageInEditmode;
                    ToolTip = 'Specifies the name of a company that has been created in the current database.';

                    trigger OnValidate()
                    begin

                        if (CompanyNameVar <> xRec.Name) and (xRec.Name <> '') then
                            if SoftwareAsAService then
                                Error(RenameNotAllowedErr, FieldCaption("Display Name"));
                        Validate(Name, CompanyNameVar);
                    end;

                }
                field("Display Name"; "Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the name to display for the company in the user interface instead of the text that is specified in the Name field.';
                }
                field("Evaluation Company"; "Evaluation Company")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Evaluation Company';
                    Editable = false;
                    ToolTip = 'Specifies that the company is for trial purposes only, and that a subscription has not been purchased. ';
                    Visible = IsFoundation;
                }
                field(EnableAssistedCompanySetup; EnableAssistedCompanySetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable Assisted Company Setup';
                    ToolTip = 'Specifies that the user will be assisted in setting up the company.';

                    trigger OnValidate()
                    var
                        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
                    begin
                        AssistedCompanySetupStatus.SetEnabled(Name, EnableAssistedCompanySetup, false);
                    end;
                }
                field(SetupStatus; SetupStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup Status';
                    Editable = false;
                    ToolTip = 'Specifies the setup status of the company.';

                    trigger OnDrillDown()
                    var
                        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
                    begin
                        AssistedCompanySetupStatus.DrillDownSetupStatus(Name);
                    end;
                }
                field(CompanyCreatedDateTime; CompanyCreatedDateTime)
                {
                    ApplicationArea = Advanced;
                    Caption = 'Company Created';
                    Editable = false;
                    ToolTip = 'Specifies the date and time when the company was created.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Create New Company")
            {
                AccessByPermission = TableData Company = I;
                ApplicationArea = Basic, Suite;
                Caption = 'Create New Company';
                Image = Company;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Get assistance with creating a new company.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                begin
                    // Action invoked through event subscriber to avoid hard coupling to other objects,
                    // as this page is part of the Cloud Manager.
                end;
            }
            action(CopyCompany)
            {
                AccessByPermission = TableData Company = RI;
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                Image = Copy;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = false;
                ToolTip = 'Copy an existing company to a new company.';

                trigger OnAction()
                var
                    Company: Record Company;
                    AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
                    CopyCompany: Report "Copy Company";
                    UserPermissions: Codeunit "User Permissions";
                begin
                    if not UserPermissions.IsSuper(UserSecurityId) then
                        Error(OnlySuperCanCreateNewCompanyErr);

                    Company.SetRange(Name, Name);
                    CopyCompany.SetTableView(Company);
                    CopyCompany.RunModal();

                    if Get(CopyCompany.GetCompanyName) then
                        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(Name, CopyCompany.GetCompanyName);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        PageInEditmode := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        EnableAssistedCompanySetup := false;
        SetupStatus := SetupStatus::" ";
        CompanyNameVar := CopyStr(Name, 1, MaxStrLen(CompanyNameVar));
        PageInEditmode := CurrPage.Editable;
        if ApplicationAreaMgmt.IsAdvancedExperienceEnabled then
            CompanyCreatedDateTime := GetCompanyCreatedDateTime;

        if not AssistedCompanySetupStatus.Get(Name) then
            exit;

        EnableAssistedCompanySetup := AssistedCompanySetupStatus.Enabled;
        SetupStatus := AssistedCompanySetupStatus.GetCompanySetupStatusValue(Name);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        OnBeforeDeleteRecord(Rec);
        if SoftwareAsAService and (Count = 1) then begin
            Message(DeleteLastCompanyMsg);
            Error('');
        end;

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteCompanyQst, CompanyInformationMgt.GetCompanyDisplayNameDefaulted(Rec)), false) then
            exit(false);
        if SoftwareAsAService then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteCompanyAuditQst, CompanyInformationMgt.GetCompanyDisplayNameDefaulted(Rec)), false) then
                exit(false)
            else begin
                Session.LogMessage('0000BEH', StrSubstNo(UsenCompanyTok, UserSecurityId(), CompanyName()), Verbosity::Normal, DataClassification::EndUserPseudonymousIdentifiers, TelemetryScope::ExtensionPublisher, 'Category', ALCompanyActivityCategoryTok);
                Session.LogMessage('0000BEI', StrSubstNo(CompanyTok, CompanyName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ALCompanyActivityCategoryTok);
            end;

        exit(true);
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS;
        IsFoundation := ApplicationAreaMgmtFacade.IsFoundationEnabled;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if SoftwareAsAService then
            Error(InsertNotAllowedErr);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        EnableAssistedCompanySetup := false;
        Clear(CompanyNameVar);
    end;

    var
        DeleteCompanyQst: Label 'Do you want to delete the company %1?\All company data will be deleted.\\Do you want to continue?', Comment = '%1 = Company Name';
        DeleteCompanyAuditQst: Label 'You are about to permanently delete the company %1.\\Do you want to continue?', Comment = '%1 = Company Name';
        ALCompanyActivityCategoryTok: Label 'AL Company Activity', Locked = true;
        UsenCompanyTok: Label 'User %1 deleted the %2 company', Locked = true;
        CompanyTok: Label 'Company %1 has been deleted', Locked = true;
        RenameNotAllowedErr: Label 'You cannot rename this company due to the impact on performance. Instead, change the %1.', Comment = '%1 = Display Name';
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        SetupStatus: Enum "Company Setup Status";
        EnableAssistedCompanySetup: Boolean;
        PageInEditmode: Boolean;
        SoftwareAsAService: Boolean;
        InsertNotAllowedErr: Label 'To create a new company, choose the Create New Company button. An assisted setup guide will make sure you get everything you need to get started.';
        DeleteLastCompanyMsg: Label 'Cannot delete this company. It''s the only company you have, and you must have at least one.';
        IsFoundation: Boolean;
        CompanyNameVar: Text[30];
        OnlySuperCanCreateNewCompanyErr: Label 'Only users with the SUPER permission set can create a new company.';
        CompanyCreatedDateTime: DateTime;

    local procedure GetCompanyCreatedDateTime(): DateTime
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.ChangeCompany(Name) then
            if CompanyInformation.ReadPermission then
                if CompanyInformation.Get then
                    exit(CompanyInformation."Created DateTime");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRecord(var Company: Record Company)
    begin
    end;
}

