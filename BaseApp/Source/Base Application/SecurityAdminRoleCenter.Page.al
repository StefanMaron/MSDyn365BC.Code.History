page 9024 "Security Admin Role Center"
{
    Caption = 'Administration of users, security groups and permissions', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    Description = 'Manage users, security groups and permissions';
    Editable = false;
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control6; "Headline RC Security Admin")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control7; "User Security Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Emails"; "Email Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control15; "Team Member Activities")
            {
                ApplicationArea = Suite;
            }
#if not CLEAN22
            part(Control12; "Users in User Groups Chart")
            {
                ApplicationArea = Basic, Suite;
                Visible = false; // cannot control the visibility with the feature switch
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the Security Group Members Chart part.';
                ObsoleteTag = '22.0';
            }
#endif
            part("Security Group Members Chart"; "Security Group Members Chart")
            {
                ApplicationArea = Basic, Suite;
            }
#if not CLEAN20
            part("Subscription Plans"; "Plans FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Licenses';
                Editable = false;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The part is not actionable.';
                ObsoleteTag = '20.0';
            }
#endif
#if not CLEAN22
            part(Control4; "User Groups FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Visible = false; // cannot control the visibility with the feature switch
                ObsoleteState = Pending;
                ObsoleteReason = 'Removed, use the Security Groups page directly.';
                ObsoleteTag = '22.0';
            }
#endif
            part(LicenseConfigurationPart; "Plan Configurations Part")
            {
                ApplicationArea = All;
                Caption = 'Default Permissions per License';
            }
#if not CLEAN20
            part("Plan Permission Set"; "Plan Permission Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Plan Permission Set';
                Editable = false;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The part is irrelevant as it shows only the default permission sets plans since now custom permissions set can be configured per plan.';
                ObsoleteTag = '20.0';
            }
#endif
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                AccessByPermission = TableData "Power BI User Configuration" = I;
                ApplicationArea = Basic, Suite;
            }
            part("My Job Queue"; "My Job Queue")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part(Control37; "Report Inbox Part")
            {
                AccessByPermission = TableData "Report Inbox" = R;
                ApplicationArea = Basic, Suite;
            }
#if not CLEAN21
            part("Power BI Report Spinner Part"; "Power BI Report Spinner Part")
            {
                AccessByPermission = TableData "Power BI User Configuration" = I;
                ApplicationArea = Basic, Suite;
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by PowerBIEmbeddedReportPart';
                Visible = false;
                ObsoleteTag = '21.0';
            }
#endif
            systempart(MyNotes; MyNotes)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(embedding)
        {
#if not CLEAN22
            action("User Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Groups';
                RunObject = Page "User Groups";
                ToolTip = 'Define user groups so that you can assign permission sets to multiple users easily. You can use a function to copy all permission sets from an existing user group to your new user group.';
                Visible = false; // cannot control the visibility with the feature switch
                ObsoleteState = Pending;
                ObsoleteReason = 'Replaced by the Security Groups action.';
                ObsoleteTag = '22.0';
            }
#endif
            action("Security Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Groups';
                RunObject = Page "Security Groups";
                ToolTip = 'Specify security groups so that you can assign permission sets to multiple users easily. You can use a function to copy all permission sets from an existing security group to your new security group.';
            }
            action(Users)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                RunObject = Page Users;
                ToolTip = 'Set up the database users and assign their permission sets to define which database objects, and thereby which UI elements, they have access to, and in which companies. In the User Setup window, administrators can define periods of time during which specified users are able to post, and also specify if the system logs when users are logged on.';
            }
            action("User Review Log")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Review Log';
                RunObject = Page "Activity Log";
                RunPageView = WHERE("Table No Filter" = FILTER(9062));
                ToolTip = 'Monitor users'' activities in the database by reviewing changes that are made to data in tables that you select to track. Change log entries are chronologically ordered and show changes that are made to the fields on the specified tables. ';
            }
            action("Permission Sets")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permission Sets';
                RunObject = Page "Permission Sets";
                ToolTip = 'Define collections of permissions each representing different access rights to certain database objects, and review which permission sets are assigned to users of the database to enable them to perform their tasks in the user interface. Users are assigned permission sets according to the Office 365 subscription plan.';
            }
            action(Plans)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Plans';
                RunObject = Page Plans;
                RunPageMode = View;
                ToolTip = 'View the details of your Office 365 subscription, including your different user profiles and their assigned licenses, such as the Team Member license. Note that users are created in Office 365 and then imported into Business Central with the Get Users from Office 365 action.';
            }
        }
        area(sections)
        {
            group("User Management")
            {
                Caption = 'User Management';
                action(Action30)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Users;
                    ToolTip = 'View or edit users that will be configured in the database.';
                }
#if not CLEAN22
                action(Action31)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Groups';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "User Groups";
                    ToolTip = 'Set up or modify user groups as a fast way of giving users access to the functionality that is relevant to their work.';
                    Visible = false; // cannot control the visibility with the feature switch
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the Security Groups Section action.';
                    ObsoleteTag = '22.0';
                }
