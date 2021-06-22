page 5432 "Automation - Config. Package"
{
    APIGroup = 'automation';
    APIPublisher = 'microsoft';
    Caption = 'configurationPackage', Locked = true;
    DelayedInsert = true;
    EntityName = 'configurationPackage';
    EntitySetName = 'configurationPackages';
    PageType = API;
    SourceTable = "Config. Package";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("code"; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;
                }
                field(packageName; "Package Name")
                {
                    ApplicationArea = All;
                    Caption = 'PackageName', Locked = true;
                    ToolTip = 'Specifies the name of the package.';
                }
                field(languageId; "Language ID")
                {
                    ApplicationArea = All;
                    Caption = 'LanguageId', Locked = true;
                }
                field(productVersion; "Product Version")
                {
                    ApplicationArea = All;
                    Caption = 'ProductVersion', Locked = true;
                }
                field(processingOrder; "Processing Order")
                {
                    ApplicationArea = All;
                    Caption = 'ProcessingOrder', Locked = true;
                }
                field(excludeConfigurationTables; "Exclude Config. Tables")
                {
                    ApplicationArea = All;
                    Caption = 'ExcludeConfigurationTables', Locked = true;
                }
                field(numberOfTables; "No. of Tables")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfTables', Locked = true;
                    Editable = false;
                }
                field(numberOfRecords; "No. of Records")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfRecords', Locked = true;
                    Editable = false;
                }
                field(numberOfErrors; "No. of Errors")
                {
                    ApplicationArea = All;
                    Caption = 'NumberOfErrors', Locked = true;
                    Editable = false;
                }
                field(importStatus; "Import Status")
                {
                    ApplicationArea = All;
                    Caption = 'ImportStatus', Locked = true;
                    Editable = false;
                }
                field(applyStatus; "Apply Status")
                {
                    ApplicationArea = All;
                    Caption = 'ApplyStatus', Locked = true;
                    Editable = false;
                }
                part(file; "Automation - RS Package File")
                {
                    ApplicationArea = All;
                    Caption = 'File', Locked = true;
                    EntityName = 'file';
                    EntitySetName = 'file';
                    SubPageLink = Code = FIELD(Code);
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TenantConfigPackageFile: Record "Tenant Config. Package File";
    begin
        Validate("Import Status", "Import Status"::No);
        Validate("Apply Status", "Apply Status"::No);

        TenantConfigPackageFile.Validate(Code, Code);
        TenantConfigPackageFile.Insert(true);
    end;

    trigger OnOpenPage()
    begin
        BindSubscription(AutomationAPIManagement);
    end;

    var
        ApplyOrImportInProgressImportErr: Label 'Cannot import a package while import or apply is in progress.';
        ApplyOrImportInProgressApplyErr: Label 'Cannot apply a package while import or apply is in progress.';
        ImportNotCompletedErr: Label 'Import Status is not completed. You must import the package before you apply it.';
        AutomationAPIManagement: Codeunit "Automation - API Management";
        MissingRapisStartFileErr: Label 'Please upload a Rapid Start File, before running the import.';

    [ServiceEnabled]
    procedure Import(var ActionContext: DotNet WebServiceActionContext)
    var
        TenantConfigPackageFile: Record "Tenant Config. Package File";
        ODataActionManagement: Codeunit "OData Action Management";
        ImportSessionID: Integer;
    begin
        if IsImportOrApplyPending then
            Error(ApplyOrImportInProgressImportErr);

        TenantConfigPackageFile.SetAutoCalcFields(Content);
        if not TenantConfigPackageFile.Get(Code) then
            Error(MissingRapisStartFileErr);
        if not TenantConfigPackageFile.Content.HasValue then
            Error(MissingRapisStartFileErr);

        Validate("Import Status", "Import Status"::Scheduled);
        Modify(true);

        if TASKSCHEDULER.CanCreateTask then
            TASKSCHEDULER.CreateTask(
              CODEUNIT::"Automation - Import RSPackage", CODEUNIT::"Automation - Failure RSPackage", true, CompanyName, CurrentDateTime + 200,
              RecordId)
        else begin
            Commit();
            ImportSessionID := 0;
            StartSession(ImportSessionID, CODEUNIT::"Automation - Import RSPackage", CompanyName, Rec);
        end;

        ODataActionManagement.AddKey(FieldNo(Code), Code);
        ODataActionManagement.SetUpdatedPageResponse(ActionContext, PAGE::"Automation - Config. Package");
    end;

    [ServiceEnabled]
    procedure Apply(var ActionContext: DotNet WebServiceActionContext)
    var
        ODataActionManagement: Codeunit "OData Action Management";
        ImportSessionID: Integer;
    begin
        if IsImportOrApplyPending then
            Error(ApplyOrImportInProgressApplyErr);

        if "Import Status" <> "Import Status"::Completed then
            Error(ImportNotCompletedErr);

        Validate("Apply Status", "Apply Status"::Scheduled);
        Modify(true);

        if TASKSCHEDULER.CanCreateTask then
            TASKSCHEDULER.CreateTask(
              CODEUNIT::"Automation - Apply RSPackage", CODEUNIT::"Automation - Failure RSPackage", true, CompanyName, CurrentDateTime + 200,
              RecordId)
        else begin
            Commit();
            ImportSessionID := 0;
            StartSession(ImportSessionID, CODEUNIT::"Automation - Apply RSPackage", CompanyName, Rec);
        end;
        ODataActionManagement.AddKey(FieldNo(Code), Code);
        ODataActionManagement.SetUpdatedPageResponse(ActionContext, PAGE::"Automation - Config. Package");
    end;

    local procedure IsImportOrApplyPending(): Boolean
    begin
        exit(
          ("Import Status" in ["Import Status"::InProgress, "Import Status"::Scheduled]) or
          ("Apply Status" in ["Apply Status"::InProgress, "Apply Status"::Scheduled]));
    end;
}

