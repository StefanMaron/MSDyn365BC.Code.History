page 4007 "Intelligent Cloud Ready"
{
    Caption = 'Cloud Ready Checklist';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(CloudreadyInfo)
            {
                ShowCaption = false;

                group(Checklist)
                {
                    ShowCaption = false;
                    InstructionalText = 'This process will disable your Cloud Migration environment and data migration from your on-premises solution. It is highly recommended that you work with your partner to complete this process if you intend to make your Business Central tenant your primary solution.';

                    field(Spacer1; '')
                    {
                        ApplicationArea = All;
                        Caption = '';
                        Editable = false;
                        MultiLine = true;
                    }
                    group(RecommendedSteps)
                    {
                        Caption = 'Recommended Steps:';
                        field(ReadWhitePaperTxt; ReadMigrationWhitePaperTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            trigger OnDrillDown()
                            begin
                                Hyperlink(ReadWhitePaperURLTxt);
                            end;
                        }
                        field(ExitAllUsersTxt; HaveAllUsersExitTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RunFullReplicationTxt; RunFullMigrationTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(CorrectErrorsTxt; FixErrorsTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RunReplicationAgainTxt; RunMigrationAgainTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(DisableIntelligentCloudTxt; DisableMigrationTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(ReviewUserPermissionsTxt; ReviewPermissionsTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(ChecklistAgreement; InAgreement)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'I have read and understand the recommended steps';
                            Enabled = IsSuperAndSetupComplete;
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunReplicationNow)
            {
                Enabled = IsSuperAndSetupComplete;
                ApplicationArea = Basic, Suite;
                Caption = 'Run Full Migration Now';
                ToolTip = 'Manually trigger full Cloud Migration.';
                Image = Setup;

                trigger OnAction()
                var
                    HybridReplicationSummary: Record "Hybrid Replication Summary";
                    HybridCloudManagement: Codeunit "Hybrid Cloud Management";
                    RunId: Text;
                begin
                    if Dialog.Confirm(RunReplicationConfirmQst, false) then begin
                        HybridDeployment.ResetCloudData();
                        RunId := HybridCloudManagement.RunReplication(HybridReplicationSummary.ReplicationType::Full);

                        HybridReplicationSummary.Get(RunId);
                        HybridReplicationSummary.SetDetails(FullReplicationTxt);
                        HybridReplicationSummary.Modify();

                        Message(RunReplicationTxt);
                    end;
                end;
            }
            action(DisableReplication)
            {
                Enabled = IsSuperAndSetupComplete and InAgreement;
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Cloud Migration';
                ToolTip = 'Disables Cloud Migration setup.';
                Image = Delete;

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                    UserPermissions: Codeunit "User Permissions";
                begin
                    if Dialog.Confirm(DisableReplicationConfirmQst, false) then begin
                        HybridDeployment.DisableReplication();
                        Message(DisablereplicationTxt);

                        IsSuperAndSetupComplete := PermissionManager.IsIntelligentCloud() and UserPermissions.IsSuper(UserSecurityId());
                        InAgreement := false;
                    end;
                end;
            }
            action(PermissionSets)
            {
                Enabled = IsSuperAndSetupComplete;
                ApplicationArea = Basic, Suite;
                Caption = 'Permission Sets';
                RunObject = page "Permission Sets";
                RunPageMode = Edit;
                Image = Permission;
            }
        }
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
    end;

    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        DisableReplicationConfirmQst: Label 'You will no longer have the Cloud Migration setup. Are you sure you want to disable?';
        RunReplicationConfirmQst: Label 'Are you sure you want to trigger a full migration?';
        DisablereplicationTxt: Label 'Cloud Migration has been disabled.';
        RunReplicationTxt: Label 'Full migration has been started. You can track the status on the management page.';
        FullReplicationTxt: Label 'Full migration';
        ReadMigrationWhitePaperTxt: Label '1. Read the Business Central Cloud Migration help.';
        ReadWhitePaperURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009758', Locked = true;
        HaveAllUsersExitTxt: Label '2. Have all users exit both the cloud tenant and on-premises solution.';
        RunFullMigrationTxt: Label '3. Run a migration by selecting Run Migration Now within the Cloud Migration Management page.';
        FixErrorsTxt: Label '4. Correct any necessary errors.';
        RunMigrationAgainTxt: Label '5. Run the migration again if you had to make any corrections in step #4.';
        DisableMigrationTxt: Label '6. Disable Cloud Migration in the Actions menu above.';
        ReviewPermissionsTxt: Label '7. Review and make necessary updates to users, user groups and permission sets.';
        InAgreement: Boolean;
        IsSuperAndSetupComplete: Boolean;
}