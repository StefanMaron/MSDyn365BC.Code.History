// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

permissionset 9515 "AAD User Management - Exec"
{
    Access = Public;
    Assignable = false;

    IncludedPermissionSets = "User Login Times - Read",
                             "Azure AD User - View",
                             "Azure AD Plan - View",
                             "Language - View";

    Permissions = tabledata User = rm,
                  tabledata "User Personalization" = r,
                  tabledata "User Property" = r;
}