#endif
                action("Security Groups Section")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Security Groups';
                    RunObject = Page "Security Groups";
                    ToolTip = 'Set up or modify security groups as a fast way of giving users access to the functionality that is relevant to their work.';
                }
                action(Action28)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Sets';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Permission Sets";
                    ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';
                }
                action(Action27)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Plans';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Plans;
                    RunPageMode = View;
                    ToolTip = 'View subscription plans.';
                }
                action(Action29)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Review Log';
                    RunObject = Page "Activity Log";
                    RunPageView = WHERE("Table No Filter" = FILTER(9062));
                    ToolTip = 'View a log of users'' activities in the database.';
                }
            }
            group("App Management")
            {
                Caption = 'App Management';
                action("Apps")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apps';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "AAD Application List";
                    ToolTip = 'View or edit apps.';
                }
            }
            group("Data Privacy")
            {
                Caption = 'Data Privacy';
                Image = HumanResources;
                ToolTip = 'Manage data privacy classifications, and respond to requests from data subjects.';
                action("Page Data Classifications")
                {
                    ApplicationArea = All;
                    Caption = 'Data Classifications';
                    RunObject = Page "Data Classification Worksheet";
                    ToolTip = 'View your current data classifications';
                }
                action(Classified)
                {
                    ApplicationArea = All;
                    Caption = 'Classified Fields';
                    RunObject = Page "Data Classification Worksheet";
                    RunPageView = WHERE("Data Sensitivity" = FILTER(<> Unclassified));
                    ToolTip = 'View only classified fields';
                }
                action(Unclassified)
                {
                    ApplicationArea = All;
                    Caption = 'Unclassified Fields';
                    RunObject = Page "Data Classification Worksheet";
                    RunPageView = WHERE("Data Sensitivity" = CONST(Unclassified));
                    ToolTip = 'View only unclassified fields';
                }
                action("Page Data Subjects")
                {
                    ApplicationArea = All;
                    Caption = 'Data Subjects';
                    RunObject = Page "Data Subject";
                    ToolTip = 'View your potential data subjects';
                }
                action("Page Change Log Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Change Log Entries';
                    RunObject = Page "Change Log Entries";
                    ToolTip = 'View the log with all the changes in your system';
                }
            }
        }
#if not CLEAN21
        area(processing)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'This area has been moved to the tab dedicated to Power Automate';
            ObsoleteTag = '21.0';
            group(Flow)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'This group has been moved to the tab dedicated to Power Automate';
                ObsoleteTag = '21.0';
                Caption = 'Power Automate';
                action("Manage Flows")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manage flows';
                    Image = Flow;
                    Visible = false;
                    RunObject = Page "Flow Selector";
                    ToolTip = 'View or edit automated flows created with Power Automate.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This action has been moved to the tab dedicated to Power Automate';
                    ObsoleteTag = '21.0';
                }
            }
        }
#endif
    }
}

