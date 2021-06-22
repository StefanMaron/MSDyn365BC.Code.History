page 4020 "Post Migration Checklist"
{
    Caption = 'Post Migration Checklist';
    SourceTable = "Post Migration Checklist";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(PostMigInfo)
            {
                ShowCaption = false;
                InstructionalText = 'Once the migration process has been completed, there is additional data that will need to be setup. Complete the recommended steps below for areas that may need to be re-setup.';
            }
            group(ChecklistSteps)
            {
                ShowCaption = false;
                grid(StepsGrid)
                {
                    GridLayout = Columns;
                    group(RecommendedSteps)
                    {
                        Caption = 'Recommended Steps:';
                        field(ReadWhitePaperTxt; ReadWhitePaperTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            trigger OnDrillDown()
                            begin
                                Hyperlink(ReadWhitePaperURLTxt);
                            end;
                        }
                        field(UsersSetupTxt; UsersSetupTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            trigger OnDrillDown()
                            begin
                                Page.Run(Page::"Users");
                            end;
                        }
                        field(DisableCloudTxt; DisableCloudTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            trigger OnDrillDown()
                            begin
                                Page.Run(Page::"Intelligent Cloud Ready");
                            end;
                        }
                        field(DefineUserMappingsTxt; DefineUserMappingsTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            trigger OnDrillDown()
                            begin
                                Page.Run(Page::"Migration User Mapping");
                            end;
                        }
                        field(ResetupSalesConnectionTxt; ResetupSalesConnectionTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            trigger OnDrillDown()
                            begin
                                Page.Run(Page::"CRM Connection Setup Wizard");
                            end;
                        }
                    }
                }

                group(Checkbox)
                {
                    Caption = 'Mark Complete';
                    field(Help; Help)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        trigger OnValidate();
                        var
                            PostMigChecklist: Record "Post Migration Checklist";
                        begin
                            PostMigChecklist.Reset();
                            PostMigChecklist.SetRange(Help);
                            if Help = true then begin
                                PostMigChecklist.ModifyAll(Help, true);
                                Commit();
                                CurrPage.Update(false);
                            end else
                                if Help = false then begin
                                    PostMigChecklist.ModifyAll(Help, false);
                                    Commit();
                                    CurrPage.Update(false);
                                end;
                        end;
                    }
                    field("Users Setup"; "Users Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        trigger OnValidate();
                        var
                            PostMigChecklist: Record "Post Migration Checklist";
                        begin
                            PostMigChecklist.Reset();
                            PostMigChecklist.SetRange("Users Setup");
                            if "Users Setup" = true then begin
                                PostMigChecklist.ModifyAll("Users Setup", true);
                                Commit();
                                CurrPage.Update(false);
                            end else
                                if "Users Setup" = false then begin
                                    PostMigChecklist.ModifyAll("Users Setup", false);
                                    Commit();
                                    CurrPage.Update(false);
                                end;
                        end;
                    }
                    field("Disable Intelligent Cloud"; "Disable Intelligent Cloud")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        trigger OnValidate();
                        var
                            PostMigChecklist: Record "Post Migration Checklist";
                        begin
                            PostMigChecklist.Reset();
                            PostMigChecklist.SetRange("Disable Intelligent Cloud");
                            if "Disable Intelligent Cloud" = true then begin
                                PostMigChecklist.ModifyAll("Disable Intelligent Cloud", true);
                                Commit();
                                CurrPage.Update(false);
                            end else
                                if "Disable Intelligent Cloud" = false then begin
                                    PostMigChecklist.ModifyAll("Disable Intelligent Cloud", false);
                                    Commit();
                                    CurrPage.Update(false);
                                end;
                        end;
                    }
                    field("Define User Mappings"; "Define User Mappings")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        trigger OnValidate();
                        var
                            PostMigChecklist: Record "Post Migration Checklist";
                        begin
                            PostMigChecklist.Reset();
                            PostMigChecklist.SetRange("Define User Mappings");
                            if "Define User Mappings" = true then begin
                                PostMigChecklist.ModifyAll("Define User Mappings", true);
                                Commit();
                                CurrPage.Update(false);
                            end else
                                if "Define User Mappings" = false then begin
                                    PostMigChecklist.ModifyAll("Define User Mappings", false);
                                    Commit();
                                    CurrPage.Update(false);
                                end;
                        end;
                    }
                    field("D365 Sales"; "D365 Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        trigger OnValidate();
                        var
                            PostMigChecklist: Record "Post Migration Checklist";
                        begin
                            PostMigChecklist.Reset();
                            PostMigChecklist.SetRange("D365 Sales");
                            if "D365 Sales" = true then begin
                                PostMigChecklist.ModifyAll("D365 Sales", true);
                                Commit();
                                CurrPage.Update(false);
                            end else
                                if "D365 Sales" = false then begin
                                    PostMigChecklist.ModifyAll("D365 Sales", false);
                                    Commit();
                                    CurrPage.Update(false);
                                end;
                        end;
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
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        PermissionManager: Codeunit "Permission Manager";
        UserPermissions: Codeunit "User Permissions";
    begin
        IsSuperAndSetupComplete := PermissionManager.IsIntelligentCloud() and UserPermissions.IsSuper(UserSecurityId());

        if IntelligentCloudSetup.Get() then
            HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
        PopulateCompany();
        RemoveCompanies();
        MarkAll();
        Rec.SetRange("Company Name", COMPANYNAME());
    end;

    trigger OnClosePage()
    var
        PostMigrationNotification: Codeunit "Post Migration Notificaton";

    begin
        if PostMigrationNotification.IsCLNotificationEnabled() then
            PostMigrationNotification.ShowChecklistNotification();
    end;

    local procedure PopulateCompany()
    var
        HybridCompany: Record "Hybrid Company";
        PostMigChecklist: Record "Post Migration Checklist";
        Help: Boolean;
        Users: Boolean;
        Sales: Boolean;
        DisableIntelligentCloud: Boolean;
        DefineUserMappings: Boolean;

    begin
        PostMigChecklist.Reset();
        PostMigChecklist.SetFilter(Help, '=%1', true);
        if PostMigChecklist.FindSet() then
            Help := true;

        PostMigChecklist.Reset();
        PostMigChecklist.SetFilter("Users Setup", '=%1', true);
        if PostMigChecklist.FindSet() then
            Users := true;

        PostMigChecklist.Reset();
        PostMigChecklist.SetFilter("D365 Sales", '=%1', true);
        if PostMigChecklist.FindSet() then
            Sales := true;

        PostMigChecklist.Reset();
        PostMigChecklist.SetFilter("Disable Intelligent Cloud", '=%1', true);
        if PostMigChecklist.FindSet() then
            DisableIntelligentCloud := true;

        PostMigChecklist.Reset();
        PostMigChecklist.SetFilter("Define User Mappings", '=%1', true);
        if PostMigChecklist.FindSet() then
            DefineUserMappings := true;

        PostMigChecklist.Reset();
        if PostMigChecklist.FindSet() then
            HybridCompany.SetRange(Replicate, true);
        repeat
            if not PostMigChecklist.Get(HybridCompany.Name) then begin
                PostMigChecklist.Init();
                PostMigChecklist."Company Name" := HybridCompany.Name;
                PostMigChecklist.Help := Help;
                PostMigChecklist."Users Setup" := Users;
                PostMigChecklist."Disable Intelligent Cloud" := DisableIntelligentCloud;
                PostMigChecklist."D365 Sales" := Sales;
                PostMigChecklist."Define User Mappings" := DefineUserMappings;
                PostMigChecklist.Insert();
            end;
        until HybridCompany.Next() = 0;
    end;

    local procedure RemoveCompanies()
    var
        HybridCompany: Record "Hybrid Company";
        PostMigChecklist: Record "Post Migration Checklist";
        PostMigChecklistWork: Record "Post Migration Checklist";

    begin
        PostMigChecklistWork.Reset();

        if PostMigChecklistWork.FindSet() then
            repeat
                if not HybridCompany.Get(PostMigChecklistWork."Company Name") then begin
                    PostMigChecklist.Get(PostMigChecklistWork."Company Name");
                    PostMigChecklist.Delete();
                end else
                    If HybridCompany.Replicate = false then begin
                        PostMigChecklist.Get(PostMigChecklistWork."Company Name");
                        PostMigChecklist.Delete();
                    end;
            until PostMigChecklistWork.Next() = 0;
    end;

    local procedure MarkAll()
    var
        PostMigChecklist: Record "Post Migration Checklist";
    begin
        PostMigChecklist.Reset();
        PostMigChecklist.SetRange(Help, true);
        if PostMigChecklist.FindSet() then begin
            PostMigChecklist.Reset();
            PostMigChecklist.ModifyAll(Help, true);
            Commit();
        end;
        PostMigChecklist.Reset();
        PostMigChecklist.SetRange("Users Setup", true);
        if PostMigChecklist.FindSet() then begin
            PostMigChecklist.Reset();
            PostMigChecklist.ModifyAll("Users Setup", true);
            Commit();
        end;
        PostMigChecklist.Reset();
        PostMigChecklist.SetRange("D365 Sales", true);
        if PostMigChecklist.FindSet() then begin
            PostMigChecklist.Reset();
            PostMigChecklist.ModifyAll("D365 Sales", true);
            Commit();
        end;
        PostMigChecklist.Reset();
        PostMigChecklist.SetRange("Disable Intelligent Cloud", true);
        if PostMigChecklist.FindSet() then begin
            PostMigChecklist.Reset();
            PostMigChecklist.ModifyAll("Disable Intelligent Cloud", true);
            Commit();
        end;
        PostMigChecklist.Reset();
        PostMigChecklist.SetRange("Define User Mappings", true);
        if PostMigChecklist.FindSet() then begin
            PostMigChecklist.Reset();
            PostMigChecklist.ModifyAll("Define User Mappings", true);
            Commit();
        end;
    end;

    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        ReadWhitePaperTxt: Label '1. Read the Business Central Cloud Migration help.';
        ReadWhitePaperURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009758', Locked = true;
        UsersSetupTxt: Label '2. Setup Users and permissions within Business Central.';
        DisableCloudTxt: Label '3. Disable the Cloud Migration.';
        DefineUserMappingsTxt: Label '4. Define User Mappings.';
        ResetupSalesConnectionTxt: Label '5. Resetup D365 Sales Connection.';
        IsSuperAndSetupComplete: Boolean;

}