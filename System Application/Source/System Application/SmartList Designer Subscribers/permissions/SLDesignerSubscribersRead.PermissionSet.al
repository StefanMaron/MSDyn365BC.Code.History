// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

PermissionSet 2888 "SL Designer Subscribers - Read"
{
    Access = Internal;
    Assignable = false;

    Permissions = tabledata "Query Navigation" = r,
                  tabledata "Query Navigation Validation" = R, // Needed because the record is Public
                  tabledata "SmartList Designer Handler" = R;
}
