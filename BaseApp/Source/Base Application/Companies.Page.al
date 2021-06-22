page 357 Companies
{
    ApplicationArea = Basic, Suite;
    Caption = 'Companies';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = Company;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of a company that has been created in the current database.';
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
                    OptionCaption = ' ,Completed,In Progress,Error,Missing Permission';
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
                    CopyCompany.RunModal;

                    if Get(CopyCompany.GetCompanyName) then
                        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(Name, CopyCompany.GetCompanyName);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        EnableAssistedCompanySetup := false;
        SetupStatus := 0;

        if ApplicationAreaMgmt.IsAdvancedExperienceEnabled then
            CompanyCreatedDateTime := GetCompanyCreatedDateTime;

        if not AssistedCompanySetupStatus.Get(Name) then
            exit;
        EnableAssistedCompanySetup := AssistedCompanySetupStatus.Enabled;
        SetupStatus := AssistedCompanySetupStatus.GetCompanySetupStatus(Name);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeDeleteRecord(Rec);
        if SoftwareAsAService and (Count = 1) then begin
            Message(DeleteLastCompanyMsg);
            Error('');
        end;

        if not ConfirmManagement.GetResponseOrDefault(DeleteCompanyQst, false) then
            exit(false);
        if SoftwareAsAService then
            if not ConfirmManagement.GetResponseOrDefault(DeleteCompanyAuditQst, false) then
                exit(false)
            else begin
                SENDTRACETAG('0000BEH', ALCompanyActivityCategoryTok, Verbosity::Normal, STRSUBSTNO(UsenCompanyTok, UserId(), COMPANYNAME()), DataClassification::EndUserIdentifiableInformation);
                SENDTRACETAG('0000BEI', ALCompanyActivityCategoryTok, Verbosity::Normal, STRSUBSTNO(CompanyTok, COMPANYNAME()), DataClassification::SystemMetadata);
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
    end;

    var
        DeleteCompanyQst: Label 'Do you want to delete the company?\All company data will be deleted.\\Do you want to continue?';
        DeleteCompanyAuditQst: Label 'The company will be permanently deleted. We will record your user name and the time of day that you deleted the company for auditing purposes.\\Do you want to continue?';
        ALCompanyActivityCategoryTok: Label 'AL Company Activity', Locked = true;
        UsenCompanyTok: Label 'User %1 deleted the %2 company', Locked = true;
        CompanyTok: Label 'Company %1 has been deleted', Locked = true;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        SetupStatus: Option " ",Completed,"In Progress",Error,"Missing Permission";
        EnableAssistedCompanySetup: Boolean;
        SoftwareAsAService: Boolean;
        InsertNotAllowedErr: Label 'To create a new company, choose the Create New Company button. An assisted setup guide will make sure you get everything you need to get started.';
        DeleteLastCompanyMsg: Label 'Cannot delete this company. It''s the only company you have, and you must have at least one.';
        IsFoundation: Boolean;
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

