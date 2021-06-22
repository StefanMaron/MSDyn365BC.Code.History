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
                        field(ReadWhitePaperTxt; ReadWhitePaperTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '';
                            trigger OnDrillDown()
                            begin
                                Hyperlink(ReadWhitePaperURLTxt);
                            end;
                        }
                        field(ExitAllUsersTxt; ExitAllUsersTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RunFullReplicationTxt; RunFullReplicationTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(CorrectErrorsTxt; CorrectErrorsTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(RunReplicationAgainTxt; RunReplicationAgainTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(DisableIntelligentCloudTxt; DisableIntelligentCloudTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(ReviewUserPermissionsTxt; ReviewUserPermissionsTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field(ChecklistAgreement; ChecklistAgreement)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'I have read and understand the recommended steps';
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
                Enabled = IsSuperAndSetupComplete and ChecklistAgreement;
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Cloud Migration';
                ToolTip = 'Disables Cloud Migration setup.';
                Image = Delete;

                trigger OnAction()
                begin
                    if Dialog.Confirm(DisableReplicationConfirmQst, false) then begin
                        HybridDeployment.DisableReplication();
                        Message(DisablereplicationTxt);
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
        ReadWhitePaperTxt: Label '1. Read the Business Central Cloud Migration help.';
        ReadWhitePaperURLTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009758', Locked = true;
        ExitAllUsersTxt: Label '2. Have all users exit both the cloud tenant and on-premises solution.';
        RunFullReplicationTxt: Label '3. Run a full migration.';
        CorrectErrorsTxt: Label '4. Correct any necessary errors.';
        RunReplicationAgainTxt: Label '5. Run the migration again.';
        DisableIntelligentCloudTxt: Label '6. Disable Cloud Migration.';
        ReviewUserPermissionsTxt: Label '7. Review and make necessary updates to users, user groups and permission sets.';
        ChecklistAgreement: Boolean;
        IsSuperAndSetupComplete: Boolean;
}