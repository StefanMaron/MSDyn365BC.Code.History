permissionset 184 "BaseApp Login - Objects"
{
    Access = Internal;
    Assignable = false;
    Permissions = codeunit "API Webhook Notification Mgt." = X,
                  codeunit "Application Area Cache" = X,
                  codeunit "Application Area Mgmt." = X,
                  codeunit "Application Area Mgmt. Facade" = X,
                  codeunit "Assisted Company Setup" = X,
                  codeunit "Automation - API Management" = X,
                  codeunit "Change Log Management" = X,
                  codeunit "Company Information Mgt." = X,
                  codeunit "Conf./Personalization Mgt." = X,
                  codeunit "CRM Integration Management" = X,
                  codeunit "Document Service Management" = X,
                  codeunit "GlobalTriggerManagement" = X,
                  codeunit "Graph Mgt - General Tools" = X,
                  codeunit "Identity Management" = X,
                  codeunit "Integration Management" = X,
                  codeunit "License Agreement Management" = X,
                  codeunit LogInManagement = X,
                  codeunit "Manage User Plans And Groups" = X,
                  codeunit "My Platform Notifications" = X,
                  codeunit "My Settings" = X,
                  codeunit "Permission Manager" = X,
                  codeunit "SaaS Log In Management" = X,
                  codeunit "Type Helper" = X,
                  codeunit "User Groups" = X,
                  page "Additional Customer Terms" = X,
#if not CLEAN19
                  page "My Settings" = X,
#endif
                  tabledata "Onboarding Signal" = rimd,
                  table "Assisted Company Setup Status" = X,
                  table "License Agreement" = X,
                  table "Company Information" = X,
                  table "CRM Connection Setup" = X,
                  table "My Notifications" = X;
}