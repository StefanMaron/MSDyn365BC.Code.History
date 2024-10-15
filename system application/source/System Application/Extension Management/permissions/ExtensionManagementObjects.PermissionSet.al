// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps;

using System.Environment.Configuration;

permissionset 2504 "Extension Management - Objects"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Guided Experience - Objects";

    Permissions = codeunit "Data Out Of Geo. App" = X,
                  codeunit "Extension Management" = X,
                  codeunit "Extension Marketplace" = X,
                  page "Delete Orphaned Extension Data" = X,
                  page "Extension Deployment Status" = X,
                  page "Extension Details" = X,
                  page "Extension Details Part" = X,
                  page "Extension Installation" = X,
                  page "Extension Logo Part" = X,
                  page "Extension Management" = X,
                  page "Extension Marketplace" = X,
                  page "Extension Settings" = X,
                  page "Extension Setup Launcher" = X,
                  page "Extn. Installation Progress" = X,
                  page "Extn. Orphaned App Details" = X,
                  page "Extn Deployment Status Detail" = X,
                  page "Marketplace Extn Deployment" = X,
                  page "Upload And Deploy Extension" = X,
                  table "Extension Installation" = X;
}
