page 9024 "Security Admin Role Center"
{
    Caption = 'Administration of users, user groups and permissions', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    Description = 'Manage users, users groups and permissions';
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
            part(Control12; "Users in User Groups Chart")
            {
                ApplicationArea = Basic, Suite;
            }
            part("Subscription Plans"; "Plans FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Subscription Plans';
                Editable = false;
            }
            part(Control4; "User Groups FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            part("Plan Permission Set"; "Plan Permission Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Plan Permission Set';
                Editable = false;
            }
            part(Control15; "Team Member Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control37; "Report Inbox Part")
            {
                AccessByPermission = TableData "Report Inbox" = R;
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(embedding)
        {
            action("User Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Groups';
                RunObject = Page "User Groups";
                ToolTip = 'Define user groups so that you can assign permission sets to multiple users easily. You can use a function to copy all permission sets from an existing user group to your new user group.';
            }
            action(Users)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Users';
                RunObject = Page Users;
                ToolTip = 'Set up the database users and assign their permission sets to define which database objects, and thereby which UI elements, they have access to, and in which companies. You can add users to user groups to make it easier to assign the same permission sets to multiple users. In the User Setup window, administrators can define periods of time during which specified users are able to post, and also specify if the system logs when users are logged on.';
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
                action(Action31)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Groups';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "User Groups";
                    ToolTip = 'Set up or modify user groups as a fast way of giving users access to the functionality that is relevant to their work.';
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
            group(SetupAndExtensions)
            {
                Caption = 'Setup & Extensions';
                Image = Setup;
                ToolTip = 'Overview and change system and application settings, and manage extensions and services';
                action("Assisted Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assisted Setup';
                    Image = QuestionaireSetup;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Assisted Setup";
                    ToolTip = 'Set up core functionality such as sales tax, sending documents as email, and approval workflow by running through a few pages that guide you through the information.';
                }
                action("Manual Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manual Setup';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Manual Setup";
                    ToolTip = 'Define your company policies for business departments and for general activities by filling setup windows manually.';
                }
                action("Service Connections")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Connections';
                    Image = ServiceTasks;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Service Connections";
                    ToolTip = 'Enable and configure external services, such as exchange rate updates, Microsoft Social Engagement, and electronic bank integration.';
                }
                action(Extensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extensions';
                    Image = NonStockItemSetup;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Extension Management";
                    ToolTip = 'Install extensions for greater functionality of the system.';
                }
                action(Workflows)
                {
                    ApplicationArea = Suite;
                    Caption = 'Workflows';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Workflows;
                    ToolTip = 'Set up or enable workflows that connect business-process tasks performed by different users. System tasks, such as automatic posting, can be included as steps in workflows, preceded or followed by user tasks. Requesting and granting approval to create new records are typical workflow steps.';
                }
            }
        }
        area(processing)
        {
            group(Flow)
            {
                Caption = 'Flow';
                action("Manage Flows")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manage Flows';
                    Image = Flow;
                    RunObject = Page "Flow Selector";
                    ToolTip = 'View or edit automated workflows created with Microsoft Flow.';
                }
            }
        }
    }
}

