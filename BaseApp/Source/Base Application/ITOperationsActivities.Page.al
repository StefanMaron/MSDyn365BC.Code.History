page 9072 "IT Operations Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Administration Cue";

    layout
    {
        area(content)
        {
#if not CLEAN20
            cuegroup("Intelligent Cloud")
            {
                Caption = 'Intelligent Cloud';
                Visible = false;
                ObsoleteTag = '20.0';
                ObsoleteReason = 'Intelligent Cloud Insights is discontinued.';
                ObsoleteState = Pending;

                actions
                {
                    action("Learn More")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Learn More';
                        Image = TileInfo;
                        RunPageMode = View;
                        ToolTip = ' Learn more about the Intelligent Cloud and how it can help your business.';
                        Visible = false;
                        ObsoleteTag = '20.0';
                        ObsoleteReason = 'Intelligent Cloud Insights is discontinued.';
                        ObsoleteState = Pending;

                        trigger OnAction()
                        var
                            IntelligentCloudManagement: Codeunit "Intelligent Cloud Management";
                        begin
                            HyperLink(IntelligentCloudManagement.GetIntelligentCloudLearnMoreUrl());
                        end;
                    }
                }
            }
#endif  
            cuegroup(Administration)
            {
                Caption = 'Administration';
                field("Job Queue Entries Until Today"; Rec."Job Queue Entries Until Today")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Job Queue Entries";
                    ToolTip = 'Specifies the number of job queue entries that are displayed in the Administration Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("User Posting Period"; Rec."User Posting Period")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "User Setup";
                    ToolTip = 'Specifies the period number of the documents that are displayed in the Administration Cue on the Role Center.';
                }
                field("No. Series Period"; Rec."No. Series Period")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "No. Series Lines";
                    ToolTip = 'Specifies the period number of the number series for the documents that are displayed in the Administration Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Job Queue Entry Card")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Job Queue Entry Card';
                        RunObject = Page "Job Queue Entry Card";
                        ToolTip = 'Change the settings for the job queue entry.';
                    }
                    action("Edit User Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit User Setup';
                        RunObject = Page "User Setup";
                        ToolTip = 'Manage users and their permissions.';
                    }
                    action("Edit Migration Overview")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Migration Overview';
                        RunObject = Page "Config. Package Card";
                        ToolTip = 'Get an overview of data migration tasks.';
                    }
                }
            }
            cuegroup("Data Integration")
            {
                Caption = 'Data Integration';
                Visible = ShowDataIntegrationCues;
                field("CDS Integration Errors"; Rec."CDS Integration Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Integration Errors';
                    DrillDownPageID = "Integration Synch. Error List";
                    ToolTip = 'Specifies the number of errors related to data integration.';
                    Visible = ShowDataIntegrationCues;
                }
                field("Coupled Data Synch Errors"; Rec."Coupled Data Synch Errors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    DrillDownPageID = "CRM Skipped Records";
                    ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
                    Visible = ShowD365SIntegrationCues;
                }
            }
            cuegroup("Data Privacy")
            {
                Caption = 'Data Privacy';
                field(UnclassifiedFields; UnclassifiedFields)
                {
                    ApplicationArea = All;
                    Caption = 'Fields Missing Data Sensitivity';
                    ToolTip = 'Specifies the number fields with Data Sensitivity set to unclassified.';

                    trigger OnDrillDown()
                    var
                        DataSensitivity: Record "Data Sensitivity";
                    begin
                        DataSensitivity.SetRange("Company Name", CompanyName);
                        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
                        PAGE.Run(PAGE::"Data Classification Worksheet", DataSensitivity);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        DataSensitivity: Record "Data Sensitivity";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        DataClassNotificationMgt: Codeunit "Data Class. Notification Mgt.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        DataClassNotificationMgt.ShowNotifications();

        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        UnclassifiedFields := DataSensitivity.Count();

        Rec.SetFilter("Date Filter2", '<=%1', CreateDateTime(Today, 0T));
        Rec.SetFilter("Date Filter3", '>%1', CreateDateTime(Today, 0T));
        Rec.SetRange("User ID Filter", UserId());

        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
        IntegrationSynchJobErrors.SetDataIntegrationUIElementsVisible(ShowDataIntegrationCues);
        ShowD365SIntegrationCues := CRMIntegrationManagement.IsIntegrationEnabled() or CDSIntegrationMgt.IsIntegrationEnabled();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        UnclassifiedFields: Integer;
        ShowIntelligentCloud: Boolean;
        ShowD365SIntegrationCues: Boolean;
        ShowDataIntegrationCues: Boolean;
}

